#!/usr/bin/env python3
"""
Write comprehensive, consumer-focused descriptions for ALL 414 additives.
This replaces generic template content with real, researched information.
"""

import json

# Load the database
with open('NutraSafe Beta/ingredients_comprehensive.json', 'r') as f:
    db = json.load(f)

print(f"Loaded {len(db['ingredients'])} additives")
print("Writing comprehensive descriptions...\n")

# Dictionary to store all comprehensive data
# Format: "Name": {whatItIs, whereItComesFrom, whyItsUsed, whatYouNeedToKnow, fullDescription}

comprehensive_data = {}

# ============================================================================
# BATCH 1: MOST COMMON ADDITIVES (Top 50)
# ============================================================================

comprehensive_data["Citric acid"] = {
    "whatItIs": "The sharp, tangy acid that makes lemons taste sour - the most abundant acid in citrus fruits.",
    "whereItComesFrom": "Nearly all commercial citric acid comes from feeding sugar to Aspergillus niger mold in fermentation tanks. The mold produces citric acid as it digests the sugar.",
    "whyItsUsed": "Adds tartness to foods, prevents browning in fruits, and acts as a preservative by lowering pH where bacteria struggle.",
    "whatYouNeedToKnow": [
        "Generally recognized as safe - identical to citric acid in oranges",
        "One of the most widely used food additives worldwide",
        "Can be derived from genetically modified corn",
        "Your cells naturally produce it for energy metabolism"
    ],
    "fullDescription": "Citric acid (E330) is an organic acid naturally present in all living organisms, playing a crucial role in the Krebs cycle that generates cellular energy. Industrial production switched from citrus extraction to microbial fermentation in the 1900s when lemons became scarce. Aspergillus niger mold efficiently converts sugar into citric acid in days. The acid is filtered, purified, and crystallized. In food, it provides flavor (pleasant sourness), pH adjustment (preserving color and preventing microbes), and chelation (binding metals that cause oxidation). No restrictions exist because it's metabolized like natural citric acid."
}

comprehensive_data["Ascorbic acid"] = {
    "whatItIs": "Vitamin C - an essential nutrient your body cannot produce. Synthetic vitamin C is chemically identical to the version in oranges.",
    "whereItComesFrom": "Synthesized from glucose (usually from corn) through the Reichstein process involving bacterial fermentation and chemical modifications.",
    "whyItsUsed": "Fortifies foods with vitamin C and acts as an antioxidant to prevent browning and extend shelf life.",
    "whatYouNeedToKnow": [
        "Essential vitamin - you need 75-90mg daily to prevent scurvy",
        "Can form benzene (carcinogen) when combined with sodium benzoate and heat",
        "High doses above 2000mg may cause digestive upset",
        "Excess is excreted in urine - your body regulates absorption"
    ],
    "fullDescription": "Ascorbic acid (E300/Vitamin C) is essential for collagen formation, wound healing, iron absorption, and immune function. Humans lost the ability to synthesize it millions of years ago. The Reichstein process converts corn-derived glucose through fermentation into pure ascorbic acid. It serves dual purposes: nutritional fortification and antioxidant preservation. Benzene formation concerns arose when researchers found that combining it with sodium benzoate in heat-exposed beverages could form the carcinogen benzene. Properly formulated products keep benzene negligible. Your intestine absorbs up to 400mg efficiently; beyond that, excess causes osmotic diarrhea."
}

comprehensive_data["Sodium benzoate"] = {
    "whatItIs": "The sodium salt of benzoic acid, a preservative naturally found in cranberries, prunes, and cinnamon.",
    "whereItComesFrom": "Synthesized by reacting benzoic acid (made from petroleum-derived toluene) with sodium hydroxide.",
    "whyItsUsed": "Prevents bacteria and fungi in acidic foods - particularly effective in soft drinks, pickles, and dressings below pH 4.5.",
    "whatYouNeedToKnow": [
        "Generally safe when used alone in permitted amounts",
        "Can form benzene (carcinogen) when combined with vitamin C and heat",
        "May trigger reactions in aspirin-sensitive people",
        "Linked to hyperactivity in the Southampton study"
    ],
    "fullDescription": "Sodium benzoate (E211) is economical and effective in acidic foods, working by interfering with cellular enzymes in bacteria and fungi. Major controversy erupted when researchers found it could form benzene when combined with ascorbic acid (vitamin C), especially with heat exposure. This led to soft drink recalls. The FDA maintains proper formulations stay below safety limits (5 ppb). The 2007 Southampton study linked it to hyperactivity in children. It's metabolized in your liver to hippuric acid and excreted within 24 hours. People sensitive to aspirin may react because of chemical similarity."
}

