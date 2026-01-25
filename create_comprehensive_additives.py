#!/usr/bin/env python3
"""
Create comprehensive additive database with consumer-focused information.
Each additive includes:
- shortSummary: Quick 1-2 sentence overview
- whatItIs: Detailed engaging description (what it actually is)
- whereItComesFrom: Honest origin story (e.g., "crushed beetles", "coal tar derivatives")
- whyItsUsed: Clear explanation of purpose
- whatYouNeedToKnow: Health-focused bullet points (concerns, warnings, research)
- fullDescription: Comprehensive scientific background (collapsible by default)
"""

import json
from datetime import datetime

# Comprehensive additive data - consumer-first, honest, engaging
COMPREHENSIVE_ADDITIVES = [
    # COLOURS (E100-E199)
    {
        "eNumbers": ["E100"],
        "name": "Curcumin",
        "category": "colour",
        "group": "colour",
        "origin": "plant",
        "shortSummary": "Natural yellow-orange colour from turmeric root, widely used in curry powders and mustards.",
        "whatItIs": "A vibrant yellow pigment extracted from turmeric, the golden spice used in curry for thousands of years.",
        "whereItComesFrom": "Extracted from the rhizomes (underground stems) of turmeric plants (Curcuma longa), native to India and Southeast Asia. The roots are dried and ground to extract the bright yellow curcumin.",
        "whyItsUsed": "Adds a natural golden-yellow colour to foods and is valued for its antioxidant properties. Used in mustards, curries, cheese, butter, and beverages.",
        "whatYouNeedToKnow": [
            "Generally recognised as safe with no significant health concerns",
            "May have anti-inflammatory and antioxidant benefits",
            "One of the safest food colourings available"
        ],
        "fullDescription": "Curcumin is the principal curcuminoid of turmeric, a member of the ginger family. It has been used as a spice and traditional medicine for over 4,000 years. Modern research has investigated its potential health benefits, including anti-inflammatory and antioxidant effects. In food production, it's extracted using solvents and purified. The distinctive yellow colour comes from the polyphenol structure. Unlike synthetic colours, curcumin has a long history of safe use in traditional diets across Asia.",
        "effectsVerdict": "neutral",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Turmeric yellow", "Natural Yellow 3"],
        "sources": [
            {"title": "EFSA Scientific Opinion on Curcumin", "url": "https://efsa.europa.eu", "covers": "safety evaluation"}
        ]
    },
    {
        "eNumbers": ["E120"],
        "name": "Cochineal (Carmine)",
        "category": "colour",
        "group": "colour",
        "origin": "animal",
        "shortSummary": "Vivid red colour extracted from crushed cochineal beetles, used in yoghurts, sweets, and beverages.",
        "whatItIs": "A deep crimson red dye made from the dried bodies of female cochineal insects.",
        "whereItComesFrom": "Harvested from cochineal beetles (Dactylopius coccus) that live on prickly pear cacti in Central and South America. Around 70,000 insects are needed to produce 500g of dye. The insects are dried and crushed to extract carminic acid, which produces the vivid red colour.",
        "whyItsUsed": "Provides an intense, stable red colour that doesn't fade easily. Popular in yoghurts, sweets, fruit drinks, and cosmetics. Valued because it's more stable than many synthetic reds.",
        "whatYouNeedToKnow": [
            "Not suitable for vegans or vegetarians (made from insects)",
            "May cause allergic reactions in sensitive individuals",
            "Rare reports of anaphylaxis in highly allergic people",
            "Must be labelled clearly for dietary/religious reasons"
        ],
        "fullDescription": "Cochineal has been used as a red dye since the Aztec and Maya civilisations. The Spanish conquistadors discovered it in Mexico in the 1500s and it became one of the most valuable exports from the New World. The female insects are harvested, dried in the sun, and then crushed to extract carminic acid. This is processed into carmine, a stable red pigment. While it's a natural colouring, its insect origin makes it unsuitable for vegans and those with specific allergies. The UK and EU require clear labelling. Some people may experience allergic reactions ranging from mild hives to, very rarely, severe anaphylaxis.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Carmine", "Crimson Lake", "Natural Red 4"],
        "sources": [
            {"title": "FSA Position on Cochineal", "url": "https://www.food.gov.uk", "covers": "allergen information"}
        ]
    },
    {
        "eNumbers": ["E122"],
        "name": "Carmoisine (Azorubine)",
        "category": "colour",
        "group": "colour",
        "origin": "synthetic",
        "shortSummary": "Synthetic red colour derived from coal tar, linked to hyperactivity in children.",
        "whatItIs": "A synthetic red azo dye created in laboratories from petroleum derivatives.",
        "whereItComesFrom": "Manufactured synthetically from coal tar or petroleum-based chemicals through complex chemical reactions. It's part of the 'azo' family of dyes, which are made by combining nitrogen compounds with aromatic hydrocarbons.",
        "whyItsUsed": "Cheaper and more stable than natural red colours. Used in jellies, sweets, marzipan, dessert mixes, and some soft drinks to provide a bright reddish-pink colour.",
        "whatYouNeedToKnow": [
            "⚠️ May affect children's activity and attention (Southampton 6 study)",
            "Must carry warning label in EU: 'May have an adverse effect on activity and attention in children'",
            "Banned in several countries including USA, Norway, and Sweden",
            "Some people may experience allergic reactions, especially those sensitive to aspirin"
        ],
        "fullDescription": "Carmoisine is part of a group of six artificial colours (the 'Southampton 6') found by a 2007 University of Southampton study to be associated with increased hyperactivity in children. Following this research, the European Food Safety Authority (EFSA) reviewed the evidence and required warning labels on foods containing these colours. The colour is created through synthetic chemical processes and has no natural source. It belongs to the azo dye family, which some people cannot properly metabolise. The colour has been banned in several countries due to health concerns, though it remains permitted in the UK and EU with mandatory warnings.",
        "effectsVerdict": "avoid",
        "hasChildWarning": True,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Azorubine", "Acid Red 14"],
        "sources": [
            {"title": "Southampton Study on Food Colours", "url": "https://www.thelancet.com", "covers": "hyperactivity research"}
        ]
    },
    {
        "eNumbers": ["E129"],
        "name": "Allura Red AC",
        "category": "colour",
        "group": "colour",
        "origin": "synthetic",
        "shortSummary": "Bright red synthetic dye from petroleum, one of the Southampton 6 colours linked to hyperactivity.",
        "whatItIs": "A vivid red azo dye created from petroleum-based chemicals in laboratories.",
        "whereItComesFrom": "Synthesised from petroleum derivatives through industrial chemical processes. It's a coal tar derivative, meaning it's ultimately derived from fossil fuels.",
        "whyItsUsed": "Provides a bright, stable red colour that's cheaper than natural alternatives. Commonly found in sweets, soft drinks, snacks, and desserts. Replaced the banned dye Amaranth (E123) in many products.",
        "whatYouNeedToKnow": [
            "⚠️ May affect children's activity and attention (Southampton 6 study)",
            "Must carry warning label: 'May have an adverse effect on activity and attention in children'",
            "Linked to hyperactivity and behavioural issues in some studies",
            "Some evidence of immunotoxicity in animal studies",
            "Banned in Denmark, Belgium, France, Switzerland, and Sweden"
        ],
        "fullDescription": "Allura Red AC replaced the banned Amaranth dye in many products. It's one of the most widely used synthetic colours in the world, particularly popular in North America. However, the 2007 Southampton study raised concerns about its effects on children's behaviour. The European Union now requires foods containing it to carry warning labels. Research has shown that some children are more sensitive to these colours than others, with effects including increased impulsivity and decreased attention span. Animal studies have suggested potential immunotoxicity and the ability to cross the blood-brain barrier. Despite these concerns, it remains widely used due to its low cost and stability.",
        "effectsVerdict": "avoid",
        "hasChildWarning": True,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Red 40", "FD&C Red No. 40"],
        "sources": [
            {"title": "EFSA Opinion on Allura Red", "url": "https://efsa.europa.eu", "covers": "safety assessment"}
        ]
    },
    {
        "eNumbers": ["E104"],
        "name": "Quinoline Yellow",
        "category": "colour",
        "group": "colour",
        "origin": "synthetic",
        "shortSummary": "Greenish-yellow synthetic dye from coal tar, one of the Southampton 6 affecting children's behaviour.",
        "whatItIs": "A synthetic yellow-green dye produced from coal tar derivatives.",
        "whereItComesFrom": "Manufactured from petroleum or coal tar through complex chemical synthesis. The process involves combining quinoline (a coal tar derivative) with other synthetic compounds.",
        "whyItsUsed": "Creates yellow and greenish colours in foods, particularly in scotch eggs, smoked fish, and some soft drinks. Often used in combination with blue dyes to create green colours.",
        "whatYouNeedToKnow": [
            "⚠️ May affect children's activity and attention (Southampton 6 study)",
            "Must carry warning label about effects on children",
            "Banned in Australia, USA, Norway, and Japan",
            "Some evidence of potential allergenicity",
            "Not recommended for people with asthma or aspirin sensitivity"
        ],
        "fullDescription": "Quinoline Yellow is derived from quinoline, a component of coal tar. It's one of the Southampton 6 colours linked to hyperactivity in children. The colour has a long history of controversy - it was temporarily banned in the UK in the 1980s but later reinstated with restrictions. Some studies suggest it may trigger allergic reactions, particularly in people with aspirin sensitivity or asthma. The colour can also be contaminated with heavy metals during manufacturing if not properly purified. Many countries have banned it entirely, and in the EU it must carry warning labels. Food manufacturers are increasingly moving away from it in favour of natural alternatives.",
        "effectsVerdict": "avoid",
        "hasChildWarning": True,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["China Yellow", "CI 47005"],
        "sources": [
            {"title": "FSA Guidance on Colour Additives", "url": "https://www.food.gov.uk", "covers": "regulatory status"}
        ]
    },

    # PRESERVATIVES (E200-E299)
    {
        "eNumbers": ["E211"],
        "name": "Sodium Benzoate",
        "category": "preservative",
        "group": "preservative",
        "origin": "synthetic",
        "shortSummary": "Common preservative in soft drinks and sauces, can form benzene (a carcinogen) when combined with vitamin C.",
        "whatItIs": "A sodium salt of benzoic acid, widely used to prevent mould and bacterial growth in acidic foods.",
        "whereItComesFrom": "Synthetically produced by neutralising benzoic acid (originally from benzoin tree gum, now made from petroleum) with sodium hydroxide. Modern production uses entirely synthetic processes.",
        "whyItsUsed": "Extremely effective at preventing mould, yeast, and bacterial growth in acidic foods (pH below 4.5). Used in soft drinks, fruit juices, pickles, sauces, and salad dressings. Very cost-effective.",
        "whatYouNeedToKnow": [
            "⚠️ Can form benzene (a known carcinogen) when combined with vitamin C (ascorbic acid) and exposed to heat or light",
            "May trigger hyperactivity in sensitive children",
            "Can cause allergic reactions including hives and asthma attacks in sensitive individuals",
            "Linked to increased ADHD symptoms in some studies",
            "Generally safe at low levels, but concerns about cumulative exposure"
        ],
        "fullDescription": "Sodium benzoate has been used as a preservative for over 100 years. However, research in the early 2000s revealed a concerning issue: when combined with vitamin C (ascorbic acid) in the presence of heat and light, it can form benzene - a known carcinogen. This is particularly problematic in soft drinks that contain both ingredients. Following these discoveries, many manufacturers reformulated products to avoid the combination. The preservative has also been linked to hyperactivity in children, particularly when combined with artificial colours. Some studies suggest it may trigger or worsen ADHD symptoms. People with asthma or aspirin sensitivity may experience allergic reactions. While regulatory bodies maintain it's safe at permitted levels, there's ongoing debate about long-term cumulative exposure.",
        "effectsVerdict": "caution",
        "hasChildWarning": True,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Benzoate of soda"],
        "sources": [
            {"title": "FDA Study on Benzene Formation", "url": "https://www.fda.gov", "covers": "benzene research"}
        ]
    },
    {
        "eNumbers": ["E220", "E221", "E222", "E223", "E224", "E225", "E226", "E227", "E228"],
        "name": "Sulphur Dioxide and Sulphites",
        "category": "preservative",
        "group": "preservative",
        "origin": "synthetic",
        "shortSummary": "Preservatives and antioxidants that can trigger severe allergic reactions, especially in asthmatics. Must be declared as an allergen.",
        "whatItIs": "A group of sulphur-based compounds used to prevent browning and preserve colour in foods.",
        "whereItComesFrom": "Produced industrially by burning sulphur or from the byproducts of fossil fuel processing. Sulphur dioxide is a gas that dissolves in water; sulphites are salts formed from this gas.",
        "whyItsUsed": "Prevents browning in cut fruits and vegetables, preserves colour in dried fruits, inhibits bacterial growth in wine, and acts as an antioxidant. Extremely effective and widely used in wine-making.",
        "whatYouNeedToKnow": [
            "⚠️ ALLERGEN - Must be declared on labels when present above 10mg/kg",
            "Can trigger severe asthma attacks in sensitive individuals (up to 5-10% of asthmatics)",
            "May cause headaches, breathing difficulties, and skin reactions",
            "Destroys vitamin B1 (thiamine) in foods",
            "Linked to behavioural issues in some sensitive children",
            "Can cause anaphylaxis in rare cases"
        ],
        "fullDescription": "Sulphites are among the most controversial preservatives due to their potential to cause severe allergic reactions, particularly in people with asthma. Studies suggest that 5-10% of asthmatics are sensitive to sulphites, with reactions ranging from mild wheezing to life-threatening asthma attacks. The UK and EU classify sulphites as one of the 14 major allergens that must be declared on food labels. Beyond allergic reactions, sulphites destroy vitamin B1 (thiamine) in foods, which led to restrictions on their use in meat and foods that are important thiamine sources. They're particularly common in wine (where they prevent oxidation), dried fruits (prevent browning), and some processed potatoes. Some people report headaches and digestive issues after consuming sulphites, though research on these effects is limited. Despite safety concerns, they remain widely used because they're highly effective at preserving colour and preventing spoilage.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": True,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Sulfites", "SO2", "Metabisulphite", "Bisulphite"],
        "sources": [
            {"title": "Asthma UK Guidance on Sulphites", "url": "https://www.asthma.org.uk", "covers": "allergen information"}
        ]
    },
    {
        "eNumbers": ["E249", "E250", "E251", "E252"],
        "name": "Nitrites and Nitrates",
        "category": "preservative",
        "group": "preservative",
        "origin": "synthetic",
        "shortSummary": "Preservatives in cured meats that prevent botulism but can form cancer-causing nitrosamines when cooked at high heat.",
        "whatItIs": "Salts of nitrous and nitric acid used primarily in cured and processed meats to prevent bacterial growth and maintain pink colour.",
        "whereItComesFrom": "Produced synthetically through chemical processes, though nitrates also occur naturally in some vegetables. Sodium and potassium nitrites/nitrates are manufactured for use in food preservation.",
        "whyItsUsed": "Critical for preventing botulism (a deadly food poisoning) in cured meats like bacon, ham, salami, and hot dogs. Also maintains the characteristic pink colour of cured meats and contributes to flavour.",
        "whatYouNeedToKnow": [
            "⚠️ Can form nitrosamines (known carcinogens) when heated to high temperatures, especially during frying or grilling",
            "WHO classifies processed meats containing nitrites as 'probably carcinogenic' (Group 2A)",
            "Linked to increased risk of colorectal cancer with regular consumption",
            "May interfere with thyroid function in high doses",
            "Essential for preventing deadly botulism - risk vs benefit trade-off",
            "Vitamin C can help reduce nitrosamine formation"
        ],
        "fullDescription": "Nitrites and nitrates present one of food safety's most complex dilemmas. On one hand, they're essential for preventing Clostridium botulinum (botulism), a deadly bacterium that can grow in cured meats. Before their use, botulism from cured meats was common and often fatal. On the other hand, when nitrites are exposed to high heat (especially during frying or grilling), they can combine with amino acids from the meat to form nitrosamines - potent carcinogens. The WHO's International Agency for Research on Cancer (IARC) has classified processed meats as 'probably carcinogenic,' partly due to this mechanism. Studies have found associations between regular consumption of processed meats and increased colorectal cancer risk. However, industry and regulators argue that the cancer risk is outweighed by the prevention of potentially fatal botulism. Some manufacturers now add vitamin C (ascorbic acid) to inhibit nitrosamine formation. The debate continues: are the tiny amounts in food safe, or does cumulative exposure over a lifetime pose significant cancer risk?",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Saltpetre", "Prague powder", "Curing salt"],
        "sources": [
            {"title": "WHO IARC Classification of Processed Meat", "url": "https://www.iarc.who.int", "covers": "cancer research"}
        ]
    },

    # SWEETENERS (E420, E950-E999)
    {
        "eNumbers": ["E951"],
        "name": "Aspartame",
        "category": "sweetener",
        "group": "sweetener",
        "origin": "synthetic",
        "shortSummary": "Artificial sweetener 200x sweeter than sugar, breaks down into phenylalanine (dangerous for people with PKU).",
        "whatItIs": "An artificial sweetener made from two amino acids (aspartic acid and phenylalanine) chemically bonded together.",
        "whereItComesFrom": "Discovered accidentally in 1965 by a chemist working on an anti-ulcer drug. Manufactured through chemical synthesis of two amino acids. It's not found in nature.",
        "whyItsUsed": "Approximately 200 times sweeter than sugar, so tiny amounts provide intense sweetness with almost no calories. Used in diet sodas, sugar-free gum, yoghurts, and thousands of 'diet' or 'light' products worldwide.",
        "whatYouNeedToKnow": [
            "⚠️ DANGEROUS for people with phenylketonuria (PKU) - can cause brain damage",
            "Must carry warning: 'Contains a source of phenylalanine'",
            "Recently reclassified by WHO as 'possibly carcinogenic' (Group 2B) in 2023",
            "Some people report headaches, dizziness, or mood changes (though studies are mixed)",
            "Breaks down in heat, so not suitable for cooking or baking",
            "Controversial history with ongoing safety debates"
        ],
        "fullDescription": "Aspartame is one of the world's most studied and most controversial food additives. Approved in the 1980s after intense debate, it's been the subject of hundreds of studies examining everything from cancer risk to neurological effects. In July 2023, the WHO's IARC classified it as 'possibly carcinogenic to humans' (Group 2B) based on limited evidence linking it to liver cancer. However, the WHO's separate food safety body (JECFA) maintained its safety at current intake levels. This created confusion: is it safe or not? The science suggests that at normal consumption levels, most people can safely consume it - but the long-term effects of daily consumption remain debated. For people with PKU (phenylketonuria), a rare genetic disorder affecting about 1 in 10,000 people, aspartame is extremely dangerous because they cannot metabolise phenylalanine. This amino acid can build up in the brain, causing intellectual disability. All products containing aspartame must carry PKU warnings. Some people also report headaches, dizziness, or mood changes after consuming it, though large controlled studies haven't consistently confirmed these effects.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": True,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["NutraSweet", "Equal", "Canderel"],
        "sources": [
            {"title": "WHO IARC 2023 Classification", "url": "https://www.iarc.who.int", "covers": "recent cancer classification"}
        ]
    },
    {
        "eNumbers": ["E950"],
        "name": "Acesulfame K",
        "category": "sweetener",
        "group": "sweetener",
        "origin": "synthetic",
        "shortSummary": "Artificial sweetener often combined with aspartame, some studies suggest potential cancer risk but approved by regulators.",
        "whatItIs": "A calorie-free artificial sweetener discovered in 1967, often used in combination with other sweeteners.",
        "whereItComesFrom": "Discovered accidentally by a German chemist. Produced synthetically from acetoacetic acid and potassium. The 'K' stands for potassium.",
        "whyItsUsed": "About 200 times sweeter than sugar with a clean, sweet taste. Heat-stable (unlike aspartame), so can be used in baking. Often combined with aspartame or sucralose to mask bitter aftertastes.",
        "whatYouNeedToKnow": [
            "Some older studies suggested potential cancer risk in animals, but newer research is mixed",
            "Not broken down by the body - excreted unchanged in urine",
            "Critics argue it hasn't been adequately tested for long-term safety",
            "Generally recognised as safe by FDA and EFSA at current levels",
            "May affect gut bacteria according to recent studies",
            "Contains potassium (relevant for people on potassium-restricted diets)"
        ],
        "fullDescription": "Acesulfame K (Ace-K) has faced less scrutiny than aspartame but still carries controversy. Early animal studies in the 1970s suggested possible cancer risks, but these were dismissed by regulators as flawed. Critics, including the Center for Science in the Public Interest (CSPI), argue that the sweetener was approved based on inadequate testing and should undergo more rigorous long-term studies. Unlike most food components, Ace-K is not metabolised by the body - it's absorbed and then excreted unchanged in urine. While this means it provides zero calories, questions remain about its effects on metabolism and gut health. Recent research suggests artificial sweeteners like Ace-K may alter gut bacteria composition, potentially affecting glucose metabolism and weight regulation - ironically, possibly contributing to the very issues they're meant to help. The sweetener is often used alongside other artificial sweeteners because it has a slightly bitter aftertaste when used alone. It's particularly common in soft drinks, desserts, and 'sugar-free' products.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Ace-K", "Sunett", "Sweet One"],
        "sources": [
            {"title": "CSPI Analysis of Acesulfame K", "url": "https://www.cspinet.org", "covers": "safety concerns"}
        ]
    },

    # FLAVOUR ENHANCERS (E620-E650)
    {
        "eNumbers": ["E621"],
        "name": "Monosodium Glutamate (MSG)",
        "category": "flavour_enhancer",
        "group": "flavour_enhancer",
        "origin": "synthetic",
        "shortSummary": "Common flavour enhancer that boosts 'umami' taste, controversial due to reported sensitivity reactions ('Chinese Restaurant Syndrome').",
        "whatItIs": "The sodium salt of glutamic acid, an amino acid that occurs naturally in many foods. It enhances savoury 'umami' flavours.",
        "whereItComesFrom": "Originally extracted from seaweed in Japan in 1908. Now mass-produced through bacterial fermentation of sugars (similar to how yoghurt is made). The glutamate is the same as naturally-occurring glutamate in foods like tomatoes and cheese.",
        "whyItsUsed": "Intensifies meaty, savoury (umami) flavours, making foods taste richer and more satisfying. Used in crisps, instant noodles, soups, sauces, and processed meats. Very effective at masking off-flavours in low-quality ingredients.",
        "whatYouNeedToKnow": [
            "Some people report sensitivity symptoms: headaches, flushing, sweating, numbness (called 'Chinese Restaurant Syndrome')",
            "Large controlled studies have not consistently confirmed these reactions",
            "The FDA and EFSA consider it safe for most people",
            "May trigger symptoms in people who are genuinely sensitive (estimated 1-2% of population)",
            "Often used to mask poor ingredient quality",
            "Naturally occurring glutamate in foods doesn't typically cause the same reactions"
        ],
        "fullDescription": "MSG is perhaps the most controversial flavour enhancer in food history. Discovered in Japan in 1908 by Professor Kikunae Ikeda, it revolutionised food manufacturing by providing a way to enhance flavours cheaply. The controversy began in 1968 when a doctor wrote to the New England Journal of Medicine describing symptoms after eating at Chinese restaurants - coining the term 'Chinese Restaurant Syndrome.' This sparked decades of research and debate. Large, well-controlled scientific studies have generally failed to reproduce the reported symptoms when MSG is consumed without people knowing. However, some individuals do appear genuinely sensitive. The difference may lie in the amount consumed and whether it's eaten on an empty stomach. Glutamate itself is a natural amino acid found in high concentrations in aged cheese, tomatoes, mushrooms, and breast milk. The body produces about 40g of glutamate daily. The question is whether concentrated, isolated MSG affects the body differently than naturally-occurring glutamate in foods. Critics also note that MSG is often used to make low-quality ingredients taste better, potentially masking poor food quality.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["MSG", "Glutamate", "Accent", "Vetsin"],
        "sources": [
            {"title": "FDA Report on MSG", "url": "https://www.fda.gov", "covers": "safety assessment"}
        ]
    },

    # EMULSIFIERS (E400-E499)
    {
        "eNumbers": ["E433", "E434", "E435", "E436"],
        "name": "Polysorbates",
        "category": "emulsifier",
        "group": "emulsifier",
        "origin": "synthetic",
        "shortSummary": "Synthetic emulsifiers that help mix oil and water, recent research links them to gut inflammation and altered microbiome.",
        "whatItIs": "A family of synthetic compounds that help mix ingredients that normally don't combine, like oil and water.",
        "whereItComesFrom": "Manufactured through chemical reactions involving sorbitol (a sugar alcohol) and fatty acids, then treated with ethylene oxide (a toxic gas used in the synthesis). The final product is different from these starting materials.",
        "whyItsUsed": "Prevents oil and water from separating in foods like ice cream, salad dressings, and baked goods. Creates smooth textures and extends shelf life. Very effective at small concentrations.",
        "whatYouNeedToKnow": [
            "⚠️ Recent studies link polysorbates to gut inflammation and inflammatory bowel disease in mice",
            "May disrupt the gut microbiome and increase intestinal permeability ('leaky gut')",
            "Research suggests they may promote bacteria crossing the gut barrier",
            "Concerns about ethylene oxide residues in some commercial preparations",
            "Increasingly scrutinised for role in rise of inflammatory bowel diseases",
            "Generally recognised as safe by regulators, but emerging research raises questions"
        ],
        "fullDescription": "Polysorbates represent the darker side of food emulsifiers. Until recently, they were considered completely safe and inert. However, groundbreaking research published in Nature and other prestigious journals has revealed concerning effects on gut health. Studies show that in mice, polysorbates can disrupt the mucus layer protecting the gut lining, allowing bacteria to penetrate tissues and trigger inflammation. This has been linked to the development of colitis and metabolic syndrome. The emulsifiers appear to alter gut bacteria composition and promote low-grade inflammation. With inflammatory bowel diseases (Crohn's and ulcerative colitis) rising sharply in developed countries, researchers are investigating whether widespread emulsifier consumption could be a contributing factor. The concern is amplified by the fact that emulsifiers are now ubiquitous in processed foods - the average person may consume several grams daily. Additionally, the manufacturing process involves ethylene oxide, a known carcinogen, raising concerns about residues. While human studies are still limited and regulators maintain these additives are safe, the animal research is compelling enough that some researchers recommend limiting consumption, especially for people with digestive issues.",
        "effectsVerdict": "caution",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Polysorbate 20", "Polysorbate 60", "Polysorbate 65", "Polysorbate 80", "Tween"],
        "sources": [
            {"title": "Nature Study on Emulsifiers and Gut Health", "url": "https://www.nature.com", "covers": "microbiome research"}
        ]
    },

    # ANTIOXIDANTS (E300-E399)
    {
        "eNumbers": ["E320"],
        "name": "Butylated Hydroxyanisole (BHA)",
        "category": "antioxidant",
        "group": "antioxidant",
        "origin": "synthetic",
        "shortSummary": "Synthetic antioxidant classified as 'reasonably anticipated to be a human carcinogen' by US health authorities.",
        "whatItIs": "A synthetic antioxidant used to prevent fats and oils from going rancid.",
        "whereItComesFrom": "Produced synthetically through chemical reactions involving petroleum-derived chemicals. It does not occur in nature.",
        "whyItsUsed": "Prevents oxidation of fats and oils, extending shelf life of fatty foods like crisps, cereals, baked goods, and chewing gum. Very effective and cheap.",
        "whatYouNeedToKnow": [
            "⚠️ Classified as 'reasonably anticipated to be a human carcinogen' by the US National Toxicology Program",
            "Caused cancer in animal studies (particularly stomach tumours in rats)",
            "Banned in Japan and several other countries",
            "May act as an endocrine disruptor, affecting hormones",
            "Can cause allergic reactions in sensitive individuals",
            "Still permitted in UK/EU but with strict limits and ongoing review"
        ],
        "fullDescription": "BHA is one of the most controversial antioxidants in the food supply. The US National Toxicology Program has listed it as 'reasonably anticipated to be a human carcinogen' since 2011, based on consistent evidence that it causes tumours in animals. Studies in rats and hamsters have shown that BHA causes forestomach tumours and other cancers. The International Agency for Research on Cancer (IARC) classifies it as 'possibly carcinogenic to humans' (Group 2B). Japan banned BHA in the 1960s after finding it caused cancer in rats. Despite this concerning evidence, the FDA and EFSA maintain it's safe at the low levels used in foods, arguing that rodent forestomach tumours may not be relevant to humans (who don't have forestomachs). However, critics point out that BHA accumulates in body fat and we don't fully understand long-term, low-level exposure effects. There's also evidence it may disrupt hormone systems and cause allergic reactions. Many food manufacturers have voluntarily removed it, switching to safer alternatives like vitamin E (tocopherols), but it remains in many products.",
        "effectsVerdict": "avoid",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["BHA"],
        "sources": [
            {"title": "US National Toxicology Program Report", "url": "https://ntp.niehs.nih.gov", "covers": "carcinogen classification"}
        ]
    },
    {
        "eNumbers": ["E321"],
        "name": "Butylated Hydroxytoluene (BHT)",
        "category": "antioxidant",
        "group": "antioxidant",
        "origin": "synthetic",
        "shortSummary": "Synthetic antioxidant similar to BHA, studies show mixed results on cancer risk, banned in several countries.",
        "whatItIs": "A synthetic antioxidant chemically similar to BHA, used to prevent rancidity in fats.",
        "whereItComesFrom": "Manufactured from petroleum derivatives through industrial chemical processes. Originally developed for use in industrial oils, later adopted for food.",
        "whyItsUsed": "Prevents oxidation and rancidity in foods containing fats and oils. Found in cereals, crisps, baked goods, and chewing gum. Often used alongside BHA for synergistic effect.",
        "whatYouNeedToKnow": [
            "Studies show contradictory results - some suggest cancer-promoting effects, others show anti-cancer properties",
            "May affect thyroid and liver function in high doses",
            "Can cause allergic reactions and hyperactivity in sensitive individuals",
            "Banned in Japan, Romania, Sweden, and Australia",
            "Accumulates in body fat with repeated consumption",
            "Interacts with vitamin K, potentially affecting blood clotting"
        ],
        "fullDescription": "BHT presents a scientific paradox: some studies suggest it promotes cancer, while others suggest it may help prevent it. This contradiction has puzzled researchers for decades. Animal studies have shown BHT can promote tumour growth in some organs while inhibiting it in others, depending on dose, timing, and the animal species studied. The confusion led to its ban in several countries. Research has shown BHT can affect the liver and thyroid, particularly in young animals. It may also interfere with blood clotting by affecting vitamin K metabolism. Some children appear sensitive to BHT, with reports of hyperactivity, though controlled studies are limited. Like BHA, it accumulates in body fat, raising concerns about cumulative exposure. The food industry argues that the doses in foods are far below levels that show effects in animal studies. However, critics counter that we don't understand the effects of lifelong, daily exposure to multiple synthetic antioxidants. Many manufacturers have switched to natural alternatives like vitamin E (E306-309) and rosemary extract.",
        "effectsVerdict": "avoid",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["BHT"],
        "sources": [
            {"title": "IARC Evaluation of BHT", "url": "https://monographs.iarc.who.int", "covers": "cancer research"}
        ]
    },

    # VITAMINS (beneficial additives)
    {
        "eNumbers": ["E300", "E301", "E302", "E303"],
        "name": "Ascorbic Acid (Vitamin C)",
        "category": "antioxidant",
        "group": "antioxidant",
        "origin": "synthetic",
        "shortSummary": "Vitamin C added to foods as an antioxidant and nutrient, generally very safe and beneficial.",
        "whatItIs": "Vitamin C, an essential nutrient that acts as an antioxidant in foods and in the body.",
        "whereItComesFrom": "Naturally found in citrus fruits, berries, and vegetables. Most commercial vitamin C is now synthesised from glucose using chemical or bacterial processes (the Reichstein process).",
        "whyItsUsed": "Prevents browning and oxidation in foods, particularly cut fruits and fruit juices. Also added to fortify foods and improve nutritional value. Helps prevent nitrosamine formation in cured meats.",
        "whatYouNeedToKnow": [
            "✓ Essential nutrient with numerous health benefits",
            "✓ Acts as antioxidant, protecting cells from damage",
            "✓ Helps iron absorption",
            "✓ Generally very safe with few side effects",
            "Very high doses may cause digestive upset in some people",
            "Can form benzene when combined with sodium benzoate (E211) in soft drinks"
        ],
        "fullDescription": "Vitamin C (ascorbic acid) is one of the few food additives that's genuinely beneficial. As an essential nutrient, humans cannot produce it and must obtain it from diet. When added to foods, it serves dual purposes: preserving freshness by preventing oxidation, and fortifying foods with a beneficial nutrient. The vitamin is crucial for immune function, collagen production, wound healing, and iron absorption. In processed meats containing nitrites, vitamin C helps block the formation of carcinogenic nitrosamines. However, there's one notable concern: when combined with sodium benzoate (E211) in acidic drinks exposed to heat or light, vitamin C can contribute to benzene formation. This led to reformulations of many soft drinks in the 2000s. The ascorbic acid used in foods is chemically identical to that in oranges - there's no difference between 'natural' and 'synthetic' vitamin C at the molecular level. For most people, the amounts in fortified foods pose no risk, though extremely high supplemental doses (several grams daily) may cause digestive upset.",
        "effectsVerdict": "neutral",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "synonyms": ["Vitamin C", "Sodium ascorbate", "Calcium ascorbate"],
        "sources": [
            {"title": "NHS Information on Vitamin C", "url": "https://www.nhs.uk", "covers": "nutritional benefits"}
        ]
    },
]

