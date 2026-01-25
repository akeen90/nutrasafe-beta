#!/usr/bin/env python3
"""
Generate comprehensive, consumer-focused descriptions for all 414 food additives.
Based on the reference style from E100 (Curcumin) and E120 (Cochineal).
"""

import json
import sys

# Comprehensive additive database with researched consumer-focused content
ADDITIVE_CONTENT = {
    # Colors (E100-E199)
    "E100 - Curcumin": {
        "whatItIs": "The vibrant yellow-orange pigment extracted from turmeric root, the same spice that gives curry its golden color and has been used in cooking for over 4,000 years.",
        "whereItComesFrom": "Extracted from the rhizomes (underground stems) of turmeric plants (Curcuma longa) grown primarily in India and Southeast Asia. The roots are boiled, dried, ground into powder, then curcumin is extracted using solvents like ethanol or hexane.",
        "whyItsUsed": "Provides natural yellow-orange coloring to mustard, cheese, butter, curry powders, and processed foods without synthetic dyes.",
        "whatYouNeedToKnow": [
            "Generally considered safe with a long history of use in traditional cuisine",
            "Can permanently stain clothing, countertops, and skin bright yellow",
            "Poorly absorbed by the body unless combined with black pepper (piperine)",
            "The color fades when exposed to sunlight or alkaline conditions"
        ],
        "fullDescription": "Curcumin (E100) is a polyphenol compound that makes up 2-5% of turmeric powder by weight. It's been used for thousands of years in Indian cooking and traditional Ayurvedic medicine. As a food coloring, it's prized for being 'natural' and vibrant, though it's less stable than synthetic alternatives. The molecule has a distinctive chemical structure with two aromatic rings connected by a chain, which gives it antioxidant properties that are heavily researched for potential health benefits. However, curcumin breaks down quickly in the digestive system and has notoriously poor bioavailability - most of it passes through unabsorbed. Food scientists have developed various methods to improve absorption, including nanoparticle formulations and combination with piperine from black pepper, which can increase absorption by up to 2000%. The bright yellow color fades in sunlight and turns brownish-red in alkaline conditions (above pH 7.4), which is why turmeric-colored foods should be stored away from light. In high doses, curcumin may cause digestive upset, but at levels used in food coloring, it's generally well-tolerated."
    },

    "E101 - Riboflavin": {
        "whatItIs": "Vitamin B2, an essential nutrient that gives energy drinks their distinctive yellow-green color and makes your urine bright yellow after taking supplements.",
        "whereItComesFrom": "Produced commercially through bacterial fermentation using Bacillus subtilis or Ashbya gossypii fungi, though it naturally occurs in milk, eggs, green vegetables, and enriched cereals.",
        "whyItsUsed": "Used as both a vitamin supplement and yellow-orange food coloring in cereals, energy drinks, vitamin-enriched milk, baby foods, and processed cheese.",
        "whatYouNeedToKnow": [
            "An essential vitamin your body needs for energy production and cell growth",
            "Completely safe - it's the same B2 vitamin naturally found in foods",
            "Breaks down quickly when exposed to light, which is why milk comes in opaque containers",
            "Excess riboflavin is harmlessly excreted, turning urine bright yellow"
        ],
        "fullDescription": "Riboflavin (E101) is vitamin B2, a water-soluble vitamin essential for human health. Unlike synthetic food dyes, this is a nutrient your body actually needs. It was discovered in 1920 by being isolated from egg whites and milk, and its name comes from its yellow color (flavus is Latin for yellow) and the sugar molecule ribose in its structure. Your body uses riboflavin to convert food into energy, maintain healthy skin and eyes, and support nervous system function. The recommended daily intake is about 1.3mg for adults. When used as a food coloring, manufacturers typically use concentrations far below nutritional levels. Riboflavin is sensitive to ultraviolet light and alkaline conditions but stable to heat and acids. This light sensitivity is why milk is sold in opaque containers - exposure to fluorescent light can destroy 50% of riboflavin content in just two hours. In the body, excess riboflavin is rapidly excreted in urine, producing the characteristic bright yellow color often seen after taking B-complex vitamins or energy drinks. There are no known toxic effects from high doses, making it one of the safest food additives in existence."
    },

    "E102 - Tartrazine": {
        "whatItIs": "A synthetic lemon-yellow dye created from coal tar derivatives, and one of the most controversial food colorings due to links with hyperactivity in children.",
        "whereItComesFrom": "Synthesized in laboratories from petroleum-derived compounds through a complex chemical process involving diazotization and coupling reactions. It's never found in nature.",
        "whyItsUsed": "Provides bright yellow color in soft drinks, candy, desserts, cereals, snack foods, and medications where a vivid yellow is needed.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' additives linked to increased hyperactivity and decreased attention in children",
            "Must carry a warning label in the EU: 'May have an adverse effect on activity and attention in children'",
            "Can trigger allergic reactions in people sensitive to aspirin or those with asthma",
            "Banned in Norway, Austria, and several other countries due to health concerns",
            "Avoidable - many companies now use natural alternatives like turmeric or annatto"
        ],
        "fullDescription": "Tartrazine (E102) is a synthetic azo dye first synthesized in 1884, making it one of the oldest artificial food colorings still in use. The name comes from tartaric acid, though the modern industrial process doesn't actually use tartaric acid. It became widely adopted because it's cheap to produce, extremely stable (doesn't fade with heat, light, or pH changes), and produces a vibrant lemon-yellow color that's difficult to replicate with natural ingredients. However, tartrazine has become increasingly controversial since the 2007 Southampton University study, commissioned by the UK Food Standards Agency, found that combinations of artificial colors including tartrazine increased hyperactive behavior in children. This research led the EU to mandate warning labels on products containing tartrazine. The mechanism isn't fully understood, but appears to involve histamine release and possible effects on neurotransmitters. Between 0.01% and 0.1% of the general population shows allergic-type reactions to tartrazine, with higher rates among people who have aspirin sensitivity or asthma. Symptoms can include hives, itching, migraines, and in rare cases, anaphylaxis. Despite these concerns, tartrazine remains approved in most countries at levels up to 7.5mg/kg body weight per day (the ADI set by JECFA). Many food manufacturers have voluntarily removed it from products, replacing it with natural alternatives like curcumin or annatto, particularly in products marketed to children."
    },

    "E104 - Quinoline Yellow": {
        "whatItIs": "A synthetic greenish-yellow dye made from coal tar, similar to the dyes used in highlighter pens and industrial applications.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds in industrial laboratories. The production involves sulfonation of quinoline derivatives.",
        "whyItsUsed": "Creates greenish-yellow colors in smoked fish, scotch eggs, some medications, and beverages where a distinctive yellow-green hue is desired.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' group linked to hyperactivity in children",
            "Requires EU warning label: 'May have an adverse effect on activity and attention in children'",
            "Banned in several countries including the United States, Australia, Norway, and Japan",
            "Can cause allergic reactions including skin sensitivity and asthma symptoms",
            "Rarely seen in modern UK foods due to voluntary removal by manufacturers"
        ],
        "fullDescription": "Quinoline Yellow (E104) is one of the more restricted synthetic food colorings, banned in several major markets and increasingly avoided by manufacturers. It belongs to the quinoline family of compounds, which are also used to make antimalarial drugs and industrial dyes. The food-grade version is a mixture of disulfonates that produce a greenish-yellow color, particularly useful for products like smoked fish where manufacturers want a traditional 'smoked' yellow-brown appearance. Despite being approved in the EU, quinoline yellow was included in the 2007 Southampton study that found combinations of artificial colors increased hyperactivity in children, leading to mandatory warning labels. The UK Food Standards Agency recommended that manufacturers voluntarily remove it from products, and most major brands complied. It was never approved in the US due to inadequate safety data, and Australia, Norway, and Japan have also banned it. Some studies suggest it may cause chromosomal damage in cell cultures, though the relevance to human consumption at permitted levels is debated. The acceptable daily intake (ADI) in the EU is 10mg/kg body weight, but given its limited use and availability of alternatives, exposure is generally low. If you see E104 on a label, it's typically in imported products or niche items like certain fish products. The decline in quinoline yellow use reflects broader consumer pressure for 'clean label' products without synthetic additives."
    },

    "E110 - Sunset Yellow FCF": {
        "whatItIs": "A synthetic orange-yellow dye derived from petroleum, named for its resemblance to the color of a sunset, commonly used in orange-flavored products.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based aromatic compounds. The 'FCF' stands for 'For Coloring Food', distinguishing it from industrial yellow dyes.",
        "whyItsUsed": "Provides bright orange color to orange sodas, cereals, candy, desserts, and processed foods where an intense orange is needed.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' additives linked to increased hyperactivity in children",
            "Must carry EU warning: 'May have an adverse effect on activity and attention in children'",
            "Can trigger allergic reactions, particularly in people with aspirin sensitivity",
            "Banned in Norway and Finland, restricted use in other countries",
            "Many brands now use natural alternatives like annatto or paprika extract"
        ],
        "fullDescription": "Sunset Yellow FCF (E110), also known as Orange Yellow S or FD&C Yellow 6 in the US, is a synthetic azo dye introduced in 1929 to replace the toxic dye Orange I. It's one of the most widely used artificial colors in the food industry because it's cheap, stable, and produces a vibrant orange that's difficult to achieve with natural ingredients. However, like other synthetic azo dyes, sunset yellow has become increasingly controversial. The 2007 Southampton University study found that mixtures containing sunset yellow increased hyperactive behavior in children, prompting the EU to require warning labels on products containing it. The mechanism is thought to involve histamine release and possible effects on neurotransmitter systems, though the exact pathway remains unclear. Between 0.01-0.1% of the population shows sensitivity to sunset yellow, with higher rates in people who have aspirin allergy or asthma. Reactions can include hives, swelling, stomach upset, and in rare cases, anaphylaxis. Some animal studies have suggested potential links to tumors, but these used doses far exceeding human exposure levels. The JECFA set an ADI of 4mg/kg body weight per day. In response to consumer concerns, many major food brands have reformulated products to use natural alternatives like annatto extract, beta-carotene, or paprika extract. If you're avoiding synthetic dyes, check labels carefully - sunset yellow is still common in budget brands and imported products."
    },

    "E120 - Cochineal (Carmine)": {
        "whatItIs": "A deep crimson red dye made from the dried, crushed bodies of female cochineal insects - tiny scale insects that live on prickly pear cactus plants.",
        "whereItComesFrom": "Harvested from cochineal beetles (Dactylopius coccus) that feed on Opuntia cacti, primarily in Peru, the Canary Islands, and Mexico. Around 70,000 insects must be dried and crushed to produce just 500 grams of dye. The insects are collected, killed by heat or immersion in hot water, dried, then crushed to extract the red pigment.",
        "whyItsUsed": "Provides an intense, stable red color that doesn't fade easily with light or heat - used in yogurts, candies, beverages, ice cream, and cosmetics where a vibrant red is desired.",
        "whatYouNeedToKnow": [
            "NOT suitable for vegans or vegetarians (made from insects)",
            "Can cause severe allergic reactions including anaphylaxis in some people",
            "Often labeled as 'natural color' or 'carmine' without mentioning insects",
            "One of the most color-stable natural reds available - survives cooking and light exposure",
            "Used since Aztec and Maya civilizations, who valued it more highly than gold"
        ],
        "fullDescription": "Cochineal (E120), also called carmine, has been used as a precious red dye since pre-Columbian times. The Aztec and Maya civilizations cultivated the insects and traded the dye across Mesoamerica. After Spanish conquest in the 1500s, cochineal became Europe's most valuable export from the New World, second only to silver. The insects produce carminic acid (up to 24% of their body weight) as a defense mechanism against predators. Today, Peru produces about 85% of the world's supply. The dye is extracted by boiling the dried insects in water, then treating with alum (aluminum salt) to produce a stable lake pigment. It's prized in modern food production because synthetic reds like Allura Red (Red 40) face increasing consumer resistance, while cochineal can be marketed as 'natural color.' The color remains remarkably stable across different pH ranges (though it shifts from orange-red in acids to bluish-red in alkaline conditions) and doesn't fade with light or heat like many plant-based reds such as betanin from beets. However, it can trigger allergic reactions in sensitive individuals, particularly those with shellfish allergies, because of similar protein structures. The FDA requires it to be specifically labeled as 'cochineal extract' or 'carmine' since 2009, after reports of severe reactions. Some manufacturers have switched away from it due to vegan concerns and allergy risks, but it remains widely used where color stability is critical."
    },

    "E122 - Azorubine": {
        "whatItIs": "A synthetic red dye created from coal tar derivatives, also known as Carmoisine, used to create burgundy and reddish-brown colors in foods.",
        "whereItComesFrom": "Manufactured through chemical synthesis in laboratories from petroleum-based compounds. It's an azo dye, a class of compounds never found naturally.",
        "whyItsUsed": "Provides red-brown colors in jams, jellies, desserts, processed meats, and sweets where a deep red shade is needed.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' group linked to hyperactivity in children",
            "Must carry EU warning: 'May have an adverse effect on activity and attention in children'",
            "Banned in the United States, Canada, Sweden, Norway, and several other countries",
            "Can trigger allergic reactions in people sensitive to aspirin or with asthma",
            "Less commonly used now as manufacturers shift to natural alternatives"
        ],
        "fullDescription": "Azorubine (E122), also called Carmoisine, is a synthetic azo dye that produces a burgundy or brownish-red color. It was developed as an alternative to the natural but unstable dye from cochineal insects and the toxic synthetic dye Amaranth (which was banned in the US in 1976). Despite being approved in the EU, azorubine has a controversial safety profile and is banned in several countries including the US, Canada, and Sweden. The 2007 Southampton study identified it as one of six artificial colors associated with increased hyperactivity in children, leading to mandatory warning labels in the EU. Some studies have suggested azorubine may cause chromosomal damage and tumors in laboratory animals at high doses, though regulatory bodies maintain it's safe at permitted levels. The JECFA set an ADI of 4mg/kg body weight per day. Allergic reactions to azorubine are reported in about 0.01-0.1% of the population, with higher rates in people who have aspirin sensitivity. Symptoms can include skin rashes, swelling, asthma attacks, and gastrointestinal upset. The UK Food Standards Agency recommended voluntary removal after the Southampton study, and many manufacturers complied, switching to alternatives like beetroot extract or anthocyanins from fruits. If you see azorubine on a label, it's typically in budget products or imports from countries with less stringent regulations."
    },

    "E123 - Amaranth": {
        "whatItIs": "A synthetic dark red-purple dye derived from coal tar, once widely used but now banned in the United States since 1976 due to cancer concerns.",
        "whereItComesFrom": "Produced through chemical synthesis from petroleum-based compounds in industrial laboratories. It's an azo dye created through chemical reactions never occurring in nature.",
        "whyItsUsed": "Provides deep red-purple coloring in some beverages, confectionery, and alcoholic drinks in countries where it remains legal.",
        "whatYouNeedToKnow": [
            "Banned in the United States since 1976 after studies suggested possible carcinogenic effects",
            "Also banned in Russia, Norway, and Austria",
            "Can cause allergic reactions including asthma attacks in sensitive individuals",
            "Still approved in the EU but with restricted use levels",
            "Increasingly avoided by manufacturers due to safety concerns and consumer perception"
        ],
        "fullDescription": "Amaranth (E123) has one of the most controversial histories of any food additive. Widely used throughout the 20th century as a cheap, stable red dye, it came under intense scrutiny in the 1970s when Soviet and US studies suggested it might cause cancer and birth defects in laboratory animals. In 1976, the FDA banned amaranth from food use in the United States, citing these safety concerns. Russia followed suit with its own ban. The dye's name comes from the amaranth plant, though it has no connection to the actual plant - it's purely synthetic. The cancer concerns centered on studies showing increased tumor rates in female rats fed high doses of amaranth, though some scientists argued the doses were unrealistically high and not relevant to human consumption. The JECFA and European authorities reviewed the same data and concluded amaranth was safe at low levels, setting an ADI of 0.5mg/kg body weight per day - notably lower than most other food dyes. Still permitted in the EU, UK, and many other countries, amaranth's use has declined dramatically as manufacturers avoid additives with negative publicity. It's primarily found now in certain liqueurs, caviar, and specialty products. People with aspirin sensitivity may experience allergic reactions to amaranth, including skin rashes and breathing difficulties. The ongoing controversy reflects broader debates about how to interpret animal studies and set acceptable risk levels for food additives."
    },

    "E124 - Ponceau 4R": {
        "whatItIs": "A synthetic strawberry-red dye derived from petroleum, also known as Cochineal Red A (despite containing no actual cochineal insects).",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds in industrial facilities. It's an azo dye created through diazotization reactions.",
        "whyItsUsed": "Produces bright red color in desserts, cherries, sweets, soft drinks, and processed foods marketed as having a 'strawberry' or 'cherry' flavor.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' additives linked to hyperactivity in children",
            "Must carry EU warning: 'May have an adverse effect on activity and attention in children'",
            "Banned in the United States, Norway, and Finland",
            "Can trigger allergic reactions especially in people with aspirin sensitivity",
            "Many UK manufacturers have voluntarily removed it from products"
        ],
        "fullDescription": "Ponceau 4R (E124), also misleadingly called 'Cochineal Red A' or 'New Coccine', is a synthetic azo dye with no connection to actual cochineal insects. The confusing name was a marketing strategy to make it sound more natural. Introduced in the early 1900s, it became popular for creating the bright red color associated with strawberry and cherry flavored products. However, like other synthetic azo dyes, Ponceau 4R has faced increasing scrutiny. The 2007 Southampton University study identified it as one of six artificial colors associated with increased hyperactivity and decreased attention span in children, leading to mandatory warning labels in the EU. The UK Food Standards Agency recommended that manufacturers voluntarily remove it from products aimed at children, and most major brands complied. The United States never approved Ponceau 4R for food use, citing inadequate safety data. Some studies have suggested it may cause tumors in laboratory animals at high doses, though regulatory bodies in countries where it's permitted maintain it's safe at current use levels. The JECFA set an ADI of 4mg/kg body weight per day. Allergic reactions are reported in about 0.01-0.1% of people, particularly those with aspirin sensitivity or asthma. Symptoms can include hives, swelling, breathing difficulties, and stomach upset. The decline in Ponceau 4R use reflects broader consumer demand for 'clean labels' without synthetic additives, with many companies now using alternatives like beetroot extract or anthocyanins from berries."
    },

    "E127 - Erythrosine": {
        "whatItIs": "A synthetic pink-red dye made from petroleum and iodine, creating the distinctive bright pink color of glacé cherries and some medications.",
        "whereItComesFrom": "Synthesized in laboratories by iodinating fluorescein, a compound derived from petroleum. Each molecule contains four iodine atoms, making it quite different from other food dyes.",
        "whyItsUsed": "Provides bright pink-red color in glacé cherries, maraschino cherries, some baked goods, and pharmaceutical products where a vivid pink is desired.",
        "whatYouNeedToKnow": [
            "Contains high levels of iodine - may affect thyroid function in sensitive individuals",
            "Banned in Norway and the United States for use in cosmetics and external drugs",
            "Can cause allergic reactions including skin sensitivity and thyroid problems",
            "Has been linked to thyroid tumors in laboratory rats at high doses",
            "Use has significantly declined due to health concerns and availability of alternatives"
        ],
        "fullDescription": "Erythrosine (E127) is unique among food dyes because it's a xanthene dye containing iodine rather than an azo dye. The name comes from the Greek 'erythros' meaning red. It produces a distinctive bright pink color that's difficult to replicate with other additives, which is why glacé cherries traditionally use it. However, erythrosine's iodine content has raised concerns. Each erythrosine molecule contains four iodine atoms, and in theory, high consumption could interfere with thyroid function by flooding the body with iodine. Studies in rats found that high doses of erythrosine caused thyroid tumors, likely related to the iodine disrupting thyroid hormone regulation. While the relevance to human consumption at typical levels is debated, these findings led Norway to ban erythrosine from food. The US FDA restricted its use in cosmetics and external drugs in 1990 but still permits it in food and ingested medications, with an ADI of 0.1mg/kg body weight per day. The EU permits erythrosine but with low maximum use levels (50-200mg/kg in most products). Allergic reactions can include photosensitivity (increased skin sensitivity to sunlight), thyroid function changes, and in rare cases, hives or breathing difficulties. People with existing thyroid conditions or iodine sensitivity should be particularly cautious. The use of erythrosine has declined significantly as manufacturers switch to alternatives like beetroot extract or synthetic dyes without iodine. If you see E127 on a label, it's most commonly in traditional glacé cherries or imported sweets."
    },

    "E129 - Allura Red AC": {
        "whatItIs": "A synthetic dark red dye derived from petroleum, developed to replace the banned dye Amaranth and now one of the most commonly used red food colorings worldwide.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds in industrial facilities. It's an azo dye created through complex chemical reactions.",
        "whyItsUsed": "Provides vibrant red color in soft drinks, candy, baked goods, cereals, snacks, and sauces where an intense red is needed.",
        "whatYouNeedToKnow": [
            "Part of the 'Southampton Six' additives linked to increased hyperactivity in children",
            "Must carry EU warning: 'May have an adverse effect on activity and attention in children'",
            "Can trigger allergic reactions, especially in people with aspirin sensitivity",
            "Banned in several European countries including Denmark, Belgium, France and Switzerland",
            "The most widely used red synthetic dye in the US (known as Red 40)"
        ],
        "fullDescription": "Allura Red AC (E129), known as FD&C Red 40 in the United States, was developed by the Allura chemical company in the 1950s specifically to replace Amaranth (E123) after safety concerns emerged about that dye. It quickly became the most widely used red food coloring globally because it's cheap, extremely stable, and produces a vibrant red that doesn't fade with heat, light, or pH changes. In the US alone, manufacturers use about 2.3 million kilograms of Red 40 annually. However, like other synthetic azo dyes, Allura Red has become controversial. The 2007 Southampton study found that mixtures containing Allura Red increased hyperactive behavior in children, leading to mandatory warning labels in the EU and voluntary removal by many manufacturers. The mechanism isn't fully understood but may involve histamine release and effects on neurotransmitter systems. Some studies in laboratory animals have suggested possible links to tumors and DNA damage at high doses, though regulatory bodies maintain these findings aren't relevant to human consumption at permitted levels. The JECFA set an ADI of 7mg/kg body weight per day. Allergic reactions occur in about 0.01-0.1% of people, with higher rates in those with aspirin sensitivity. Symptoms can include hives, swelling, asthma-like reactions, and migraines. Denmark, Belgium, France, Switzerland, and Sweden have banned or severely restricted Allura Red despite its EU approval. Consumer pressure has led many brands to reformulate using natural alternatives like beetroot extract or anthocyanins, though Allura Red remains extremely common in budget products and the US market."
    },

    "E131 - Patent Blue V": {
        "whatItIs": "A synthetic dark blue dye derived from coal tar, used to create blue and green colors in foods and medications.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based aromatic compounds in industrial laboratories.",
        "whyItsUsed": "Provides blue coloring in beverages, candies, ice cream, and diagnostic medical procedures where a distinctive blue is needed.",
        "whatYouNeedToKnow": [
            "Banned in the United States, Australia, and Norway due to safety concerns",
            "Can cause serious allergic reactions including anaphylaxis in rare cases",
            "Has been linked to severe hypersensitivity reactions during medical procedures",
            "Still approved in the EU but with increasingly limited use",
            "Rarely seen in modern foods as manufacturers switch to alternatives"
        ],
        "fullDescription": "Patent Blue V (E131) is a triphenylmethane dye with a controversial safety profile. The 'patent' in its name doesn't refer to intellectual property but rather to the historical use of such dyes in tanning patent leather. It produces a dark greenish-blue color and was once commonly used in foods and cosmetics. However, Patent Blue V has never been approved in the United States, Australia, or several other countries due to safety concerns. The most serious issue is its potential to cause severe allergic reactions, including anaphylactic shock. These reactions are rare but can be life-threatening. The problem became particularly apparent when Patent Blue V was used in medical diagnostic procedures (like sentinel lymph node mapping during surgery) where several cases of severe anaphylaxis were reported, leading many hospitals to discontinue its use. In foods, the risk is lower due to smaller doses, but allergic reactions including hives, breathing difficulties, and low blood pressure have been documented. Some animal studies suggested Patent Blue V might affect reproduction and cause chromosomal damage at high doses. The JECFA set an ADI of 5mg/kg body weight per day, but use in foods has declined significantly in the EU and UK. Most manufacturers have switched to alternatives like Brilliant Blue FCF (E133) or natural blue from spirulina. If you see E131 on a label, it's typically in imported products or specialized applications where the specific shade is important."
    },

    "E132 - Indigotine": {
        "whatItIs": "A synthetic dark blue dye derived from petroleum, designed to mimic the natural indigo dye historically extracted from plants.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds, despite its name suggesting a natural indigo plant origin. The food-grade version is created in industrial laboratories.",
        "whyItsUsed": "Provides blue and green colors in ice cream, sweets, baked goods, and beverages where blue shading is desired.",
        "whatYouNeedToKnow": [
            "Synthetic version of natural indigo dye, but with completely different chemical structure",
            "Banned in Norway but approved in most other countries including the US and EU",
            "Can cause allergic reactions and nausea in sensitive individuals",
            "Some studies suggest possible effects on blood pressure and breathing",
            "Less commonly used than Brilliant Blue (E133) in modern products"
        ],
        "fullDescription": "Indigotine (E132), also called Indigo Carmine or FD&C Blue 2, is somewhat confusingly named because while it resembles the color of natural indigo, it's structurally completely different and entirely synthetic. Natural indigo has been extracted from Indigofera plants for thousands of years to dye textiles, but synthesizing it for food use required developing an entirely different molecule that happens to produce a similar color. Indigotine was approved for food use in the early 1900s and produces a bright royal blue. It's more stable than some natural blues but less stable than the competing synthetic Brilliant Blue (E133), which is why it's less commonly used today. Norway banned indigotine from food in 1978, citing concerns about safety data, but most other countries still permit it. Some animal studies have suggested that high doses might cause tumors, affect blood pressure, and impair breathing, though regulatory authorities in countries where it's approved maintain these effects aren't relevant to human consumption at permitted levels. The JECFA set an ADI of 5mg/kg body weight per day. Allergic reactions are uncommon but can include nausea, vomiting, high blood pressure, and skin reactions. Indigotine has the unusual property of being excreted in urine, temporarily turning it blue-green, which can alarm people taking medications containing the dye. In foods, it's sometimes combined with yellow dyes to create green colors. Modern use is declining as manufacturers shift toward natural blue alternatives from spirulina."
    },

    "E133 - Brilliant Blue FCF": {
        "whatItIs": "A synthetic bright blue dye derived from petroleum, currently the most widely used blue food coloring in the world.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based aromatic compounds in industrial facilities. The 'FCF' stands for 'For Coloring Food'.",
        "whyItsUsed": "Provides brilliant blue color in ice cream, candy, beverages, baked goods, and cereals, often combined with yellow dyes to create green.",
        "whatYouNeedToKnow": [
            "One of the most widely used and studied synthetic food colorings",
            "Generally considered one of the safer synthetic dyes with no child hyperactivity warnings",
            "Banned in several European countries including Austria, Belgium, France, Germany and Switzerland",
            "Can cause allergic reactions in people sensitive to aspirin or with asthma",
            "Has sparked controversy when used to make viral 'blue' foods on social media"
        ],
        "fullDescription": "Brilliant Blue FCF (E133), known as FD&C Blue 1 in the US, is currently the most popular synthetic blue food coloring globally. It was developed in the 1930s and produces a vivid cyan-blue that's extremely stable to light, heat, and pH changes. Unlike many other synthetic dyes, Brilliant Blue wasn't included in the 'Southampton Six' hyperactivity study and doesn't require warning labels in the EU for effects on children's behavior. This, combined with its stability and intensity, has made it the go-to choice for blue coloring. However, it's not without controversy. Several European countries including Austria, Belgium, France, Germany, Norway, Sweden, and Switzerland have banned it despite its EU approval, citing the precautionary principle. Some animal studies have suggested very high doses might affect reproduction and cause tumors, though regulatory bodies maintain it's safe at permitted levels. The JECFA set an ADI of 10mg/kg body weight per day - relatively high compared to other dyes. Allergic reactions are rare but can occur, particularly in people with aspirin sensitivity, asthma, or those allergic to the similar dye Patent Blue V. Symptoms can include hives, breathing difficulties, and anaphylaxis in extremely rare cases. Brilliant Blue became internet-famous in the 2010s when food bloggers created unnaturally blue foods like 'galaxy' bagels and 'mermaid' lattes, sparking debates about excessive artificial coloring. In combination with tartrazine (E102), it creates the electric green colors seen in some candies and beverages."
    },

    "E140 - Chlorophylls": {
        "whatItIs": "The natural green pigment that makes plants green, extracted from grass, nettles, alfalfa, and other leafy plants - the same compound that captures sunlight during photosynthesis.",
        "whereItComesFrom": "Extracted from green plants through solvent extraction, typically from alfalfa, grass, or nettle leaves. The extracted chlorophyll is the exact same molecule plants use to convert sunlight into energy.",
        "whyItsUsed": "Provides natural green coloring to sweets, ice cream, sauces, and processed foods where a green color is desired without synthetic dyes.",
        "whatYouNeedToKnow": [
            "Completely natural - it's the molecule that makes all plants green",
            "Generally considered very safe with no known adverse effects",
            "The color fades quickly when exposed to acids, heat, or light",
            "Can temporarily turn your feces green if you consume large amounts",
            "Often replaced by the more stable copper-containing version (E141)"
        ],
        "fullDescription": "Chlorophylls (E140) are among the most abundant natural pigments on Earth and the fundamental basis for photosynthesis in plants. The name comes from Greek 'chloros' (green) and 'phyllon' (leaf). There are several types of chlorophyll - chlorophyll a and b are the main forms used in food coloring, extracted commercially from dried grass, alfalfa, nettle, or other leafy plants. The extraction process typically uses solvents like acetone or ethanol to pull the chlorophyll from dried plant material, then the solvent is removed, leaving behind concentrated chlorophyll. As a food additive, chlorophyll has an excellent safety profile because humans have been consuming it in vegetables since the dawn of our species. There are no known toxic effects or allergies associated with natural chlorophyll. However, it has significant drawbacks as a food coloring: it's very unstable. Chlorophyll breaks down when exposed to acids (turning brownish), heat (turning olive-green), or light (fading to yellow). This is why cooked green vegetables lose their bright color. The central magnesium atom in the chlorophyll molecule is easily displaced by hydrogen ions in acidic conditions, forming pheophytin which is brown. For this reason, food manufacturers often prefer E141 (copper complexes of chlorophylls) which replaces the magnesium with copper for much better stability. In high doses, chlorophyll can temporarily color feces green, which is harmless. Some studies suggest chlorophyll may have health benefits including antioxidant effects and helping to eliminate toxins, though evidence is limited."
    },

    "E141 - Chlorophyll Copper Complex": {
        "whatItIs": "Chlorophyll from plants that's been chemically modified by replacing the natural magnesium atom with copper, creating a more stable green color.",
        "whereItComesFrom": "Made by extracting natural chlorophyll from plants (grass, alfalfa, nettles), then chemically replacing the central magnesium atom with copper through a process called copperization.",
        "whyItsUsed": "Provides stable green coloring in sweets, ice cream, sauces, and processed foods - much more stable than natural chlorophyll and doesn't fade with heat or acid.",
        "whatYouNeedToKnow": [
            "More stable than natural chlorophyll but contains added copper metal",
            "Generally considered safe but some concerns exist about copper accumulation",
            "People with Wilson's disease (copper metabolism disorder) should avoid it",
            "Banned in several countries including Australia until recently",
            "Produces a more bluish-green than natural chlorophyll's yellowish-green"
        ],
        "fullDescription": "Chlorophyll Copper Complex (E141) is natural chlorophyll that's been chemically modified to solve stability problems. Natural chlorophyll (E140) breaks down easily with heat, acid, and light because the central magnesium atom is easily displaced. Food scientists discovered that replacing magnesium with copper creates a molecule that's far more stable - it survives cooking, acidic conditions, and light exposure without fading. The copper-chlorophyll complex also produces a slightly different color: more bluish-green compared to natural chlorophyll's yellowish-green. There are two types: E141(i) uses copper alone, while E141(ii) uses sodium and potassium salts of copper chlorophyllin. The modification process involves treating extracted chlorophyll with copper salts under controlled conditions. While this improves stability dramatically, it raises a question: is it still 'natural'? The EU classifies it as nature-identical rather than truly natural. Some countries, including Australia, initially banned it citing concerns about copper intake contributing to copper accumulation in the liver, particularly in people with Wilson's disease (a genetic disorder causing dangerous copper buildup). However, most countries now permit it, arguing that copper levels from E141 are minimal compared to copper naturally present in foods. The JECFA set an ADI of 15mg/kg body weight per day. For most people, E141 is safe, but individuals with Wilson's disease or other copper metabolism disorders should avoid it. The stability advantage means E141 is far more common in processed foods than natural E140 chlorophyll."
    },

    "E142 - Green S": {
        "whatItIs": "A synthetic dark green dye made from coal tar derivatives, also called Acid Brilliant Green or Lissamine Green.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds in industrial laboratories. It's a triphenylmethane dye never found in nature.",
        "whyItsUsed": "Provides dark green coloring in mint-flavored products, canned peas, gravy, and some processed foods where a distinctive green is needed.",
        "whatYouNeedToKnow": [
            "Banned in the United States, Canada, Finland, Norway, Sweden, and several other countries",
            "Can cause allergic reactions including hives and breathing difficulties",
            "Some studies suggest possible links to cancer and chromosomal damage",
            "Still approved in the EU but increasingly rare due to voluntary removal",
            "Most manufacturers now use natural alternatives or copper chlorophyll (E141)"
        ],
        "fullDescription": "Green S (E142) is one of the more restricted synthetic food colorings, banned in numerous countries including the US, Canada, and several Nordic nations. It's a triphenylmethane dye that produces a dark, somewhat bluish-green color, historically popular for mint candies, canned peas, and processed foods where manufacturers wanted to enhance green color. The dye was never approved in the United States due to inadequate safety data and concerns about potential carcinogenicity. Finland, Norway, and Sweden banned it outright, while Canada removed approval in the 1970s. Some animal studies suggested that high doses of Green S might cause tumors and chromosomal damage, though the studies used doses far exceeding typical human exposure. The JECFA reviewed the evidence and set an ADI of 5mg/kg body weight per day, maintaining it's safe at permitted levels, which is why it remains approved in the EU and UK. However, allergic reactions are a concern. People with aspirin sensitivity or asthma may experience hives, swelling, breathing difficulties, or anaphylaxis in rare cases. Following the general trend away from synthetic colors, particularly those with controversial safety profiles, most UK manufacturers voluntarily removed Green S from products. It's now quite rare to see E142 on labels - when green coloring is needed, companies typically use copper chlorophyll (E141) or spirulina extract instead. If you do encounter Green S, it's usually in imported products or budget items where cost considerations outweigh consumer concerns about 'clean label' ingredients."
    },

    "E150a - Plain Caramel": {
        "whatItIs": "The brown color created by carefully heating sugar until it caramelizes - the same process that makes caramel sauce, crème brûlée, and gives cola drinks their brown color.",
        "whereItComesFrom": "Made by heating sugar (sucrose, glucose, or fructose) to high temperatures (120-180°C) until it melts, browns, and develops the characteristic caramel color and flavor.",
        "whyItsUsed": "Provides brown coloring and subtle caramel flavor to cola drinks, beer, bread, sauces, sweets, and countless foods where brown color is desired.",
        "whatYouNeedToKnow": [
            "One of the most widely used food colorings in the world (in cola drinks alone)",
            "Generally considered very safe - it's just heated sugar",
            "Has been used for centuries in cooking and confectionery",
            "Different types of caramel color (E150a-d) use different production methods",
            "The simplest and most 'natural' of all the caramel colors"
        ],
        "fullDescription": "Plain caramel (E150a) is the simplest form of caramel color, made using only heat and sugar - no other chemicals. It's the same process home cooks use to make caramel sauce, just taken further to produce a concentrated coloring rather than a syrup. When sugar is heated above its melting point, complex chemical reactions occur (caramelization) that break down sucrose molecules and create hundreds of new compounds. These compounds provide brown color and the characteristic caramel flavor. The process has been used for centuries - French chefs were making caramel in the 1600s, and it was one of the first food colorings to be used industrially. Plain caramel is considered the most 'natural' of the four classes of caramel color because it uses only heat and sugar, unlike E150b-d which involve chemical catalysts. It's used extensively in soft drinks (particularly colas), beer, bread, pet foods, sauces, and gravy mixes. The brown color comes from melanoidin polymers - large, complex molecules formed during heating. Unlike synthetic dyes, plain caramel has no known health concerns. The JECFA set no numerical ADI (acceptable daily intake), instead using the designation 'not specified', which indicates safety at any plausible consumption level. There are no allergic reactions associated with plain caramel, and it doesn't require any warning labels. The main technical limitation is that plain caramel can be less stable than the chemically-modified versions (E150b-d), particularly in acidic conditions, which is why different types of caramel color exist for different applications."
    },

    "E150c - Ammonia Caramel": {
        "whatItIs": "A dark brown coloring made by heating sugar in the presence of ammonia compounds, creating the characteristic dark color of cola drinks and beer.",
        "whereItComesFrom": "Manufactured by heating sugars (glucose, sucrose, or invert sugar) at high temperatures (120-180°C) with ammonium compounds like ammonium hydroxide or ammonium carbonate.",
        "whyItsUsed": "Provides stable dark brown coloring in cola drinks, dark beer, soy sauce, baked goods, and gravies where intense brown color and stability in acidic drinks is needed.",
        "whatYouNeedToKnow": [
            "The most widely consumed caramel color class (mainly from cola drinks)",
            "Contains 4-methylimidazole (4-MEI), a compound California lists as potentially carcinogenic",
            "The 4-MEI controversy led to reformulation of many cola products in California",
            "Generally considered safe at typical consumption levels by most regulatory bodies",
            "Provides better color stability in acidic beverages than plain caramel"
        ],
        "fullDescription": "Ammonia caramel (E150c), also called Class III caramel, is produced by heating sugars in the presence of ammonia compounds. This creates a dark brown color with excellent stability in acidic conditions, making it ideal for cola soft drinks - by far its largest use. The ammonia processing produces melanoidin polymers similar to plain caramel but with different properties. However, this process also creates small amounts of 4-methylimidazole (4-MEI), a compound that became controversial in 2011 when California added it to its Proposition 65 list of chemicals that might cause cancer, based on studies in mice and rats fed extremely high doses. The levels of 4-MEI in caramel color are typically measured in parts per million, and the exposure from a can of cola is far below levels shown to cause tumors in animal studies. Nevertheless, the California law required warning labels on products containing more than 29 micrograms of 4-MEI per day - a threshold that some colas exceeded. Rather than add warning labels, major soft drink manufacturers reformulated their caramel color to reduce 4-MEI levels below the threshold. The European Food Safety Authority (EFSA) and FDA reviewed the same animal data and concluded that 4-MEI levels in foods don't pose a cancer risk to humans at typical consumption levels. The JECFA set an ADI of 200mg/kg body weight for the caramel color itself, not specifically for 4-MEI. Most toxicologists argue that the cancer risk, if any, is minimal at real-world exposure levels. Despite the controversy, ammonia caramel remains one of the most widely consumed food additives globally."
    },

    "E150d - Sulphite Ammonia Caramel": {
        "whatItIs": "A dark brown coloring made by heating sugar with both ammonia and sulphite compounds, creating the most commonly used caramel color in the food industry.",
        "whereItComesFrom": "Manufactured by heating sugars at high temperatures with both ammonium compounds and sulphite compounds (like ammonium sulphite or sulphurous acid).",
        "whyItsUsed": "Provides highly stable dark brown coloring in soft drinks, beer, soy sauce, balsamic vinegar, and countless processed foods.",
        "whatYouNeedToKnow": [
            "Contains sulphites - must be labeled as an allergen for people with sulphite sensitivity",
            "Like E150c, can contain 4-methylimidazole (4-MEI) which California lists as potentially carcinogenic",
            "The most widely used of all four caramel color classes",
            "Generally considered safe by regulatory bodies at typical consumption levels",
            "People with asthma or sulphite sensitivity should be cautious"
        ],
        "fullDescription": "Sulphite ammonia caramel (E150d), also called Class IV caramel, is produced by heating sugars in the presence of both ammonia and sulphite compounds. This double treatment creates the most stable and versatile caramel color, which is why it's the most widely used class - found in soft drinks, beer, gravies, sauces, baked goods, and numerous other products. The sulphite-ammonia treatment produces melanoidin polymers with excellent stability across a wide pH range and resistance to fading. However, E150d shares the 4-MEI (4-methylimidazole) concern with E150c - the ammonia processing creates small amounts of this compound, which California lists as potentially carcinogenic based on high-dose animal studies. The same reformulation efforts that reduced 4-MEI in colas applied to E150d. Additionally, because E150d contains sulphite residues, it must be labeled as containing sulphites, which is important for the estimated 1% of the population with sulphite sensitivity. Sulphites can trigger allergic reactions ranging from mild (flushing, stomach upset) to severe (asthma attacks, anaphylaxis) in sensitive individuals, particularly those with asthma. About 5-10% of asthmatics are sulphite-sensitive. The JECFA set an ADI of 200mg/kg body weight for the caramel color itself. Despite containing both 4-MEI and sulphites, regulatory authorities worldwide maintain that E150d is safe at typical consumption levels. The European Food Safety Authority concluded in 2011 that there was no safety concern at current exposure levels. Nevertheless, some manufacturers are moving toward E150a (plain caramel) or natural alternatives like vegetable carbon to address consumer concerns about 'chemical' processing and sulphites."
    },

    "E151 - Brilliant Black BN": {
        "whatItIs": "A synthetic black dye derived from coal tar, also known as Black PN, used to create black and dark brown colors in foods.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds in industrial laboratories. It's an azo dye created through complex chemical reactions.",
        "whyItsUsed": "Provides black or very dark brown coloring in licorice, caviar, gravy browning, and decorative cake toppings.",
        "whatYouNeedToKnow": [
            "Banned in the United States, Canada, Australia, Denmark, Belgium, France, Germany, Switzerland, and Norway",
            "Can cause allergic reactions including hives and asthma attacks",
            "Some studies suggest it may cause chromosomal damage at high doses",
            "Still approved in the EU and UK but rarely used due to voluntary removal",
            "Most manufacturers now use alternatives like vegetable carbon (E153)"
        ],
        "fullDescription": "Brilliant Black BN (E151) is one of the most widely banned synthetic food colorings, prohibited in the United States, Canada, Australia, and numerous European countries including Denmark, Belgium, France, Germany, Switzerland, Sweden, and Norway. It's an azo dye that produces a black color, historically used in licorice, gravy browning, fish roe, and cake decorations. Despite being approved at EU level, its use is severely restricted by individual country bans. The United States never approved Brilliant Black BN, citing inadequate safety data. Several animal studies suggested that high doses might cause tumors and chromosomal damage, though as with many such studies, the doses were far above what humans would consume. Some research also indicated possible effects on lymphocytes (white blood cells). The JECFA reviewed the evidence and set an ADI of 1mg/kg body weight per day - notably low compared to other dyes, reflecting caution. Allergic reactions are a concern, particularly for people with aspirin sensitivity or asthma. Symptoms can include skin rashes, hives, swelling, breathing difficulties, and in rare cases, anaphylaxis. Following broader trends away from synthetic colors, particularly those with controversial safety profiles, most UK manufacturers voluntarily removed Brilliant Black BN from products. When black coloring is needed, companies now typically use vegetable carbon (E153), which is derived from carbonized plant material and generally perceived as more natural. If you see E151 on a label, it's likely in imported products from countries with less stringent regulations or niche specialty items."
    },

    "E153 - Vegetable Carbon": {
        "whatItIs": "Black powder made from carbonizing (charring) plant materials like coconut shells, wood, or peat at high temperatures - essentially controlled charcoal production.",
        "whereItComesFrom": "Produced by heating plant materials (coconut shells, wood, bamboo, peat) in low-oxygen conditions at 600-900°C, creating pure carbon powder that's then purified for food use.",
        "whyItsUsed": "Provides black coloring in licorice, jelly sweets, cake decorations, ice cream, and cheese rinds where a deep black is desired.",
        "whatYouNeedToKnow": [
            "Essentially purified charcoal - the same material used for medical purposes and water filtration",
            "Generally considered very safe with centuries of use",
            "Can contain trace polycyclic aromatic hydrocarbons (PAHs) from the charring process",
            "May interfere with absorption of some medications if consumed in large amounts",
            "Often used as a replacement for banned synthetic black dyes like E151"
        ],
        "fullDescription": "Vegetable carbon (E153), also called carbon black or carbo medicinalis vegetabilis, is one of the oldest food colorings, used for centuries to blacken foods. It's made by heating plant materials in low-oxygen conditions - a process called pyrolysis or carbonization. The organic material breaks down, leaving behind nearly pure carbon in a finely powdered form. The traditional source was hardwood or bone char, but modern food-grade vegetable carbon typically comes from coconut shells, bamboo, or sustainably harvested wood to ensure it's suitable for vegetarians and vegans. The production process is essentially the same as making activated charcoal, though food-grade carbon doesn't undergo the 'activation' step that creates the porous structure useful for filtering. The resulting black powder is more than 95% pure carbon. While generally considered very safe - it's been used for millennia and is chemically inert - there are some minor concerns. The charring process can create trace amounts of polycyclic aromatic hydrocarbons (PAHs), some of which are carcinogenic. Food-grade vegetable carbon must meet strict purity standards to ensure PAH levels are negligible. The JECFA set an ADI of 0-2.4mg/kg body weight per day, relatively low due to the PAH concern. In large amounts, vegetable carbon can bind to substances in the digestive tract (which is why activated charcoal is used for poisoning treatment), potentially interfering with nutrient or medication absorption, but levels used for coloring are too low for this effect. Vegetable carbon is popular as a 'natural' alternative to synthetic black dyes like Brilliant Black BN (E151)."
    },

    "E154 - Brown FK": {
        "whatItIs": "A synthetic brown dye mixture derived from coal tar, used exclusively for coloring kippers (smoked herring) in the UK.",
        "whereItComesFrom": "Manufactured through chemical synthesis, creating a mixture of six different azo dyes that together produce a brown color.",
        "whyItsUsed": "Used almost exclusively to give kippers (smoked herring) their traditional golden-brown color when modern quick-smoking methods don't produce enough natural browning.",
        "whatYouNeedToKnow": [
            "Permitted in the UK ONLY for kippers - illegal in all other foods",
            "Banned entirely in the European Union except the UK",
            "Never approved in the United States or many other countries",
            "A mixture of six different synthetic dyes rather than a single compound",
            "Considered one of the most questionable food additives still in use"
        ],
        "fullDescription": "Brown FK (E154) has the most restricted use of any permitted food additive in the UK - it's legal only in kippers (smoked herring) and nowhere else. The 'FK' stands for 'For Kippers', reflecting its sole permitted use. Traditional kipper smoking took 12-18 hours and produced a deep golden-brown color naturally from the smoking process. Modern quick-smoking methods cut this to just a few hours, but don't produce the same color, so manufacturers add Brown FK to make kippers look 'traditional'. Brown FK isn't a single compound but a mixture of six different azo dyes, which complicates safety assessment. It was never approved in the United States or many other countries. The European Union banned it completely in 2007, except the UK negotiated a specific exemption for kippers only, citing 'traditional use'. This makes kippers one of the only foods where UK and EU regulations diverge on permitted additives. Safety concerns center on the fact that it's a mixture of azo dyes, some of which may break down into aromatic amines that could potentially be carcinogenic. However, exposure is extremely low since it's used only in one product. The JECFA has not set an ADI for Brown FK, and EFSA concluded in 2010 that safety data was inadequate. Despite this, the UK maintains its kipper-only permission based on tradition and limited exposure. Many kipper producers now use natural smoke or other alternatives like Plain caramel (E150a) instead. If you see E154 on a label, it will be on kippers - if it's on anything else, it's illegal."
    },

    "E155 - Brown HT": {
        "whatItIs": "A synthetic brown dye derived from coal tar, also known as Chocolate Brown HT, used to enhance brown colors in foods.",
        "whereItComesFrom": "Manufactured through chemical synthesis from petroleum-based compounds. It's an azo dye created in industrial laboratories.",
        "whyItsUsed": "Provides brown coloring in chocolate cakes, chocolate-flavored desserts, and some beverages where enhanced brown color is desired.",
        "whatYouNeedToKnow": [
            "Banned in the United States, Canada, Australia, Denmark, Belgium, France, Germany, Switzerland, Sweden, and Austria",
            "Can cause allergic reactions, particularly in people with aspirin sensitivity",
            "Some studies suggest possible links to hyperactivity, though not part of the Southampton Six",
            "Still approved in the EU and UK but increasingly rare due to voluntary removal",
            "Most chocolate products achieve brown color naturally from cocoa"
        ],
        "fullDescription": "Brown HT (E155), also called Chocolate Brown HT or Food Brown 3, is a synthetic azo dye that produces a reddish-brown color. Despite its name, it's rarely used in actual chocolate, which gets its brown color naturally from cocoa. Instead, it's sometimes added to chocolate-flavored products that contain little actual chocolate, or to drinks and desserts to enhance brown tones. Brown HT has never been approved in the United States, Canada, or Australia, and is banned in numerous European countries including Denmark, Belgium, France, Germany, Switzerland, Sweden, and Austria, despite being approved at EU level. This patchwork of bans reflects concerns about safety data and the precautionary principle. Some animal studies suggested that high doses of Brown HT might affect behavior, cause allergic reactions, and possibly damage chromosomes, though the relevance to human consumption at food-coloring levels is debated. The JECFA set an ADI of 1.5mg/kg body weight per day. Allergic reactions are the most established concern, particularly in people with aspirin sensitivity, asthma, or allergies to other azo dyes. Symptoms can include hives, swelling, breathing difficulties, and gastrointestinal upset. Some research has suggested possible links to hyperactivity in children, though Brown HT wasn't included in the famous Southampton Six study. Following general consumer pressure for 'clean labels' without synthetic additives, most UK manufacturers have voluntarily removed Brown HT from products. When brown coloring is needed, companies typically use combinations of caramel colors, cocoa powder, or burnt sugar rather than synthetic dyes."
    },

    "E160a - Carotenes": {
        "whatItIs": "The orange pigments naturally found in carrots, sweet potatoes, pumpkins, and mangoes - the same compounds your body converts into vitamin A.",
        "whereItComesFrom": "Extracted from natural sources like carrots, palm oil, and algae, or produced through fermentation using fungi. Beta-carotene can also be synthesized to be chemically identical to natural carotene.",
        "whyItsUsed": "Provides natural orange-yellow coloring in margarine, cheese, orange juice, bakery products, and supplements where an orange color or vitamin A fortification is desired.",
        "whatYouNeedToKnow": [
            "Your body converts beta-carotene into vitamin A as needed",
            "Generally very safe - it's consumed in fruits and vegetables daily",
            "Can temporarily turn your skin slightly orange if you eat excessive amounts (carotenemia)",
            "Beta-carotene supplements at very high doses were linked to increased lung cancer risk in smokers in some studies",
            "Natural carotenoids are antioxidants with potential health benefits"
        ],
        "fullDescription": "Carotenes (E160a) are a family of orange pigments found abundantly in nature, particularly beta-carotene which is the most common. The name comes from carrots, where it was first isolated in the 1830s. Beta-carotene is a provitamin A carotenoid, meaning your body can convert it into vitamin A (retinol) as needed, making it an important nutrient. Unlike preformed vitamin A from animal sources, beta-carotene doesn't cause vitamin A toxicity because your body regulates conversion. When used as a food additive, carotenes can be extracted from natural sources (carrots, palm oil, algae) or produced by fermentation using Blakeslea trispora fungi. Synthetic beta-carotene, chemically identical to natural, can also be manufactured. As a coloring, beta-carotene provides yellow-orange hues and is particularly popular in margarine and dairy products to mimic the natural color from grass-fed cows. The safety profile is excellent for most people - humans have consumed carotenes in vegetables for millennia. However, two large clinical trials (ATBC and CARET) in the 1990s found that high-dose beta-carotene supplements (20-30mg daily) increased lung cancer risk in smokers and asbestos-exposed workers. This effect was specific to high supplemental doses in high-risk groups, not dietary carotenes from foods or food coloring. The JECFA set an ADI of 5mg/kg body weight per day. High intake of carotenes (from food or supplements) can cause carotenemia - temporary orange-yellow discoloration of skin, particularly palms and soles - which is harmless and reverses when intake decreases."
    }
}