comprehensive_data["Potassium sorbate"] = {
    "whatItIs": "The potassium salt of sorbic acid, providing both antimicrobial preservation and potassium ions.",
    "whereItComesFrom": "Produced by neutralizing synthetically-made sorbic acid with potassium hydroxide.",
    "whyItsUsed": "Prevents mold, yeast, and some bacteria in foods like cheese, wine, dried fruits, and baked goods.",
    "whatYouNeedToKnow": [
        "Generally considered very safe - one of the least toxic preservatives",
        "More water-soluble than sorbic acid itself",
        "Can cause mild irritation in very high concentrations",
        "Most widely used preservative globally"
    ],
    "fullDescription": "Potassium sorbate (E202) is the most widely used sorbate preservative due to excellent water solubility. It breaks down into sorbic acid in your digestive system, then metabolizes like normal fatty acids through beta-oxidation. Unlike sodium benzoate, it doesn't form concerning breakdown products. Particularly effective against molds and yeasts that spoil cheese, wine, and baked goods. Works best in acidic conditions. WHO considers it one of the safest preservatives with no evidence of carcinogenicity, genotoxicity, or reproductive effects. Even high doses show minimal toxicity."
}

comprehensive_data["Sorbic acid"] = {
    "whatItIs": "A natural antimicrobial compound originally isolated from mountain ash berries, now mostly synthesized.",
    "whereItComesFrom": "Historically from rowan (mountain ash) berries, but commercial production uses chemical synthesis from ketene and crotonaldehyde for cost efficiency.",
    "whyItsUsed": "Prevents mold and yeast growth in cheese, baked goods, wine, and dried fruits without affecting taste.",
    "whatYouNeedToKnow": [
        "Generally recognized as safe with minimal side effects",
        "One of the least toxic food preservatives available",
        "Works best in acidic foods below pH 6.5",
        "Can cause mild skin irritation in sensitive individuals"
    ],
    "fullDescription": "Sorbic acid (E200) and its salts (E201-E203) are among the safest preservatives available. Discovered in rowan berries in the 1850s, it's now cheaply synthesized. Works by disrupting enzymes in mold and yeast, preventing growth without killing beneficial bacteria in fermented products. Most effective in acidic conditions (pH below 6.5), which is why it's common in pickles, cheese, and wine. Unlike some preservatives, it doesn't form harmful compounds when heated. Your body metabolizes it like other fatty acids, breaking it down completely. Allergic reactions are rare and usually limited to contact dermatitis."
}

comprehensive_data["Calcium propionate"] = {
    "whatItIs": "The calcium salt of propionic acid, a compound naturally produced during Swiss cheese fermentation.",
    "whereItComesFrom": "Synthetically produced by reacting propionic acid (made from ethylene and carbon monoxide) with calcium hydroxide.",
    "whyItsUsed": "Prevents mold growth in bread and baked goods without affecting yeast, so bread still rises normally.",
    "whatYouNeedToKnow": [
        "Generally recognized as safe",
        "Your gut bacteria naturally produce propionic acid during fiber digestion",
        "Particularly effective against bread mold without inhibiting yeast",
        "Some parents report behavioral changes in children (limited scientific evidence)"
    ],
    "fullDescription": "Calcium propionate (E282) is unique because your colon bacteria naturally produce propionic acid during fiber fermentation. This short-chain fatty acid actually has health benefits, feeding colon cells and regulating appetite. The synthetic version is chemically identical. Specifically used in bread because unlike many preservatives, it doesn't inhibit yeast - bread rises properly. Some parents claim it causes irritability or sleep problems in children, but controlled studies haven't confirmed this. Generally considered one of the safer preservatives, though some consumers choose propionate-free bread to avoid all additives."
}

comprehensive_data["Lecithin"] = {
    "whatItIs": "A natural mixture of phospholipids (fat molecules) that exists in all living cells - the same compounds that make up your cell membranes.",
    "whereItComesFrom": "Primarily extracted from soybeans (which may be genetically modified) or egg yolks. The oil is degummed, and lecithin separates out as a sticky, brownish substance.",
    "whyItsUsed": "Acts as an emulsifier, helping oil and water mix smoothly in chocolate, baked goods, margarine, and salad dressings.",
    "whatYouNeedToKnow": [
        "Generally recognized as safe - it's a natural component of all cells",
        "Most commercial lecithin comes from GMO soybeans",
        "Sunflower lecithin is a non-GMO alternative",
        "Can be beneficial as a source of choline (an essential nutrient)"
    ],
    "fullDescription": "Lecithin (E322) is a complex mixture of phospholipids, primarily phosphatidylcholine, that forms the basis of all cell membranes. Your body produces it naturally, and you consume it whenever you eat eggs, soybeans, or meat. Commercial lecithin is extracted from soybeans during oil refining - the oil is washed with water, and lecithin naturally separates. As an emulsifier, it has unique properties: one end of the molecule loves water (hydrophilic), the other loves fat (lipophobic), allowing it to create stable mixtures of oil and water. This is why chocolate becomes smooth when lecithin is added - it helps cocoa butter and cocoa solids blend seamlessly. Soy lecithin dominates the market because soybeans are processed in massive quantities for oil, making lecithin an inexpensive byproduct. However, most soybeans are genetically modified, leading to demand for alternatives like sunflower lecithin. No significant safety concerns exist - lecithin is actually sold as a nutritional supplement for its choline content, which supports brain health and liver function."
}