def create_comprehensive_database():
    """Create the comprehensive additives database"""

    database = {
        "metadata": {
            "version": "3.0.0-comprehensive",
            "total_ingredients": len(COMPREHENSIVE_ADDITIVES),
            "last_updated": datetime.now().strftime("%Y-%m-%d"),
            "description": "Consumer-focused comprehensive additive database with detailed, honest information about what additives are, where they come from, and what consumers need to know",
            "sources": [
                "UK Food Standards Agency (FSA)",
                "European Food Safety Authority (EFSA)",
                "US Food and Drug Administration (FDA)",
                "WHO International Agency for Research on Cancer (IARC)",
                "Scientific peer-reviewed literature",
                "Consumer advocacy groups (CSPI, etc.)"
            ],
            "data_philosophy": "Honest, consumer-first information. We tell you if something comes from crushed insects, coal tar, or petroleum. We explain real health concerns backed by research, not just industry talking points."
        },
        "ingredients": COMPREHENSIVE_ADDITIVES
    }

    return database

if __name__ == "__main__":
    print("🔬 Creating comprehensive additive database...")
    print()

    db = create_comprehensive_database()

    # Save to file
    output_path = "NutraSafe Beta/ingredients_comprehensive.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"✅ Created comprehensive database: {output_path}")
    print(f"📊 Total additives: {len(COMPREHENSIVE_ADDITIVES)}")
    print()
    print("Sample entries created:")
    for additive in COMPREHENSIVE_ADDITIVES[:5]:
        print(f"  • {additive['name']} ({', '.join(additive['eNumbers'])})")

    print()
    print("⚠️  This is a starter database with 15 detailed examples.")
    print("    You'll need to expand it to cover all ~400 common additives.")
