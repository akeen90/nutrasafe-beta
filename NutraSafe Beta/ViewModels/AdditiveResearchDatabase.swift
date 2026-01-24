//
//  AdditiveResearchDatabase.swift
//  NutraSafe Beta
//
//  Comprehensive additive reactions and research database
//  Contains evidence-based health claims with proper citations
//

import Foundation
import SwiftUI

// MARK: - Research Strength Rating

enum ResearchStrength: String {
    case strong = "Strong evidence"
    case moderate = "Moderate evidence"
    case emerging = "Emerging evidence"
    case limited = "Limited evidence"

    var color: Color {
        switch self {
        case .strong: return .red
        case .moderate: return .orange
        case .emerging: return .yellow
        case .limited: return .green
        }
    }

    var icon: String {
        switch self {
        case .strong: return "exclamationmark.triangle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .emerging: return "info.circle.fill"
        case .limited: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Additive Research Entry

struct AdditiveResearchEntry {
    let code: String
    let whatItIs: String              // Proper description of what the additive is
    let commonFoods: [String]
    let knownReactions: [String]
    let researchSummary: String
    let researchStrength: ResearchStrength
}

// MARK: - Additive Research Database

struct AdditiveResearchDatabase {

    static let shared = AdditiveResearchDatabase()

    private let entries: [String: AdditiveResearchEntry]

    private init() {
        var map: [String: AdditiveResearchEntry] = [:]

        // MARK: - Southampton Six (Azo Dyes) - Child Hyperactivity

        map["e102"] = AdditiveResearchEntry(
            code: "E102",
            whatItIs: "A bright lemon-yellow synthetic dye made from coal tar. One of the 'Southampton Six' additives linked to hyperactivity in children. Also known as Tartrazine.",
            commonFoods: ["Soft drinks", "Sweets", "Ice lollies", "Mushy peas", "Pickles", "Cake decorations", "Custard powder"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Urticaria (hives) in sensitive individuals",
                "Asthma symptoms in aspirin-sensitive people",
                "Allergic reactions including skin rashes"
            ],
            researchSummary: "The 2007 Southampton Study (The Lancet) found E102 (Tartrazine) significantly increased hyperactivity in children. The FSA now requires products containing this to carry warnings. EFSA reduced the ADI in 2009 due to concerns. Some countries have banned it entirely.",
            researchStrength: .strong
        )

        map["e104"] = AdditiveResearchEntry(
            code: "E104",
            whatItIs: "A greenish-yellow synthetic dye derived from coal tar. One of the 'Southampton Six' linked to behavioural issues. Also known as Quinoline Yellow.",
            commonFoods: ["Smoked haddock", "Scotch eggs", "Pickles", "Sweets", "Ice cream", "Soft drinks"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Allergic reactions in sensitive individuals",
                "Contact dermatitis",
                "May exacerbate asthma"
            ],
            researchSummary: "Quinoline Yellow was one of the Southampton Six additives linked to hyperactivity in the 2007 Lancet study. The EU requires warning labels. Banned in Australia, Japan, Norway, and the USA for food use.",
            researchStrength: .strong
        )

        map["e110"] = AdditiveResearchEntry(
            code: "E110",
            whatItIs: "A reddish-orange synthetic azo dye derived from petroleum. One of the 'Southampton Six' colours requiring warning labels. Also known as Sunset Yellow FCF.",
            commonFoods: ["Orange squash", "Marmalade", "Apricot jam", "Citrus sweets", "Hot chocolate mix", "Cheese sauce mixes"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Hives and swelling",
                "Stomach upset and vomiting",
                "May trigger asthma attacks",
                "Cross-reactivity with aspirin sensitivity"
            ],
            researchSummary: "Sunset Yellow is banned in Norway and Finland. The Southampton Study (The Lancet, 2007) confirmed its link to childhood hyperactivity. Products must carry warnings in the EU/UK. Some studies suggest it may affect kidney and adrenal function at high doses.",
            researchStrength: .strong
        )

        map["e122"] = AdditiveResearchEntry(
            code: "E122",
            whatItIs: "A dark red to maroon synthetic azo dye. One of the 'Southampton Six' colours linked to hyperactivity. Also known as Carmoisine or Azorubine.",
            commonFoods: ["Cheesecake", "Jams", "Sweets", "Marzipan", "Swiss roll", "Yogurts", "Jelly"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Allergic reactions including hives",
                "May worsen asthma symptoms",
                "Skin rashes in sensitive individuals"
            ],
            researchSummary: "Carmoisine (Azorubine) was identified in the Southampton Study (The Lancet, 2007) as contributing to hyperactivity. Banned in Austria, Japan, Norway, Sweden, and the USA. Required to carry warnings in EU/UK products.",
            researchStrength: .strong
        )

        map["e124"] = AdditiveResearchEntry(
            code: "E124",
            whatItIs: "A strawberry-red synthetic azo dye derived from coal tar. One of the 'Southampton Six' requiring mandatory warnings. Also known as Ponceau 4R or Cochineal Red A.",
            commonFoods: ["Tinned strawberries", "Fruit pie filling", "Salami", "Seafood dressings", "Cheesecake", "Trifle"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Severe allergic reactions possible",
                "Asthma attacks in sensitive individuals",
                "Hives and angioedema"
            ],
            researchSummary: "Ponceau 4R is banned in the USA and Norway. One of the Southampton Six linked to childhood behavioural problems (The Lancet, 2007). Must carry warnings in EU/UK. The FSA advises parents of hyperactive children to avoid it.",
            researchStrength: .strong
        )

        map["e129"] = AdditiveResearchEntry(
            code: "E129",
            whatItIs: "A dark red synthetic azo dye commonly used as a replacement for the natural carmine. One of the 'Southampton Six' colours. Also known as Allura Red AC.",
            commonFoods: ["Sweets", "Soft drinks", "Medicines", "Cosmetics", "Biscuits", "Sauces"],
            knownReactions: [
                "Hyperactivity and attention problems in children",
                "Allergic reactions",
                "May worsen ADHD symptoms",
                "Hives and skin reactions"
            ],
            researchSummary: "Allura Red AC is banned in Denmark, Belgium, France, Germany, Switzerland, Sweden, Austria, and Norway. The sixth member of the Southampton Six (The Lancet, 2007). The FSA recommends avoiding it for children showing hyperactive behaviour.",
            researchStrength: .strong
        )

        // MARK: - Other Colours

        map["e100"] = AdditiveResearchEntry(
            code: "E100",
            whatItIs: "A bright yellow natural colour extracted from turmeric root (Curcuma longa). Has been used as a spice and dye for thousands of years.",
            commonFoods: ["Curry dishes", "Mustard", "Margarine", "Rice dishes", "Pickles", "Cheese"],
            knownReactions: [
                "Generally well-tolerated",
                "May cause stomach upset in very high doses",
                "Rare skin reactions reported"
            ],
            researchSummary: "Curcumin is generally considered safe with potential anti-inflammatory benefits. EFSA (2010) established an ADI of 3mg/kg body weight. Some research suggests health benefits, though at supplement doses rather than food colouring levels.",
            researchStrength: .limited
        )

        map["e101"] = AdditiveResearchEntry(
            code: "E101",
            whatItIs: "A yellow-orange natural colour also known as Vitamin B2 (Riboflavin). Essential nutrient that can also be produced synthetically.",
            commonFoods: ["Cereals", "Baby foods", "Sauces", "Cheese products", "Nutritional supplements"],
            knownReactions: [
                "Generally very safe as it's an essential vitamin",
                "May turn urine bright yellow (harmless)"
            ],
            researchSummary: "Riboflavin is an essential B vitamin with no safety concerns at normal food additive levels. Excess is simply excreted in urine. EFSA considers it completely safe.",
            researchStrength: .limited
        )

        map["e120"] = AdditiveResearchEntry(
            code: "E120",
            whatItIs: "A deep crimson-red natural colour extracted from crushed cochineal insects (female scale insects). Used since Aztec times. Also called Carmine or Natural Red 4.",
            commonFoods: ["Yogurts", "Sweets", "Jams", "Desserts", "Alcoholic drinks", "Cosmetics"],
            knownReactions: [
                "Allergic reactions in some people",
                "Anaphylaxis reported (rare but serious)",
                "Not suitable for vegetarians/vegans"
            ],
            researchSummary: "Cochineal can cause severe allergic reactions in sensitive individuals. The FDA requires it to be listed by name. Generally safe for most people but those with allergies should avoid it. Not suitable for vegetarians.",
            researchStrength: .moderate
        )

        map["e127"] = AdditiveResearchEntry(
            code: "E127",
            whatItIs: "A cherry-pink to red synthetic fluorescent dye. Also known as Erythrosine. Only permitted in limited foods due to concerns about thyroid effects.",
            commonFoods: ["Glacé cherries", "Cocktail cherries", "Some sweets"],
            knownReactions: [
                "May affect thyroid function",
                "Phototoxic reactions possible",
                "Allergic reactions"
            ],
            researchSummary: "Erythrosine contains iodine and may affect thyroid function. Use is heavily restricted in the EU/UK. EFSA (2011) significantly reduced the ADI. The FDA limits its use in the USA.",
            researchStrength: .moderate
        )

        map["e131"] = AdditiveResearchEntry(
            code: "E131",
            whatItIs: "A dark blue synthetic dye. Also known as Patent Blue V. Primarily used for medical purposes and some foods.",
            commonFoods: ["Scotch eggs", "Some sweets", "Medical dyes"],
            knownReactions: [
                "Allergic reactions",
                "Anaphylaxis reported (rare)",
                "May cause skin discoloration"
            ],
            researchSummary: "Patent Blue V is banned in Australia, Norway, and the USA. Can cause severe allergic reactions. Primarily used as a medical dye for sentinel node detection.",
            researchStrength: .moderate
        )

        map["e132"] = AdditiveResearchEntry(
            code: "E132",
            whatItIs: "A bright royal blue synthetic dye derived from coal tar. Also known as Indigo Carmine or Indigotine.",
            commonFoods: ["Sweets", "Ice cream", "Biscuits", "Tablets"],
            knownReactions: [
                "May cause nausea and vomiting",
                "Skin reactions in sensitive individuals",
                "High blood pressure reported (rare)"
            ],
            researchSummary: "Indigo Carmine can cause allergic reactions in sensitive individuals. EFSA (2014) maintained the ADI but noted limitations in available data. Generally considered safe at permitted levels.",
            researchStrength: .emerging
        )

        map["e133"] = AdditiveResearchEntry(
            code: "E133",
            whatItIs: "A bright blue synthetic dye derived from coal tar. Also known as Brilliant Blue FCF. Often combined with yellow colours to make green.",
            commonFoods: ["Sweets", "Ice cream", "Canned peas", "Dairy products", "Soft drinks"],
            knownReactions: [
                "Allergic reactions in sensitive individuals",
                "May worsen asthma in some people",
                "Hyperactivity (less evidence than Southampton Six)"
            ],
            researchSummary: "Brilliant Blue FCF is banned in some European countries. Generally considered one of the safer synthetic blues but can cause reactions in aspirin-sensitive individuals.",
            researchStrength: .emerging
        )

        map["e140"] = AdditiveResearchEntry(
            code: "E140",
            whatItIs: "A natural green colour extracted from plants (chlorophyll). The same pigment that makes leaves green. Can also include copper complexes (E141).",
            commonFoods: ["Pasta", "Chewing gum", "Vegetables", "Ice cream", "Soups"],
            knownReactions: [
                "Generally very safe",
                "Photosensitivity possible at very high doses"
            ],
            researchSummary: "Chlorophyll is a natural plant pigment considered very safe. No significant adverse effects reported at food additive levels. EFSA (2015) found no safety concerns.",
            researchStrength: .limited
        )

        map["e141"] = AdditiveResearchEntry(
            code: "E141",
            whatItIs: "Chlorophyll complexed with copper to give a more stable, vivid green colour. Known as Copper Chlorophyll or Copper Chlorophyllin.",
            commonFoods: ["Green vegetables", "Pasta", "Ice cream", "Sweets"],
            knownReactions: [
                "Generally well-tolerated",
                "Copper accumulation concerns at very high intakes"
            ],
            researchSummary: "Copper chlorophyll is more stable than regular chlorophyll. EFSA (2015) set an ADI but noted copper absorption is limited. Generally considered safe at permitted levels.",
            researchStrength: .limited
        )

        map["e150a"] = AdditiveResearchEntry(
            code: "E150a",
            whatItIs: "A brown colour made by heating carbohydrates (sugar caramelisation). The simplest form of caramel colour - plain caramel.",
            commonFoods: ["Beer", "Whisky", "Gravy", "Soy sauce", "Baked goods"],
            knownReactions: [
                "Generally well-tolerated",
                "No significant adverse effects reported"
            ],
            researchSummary: "Plain caramel (Class I) is made simply by heating sugars with no additives. EFSA considers it safe with no specific ADI required. The most benign form of caramel colour.",
            researchStrength: .limited
        )

        map["e150b"] = AdditiveResearchEntry(
            code: "E150b",
            whatItIs: "A brown colour made by heating carbohydrates with sulphite compounds. Known as Caustic Sulphite Caramel (Class II).",
            commonFoods: ["Soy sauce", "Some beers", "Dark spirits"],
            knownReactions: [
                "Contains sulphites - may trigger asthma",
                "Allergic reactions in sensitive individuals"
            ],
            researchSummary: "Caustic sulphite caramel contains sulphites which must be declared. People with sulphite sensitivity should avoid it. Part of the caramel colour family.",
            researchStrength: .moderate
        )

        map["e150c"] = AdditiveResearchEntry(
            code: "E150c",
            whatItIs: "A brown colour made by heating carbohydrates with ammonia compounds. Known as Ammonia Caramel (Class III).",
            commonFoods: ["Beer", "Soy sauce", "Gravy browning", "Some baked goods"],
            knownReactions: [
                "Contains 4-MEI (possible carcinogen)",
                "Generally well-tolerated at food levels"
            ],
            researchSummary: "Ammonia caramel contains 4-MEI, which California lists as a possible carcinogen. EFSA (2011) set limits but considered it safe at permitted levels. Some companies have reformulated to reduce 4-MEI.",
            researchStrength: .emerging
        )

        map["e150d"] = AdditiveResearchEntry(
            code: "E150d",
            whatItIs: "A brown colour made by heating carbohydrates with both sulphite and ammonia compounds. Known as Sulphite Ammonia Caramel (Class IV). The most commonly used caramel colour.",
            commonFoods: ["Cola drinks", "Soy sauce", "Dark spirits", "Gravies"],
            knownReactions: [
                "Contains sulphites - may trigger asthma",
                "Allergic reactions in sensitive individuals",
                "Contains 4-MEI (possible carcinogen) - debated"
            ],
            researchSummary: "Sulphite ammonia caramel contains sulphites requiring allergen declaration. Also contains 4-MEI which California lists as a carcinogen, though levels in foods are generally low.",
            researchStrength: .moderate
        )

        map["e153"] = AdditiveResearchEntry(
            code: "E153",
            whatItIs: "A black colour made from charred vegetable matter (vegetable carbon) or bones. Also known as Carbon Black or Vegetable Carbon.",
            commonFoods: ["Liquorice", "Jelly beans", "Jam", "Fish paste", "Confectionery coatings"],
            knownReactions: [
                "Generally considered safe",
                "May contain polycyclic aromatic hydrocarbons (PAHs)"
            ],
            researchSummary: "Vegetable carbon is generally considered safe. EFSA (2012) noted potential PAH contamination and set limits. Only permitted in specific foods in the EU/UK.",
            researchStrength: .limited
        )

        map["e160a"] = AdditiveResearchEntry(
            code: "E160a",
            whatItIs: "An orange-red natural colour extracted from carrots, palm oil, or algae. The same pigment that makes carrots orange. Also known as Carotene.",
            commonFoods: ["Margarine", "Butter", "Cheese", "Soft drinks", "Cakes", "Soups"],
            knownReactions: [
                "Generally very safe",
                "May cause orange skin colour (carotenemia) at very high doses - harmless"
            ],
            researchSummary: "Beta-carotene is a precursor to Vitamin A and is considered very safe. Can cause harmless orange skin at supplement doses. No safety concerns at food colouring levels.",
            researchStrength: .limited
        )

        map["e160b"] = AdditiveResearchEntry(
            code: "E160b",
            whatItIs: "A natural orange-red colour extracted from the seeds of the achiote tree (Bixa orellana). Used for centuries in Latin American cuisine. Also known as Annatto or Bixin/Norbixin.",
            commonFoods: ["Cheese", "Butter", "Margarine", "Custard", "Cakes", "Smoked fish"],
            knownReactions: [
                "Skin rashes and hives",
                "Headaches in sensitive individuals",
                "Possible irritable bowel symptoms",
                "Rarely, anaphylactic reactions"
            ],
            researchSummary: "Annatto is a natural colour but can cause allergic reactions. Journal of Paediatrics and Child Health (2009) found some children showed behavioural reactions in controlled trials. Not part of Southampton Six but watch for sensitivity.",
            researchStrength: .emerging
        )

        map["e160c"] = AdditiveResearchEntry(
            code: "E160c",
            whatItIs: "A red-orange natural colour extracted from paprika peppers (Capsicum annuum). The same pigment that gives peppers their colour. Also known as Paprika Extract or Capsanthin.",
            commonFoods: ["Sauces", "Cheese", "Salad dressings", "Snacks", "Processed meats"],
            knownReactions: [
                "Generally well-tolerated",
                "May cause reactions in people allergic to peppers"
            ],
            researchSummary: "Paprika extract is generally considered safe. Contains capsaicinoids which may cause sensitivity in some people allergic to peppers. EFSA (2015) found no safety concerns.",
            researchStrength: .limited
        )

        map["e160d"] = AdditiveResearchEntry(
            code: "E160d",
            whatItIs: "A red natural colour extracted from tomatoes. The same antioxidant that makes tomatoes red. Also known as Lycopene.",
            commonFoods: ["Tomato products", "Fruit drinks", "Soups", "Breakfast cereals"],
            knownReactions: [
                "Generally very safe",
                "May interact with some medications at supplement doses"
            ],
            researchSummary: "Lycopene is a powerful antioxidant considered very safe. May have health benefits including prostate health. No safety concerns at food colouring levels.",
            researchStrength: .limited
        )

        map["e160e"] = AdditiveResearchEntry(
            code: "E160e",
            whatItIs: "An orange natural colour found in many fruits and vegetables. Also known as Beta-Apo-8'-Carotenal.",
            commonFoods: ["Orange drinks", "Cheese", "Margarine"],
            knownReactions: [
                "Generally well-tolerated",
                "Similar safety profile to other carotenoids"
            ],
            researchSummary: "Beta-apo-8'-carotenal is chemically similar to beta-carotene and is considered safe. EFSA (2012) established an ADI but noted limited data.",
            researchStrength: .limited
        )

        map["e161b"] = AdditiveResearchEntry(
            code: "E161b",
            whatItIs: "A yellow natural colour found in egg yolks and chicken skin. Responsible for the golden colour of free-range eggs. Also known as Lutein.",
            commonFoods: ["Chicken feed", "Sauces", "Confectionery"],
            knownReactions: [
                "Generally very safe",
                "May support eye health"
            ],
            researchSummary: "Lutein is a natural carotenoid associated with eye health benefits. No safety concerns. Often taken as a supplement for macular health.",
            researchStrength: .limited
        )

        map["e162"] = AdditiveResearchEntry(
            code: "E162",
            whatItIs: "A deep purplish-red natural colour extracted from beetroot. The same pigment that stains your hands when preparing beetroot. Also known as Beetroot Red or Betanin.",
            commonFoods: ["Ice cream", "Yogurts", "Sweets", "Soups", "Tomato products", "Jams"],
            knownReactions: [
                "Generally very safe",
                "May cause red urine (beeturia) - harmless",
                "Rare allergic reactions"
            ],
            researchSummary: "Beetroot red is considered one of the safest food colours. May cause harmless red colouration of urine. No safety concerns at food levels. Often used as a natural alternative to synthetic reds.",
            researchStrength: .limited
        )

        map["e163"] = AdditiveResearchEntry(
            code: "E163",
            whatItIs: "Natural red, purple, and blue colours found in fruits and vegetables like grapes, berries, and red cabbage. Also known as Anthocyanins.",
            commonFoods: ["Fruit drinks", "Jams", "Yogurts", "Confectionery", "Ice cream"],
            knownReactions: [
                "Generally very safe",
                "Potential health benefits as antioxidants"
            ],
            researchSummary: "Anthocyanins are natural plant pigments with antioxidant properties. Considered very safe with potential health benefits. No safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e170"] = AdditiveResearchEntry(
            code: "E170",
            whatItIs: "A white colour and anti-caking agent derived from limestone or chalk. The same compound found in eggshells and chalk. Also known as Calcium Carbonate.",
            commonFoods: ["Bread", "Confectionery", "Supplements", "Toothpaste"],
            knownReactions: [
                "Generally very safe",
                "May cause digestive issues at very high doses"
            ],
            researchSummary: "Calcium carbonate is considered completely safe and is used as a calcium supplement. No safety concerns. Also used as an antacid.",
            researchStrength: .limited
        )

        map["e171"] = AdditiveResearchEntry(
            code: "E171",
            whatItIs: "A bright white colour made from titanium ore. Used to make foods intensely white and opaque. Also known as Titanium Dioxide.",
            commonFoods: ["Chewing gum", "Sweets", "White icing", "Marshmallows", "Toothpaste", "Medicines", "Supplements"],
            knownReactions: [
                "Potential DNA damage (genotoxicity)",
                "Intestinal inflammation",
                "May cross the blood-brain barrier",
                "Accumulates in organs over time"
            ],
            researchSummary: "Titanium Dioxide was BANNED in the EU in 2022 due to genotoxicity concerns - it can damage DNA. The UK still permits it post-Brexit. EFSA (2021) concluded it could no longer be considered safe. Nanoparticles can accumulate in the body.",
            researchStrength: .strong
        )

        map["e172"] = AdditiveResearchEntry(
            code: "E172",
            whatItIs: "Natural mineral colours ranging from yellow to red, brown, and black. Derived from iron compounds found in soil. Also known as Iron Oxides.",
            commonFoods: ["Cake mixes", "Meat products", "Salmon paste", "Confectionery coatings"],
            knownReactions: [
                "Generally well-tolerated",
                "Safe at food additive levels"
            ],
            researchSummary: "Iron oxides are natural minerals considered safe at food levels. EFSA (2015) set an ADI but noted low absorption. Used extensively in cosmetics and pharmaceuticals.",
            researchStrength: .limited
        )

        // MARK: - Preservatives (Sodium Benzoate etc)

        map["e200"] = AdditiveResearchEntry(
            code: "E200",
            whatItIs: "A natural preservative originally derived from rowan berries. Prevents growth of moulds, yeasts, and some bacteria. Also known as Sorbic Acid.",
            commonFoods: ["Cheese", "Wine", "Baked goods", "Dried fruits", "Fruit juices"],
            knownReactions: [
                "Generally well-tolerated",
                "Rare skin reactions",
                "May cause mild stomach upset"
            ],
            researchSummary: "Sorbic acid is considered one of the safest preservatives. EFSA (2015) established an ADI of 25mg/kg body weight. Low toxicity and rarely causes reactions.",
            researchStrength: .limited
        )

        map["e202"] = AdditiveResearchEntry(
            code: "E202",
            whatItIs: "The potassium salt of sorbic acid. A very common preservative that prevents mould and yeast growth. Also known as Potassium Sorbate.",
            commonFoods: ["Margarine", "Wine", "Cheese", "Dried fruits", "Soft drinks", "Baked goods"],
            knownReactions: [
                "Generally well-tolerated",
                "Rare allergic reactions",
                "May cause mouth tingling in some people"
            ],
            researchSummary: "Potassium sorbate is one of the most widely used and safest preservatives. EFSA considers it safe at permitted levels. Preferred by many manufacturers due to low reactivity.",
            researchStrength: .limited
        )

        map["e210"] = AdditiveResearchEntry(
            code: "E210",
            whatItIs: "A preservative that occurs naturally in berries, particularly cranberries. Prevents bacterial and fungal growth. Also known as Benzoic Acid.",
            commonFoods: ["Pickles", "Soft drinks", "Fruit juices", "Sauces", "Jams"],
            knownReactions: [
                "May trigger asthma or urticaria in sensitive individuals",
                "Can worsen ADHD symptoms in some children",
                "Allergic reactions possible"
            ],
            researchSummary: "Benzoic acid can cause reactions in aspirin-sensitive individuals. EFSA (2016) reduced the ADI due to concerns. May form benzene when combined with vitamin C in acidic drinks.",
            researchStrength: .moderate
        )

        map["e211"] = AdditiveResearchEntry(
            code: "E211",
            whatItIs: "The sodium salt of benzoic acid. One of the most common preservatives in acidic foods and drinks. Also known as Sodium Benzoate.",
            commonFoods: ["Soft drinks", "Pickles", "Sauces", "Fruit juices", "Margarine", "Salad dressings"],
            knownReactions: [
                "Hyperactivity when combined with certain colours",
                "Asthma and allergic reactions",
                "Hives and skin irritation",
                "May form benzene when combined with vitamin C"
            ],
            researchSummary: "Sodium Benzoate was part of the Southampton Study mix (The Lancet, 2007). When combined with vitamin C (ascorbic acid), it can form benzene, a known carcinogen. The FSA monitors benzene levels in soft drinks.",
            researchStrength: .strong
        )

        map["e212"] = AdditiveResearchEntry(
            code: "E212",
            whatItIs: "The potassium salt of benzoic acid. A preservative with similar properties to sodium benzoate. Also known as Potassium Benzoate.",
            commonFoods: ["Margarine", "Soft drinks", "Fruit juices", "Pickles"],
            knownReactions: [
                "Same concerns as sodium benzoate",
                "May trigger asthma in sensitive individuals",
                "Can form benzene with vitamin C"
            ],
            researchSummary: "Potassium benzoate has the same safety profile as sodium benzoate. EFSA (2016) set a group ADI with other benzoates. Same benzene formation concerns in acidic drinks with vitamin C.",
            researchStrength: .moderate
        )

        // MARK: - Sulphites

        map["e220"] = AdditiveResearchEntry(
            code: "E220",
            whatItIs: "A pungent gas used as a preservative and antioxidant. One of the oldest known preservatives, used since Roman times. Also known as Sulphur Dioxide.",
            commonFoods: ["Wine", "Dried fruits", "Cordials", "Pickled foods", "Vinegar", "Fruit juices"],
            knownReactions: [
                "Asthma attacks (potentially severe)",
                "Breathing difficulties",
                "Skin rashes and hives",
                "Headaches and nausea",
                "Anaphylaxis in severe cases"
            ],
            researchSummary: "Sulphur dioxide is a major allergen - products must declare it if over 10mg/kg. Affects 5-10% of asthmatics, potentially causing severe attacks. FSA and Clinical & Experimental Allergy journal (2012) confirm sulphites can trigger severe bronchospasm.",
            researchStrength: .strong
        )

        map["e221"] = AdditiveResearchEntry(
            code: "E221",
            whatItIs: "A preservative and antioxidant derived from sulphur dioxide. Releases sulphur dioxide in food. Also known as Sodium Sulphite.",
            commonFoods: ["Wine", "Beer", "Cider", "Dried fruits", "Dehydrated vegetables"],
            knownReactions: [
                "Asthma attacks in sensitive individuals",
                "Breathing difficulties",
                "Allergic reactions",
                "Headaches",
                "Digestive upset"
            ],
            researchSummary: "Sodium sulphite has the same effects as sulphur dioxide. Listed among 14 major allergens requiring declaration (EU Allergen Labelling Regulation, 2014). Particularly dangerous for asthmatics.",
            researchStrength: .strong
        )

        map["e222"] = AdditiveResearchEntry(
            code: "E222",
            whatItIs: "A preservative and antioxidant that releases sulphur dioxide. Also known as Sodium Hydrogen Sulphite or Sodium Bisulphite.",
            commonFoods: ["Wine", "Beer", "Dried fruits", "Cordials"],
            knownReactions: [
                "Asthma attacks",
                "Allergic reactions",
                "Breathing difficulties",
                "Skin reactions"
            ],
            researchSummary: "Sodium hydrogen sulphite triggers the same reactions as other sulphites. Must be declared as an allergen. The FSA advises sulphite-sensitive individuals to check all labels carefully.",
            researchStrength: .strong
        )

        map["e223"] = AdditiveResearchEntry(
            code: "E223",
            whatItIs: "A powerful preservative and antioxidant. Releases more sulphur dioxide than other sulphites. Also known as Sodium Metabisulphite.",
            commonFoods: ["Wine", "Dried apricots", "Potato products", "Prawns", "Pickled onions"],
            knownReactions: [
                "Severe asthma attacks",
                "Anaphylactic reactions (rare but serious)",
                "Skin reactions and hives",
                "Headaches",
                "Nausea and stomach cramps"
            ],
            researchSummary: "Sodium metabisulphite is widely used but causes severe reactions in sulphite-sensitive people. The FSA treats it as a major allergen. Reactions can be life-threatening in sensitive asthmatics.",
            researchStrength: .strong
        )

        map["e224"] = AdditiveResearchEntry(
            code: "E224",
            whatItIs: "A preservative similar to sodium metabisulphite. Releases sulphur dioxide. Also known as Potassium Metabisulphite.",
            commonFoods: ["Wine", "Cider", "Fruit juices", "Dried fruits"],
            knownReactions: [
                "Asthma attacks",
                "Allergic reactions",
                "Breathing difficulties",
                "Headaches"
            ],
            researchSummary: "Potassium metabisulphite has the same allergenic potential as other sulphites. Must be declared on labels. Part of the 14 major allergens under EU/UK food law.",
            researchStrength: .strong
        )

        map["e226"] = AdditiveResearchEntry(
            code: "E226",
            whatItIs: "A preservative that releases sulphur dioxide. Also known as Calcium Sulphite.",
            commonFoods: ["Wine", "Cider", "Fruit products"],
            knownReactions: [
                "Asthma attacks",
                "Allergic reactions",
                "Respiratory distress"
            ],
            researchSummary: "Calcium sulphite triggers the same reactions as other sulphites. Must be declared as an allergen when present above 10mg/kg.",
            researchStrength: .strong
        )

        map["e227"] = AdditiveResearchEntry(
            code: "E227",
            whatItIs: "A preservative that releases sulphur dioxide. Also known as Calcium Hydrogen Sulphite or Calcium Bisulphite.",
            commonFoods: ["Wine", "Beer", "Fruit products"],
            knownReactions: [
                "Asthma attacks",
                "Allergic reactions",
                "Breathing difficulties"
            ],
            researchSummary: "Calcium hydrogen sulphite has the same allergenic profile as other sulphites. Part of the 14 major allergens requiring declaration.",
            researchStrength: .strong
        )

        map["e228"] = AdditiveResearchEntry(
            code: "E228",
            whatItIs: "A preservative that releases sulphur dioxide. Also known as Potassium Hydrogen Sulphite or Potassium Bisulphite.",
            commonFoods: ["Wine", "Dried fruits", "Fruit juices"],
            knownReactions: [
                "Asthma attacks",
                "Allergic reactions",
                "Respiratory symptoms"
            ],
            researchSummary: "Potassium hydrogen sulphite is another sulphite requiring mandatory allergen declaration. Same warnings apply as for all sulphites.",
            researchStrength: .strong
        )

        // MARK: - Nitrates/Nitrites

        map["e249"] = AdditiveResearchEntry(
            code: "E249",
            whatItIs: "A curing salt used to preserve meat and give it a pink colour. Prevents dangerous botulism bacteria. Also known as Potassium Nitrite.",
            commonFoods: ["Bacon", "Ham", "Salami", "Hot dogs", "Cured meats", "Corned beef"],
            knownReactions: [
                "Forms nitrosamines (carcinogenic compounds)",
                "Linked to colorectal cancer",
                "May affect oxygen transport in blood",
                "Headaches in sensitive individuals"
            ],
            researchSummary: "Nitrites combine with proteins during cooking to form nitrosamines, classified as 'probably carcinogenic' by WHO/IARC (2015). The FSA advises limiting processed meat to 70g daily. Strong evidence links regular consumption to bowel cancer (The Lancet Oncology).",
            researchStrength: .strong
        )

        map["e250"] = AdditiveResearchEntry(
            code: "E250",
            whatItIs: "The most common curing salt for meat preservation. Gives bacon and ham their characteristic pink colour. Also known as Sodium Nitrite.",
            commonFoods: ["Bacon", "Ham", "Sausages", "Hot dogs", "Deli meats", "Pâté"],
            knownReactions: [
                "Forms carcinogenic nitrosamines when heated",
                "Linked to bowel and stomach cancer",
                "Methaemoglobinaemia in infants (blue baby syndrome)",
                "Headaches and dizziness at high doses"
            ],
            researchSummary: "Sodium nitrite is the primary curing agent in processed meats. WHO/IARC (2015) classifies processed meat as a Group 1 carcinogen. Each 50g of processed meat daily increases colorectal cancer risk by 18%. France is considering a ban.",
            researchStrength: .strong
        )

        map["e251"] = AdditiveResearchEntry(
            code: "E251",
            whatItIs: "A curing agent that converts to nitrite in the body over time. Provides a slower, longer-lasting preservation effect. Also known as Sodium Nitrate.",
            commonFoods: ["Cured meats", "Some cheeses", "Preserved fish"],
            knownReactions: [
                "Converts to nitrite in the body",
                "Associated with cancer risk in processed meats",
                "May affect blood pressure",
                "Headaches in sensitive individuals"
            ],
            researchSummary: "Sodium nitrate converts to nitrite in the body, with the same carcinogenic concerns. Used alongside E250 in meat curing. The cancer risk from processed meats is well-established by WHO/IARC (2015) and World Cancer Research Fund (2018).",
            researchStrength: .strong
        )

        map["e252"] = AdditiveResearchEntry(
            code: "E252",
            whatItIs: "An ancient preservative also known as saltpetre. Has been used for meat curing for centuries. Also known as Potassium Nitrate.",
            commonFoods: ["Cured ham", "Salami", "Some sausages"],
            knownReactions: [
                "Same cancer risk as other nitrates/nitrites",
                "Forms nitrosamines during digestion",
                "May affect thyroid function at high doses"
            ],
            researchSummary: "Potassium nitrate (saltpetre) has been used in meat curing for centuries. EFSA (2017) confirmed formation of carcinogenic nitrosamines from food nitrates/nitrites. Same cancer risks as sodium nitrite.",
            researchStrength: .strong
        )

        // MARK: - Antioxidants

        map["e300"] = AdditiveResearchEntry(
            code: "E300",
            whatItIs: "Vitamin C - an essential nutrient that also works as an antioxidant and preservative. Prevents browning and spoilage. Also known as Ascorbic Acid.",
            commonFoods: ["Fruit juices", "Cured meats", "Wine", "Bread", "Beer", "Soft drinks"],
            knownReactions: [
                "Generally very safe as it's an essential vitamin",
                "May cause stomach upset at very high doses",
                "Can form benzene with sodium benzoate"
            ],
            researchSummary: "Ascorbic acid is Vitamin C and is considered completely safe at food additive levels. Can form benzene when combined with benzoates in acidic conditions, though this is monitored.",
            researchStrength: .limited
        )

        map["e301"] = AdditiveResearchEntry(
            code: "E301",
            whatItIs: "The sodium salt of Vitamin C. More stable in some applications than pure ascorbic acid. Also known as Sodium Ascorbate.",
            commonFoods: ["Cured meats", "Sausages", "Beer"],
            knownReactions: [
                "Generally very safe",
                "Same safety profile as Vitamin C"
            ],
            researchSummary: "Sodium ascorbate is a form of Vitamin C considered completely safe. No specific safety concerns beyond those of ascorbic acid.",
            researchStrength: .limited
        )

        map["e302"] = AdditiveResearchEntry(
            code: "E302",
            whatItIs: "The calcium salt of Vitamin C. Provides both antioxidant and calcium fortification benefits. Also known as Calcium Ascorbate.",
            commonFoods: ["Bread", "Flour", "Nutritional supplements"],
            knownReactions: [
                "Generally very safe",
                "Same safety profile as Vitamin C"
            ],
            researchSummary: "Calcium ascorbate is a form of Vitamin C considered completely safe. Provides some calcium alongside Vitamin C. No safety concerns.",
            researchStrength: .limited
        )

        map["e304"] = AdditiveResearchEntry(
            code: "E304",
            whatItIs: "A fat-soluble form of Vitamin C. Works as an antioxidant in fatty foods where regular Vitamin C cannot. Also known as Ascorbyl Palmitate.",
            commonFoods: ["Oils", "Margarines", "Sausages", "Chicken products"],
            knownReactions: [
                "Generally well-tolerated",
                "May cause stomach upset at high doses"
            ],
            researchSummary: "Ascorbyl palmitate is a fat-soluble antioxidant considered safe. EFSA (2015) established an ADI but noted it's well within normal consumption.",
            researchStrength: .limited
        )

        map["e306"] = AdditiveResearchEntry(
            code: "E306",
            whatItIs: "Vitamin E - an essential nutrient that works as a powerful antioxidant. Extracted from vegetable oils. Also known as Tocopherol-rich Extract.",
            commonFoods: ["Vegetable oils", "Margarine", "Mayonnaise", "Breakfast cereals"],
            knownReactions: [
                "Generally very safe as it's an essential vitamin",
                "May interact with blood thinners at high supplement doses"
            ],
            researchSummary: "Tocopherols are Vitamin E and are considered completely safe at food additive levels. May have cardiovascular and antioxidant benefits. No safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e307"] = AdditiveResearchEntry(
            code: "E307",
            whatItIs: "The most active form of Vitamin E. A powerful natural antioxidant. Also known as Alpha-Tocopherol.",
            commonFoods: ["Oils", "Fats", "Cereals", "Baby foods"],
            knownReactions: [
                "Generally very safe",
                "Same safety profile as Vitamin E"
            ],
            researchSummary: "Alpha-tocopherol is the most biologically active form of Vitamin E. Considered completely safe at food additive levels. Often used in supplements.",
            researchStrength: .limited
        )

        map["e308"] = AdditiveResearchEntry(
            code: "E308",
            whatItIs: "A form of Vitamin E with slightly different properties. Also known as Gamma-Tocopherol.",
            commonFoods: ["Vegetable oils", "Margarine"],
            knownReactions: [
                "Generally very safe",
                "Same safety profile as other tocopherols"
            ],
            researchSummary: "Gamma-tocopherol is another form of Vitamin E considered safe. Some research suggests unique antioxidant benefits compared to alpha form.",
            researchStrength: .limited
        )

        map["e309"] = AdditiveResearchEntry(
            code: "E309",
            whatItIs: "A form of Vitamin E. Also known as Delta-Tocopherol.",
            commonFoods: ["Vegetable oils", "Processed foods"],
            knownReactions: [
                "Generally very safe",
                "Same safety profile as other tocopherols"
            ],
            researchSummary: "Delta-tocopherol is another form of Vitamin E considered safe at food additive levels. No specific safety concerns.",
            researchStrength: .limited
        )

        map["e310"] = AdditiveResearchEntry(
            code: "E310",
            whatItIs: "A synthetic antioxidant used to prevent rancidity in fats and oils. Also known as Propyl Gallate.",
            commonFoods: ["Fats", "Oils", "Mayonnaise", "Chewing gum"],
            knownReactions: [
                "Allergic reactions",
                "Skin rashes",
                "Stomach irritation"
            ],
            researchSummary: "Propyl gallate may cause reactions in sensitive individuals. EFSA (2014) maintained the ADI. Not permitted in infant foods. Some people report sensitivity.",
            researchStrength: .emerging
        )

        map["e311"] = AdditiveResearchEntry(
            code: "E311",
            whatItIs: "A synthetic antioxidant from the gallate family. Prevents fats from going rancid. Also known as Octyl Gallate.",
            commonFoods: ["Fats", "Oils", "Margarine"],
            knownReactions: [
                "Allergic reactions",
                "Skin irritation",
                "Gastric irritation"
            ],
            researchSummary: "Octyl gallate is an antioxidant with 'avoid' verdict due to potential for allergic reactions and gastric irritation. Not permitted in infant foods. Some countries have banned it.",
            researchStrength: .moderate
        )

        map["e312"] = AdditiveResearchEntry(
            code: "E312",
            whatItIs: "A synthetic antioxidant from the gallate family. Also known as Dodecyl Gallate.",
            commonFoods: ["Fats", "Oils"],
            knownReactions: [
                "Allergic reactions",
                "Skin reactions",
                "Gastric irritation"
            ],
            researchSummary: "Dodecyl gallate has similar concerns to octyl gallate. Carries 'avoid' verdict. Not permitted in infant foods. Limited uses in the EU.",
            researchStrength: .moderate
        )

        map["e315"] = AdditiveResearchEntry(
            code: "E315",
            whatItIs: "A close relative of Vitamin C with antioxidant properties. Also known as Erythorbic Acid or Isoascorbic Acid.",
            commonFoods: ["Cured meats", "Frozen vegetables", "Fruit juices"],
            knownReactions: [
                "Generally well-tolerated",
                "Similar safety profile to Vitamin C"
            ],
            researchSummary: "Erythorbic acid is similar to Vitamin C but with no vitamin activity. EFSA considers it safe. Often used in meat curing to reduce nitrosamine formation.",
            researchStrength: .limited
        )

        map["e316"] = AdditiveResearchEntry(
            code: "E316",
            whatItIs: "The sodium salt of erythorbic acid. Also known as Sodium Erythorbate.",
            commonFoods: ["Cured meats", "Sausages", "Processed meats"],
            knownReactions: [
                "Generally well-tolerated",
                "Same safety profile as erythorbic acid"
            ],
            researchSummary: "Sodium erythorbate is considered safe. Used in meat curing to speed up colour development and reduce nitrosamine formation. No significant safety concerns.",
            researchStrength: .limited
        )

        map["e319"] = AdditiveResearchEntry(
            code: "E319",
            whatItIs: "A powerful synthetic antioxidant derived from butane. Prevents fats from going rancid. Also known as TBHQ (Tertiary Butylhydroquinone).",
            commonFoods: ["Cooking oils", "Chicken nuggets", "Microwave popcorn", "Crackers", "Frozen fish"],
            knownReactions: [
                "Nausea and vomiting at high doses",
                "May affect immune function",
                "Possible behavioural effects",
                "Skin reactions"
            ],
            researchSummary: "TBHQ is banned in Japan and some other countries. EFSA (2004) established ADI but noted need for more data on immunotoxicity. Not permitted in infant food. Lower limits in EU than USA.",
            researchStrength: .emerging
        )

        map["e320"] = AdditiveResearchEntry(
            code: "E320",
            whatItIs: "A synthetic antioxidant derived from petroleum. Prevents fats and oils from becoming rancid. Also known as BHA (Butylated Hydroxyanisole).",
            commonFoods: ["Butter", "Lard", "Cereals", "Chewing gum", "Snack foods", "Instant mashed potato"],
            knownReactions: [
                "Possible carcinogenic effects",
                "Endocrine disruption potential",
                "Allergic reactions in some people",
                "Skin reactions (contact dermatitis)"
            ],
            researchSummary: "BHA is classified as 'reasonably anticipated to be a human carcinogen' by the US National Toxicology Program (NTP 15th Report, 2021). Banned in Japan for some uses. California requires cancer warning labels. EFSA (2012) set a low ADI of 1mg/kg due to concerns.",
            researchStrength: .moderate
        )

        map["e321"] = AdditiveResearchEntry(
            code: "E321",
            whatItIs: "A synthetic antioxidant closely related to BHA. Prevents fat oxidation and rancidity. Also known as BHT (Butylated Hydroxytoluene).",
            commonFoods: ["Cereals", "Chewing gum", "Snacks", "Baked goods", "Vegetable oils"],
            knownReactions: [
                "Possible tumour promotion",
                "Behavioural effects debated",
                "Allergic reactions",
                "Skin irritation"
            ],
            researchSummary: "BHT shows mixed results in studies - some suggest it promotes tumours, others show protective effects. EFSA (2012) set a temporary ADI pending more research. Often used alongside BHA.",
            researchStrength: .emerging
        )

        // MARK: - Emulsifiers

        map["e322"] = AdditiveResearchEntry(
            code: "E322",
            whatItIs: "A natural emulsifier extracted from soybeans, egg yolks, or sunflowers. Used for thousands of years in foods like mayonnaise. Also known as Lecithin.",
            commonFoods: ["Chocolate", "Margarine", "Baked goods", "Ice cream", "Infant formula"],
            knownReactions: [
                "Generally very safe",
                "May trigger soy allergy in sensitive individuals",
                "Rarely causes digestive upset"
            ],
            researchSummary: "Lecithin is considered very safe and has been used in foods for centuries. May cause reactions in people with severe soy allergy depending on source. EFSA (2017) confirmed safety.",
            researchStrength: .limited
        )

        map["e407"] = AdditiveResearchEntry(
            code: "E407",
            whatItIs: "A natural thickener and gelling agent extracted from red seaweed. Used in dairy products for its creamy texture. Also known as Carrageenan.",
            commonFoods: ["Ice cream", "Yogurt", "Chocolate milk", "Processed meats", "Infant formula"],
            knownReactions: [
                "Digestive issues in some people",
                "Intestinal inflammation debated",
                "May worsen IBS symptoms"
            ],
            researchSummary: "Carrageenan has been controversial due to animal studies showing intestinal inflammation. EFSA (2018) maintained safety but noted concerns. Some experts recommend avoiding it. Increasingly being replaced by alternatives.",
            researchStrength: .emerging
        )

        map["e415"] = AdditiveResearchEntry(
            code: "E415",
            whatItIs: "A natural thickener produced by bacterial fermentation. Creates a smooth, gel-like texture. Also known as Xanthan Gum.",
            commonFoods: ["Salad dressings", "Sauces", "Ice cream", "Gluten-free baked goods", "Toothpaste"],
            knownReactions: [
                "Generally well-tolerated",
                "May cause bloating or gas in large amounts",
                "Laxative effect at very high doses"
            ],
            researchSummary: "Xanthan gum is considered safe by EFSA (2017). May cause digestive issues at high doses. Important for gluten-free baking. No significant safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e471"] = AdditiveResearchEntry(
            code: "E471",
            whatItIs: "Emulsifiers made from glycerol and fatty acids. Can be derived from plant or animal sources. Also known as Mono- and Diglycerides of Fatty Acids.",
            commonFoods: ["Bread", "Ice cream", "Margarine", "Cakes", "Whipped cream"],
            knownReactions: [
                "Generally well-tolerated",
                "May not be suitable for vegans (animal sources)",
                "Very rarely causes digestive upset"
            ],
            researchSummary: "Mono- and diglycerides are considered safe by EFSA (2017). May be derived from animal fats so not always suitable for vegetarians. One of the most common emulsifiers.",
            researchStrength: .limited
        )

        map["e476"] = AdditiveResearchEntry(
            code: "E476",
            whatItIs: "A synthetic emulsifier that reduces the amount of expensive cocoa butter needed in chocolate. Also known as PGPR (Polyglycerol Polyricinoleate).",
            commonFoods: ["Chocolate", "Chocolate spread", "Low-fat spreads", "Salad dressings"],
            knownReactions: [
                "Digestive discomfort in some people",
                "Enlarged kidneys and liver in animal studies",
                "Generally well-tolerated in humans"
            ],
            researchSummary: "PGPR is used to reduce cocoa butter content in chocolate. Animal studies showed enlarged organs at very high doses. EFSA (2017) considers current uses safe with ADI of 25 mg/kg body weight.",
            researchStrength: .limited
        )

        // MARK: - Sweeteners

        map["e950"] = AdditiveResearchEntry(
            code: "E950",
            whatItIs: "A calorie-free artificial sweetener about 200 times sweeter than sugar. Often combined with other sweeteners. Also known as Acesulfame K or Ace-K.",
            commonFoods: ["Diet drinks", "Sugar-free gum", "Yogurts", "Desserts", "Tabletop sweeteners"],
            knownReactions: [
                "Generally well-tolerated",
                "May affect gut bacteria",
                "Slight bitter aftertaste"
            ],
            researchSummary: "Acesulfame K is considered safe by EFSA (2016) and FDA. Some concerns about gut microbiome effects at high doses. Often used with other sweeteners to mask bitterness.",
            researchStrength: .limited
        )

        map["e951"] = AdditiveResearchEntry(
            code: "E951",
            whatItIs: "One of the most studied artificial sweeteners, about 200 times sweeter than sugar. Made from two amino acids. Also known as Aspartame.",
            commonFoods: ["Diet drinks", "Sugar-free gum", "Low-calorie desserts", "Tabletop sweeteners", "Sugar-free sweets"],
            knownReactions: [
                "DANGEROUS for people with PKU (phenylketonuria)",
                "Headaches and migraines (reported, not confirmed)",
                "Debated neurological effects",
                "May affect gut microbiome"
            ],
            researchSummary: "Aspartame contains phenylalanine - DANGEROUS for people with PKU. In 2023, WHO/IARC classified it as 'possibly carcinogenic' (Group 2B) in The Lancet Oncology. JECFA maintained current safety levels but debate continues.",
            researchStrength: .strong
        )

        map["e952"] = AdditiveResearchEntry(
            code: "E952",
            whatItIs: "A calorie-free artificial sweetener about 30-50 times sweeter than sugar. One of the oldest artificial sweeteners. Also known as Cyclamate.",
            commonFoods: ["Tabletop sweeteners", "Soft drinks", "Confectionery"],
            knownReactions: [
                "Banned in USA since 1970 (cancer concerns)",
                "Still permitted in UK/EU",
                "May affect gut bacteria"
            ],
            researchSummary: "Cyclamate was banned in the USA in 1970 due to bladder cancer concerns in rats. EFSA (2010) maintains it's safe at current ADI. Still controversial in some countries.",
            researchStrength: .moderate
        )

        map["e954"] = AdditiveResearchEntry(
            code: "E954",
            whatItIs: "The oldest artificial sweetener, discovered in 1879. About 300-400 times sweeter than sugar. Also known as Saccharin.",
            commonFoods: ["Tabletop sweeteners", "Soft drinks", "Toothpaste", "Medicines"],
            knownReactions: [
                "Historically controversial (cancer studies in rats)",
                "Metallic aftertaste",
                "Generally considered safe in humans"
            ],
            researchSummary: "Saccharin caused bladder cancer in rats but subsequent research found the mechanism doesn't apply to humans. EFSA and FDA consider it safe. Often combined with other sweeteners.",
            researchStrength: .limited
        )

        map["e955"] = AdditiveResearchEntry(
            code: "E955",
            whatItIs: "An artificial sweetener about 600 times sweeter than sugar. Made by chemically modifying sugar. Also known as Sucralose.",
            commonFoods: ["Diet drinks", "Sugar-free products", "Baked goods", "Tabletop sweeteners"],
            knownReactions: [
                "Generally well-tolerated",
                "May affect gut bacteria",
                "Some reports of headaches and digestive issues"
            ],
            researchSummary: "Sucralose was considered very safe until recent studies raised concerns about DNA damage when heated. EFSA (2016) maintains safety at current levels. Heat stability concerns in baking.",
            researchStrength: .emerging
        )

        map["e960"] = AdditiveResearchEntry(
            code: "E960",
            whatItIs: "A natural, calorie-free sweetener extracted from the leaves of the Stevia plant. About 200-300 times sweeter than sugar. Also known as Steviol Glycosides.",
            commonFoods: ["Diet drinks", "Sugar-free products", "Yogurts", "Tabletop sweeteners"],
            knownReactions: [
                "Generally well-tolerated",
                "May cause digestive upset in some people",
                "Slight liquorice-like aftertaste"
            ],
            researchSummary: "Stevia is considered safe by EFSA (2010). Natural origin appeals to many consumers. Some concerns about processing methods. Generally well-tolerated.",
            researchStrength: .limited
        )

        map["e962"] = AdditiveResearchEntry(
            code: "E962",
            whatItIs: "A combined sweetener made from aspartame and acesulfame K salts. Also known as Aspartame-Acesulfame Salt.",
            commonFoods: ["Sugar-free products", "Diet drinks", "Chewing gum"],
            knownReactions: [
                "DANGEROUS for PKU sufferers (contains aspartame)",
                "Same concerns as aspartame alone"
            ],
            researchSummary: "This is a salt of aspartame and acesulfame K. Contains phenylalanine so carries the same PKU warning and 2023 WHO/IARC classification as aspartame.",
            researchStrength: .strong
        )

        // MARK: - Polyols (Sugar Alcohols)

        map["e420"] = AdditiveResearchEntry(
            code: "E420",
            whatItIs: "A sugar alcohol naturally found in fruits. About 60% as sweet as sugar with fewer calories. Also known as Sorbitol.",
            commonFoods: ["Sugar-free sweets", "Chewing gum", "Diabetic products", "Ice cream", "Baked goods"],
            knownReactions: [
                "Bloating and abdominal discomfort",
                "Excessive gas and flatulence",
                "Diarrhoea and laxative effect",
                "Cramping and stomach pain"
            ],
            researchSummary: "Sorbitol is poorly absorbed in the gut, causing fermentation and osmotic effects. EFSA (2011) established dose-dependent gastrointestinal symptoms. Products must warn about laxative effects. People with IBS are particularly sensitive.",
            researchStrength: .moderate
        )

        map["e421"] = AdditiveResearchEntry(
            code: "E421",
            whatItIs: "A sugar alcohol naturally found in mushrooms and seaweed. About 50-70% as sweet as sugar. Also known as Mannitol.",
            commonFoods: ["Sugar-free mints", "Chewing gum", "Chocolate", "Pharmaceuticals"],
            knownReactions: [
                "Strong laxative effect",
                "Bloating and gas",
                "Abdominal cramps",
                "Diarrhoea at moderate doses"
            ],
            researchSummary: "Mannitol has a stronger laxative effect than sorbitol. EFSA (2012) confirmed laxative effects requiring warning labels. The threshold for symptoms is lower - as little as 10-20g can cause significant discomfort.",
            researchStrength: .moderate
        )

        map["e953"] = AdditiveResearchEntry(
            code: "E953",
            whatItIs: "A sugar alcohol made from sugar beet. About 50% as sweet as sugar with half the calories. Also known as Isomalt.",
            commonFoods: ["Sugar-free sweets", "Chocolate", "Baked goods"],
            knownReactions: [
                "Bloating and gas",
                "Laxative effect",
                "Stomach discomfort"
            ],
            researchSummary: "Isomalt is a polyol with similar digestive effects to sorbitol. Products containing over 10% must carry laxative warning labels per EU Regulation 1169/2011.",
            researchStrength: .moderate
        )

        map["e964"] = AdditiveResearchEntry(
            code: "E964",
            whatItIs: "A mixture of polyols (sugar alcohols) produced from starch. Also known as Polyglycitol Syrup.",
            commonFoods: ["Sugar-free products", "Confectionery"],
            knownReactions: [
                "Bloating and flatulence",
                "Laxative effect",
                "Digestive discomfort"
            ],
            researchSummary: "Polyglycitol syrup is a polyol mixture with the same digestive effects as other sugar alcohols. Mandatory laxative warning required on products.",
            researchStrength: .moderate
        )

        map["e965"] = AdditiveResearchEntry(
            code: "E965",
            whatItIs: "A sugar alcohol about 75-90% as sweet as sugar, derived from starch. Popular in 'no added sugar' products. Also known as Maltitol.",
            commonFoods: ["Sugar-free chocolate", "Biscuits", "Ice cream", "Sweets", "Baked goods"],
            knownReactions: [
                "Bloating and flatulence",
                "Diarrhoea and laxative effect",
                "Stomach cramps",
                "May worsen IBS symptoms"
            ],
            researchSummary: "Maltitol is commonly used in 'no added sugar' products. Has about 75% of the sweetness of sugar but significant laxative effects. Products containing over 10% must warn 'excessive consumption may produce laxative effects' (EU Regulation 1169/2011).",
            researchStrength: .moderate
        )

        map["e966"] = AdditiveResearchEntry(
            code: "E966",
            whatItIs: "A sugar alcohol derived from lactose (milk sugar). About 40% as sweet as sugar. Also known as Lactitol.",
            commonFoods: ["Sugar-free products", "Diabetic foods", "Confectionery"],
            knownReactions: [
                "Bloating and gas",
                "Laxative effect",
                "Digestive discomfort"
            ],
            researchSummary: "Lactitol is a polyol with similar digestive effects to other sugar alcohols. Mandatory laxative warning required. Often used in diabetic products.",
            researchStrength: .moderate
        )

        map["e967"] = AdditiveResearchEntry(
            code: "E967",
            whatItIs: "A sugar alcohol found naturally in fruits and vegetables. Known for dental health benefits as bacteria can't metabolise it. Also known as Xylitol.",
            commonFoods: ["Chewing gum", "Toothpaste", "Sugar-free mints", "Diabetic sweets"],
            knownReactions: [
                "Digestive upset in humans",
                "TOXIC to dogs (can be fatal)",
                "Bloating and diarrhoea at high doses",
                "May cause hypoglycaemia in dogs"
            ],
            researchSummary: "Xylitol is popular for dental health (reduces cavities) but has laxative effects. EXTREMELY DANGEROUS to dogs - even small amounts can cause liver failure and death per Veterinary Clinics of North America (2016). Keep xylitol products away from pets.",
            researchStrength: .moderate
        )

        map["e968"] = AdditiveResearchEntry(
            code: "E968",
            whatItIs: "A sugar alcohol that's about 70% as sweet as sugar but with almost zero calories. Naturally occurs in some fruits. Also known as Erythritol.",
            commonFoods: ["Low-calorie drinks", "Protein bars", "Baked goods", "Ice cream"],
            knownReactions: [
                "Generally well-tolerated in small amounts",
                "May cause nausea at very high doses",
                "Some studies suggest cardiovascular concerns",
                "Bloating in sensitive individuals"
            ],
            researchSummary: "Erythritol was considered the best-tolerated polyol until 2023, when a Cleveland Clinic study (Nature Medicine) linked high blood levels to increased heart attack and stroke risk. More research is needed but the findings are concerning.",
            researchStrength: .emerging
        )

        // MARK: - Flavour Enhancers

        map["e620"] = AdditiveResearchEntry(
            code: "E620",
            whatItIs: "A naturally occurring amino acid that creates the 'umami' or savoury taste. Found in foods like tomatoes and parmesan. Also known as Glutamic Acid.",
            commonFoods: ["Savoury snacks", "Soups", "Ready meals", "Sauces"],
            knownReactions: [
                "Same concerns as MSG",
                "Sensitivity reported in some individuals"
            ],
            researchSummary: "Glutamic acid is the parent compound of MSG. EFSA (2017) considers it safe at current levels. Same controversy and generally same conclusions as MSG.",
            researchStrength: .limited
        )

        map["e621"] = AdditiveResearchEntry(
            code: "E621",
            whatItIs: "The sodium salt of glutamic acid. Creates the 'umami' taste that makes food more savoury and satisfying. Also known as MSG (Monosodium Glutamate).",
            commonFoods: ["Chinese food", "Crisps", "Ready meals", "Soups", "Stock cubes", "Savoury snacks"],
            knownReactions: [
                "'Chinese Restaurant Syndrome' (headache, flushing) - debated",
                "Numbness and tingling reported",
                "Chest pain in rare cases",
                "Most studies show no effect in controlled conditions"
            ],
            researchSummary: "MSG has been controversial since the 1960s 'Chinese Restaurant Syndrome' reports. However, EFSA (2017) and double-blind studies (Journal of Allergy and Clinical Immunology, 2000) failed to confirm consistent MSG sensitivity. Generally considered safe.",
            researchStrength: .limited
        )

        map["e622"] = AdditiveResearchEntry(
            code: "E622",
            whatItIs: "The potassium salt of glutamic acid. Similar flavour-enhancing properties to MSG. Also known as Monopotassium Glutamate.",
            commonFoods: ["Low-sodium products", "Savoury foods"],
            knownReactions: [
                "Same concerns as MSG",
                "May be preferred for low-sodium diets"
            ],
            researchSummary: "Monopotassium glutamate is essentially MSG with potassium instead of sodium. Same safety profile. Useful in low-sodium products.",
            researchStrength: .limited
        )

        map["e627"] = AdditiveResearchEntry(
            code: "E627",
            whatItIs: "A flavour enhancer that works synergistically with MSG to boost umami taste. Derived from yeast or fish. Also known as Disodium Guanylate.",
            commonFoods: ["Crisps", "Instant noodles", "Snack foods", "Soups"],
            knownReactions: [
                "Not suitable for gout sufferers (purine)",
                "Usually used with MSG"
            ],
            researchSummary: "Disodium guanylate is usually used alongside MSG. Contains purines so not suitable for people with gout. EFSA considers it safe at permitted levels.",
            researchStrength: .limited
        )

        map["e631"] = AdditiveResearchEntry(
            code: "E631",
            whatItIs: "A flavour enhancer that works synergistically with MSG. Derived from meat or fish. Also known as Disodium Inosinate.",
            commonFoods: ["Crisps", "Ready meals", "Snack foods", "Instant noodles"],
            knownReactions: [
                "Not suitable for gout sufferers (purine)",
                "Usually used with MSG"
            ],
            researchSummary: "Disodium inosinate is typically used alongside MSG and E627. Contains purines so not suitable for gout sufferers. Considered safe at permitted levels.",
            researchStrength: .limited
        )

        map["e635"] = AdditiveResearchEntry(
            code: "E635",
            whatItIs: "A combined flavour enhancer containing both E627 and E631. Creates a powerful umami taste boost. Also known as Disodium Ribonucleotides.",
            commonFoods: ["Chips", "Snacks", "Instant noodles", "Flavoured crackers"],
            knownReactions: [
                "Skin rashes reported (itching)",
                "Not suitable for gout sufferers",
                "Usually combined with MSG"
            ],
            researchSummary: "Disodium ribonucleotides is a combination of E627 and E631. Some reports of skin irritation. Contains purines so unsuitable for gout. EFSA considers it safe at current levels.",
            researchStrength: .emerging
        )

        // MARK: - Aluminium Compounds

        map["e556"] = AdditiveResearchEntry(
            code: "E556",
            whatItIs: "An anti-caking agent containing aluminium. Keeps powders free-flowing. Also known as Calcium Aluminium Silicate.",
            commonFoods: ["Anti-caking agents", "Powdered products"],
            knownReactions: [
                "Aluminium accumulation concerns",
                "Possible neurotoxicity",
                "Long-term effects uncertain"
            ],
            researchSummary: "Calcium aluminium silicate raises similar concerns to other aluminium compounds. EFSA recommends minimising aluminium intake. Best avoided where alternatives exist.",
            researchStrength: .moderate
        )

        map["e559"] = AdditiveResearchEntry(
            code: "E559",
            whatItIs: "A common anti-caking agent made from clay minerals. Keeps salt and powders free-flowing. Also known as Aluminium Silicate or Kaolin.",
            commonFoods: ["Anti-caking agent in powders", "Salt", "Dried milk"],
            knownReactions: [
                "Aluminium accumulation concerns",
                "Possible neurotoxicity at high exposure",
                "May affect bone health"
            ],
            researchSummary: "Aluminium compounds have been linked to neurotoxicity and bone disorders at high exposure levels. EFSA (2008) set a tolerable weekly intake and noted many people exceed it. Best to minimise exposure where possible.",
            researchStrength: .moderate
        )

        // MARK: - Acids and Acid Regulators

        map["e330"] = AdditiveResearchEntry(
            code: "E330",
            whatItIs: "A natural acid found in citrus fruits like lemons and oranges. Used to add tartness and preserve foods. Also known as Citric Acid.",
            commonFoods: ["Soft drinks", "Sweets", "Jams", "Canned foods", "Wine"],
            knownReactions: [
                "Generally very safe",
                "May erode tooth enamel with frequent exposure",
                "Very rarely causes mouth irritation"
            ],
            researchSummary: "Citric acid is naturally occurring and considered very safe. May contribute to dental erosion in acidic drinks. No safety concerns at food levels. Often made by fermentation.",
            researchStrength: .limited
        )

        map["e331"] = AdditiveResearchEntry(
            code: "E331",
            whatItIs: "The sodium salt of citric acid. Used as an acidity regulator and emulsifier. Also known as Sodium Citrate.",
            commonFoods: ["Ice cream", "Jams", "Sweets", "Soft drinks", "Processed cheese"],
            knownReactions: [
                "Generally very safe",
                "May affect sodium intake in large amounts"
            ],
            researchSummary: "Sodium citrate is considered very safe. Used in processed cheese to prevent fat separation. No significant safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e332"] = AdditiveResearchEntry(
            code: "E332",
            whatItIs: "The potassium salt of citric acid. Used as an acidity regulator. Also known as Potassium Citrate.",
            commonFoods: ["Soft drinks", "Confectionery", "Jams"],
            knownReactions: [
                "Generally very safe",
                "May affect potassium levels at very high doses"
            ],
            researchSummary: "Potassium citrate is considered very safe. Often preferred in low-sodium products. No significant safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e333"] = AdditiveResearchEntry(
            code: "E333",
            whatItIs: "The calcium salt of citric acid. Used as an acidity regulator and firming agent. Also known as Calcium Citrate.",
            commonFoods: ["Wines", "Soft drinks", "Cheese", "Jams"],
            knownReactions: [
                "Generally very safe",
                "Provides some calcium"
            ],
            researchSummary: "Calcium citrate is considered very safe and may provide dietary calcium. Often used as a calcium supplement. No safety concerns at food levels.",
            researchStrength: .limited
        )

        map["e334"] = AdditiveResearchEntry(
            code: "E334",
            whatItIs: "A natural acid found in grapes and other fruits. The main acid in wine. Also known as Tartaric Acid or L-Tartaric Acid.",
            commonFoods: ["Wine", "Sweets", "Baking powder", "Soft drinks", "Jams"],
            knownReactions: [
                "Generally very safe",
                "Natural component of wine"
            ],
            researchSummary: "Tartaric acid is naturally occurring in grapes and considered very safe. Main acid contributing to wine's tartness. No safety concerns.",
            researchStrength: .limited
        )

        map["e338"] = AdditiveResearchEntry(
            code: "E338",
            whatItIs: "An acidifier used in cola drinks to provide tartness. Also used as a rust remover. Also known as Phosphoric Acid.",
            commonFoods: ["Cola drinks", "Processed cheese", "Jams", "Cured meats"],
            knownReactions: [
                "May affect bone health with high intake",
                "Dental erosion concerns",
                "Generally safe at food levels"
            ],
            researchSummary: "Phosphoric acid has been linked to reduced bone density in some studies, particularly in adolescents drinking large amounts of cola. EFSA (2019) set an ADI. Dental erosion is a concern with acidic drinks.",
            researchStrength: .emerging
        )

        self.entries = map
    }

    // MARK: - Public Methods

    func getEntry(for code: String) -> AdditiveResearchEntry? {
        return entries[code.lowercased()]
    }

    func getWhatItIs(for code: String) -> String? {
        return entries[code.lowercased()]?.whatItIs
    }

    func getCommonFoods(for code: String) -> [String] {
        return entries[code.lowercased()]?.commonFoods ?? []
    }

    func getKnownReactions(for code: String) -> [String] {
        return entries[code.lowercased()]?.knownReactions ?? []
    }

    func getResearchSummary(for code: String) -> (summary: String, strength: ResearchStrength)? {
        guard let entry = entries[code.lowercased()] else { return nil }
        return (entry.researchSummary, entry.researchStrength)
    }
}