comprehensive_data["Carrageenan"] = {
    "whatItIs": "A gel-forming compound extracted from red seaweed that's been used in Irish cooking for over 600 years.",
    "whereItComesFrom": "Harvested from red seaweed species (Chondrus crispus and others) grown in coastal waters. The seaweed is washed, boiled, filtered, and the carrageenan is extracted, purified, and dried.",
    "whyItsUsed": "Thickens and stabilizes dairy products, plant milks, ice cream, and processed meats. Creates smooth texture and prevents separation.",
    "whatYouNeedToKnow": [
        "Controversial - some animal studies suggest digestive inflammation",
        "Degraded carrageenan (poligeenan) is harmful, but food-grade is different",
        "Particularly common in almond milk, ice cream, and deli meats",
        "Some consumers avoid it despite FDA approval",
        "USDA organic standards allow it, but some organic brands exclude it voluntarily"
    ],
    "fullDescription": "Carrageenan (E407) has been used since at least the 1400s in Ireland, where coastal villagers boiled Irish moss (a red seaweed) to thicken puddings and medicinal drinks. Today it's industrially extracted from farmed seaweed. The controversy stems from animal studies in the 1960s-1970s that found degraded carrageenan (called poligeenan) caused intestinal inflammation, ulcers, and tumors in lab animals. However, food-grade carrageenan has much larger molecules that don't get absorbed. The concern is whether digestive acids partially degrade food-grade carrageenan into harmful fragments. Reviews by the FDA, EFSA, and WHO conclude food-grade carrageenan is safe, but some scientists, particularly Dr. Joanne Tobacman, continue publishing research suggesting it triggers inflammatory pathways even in undegraded form. Some people report digestive issues when consuming products with carrageenan. Many plant-milk manufacturers have removed it due to consumer pressure, switching to gellan gum or other stabilizers. The debate continues - regulatory agencies say it's safe, but consumer skepticism persists."
}

comprehensive_data["Guar gum"] = {
    "whatItIs": "A fiber extracted from guar beans, the seeds of a legume plant grown primarily in India and Pakistan.",
    "whereItComesFrom": "Guar beans are dehusked, milled, and screened to produce a fine powder of galactomannan (a type of soluble fiber).",
    "whyItsUsed": "Thickens and stabilizes foods like ice cream, yogurt, sauces, and gluten-free baked goods. Prevents ice crystal formation.",
    "whatYouNeedToKnow": [
        "Generally safe - it's a type of soluble fiber",
        "Can cause gas, bloating, or diarrhea in large amounts",
        "Benefits: May help control blood sugar and lower cholesterol",
        "Used in weight-loss supplements because it swells in your stomach"
    ],
    "fullDescription": "Guar gum (E412) is a soluble fiber from guar beans, grown extensively in India. The beans are processed to isolate the endosperm, which is ground into powder. As a food additive, it's incredibly efficient - tiny amounts (0.1-0.5%) create significant thickening because the long polysaccharide chains trap water molecules. In ice cream, it prevents ice crystal growth, creating smooth texture. In gluten-free baking, it partially mimics gluten's binding properties. Beyond food, guar gum is used in hydraulic fracturing (fracking) to thicken fluids. Health-wise, being soluble fiber means it can help lower cholesterol, improve blood sugar control, and promote gut health - benefits confirmed in clinical studies. The weight-loss supplement use stems from its ability to absorb water and expand up to 20 times its volume, creating fullness. However, excessive intake (especially in supplement form) can cause severe digestive issues, and there have been cases of esophageal obstruction when guar gum tablets swell before reaching the stomach. At food-additive levels, it's considered very safe."
}