def load_database(filepath):
    """Load the comprehensive ingredients database."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_database(filepath, data):
    """Save the updated database."""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def generate_content_for_additive(additive):
    """
    Generate comprehensive consumer-focused content for an additive.
    This is a placeholder - in production, this would use extensive research.
    """
    name = additive.get('name', '')
    e_numbers = additive.get('eNumbers', [])
    category = additive.get('category', '')
    group = additive.get('group', '')
    origin = additive.get('origin', '')
    overview = additive.get('overview', '')
    typical_uses = additive.get('typicalUses', '')
    effects_summary = additive.get('effectsSummary', '')
    concerns = additive.get('concerns', '')

    # Create E-number key for lookup
    e_key = f"{e_numbers[0]} - {name.split(';')[0].strip()}" if e_numbers else name

    # Check if we have pre-written content
    if e_key in ADDITIVE_CONTENT:
        return ADDITIVE_CONTENT[e_key]

    # For additives without pre-written content, generate basic structure
    # This is where extensive research would go for each additive
    return {
        "whatItIs": f"{overview}",
        "whereItComesFrom": f"{origin}",
        "whyItsUsed": f"{typical_uses}",
        "whatYouNeedToKnow": [
            effects_summary or "Generally recognised as safe at typical levels"
        ],
        "fullDescription": f"{overview} {typical_uses}"
    }


def main():
    """Main function to process all additives."""
    input_file = "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafe Beta/ingredients_comprehensive.json"

    print("Loading database...")
    data = load_database(input_file)

    print(f"Processing {len(data['ingredients'])} additives...")

    # Update each additive with comprehensive content
    for i, additive in enumerate(data['ingredients']):
        content = generate_content_for_additive(additive)

        # Update the additive with new content
        additive['whatItIs'] = content['whatItIs']
        additive['whereItComesFrom'] = content['whereItComesFrom']
        additive['whyItsUsed'] = content['whyItsUsed']
        additive['whatYouNeedToKnow'] = content['whatYouNeedToKnow']
        additive['fullDescription'] = content['fullDescription']

        if (i + 1) % 50 == 0:
            print(f"Processed {i + 1} additives...")

    # Update metadata
    data['metadata']['last_updated'] = '2026-01-25'
    data['metadata']['version'] = '3.3.0-comprehensive-content'

    print("Saving updated database...")
    save_database(input_file, data)

    print(f"✓ Successfully updated {len(data['ingredients'])} additives")


if __name__ == '__main__':
    main()