comprehensive_data["Xanthan gum"] = {
    "whatItIs": "A slimy polysaccharide produced by feeding sugar to Xanthomonas campestris bacteria - the same bacterium that causes black rot on broccoli and cauliflower.",
    "whereItComesFrom": "Manufactured by fermenting glucose or sucrose (often from corn or soy) with Xanthomonas campestris bacteria in large tanks. The bacteria produce xanthan gum as they grow, which is then purified and dried.",
    "whyItsUsed": "Creates thickness and prevents separation in salad dressings, sauces, and gluten-free products. Remains stable across temperature and pH changes.",
    "whatYouNeedToKnow": [
        "Generally safe with extensive safety testing",
        "Can cause digestive upset (gas, bloating) in sensitive individuals",
        "Produced from bacteria but the final product contains no living bacteria",
        "Often derived from corn or soy, which may be genetically modified"
    ],
    "fullDescription": "Xanthan gum (E415) was discovered by USDA researchers in the 1960s while studying bacterial plant pathogens. Xanthomonas campestris produces a slimy coating (biofilm) as a defense mechanism, and scientists realized this polysaccharide had remarkable properties for food use. Commercial production involves fermenting corn sugar with the bacteria in controlled tanks, then killing the bacteria, purifying the xanthan gum, and spray-drying it into powder. What makes xanthan gum special is its pseudoplastic behavior - it's thick when still but flows easily when stirred or poured. This is why salad dressing clings to lettuce but pours smoothly from the bottle. It's also remarkably stable - works across wide pH ranges (from acidic to alkaline), tolerates freezing and heating, and withstands high salt concentrations. In gluten-free baking, it partially mimics gluten's structure-building properties. Safety studies are extensive because it's so widely used. Some people report digestive issues, particularly when consuming large amounts (as in meal replacement shakes). The source material (corn or soy) is usually genetically modified, which concerns some consumers."
}

# Continue with more additives...
print(f"Prepared {len(comprehensive_data)} comprehensive entries so far")
print("Applying updates to database...")

# BATCH 2: COMMON SWEETENERS & COLORS
# ============================================================================

comprehensive_data["Aspartame"] = {
    "whatItIs": "An artificial sweetener made from two amino acids (aspartic acid and phenylalanine), 200 times sweeter than sugar.",
    "whereItComesFrom": "Synthesized in laboratories by chemically bonding aspartic acid and phenylalanine (both protein building blocks) with a methyl ester group.",
    "whyItsUsed": "Provides intense sweetness with almost no calories in diet soft drinks, sugar-free gum, and low-calorie desserts.",
    "whatYouNeedToKnow": [
        "DANGEROUS for people with PKU (phenylketonuria) - cannot metabolize phenylalanine",
        "WHO in 2023 classified it as 'possibly carcinogenic to humans' (Group 2B)",
        "Breaks down in heat, so cannot be used in baking",
        "Controversial - some studies link to headaches and behavioral effects",
        "Widely studied but remains divisive among scientists and consumers"
    ],
    "fullDescription": "Aspartame (E951/NutraSweet) was accidentally discovered in 1965 by a chemist researching ulcer drugs. It's a dipeptide - two amino acids linked together. When consumed, it breaks down into aspartic acid, phenylalanine, and methanol. People with phenylketonuria (PKU), a genetic disorder affecting 1 in 10,000-15,000 people, cannot metabolize phenylalanine, causing brain damage - products must carry PKU warnings. In 2023, WHO's International Agency for Research on Cancer classified aspartame as Group 2B (possibly carcinogenic), based on limited evidence from three studies. However, WHO's separate food safety body maintained safe intake levels at 40mg/kg body weight daily. This created confusion - is it safe or not? The answer depends on interpretation. Large observational studies found associations with cancer, but causation isn't proven. It's unstable in heat and liquid over time, breaking down into components including methanol (though amounts are tiny compared to fruit juice). Some people report headaches, dizziness, or mood changes, but controlled trials often fail to reproduce these effects. Despite decades of use and hundreds of studies, controversy persists. Many manufacturers switched to sucralose or stevia due to consumer concerns."
}

comprehensive_data["Sucralose"] = {
    "whatItIs": "An artificial sweetener created by selectively chlorinating sugar molecules, making them 600 times sweeter than sugar but indigestible.",
    "whereItComesFrom": "Manufactured by replacing three hydroxyl groups on sucrose (table sugar) with chlorine atoms through a multi-step chemical process.",
    "whyItsUsed": "Provides intense sweetness without calories in diet drinks, baked goods, and sugar-free products. Unlike aspartame, it's heat-stable.",
    "whatYouNeedToKnow": [
        "Marketed as 'made from sugar' though it's heavily modified",
        "Passes through your body largely unchanged - you don't absorb or metabolize it",
        "Heat-stable, so can be used in baking unlike aspartame",
        "Some studies suggest it may alter gut bacteria",
        "Generally considered safe by regulators but some scientists remain cautious"
    ],
    "fullDescription": "Sucralose (E955/Splenda) was discovered accidentally in 1976 when a scientist misheard 'test this chemical' as 'taste this chemical.' The chlorination of sucrose creates a molecule your body doesn't recognize as food - it passes through mostly unchanged, providing sweetness without calories. About 85% is excreted unchanged in feces within 24 hours. Unlike aspartame, it remains stable when heated, making it suitable for baking. The 'made from sugar' marketing is technically true but misleading - the final product is a chlorinated compound quite different from table sugar. Recent research raises questions about effects on gut bacteria. Some studies show sucralose may reduce beneficial bacteria populations and alter the gut microbiome, particularly at high doses. There's also concern about breakdown products when sucralose is heated to very high temperatures (above 350°F), potentially forming chlorinated compounds. Most safety studies were done decades ago; newer research suggests effects not previously recognized. Despite regulatory approval, some scientists argue more research is needed, particularly on long-term gut health effects. Many consumers view it as safer than aspartame, but the science isn't settled."
}

comprehensive_data["Tartrazine"] = {
    "whatItIs": "A synthetic lemon-yellow dye derived from coal tar, one of the most widely used and controversial yellow food colorings.",
    "whereItComesFrom": "Manufactured from petroleum-based raw materials through chemical synthesis involving diazotization and coupling reactions.",
    "whyItsUsed": "Creates bright yellow colors in soft drinks, candy, chips, cereals, and desserts. Extremely stable and cost-effective.",
    "whatYouNeedToKnow": [
        "Linked to hyperactivity in children - requires EU warning label",
        "Can trigger asthma and hives in sensitive individuals (up to 10% of aspirin-sensitive people)",
        "Banned in Norway and Austria",
        "Most controversial of all yellow dyes",
        "Part of the 'Southampton Six' additives"
    ],
    "fullDescription": "Tartrazine (E102/Yellow 5) is perhaps the most controversial food coloring. Multiple studies link it to hyperactivity, particularly the landmark 2007 Southampton research that examined additives and child behavior. It can trigger allergic reactions including hives, asthma attacks, and migraines, especially in people sensitive to aspirin (salicylates) - affects up to 10% of aspirin-sensitive individuals. Norway and Austria ban it entirely as a precautionary measure. Despite controversy, it remains widely used globally because it's incredibly stable - doesn't fade with heat, light, or pH changes - and costs pennies per kilogram. The bright yellow comes from an azo dye structure (containing -N=N- bonds). Parent advocacy groups, particularly in the UK and US, have campaigned heavily for its removal from children's products. Many manufacturers reformulated using natural alternatives like turmeric or beta-carotene. EU regulations require products containing tartrazine to carry warnings: 'may have an adverse effect on activity and attention in children.' Some countries require separate labeling for tartrazine beyond general 'color' declarations. The FDA maintains it's safe at permitted levels, but growing consumer rejection has pushed many brands away from using it."
}

comprehensive_data["Sunset Yellow"] = {
    "whatItIs": "A synthetic petroleum-derived orange dye, part of the azo dye family known for causing reactions in sensitive individuals.",
    "whereItComesFrom": "Synthesized from coal tar derivatives in chemical factories through aromatic chemistry processes.",
    "whyItsUsed": "Provides bright orange coloring in beverages, desserts, candy, and processed cheese products.",
    "whatYouNeedToKnow": [
        "Linked to hyperactivity in children - EU warning required",
        "One of the 'Southampton Six' additives",
        "Banned in Norway and Finland",
        "May cause allergic reactions, particularly in aspirin-sensitive people"
    ],
    "fullDescription": "Sunset Yellow FCF (E110/Yellow 6) is an azo dye included in the Southampton Six - additives linked to behavioral changes in children in the 2007 study funded by the UK Food Standards Agency. The EU mandates warning labels on products containing it: 'may have an adverse effect on activity and attention in children.' Norway and Finland ban it outright due to health concerns, while other countries permit it with restrictions. Like other azo dyes, it can trigger reactions in people sensitive to aspirin or NSAIDs because of chemical structural similarities. Some studies suggest possible effects on attention and activity in children, though the FDA maintains current levels are safe based on their review of evidence. Used extensively in orange-flavored drinks, cheese sauces, and candy. The name 'sunset yellow' refers to its orange-yellow hue resembling sunset colors. Many food manufacturers, particularly in Europe, voluntarily removed it from products following the Southampton study, replacing it with natural alternatives like annatto or paprika extract, despite regulatory permission to use it."
}

comprehensive_data["Allura Red"] = {
    "whatItIs": "A synthetic petroleum-derived dye creating bright orange-red colors, originally developed to replace Red 2 which was banned due to cancer concerns.",
    "whereItComesFrom": "Synthesized in laboratories from petroleum-based chemicals through complex organic chemistry reactions.",
    "whyItsUsed": "Provides vivid red-orange coloring in beverages, candies, cereals, and snack foods. More stable than natural red colors.",
    "whatYouNeedToKnow": [
        "Linked to hyperactivity in children - requires warning in EU",
        "Most widely used red dye in the US (Red 40)",
        "May cause allergic reactions in sensitive individuals",
        "Banned in Denmark, Belgium, France, and Switzerland"
    ],
    "fullDescription": "Allura Red AC (E129/Red 40) became the dominant red food dye in the United States after Red 2 (amaranth) was banned in 1976 following studies suggesting cancer risks. It's now the most commonly used food dye in America, appearing in everything from Doritos to Gatorade. The 2007 Southampton study linked it to increased hyperactivity and attention problems in children, leading to mandatory EU warning labels. Some animal studies suggested potential effects on brain development and behavior, though human evidence remains mixed and debated. The FDA maintains it's safe at current consumption levels based on their evaluation. It's an azo dye, meaning people with aspirin sensitivity may react due to similar chemical structures. Several European countries banned it despite broader EU approval. Consumer advocacy groups, particularly Center for Science in the Public Interest (CSPI), continue pushing for its removal, especially from children's foods. Some manufacturers responded by creating versions without synthetic dyes for European markets while continuing to use Red 40 in the US. The color is stable across pH ranges and heat exposure, making it technically superior to natural alternatives like beet juice or anthocyanins."
}

comprehensive_data["Carmoisine"] = {
    "whatItIs": "A synthetic coal tar-derived dye that produces bright pinkish-red colors, particularly popular in European products.",
    "whereItComesFrom": "Manufactured in chemical laboratories from petroleum-derived aromatic compounds through diazotization and coupling reactions.",
    "whyItsUsed": "Creates bright red and pink colors in sweets, desserts, and beverages. Cheaper and more stable than natural alternatives.",
    "whatYouNeedToKnow": [
        "Linked to hyperactivity in children - requires warning label in EU",
        "Banned in USA, Canada, Japan, Norway, and Sweden",
        "Part of the 'Southampton Six' additives",
        "May cause allergic reactions, especially in aspirin-sensitive people"
    ],
    "fullDescription": "Carmoisine (E122/Azorubine) is an azo dye synthesized from coal tar derivatives, commonly used in Europe but banned in North America and several other regions. The 2007 Southampton study found associations between carmoisine consumption and increased hyperactivity and attention problems in children, leading to mandatory EU warnings: 'may have an adverse effect on activity and attention in children.' It's banned in the United States, Australia, Canada, Japan, Norway, and Sweden due to safety concerns, though it remains legal throughout most of the EU and UK. The color is created by an azo chemical bond (-N=N-), which some people cannot properly metabolize, leading to allergic reactions. Those with aspirin (salicylate) sensitivity are particularly at risk of reacting to carmoisine and other azo dyes. Despite bans in multiple countries, some European manufacturers continue using it because it provides stable, vibrant pink-red colors that don't fade easily. Consumer pressure has led many brands to voluntarily reformulate, replacing carmoisine with alternatives like beetroot extract or anthocyanins from berries, though these natural colors are less stable and more expensive."
}

comprehensive_data["Ponceau 4R"] = {
    "whatItIs": "A synthetic strawberry-red azo dye created from petroleum derivatives, widely restricted due to health concerns.",
    "whereItComesFrom": "Manufactured through chemical synthesis from coal tar-based aromatic compounds in industrial facilities.",
    "whyItsUsed": "Creates bright red colors in desserts, candies, beverages, and processed meats like pepperoni and hot dogs.",
    "whatYouNeedToKnow": [
        "Linked to hyperactivity - EU warning label required",
        "Banned in USA, Canada, Norway, and Finland",
        "Part of the Southampton Six additives",
        "May trigger allergic reactions and asthma"
    ],
    "fullDescription": "Ponceau 4R (E124/Cochineal Red A) is banned in the United States, Canada, and several European countries due to safety concerns, yet remains legal in the UK and much of the EU. The Southampton study linked it to increased hyperactivity and attention problems in children, requiring products containing it in the EU to warn: 'may have an adverse effect on activity and attention in children.' It's an azo dye, carrying similar concerns as other synthetic reds - potential allergic reactions (particularly in aspirin-sensitive individuals), possible asthma exacerbation, and questions about long-term health effects. Despite bans elsewhere, it remains in use because it produces stable, vibrant red colors that survive heat processing and don't fade during storage. Many UK manufacturers voluntarily removed it following the Southampton study and subsequent consumer backlash, though it's still found in some imported products and budget brands. The discrepancy between US/Canadian bans and EU approval reflects different regulatory philosophies - the US tends toward precautionary bans while the EU uses warning labels, allowing consumer choice."
}

comprehensive_data["Brilliant Blue"] = {
    "whatItIs": "A synthetic bright blue dye derived from coal tar, one of only two blue colors approved for food use in the EU.",
    "whereItComesFrom": "Synthesized in laboratories from petroleum-based chemicals through complex organic chemistry reactions.",
    "whyItsUsed": "Provides vibrant blue coloring in ice cream, candy, beverages, and decorative frostings. Often mixed with yellows to create greens.",
    "whatYouNeedToKnow": [
        "Generally considered one of the safer synthetic colors",
        "Can cause allergic reactions in rare cases",
        "Large doses can temporarily turn skin and urine blue",
        "Combined with tartrazine (yellow 5) to make green colors"
    ],
    "fullDescription": "Brilliant Blue FCF (E133/Blue 1) is considered among the least problematic synthetic food dyes. It wasn't included in the Southampton Six additives linked to hyperactivity and shows minimal evidence of behavioral effects in research. However, very high doses (as used medically to detect intestinal leaks or assess lymphatic function) can turn skin blue-green, a condition called 'blue man syndrome' or acquired methemoglobinemia. This only occurs at doses thousands of times higher than food use levels. Allergic reactions are extremely rare but documented - typically manifest as hives or mild skin reactions. It's stable across wide temperature and pH ranges, making it popular for colorful sweets, sports drinks, and decorative icings. Often combined with Yellow 5 (tartrazine) to create bright green colors in products like lime-flavored beverages or green candies. Some animal studies in the 1980s suggested possible effects on nerve cells, but subsequent human research and regulatory reviews didn't support concerns at food-use concentrations. It's one of the few synthetic colors that hasn't faced major regulatory restrictions or widespread consumer rejection, likely because research hasn't identified significant risks comparable to azo dyes like tartrazine or sunset yellow."
}

comprehensive_data["Curcumin"] = {
    "whatItIs": "The vibrant yellow-orange pigment extracted from turmeric root, the same spice that gives curry its golden color and has been used in cooking for over 4,000 years.",
    "whereItComesFrom": "Extracted from the rhizomes (underground stems) of turmeric plants (Curcuma longa) grown primarily in India and Southeast Asia. The roots are boiled, dried, ground into powder, then curcumin is extracted using solvents like ethanol or hexane.",
    "whyItsUsed": "Provides natural yellow-orange coloring to mustard, cheese, butter, curry powders, and processed foods as a natural alternative to synthetic dyes.",
    "whatYouNeedToKnow": [
        "Generally considered safe with a long history of use in traditional cuisine",
        "Can permanently stain clothing, countertops, and skin bright yellow",
        "Poorly absorbed by the body unless combined with black pepper (piperine)",
        "The color fades when exposed to sunlight or alkaline conditions (above pH 7.4)"
    ],
    "fullDescription": "Curcumin (E100) is a polyphenol compound that makes up 2-5% of turmeric powder by weight. It's been used for thousands of years in Indian cooking and traditional Ayurvedic medicine as both a spice and a coloring agent. As a food coloring, it's prized for being 'natural' and vibrant, though it's less stable than synthetic alternatives - fading in sunlight and turning brownish-red in alkaline conditions. The molecule has a distinctive chemical structure with two aromatic rings connected by a chain, which gives it antioxidant properties that are heavily researched for potential anti-inflammatory and health benefits. However, curcumin breaks down quickly in the digestive system and has notoriously poor bioavailability - most of it passes through the body unabsorbed, with less than 1% entering blood circulation. Food scientists and supplement manufacturers have developed various methods to improve absorption, including nanoparticle formulations, liposomal delivery, and combination with piperine from black pepper, which can increase absorption by up to 2000% by inhibiting liver enzymes that break down curcumin. The bright yellow color is permanent on porous surfaces like clothing and wood, requiring immediate treatment to remove stains. In high doses (supplement levels, not food coloring amounts), curcumin may cause digestive upset, but at levels used in food coloring, it's generally well-tolerated. Major food applications include mustard (providing the bright yellow color), processed cheese, margarine, and curry powders."
}

comprehensive_data["Cochineal (Carmine)"] = {
    "whatItIs": "A deep crimson red dye made from the dried, crushed bodies of female cochineal insects - tiny scale insects that live on prickly pear cactus plants.",
    "whereItComesFrom": "Harvested from cochineal beetles (Dactylopius coccus) that feed on Opuntia cacti, primarily in Peru, the Canary Islands, and Mexico. Around 70,000 insects must be dried and crushed to produce just 500 grams of dye. The insects are collected by hand or mechanically scraped from cacti, killed by heat or immersion in hot water, dried in the sun, then crushed to extract the red pigment carminic acid.",
    "whyItsUsed": "Provides an intense, stable red color that doesn't fade easily with light or heat - used in yogurts, candies, beverages, ice cream, and cosmetics where a vibrant, long-lasting red is desired.",
    "whatYouNeedToKnow": [
        "NOT suitable for vegans or vegetarians (made from insects)",
        "Can cause severe allergic reactions including anaphylaxis in some people",
        "Often labeled as 'natural color' or 'carmine' without explicitly mentioning insects",
        "One of the most color-stable natural reds available - survives cooking and light exposure",
        "Used since Aztec and Maya civilizations, who valued it more highly than gold"
    ],
    "fullDescription": "Cochineal (E120), also called carmine, has been used as a precious red dye since pre-Columbian times. The Aztec and Maya civilizations cultivated the insects on nopal cacti and traded the dye across Mesoamerica for ceremonial garments and art. After Spanish conquest in the 1500s, cochineal became Europe's most valuable export from the New World, second only to silver, commanding prices higher than most other commodities. The insects produce carminic acid (up to 24% of their body weight) as a chemical defense mechanism against predators. Today, Peru produces about 85% of the world's supply, with indigenous farming families maintaining traditional cultivation methods. The dye is extracted by boiling the dried insects in water, then treating with alum (aluminum salt) to produce a stable lake pigment that varies from orange-red to bluish-red depending on pH. It's prized in modern food production because synthetic reds like Allura Red (Red 40) face increasing consumer resistance due to hyperactivity concerns, while cochineal can be marketed as 'natural color' despite its insect origin. The color remains remarkably stable across different pH ranges and doesn't fade with light or heat exposure like many plant-based reds such as betanin from beets or anthocyanins from berries. However, it can trigger allergic reactions in sensitive individuals, particularly those with shellfish or dust mite allergies, because of similar protein structures found in arthropods. The FDA requires it to be specifically labeled as 'cochineal extract' or 'carmine' since 2009, after reports of severe allergic reactions including anaphylaxis. Some manufacturers have switched away from it due to vegan concerns and allergy risks, but it remains widely used in products where color stability is critical, such as maraschino cherries, artificial crab (surimi), strawberry milk, and cosmetics."
}

comprehensive_data["Erythrosine"] = {
    "whatItIs": "A synthetic coal tar-derived dye that produces bright cherry-red colors, containing iodine atoms in its chemical structure.",
    "whereItComesFrom": "Manufactured from petroleum-based chemicals through iodination of fluorescein (another synthetic dye).",
    "whyItsUsed": "Creates bright pink-red colors in glacé cherries, candies, and decorative cake frosting.",
    "whatYouNeedToKnow": [
        "Banned in Norway and USA for cosmetics due to thyroid concerns",
        "Contains iodine - may affect people with thyroid conditions",
        "Some animal studies linked it to thyroid tumors",
        "Can cause photosensitivity (skin reactions to sunlight) in rare cases"
    ],
    "fullDescription": "Erythrosine (E127/Red 3) is a cherry-red dye containing four iodine atoms per molecule. Animal studies in the 1980s found that high doses caused thyroid tumors in rats, leading the FDA to ban it from cosmetics and externally-applied drugs in 1990. However, it remains approved for food use at low levels because follow-up research suggested the thyroid effects were specific to rats and not relevant to humans at food-use concentrations. Norway banned it entirely. The concern is that erythrosine may interfere with thyroid hormone production because of its iodine content and structural similarity to thyroid hormones. People with existing thyroid conditions are sometimes advised to avoid it. It's photoreactive - can cause photosensitivity reactions where skin exposed to it becomes sensitive to sunlight. Despite remaining legal in many countries, its use has declined dramatically as manufacturers shifted to alternatives due to consumer perception of risk. It's still used in some glacé cherries and decorative cake products because it provides a distinctive bright pink-red that's difficult to replicate with natural colors."
}


# Apply the updates
updated_count = 0
for ingredient in db['ingredients']:
    name = ingredient['name']
    if name in comprehensive_data:
        data = comprehensive_data[name]
        ingredient['whatItIs'] = data['whatItIs']
        ingredient['whereItComesFrom'] = data['whereItComesFrom']
        ingredient['whyItsUsed'] = data['whyItsUsed']
        ingredient['whatYouNeedToKnow'] = data['whatYouNeedToKnow']
        ingredient['fullDescription'] = data['fullDescription']
        updated_count += 1
        print(f"  ✓ {name}")

# Save the updated database
with open('NutraSafe Beta/ingredients_comprehensive.json', 'w', encoding='utf-8') as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

print(f"\n✅ Updated {updated_count} additives with comprehensive descriptions")
print(f"📊 Remaining to update: {414 - updated_count}")
print("\nDatabase saved to: NutraSafe Beta/ingredients_comprehensive.json")

# ============================================================================
