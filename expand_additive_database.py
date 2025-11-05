#!/usr/bin/env python3
"""
Expand the additives database with comprehensive coverage of common additives
"""

import json
from typing import Dict, List

def load_database(filepath: str) -> Dict:
    """Load existing database"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

# Comprehensive list of missing additives and ingredients
MISSING_ADDITIVES = [
    # LECITHINS (E322 family)
    {
        "name": "Lecithin",
        "eNumbers": ["E322"],
        "synonyms": ["lecithins", "soya lecithin", "soy lecithin", "emulsifier (soya lecithin)",
                     "emulsifier (lecithin)", "emulsifiers (lecithin)", "soybean lecithin"],
        "category": "emulsifier",
        "group": "emulsifier",
        "origin": "plant",
        "overview": "A natural emulsifier derived from soybeans or sunflower seeds",
        "what_it_is": "A fatty substance extracted from soybeans or sunflower seeds that helps mix oil and water-based ingredients",
        "why_its_used": "Prevents separation, improves texture, and extends shelf life in chocolate, baked goods, and processed foods",
        "where_it_comes_from": "Extracted from soybeans, sunflower seeds, or egg yolks through chemical or mechanical processing",
        "typicalUses": "Chocolate, margarine, baked goods, instant foods, non-stick cooking sprays",
        "effectsVerdict": "neutral",
        "effectsSummary": "Generally considered safe. Derived from natural sources but requires processing to extract.",
        "concerns": "May be derived from GM soy. Generally safe for most people.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "EFSA: Safety of lecithins for all animal species",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/4742",
                "covers": "Safety assessment of lecithin as a food additive"
            }
        ],
        "processingPenalty": 5,
        "novaGroup": 3,
        "database_origin": "expanded"
    },

    # MONO AND DIGLYCERIDES (E471)
    {
        "name": "Mono- and diglycerides of fatty acids",
        "eNumbers": ["E471"],
        "synonyms": ["mono and diglycerides", "monoglycerides", "diglycerides", "glyceryl monostearate",
                     "emulsifier (mono- and diglycerides of fatty acids)", "mono and di glycerides"],
        "category": "emulsifier",
        "group": "emulsifier",
        "origin": "synthetic",
        "overview": "Synthetic emulsifiers made from glycerol and fatty acids",
        "what_it_is": "Industrially produced fat molecules created by reacting glycerol with fatty acids from plant or animal fats",
        "why_its_used": "Helps blend oil and water, improves texture, prevents staling in baked goods, and creates smooth consistency",
        "where_it_comes_from": "Synthetically produced from vegetable oils or animal fats through chemical processing with glycerol",
        "typicalUses": "Bread, cakes, ice cream, margarine, whipped toppings, non-dairy creamers",
        "effectsVerdict": "neutral",
        "effectsSummary": "Widely used synthetic emulsifier. Generally recognized as safe but highly processed.",
        "concerns": "Synthetic emulsifier created through industrial processing. May be derived from animal or plant sources.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "FDA: GRAS notice for mono- and diglycerides",
                "url": "https://www.fda.gov/food/food-additives-petitions/food-additive-status-list",
                "covers": "Regulatory status and safety of mono- and diglycerides"
            }
        ],
        "processingPenalty": 10,
        "novaGroup": 4,
        "database_origin": "expanded"
    },

    # SODIUM BICARBONATE (E500)
    {
        "name": "Sodium bicarbonate",
        "eNumbers": ["E500", "E500(ii)"],
        "synonyms": ["baking soda", "bicarbonate of soda", "bread soda", "sodium hydrogen carbonate",
                     "raising agent (sodium bicarbonate)", "nahco3"],
        "category": "raising_agent",
        "group": "other",
        "origin": "mineral",
        "overview": "A common raising agent used in baking",
        "what_it_is": "A white crystalline powder that releases carbon dioxide when heated or mixed with acid, causing dough to rise",
        "why_its_used": "Creates light, fluffy texture in baked goods by producing gas bubbles that expand during baking",
        "where_it_comes_from": "Mined from natural mineral deposits or synthetically produced from sodium carbonate",
        "typicalUses": "Baking powder, cakes, biscuits, bread, fizzy drinks, antacid medications",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural mineral compound, safe for consumption and widely used in home cooking",
        "concerns": "None - considered safe and is used in home baking",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "EFSA: Re-evaluation of sodium carbonates (E 500)",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/4884",
                "covers": "Safety assessment of sodium bicarbonate as food additive"
            }
        ],
        "processingPenalty": 0,
        "novaGroup": 0,
        "database_origin": "expanded"
    },

    # BAKING POWDER
    {
        "name": "Baking powder",
        "eNumbers": [],
        "synonyms": ["raising agent (baking powder)", "double acting baking powder", "self raising agent"],
        "category": "raising_agent",
        "group": "other",
        "origin": "mineral",
        "overview": "A mixture of sodium bicarbonate and acidifying agents used as a raising agent",
        "what_it_is": "A blend of sodium bicarbonate (baking soda) with cream of tartar or other acids, plus a starch to prevent clumping",
        "why_its_used": "Causes baked goods to rise by releasing carbon dioxide gas when mixed with wet ingredients and heated",
        "where_it_comes_from": "Manufactured by mixing sodium bicarbonate with acidifying salts and starch",
        "typicalUses": "Self-raising flour, cakes, muffins, scones, biscuits, pancakes",
        "effectsVerdict": "safe",
        "effectsSummary": "Common household ingredient made from safe components, widely used in home baking",
        "concerns": "None - considered safe and commonly used in home cooking",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 0,
        "novaGroup": 0,
        "database_origin": "expanded"
    },

    # VANILLA EXTRACT
    {
        "name": "Vanilla extract",
        "eNumbers": [],
        "synonyms": ["natural vanilla extract", "vanilla essence", "pure vanilla extract", "vanilla flavouring"],
        "category": "flavouring",
        "group": "other",
        "origin": "plant",
        "overview": "Natural flavouring extracted from vanilla beans",
        "what_it_is": "A solution made by macerating and percolating vanilla pods in a mixture of water and ethanol",
        "why_its_used": "Adds sweet, aromatic vanilla flavour to baked goods, desserts, and beverages",
        "where_it_comes_from": "Extracted from cured vanilla orchid pods (Vanilla planifolia) grown in tropical regions",
        "typicalUses": "Cakes, biscuits, ice cream, chocolate, custard, flavoured milk drinks",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural plant extract, widely used in home cooking and commercially",
        "concerns": "None - natural flavouring considered safe",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 0,
        "novaGroup": 0,
        "database_origin": "expanded"
    },

    # NATURAL FLAVOURINGS
    {
        "name": "Natural flavouring",
        "eNumbers": [],
        "synonyms": ["natural flavour", "natural flavor", "natural flavourings", "natural flavors",
                     "flavouring", "flavoring", "natural vanilla flavouring"],
        "category": "flavouring",
        "group": "other",
        "origin": "plant",
        "overview": "Flavourings derived from natural plant or animal sources",
        "what_it_is": "Flavour compounds extracted from plants, spices, fruits, or other natural sources through processing",
        "why_its_used": "Enhances or standardises flavour in processed foods without adding artificial chemicals",
        "where_it_comes_from": "Extracted from natural sources like fruits, vegetables, herbs, spices, or plant materials",
        "typicalUses": "Drinks, desserts, baked goods, confectionery, savoury foods, dairy products",
        "effectsVerdict": "neutral",
        "effectsSummary": "Derived from natural sources but processed. Generally considered safer than artificial flavours.",
        "concerns": "Though natural, these are concentrated extracts requiring processing. Actual source often not specified on labels.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "EFSA: Flavourings Group Evaluation",
                "url": "https://www.efsa.europa.eu/en/topics/topic/flavourings",
                "covers": "Safety evaluations of flavouring substances"
            }
        ],
        "processingPenalty": 3,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # COCOA BUTTER
    {
        "name": "Cocoa butter",
        "eNumbers": [],
        "synonyms": ["cacao butter", "theobroma oil"],
        "category": "fat",
        "group": "other",
        "origin": "plant",
        "overview": "Natural fat extracted from cocoa beans",
        "what_it_is": "A pale-yellow edible fat extracted from cocoa beans during chocolate production",
        "why_its_used": "Provides smooth melting texture in chocolate, adds richness, and helps chocolate set properly",
        "where_it_comes_from": "Pressed from roasted cocoa beans (the same beans used to make chocolate)",
        "typicalUses": "Chocolate, white chocolate, confectionery, cosmetics, pharmaceuticals",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural plant fat from cocoa beans, minimally processed",
        "concerns": "None - natural ingredient used in chocolate making",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 0,
        "novaGroup": 1,
        "database_origin": "expanded"
    },

    # COCOA MASS
    {
        "name": "Cocoa mass",
        "eNumbers": [],
        "synonyms": ["chocolate liquor", "cocoa liquor", "cacao mass", "unsweetened chocolate"],
        "category": "other",
        "group": "other",
        "origin": "plant",
        "overview": "Pure ground cocoa beans containing both cocoa solids and cocoa butter",
        "what_it_is": "The liquid or paste form of pure ground cocoa beans, containing both cocoa butter and cocoa solids in their natural proportions",
        "why_its_used": "Provides rich chocolate flavour and forms the base ingredient for all chocolate products",
        "where_it_comes_from": "Made by grinding roasted cocoa beans (Theobroma cacao) into a smooth paste or liquid",
        "typicalUses": "Dark chocolate, milk chocolate, chocolate products, baking chocolate",
        "effectsVerdict": "safe",
        "effectsSummary": "Minimally processed cocoa beans - natural chocolate ingredient",
        "concerns": "None - natural ingredient from cocoa beans",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 0,
        "novaGroup": 1,
        "database_origin": "expanded"
    },

    # CARAMEL (Plain)
    {
        "name": "Caramel",
        "eNumbers": ["E150a"],
        "synonyms": ["plain caramel", "caramel colour", "caramel color", "burnt sugar", "caramelised sugar"],
        "category": "colour",
        "group": "other",
        "origin": "plant",
        "overview": "Brown colouring made by heating sugar",
        "what_it_is": "A brown colouring produced by carefully heating sugar until it caramelises, used for colouring food and drinks",
        "why_its_used": "Adds brown colour to foods and beverages, creates caramel flavour in confectionery",
        "where_it_comes_from": "Made by controlled heating of carbohydrates (sugars) with or without acids or alkalis",
        "typicalUses": "Cola drinks, beer, brown bread, sauces, gravy, confectionery, desserts",
        "effectsVerdict": "neutral",
        "effectsSummary": "Made from heated sugar. Plain caramel (E150a) is considered the safest type of caramel colouring.",
        "concerns": "Some caramel colours (E150c, E150d) contain 4-MEI, a potential concern. E150a plain caramel is considered safer.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "EFSA: Re-evaluation of caramel colours (E 150)",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/3625",
                "covers": "Safety assessment of caramel food colourings"
            }
        ],
        "processingPenalty": 5,
        "novaGroup": 3,
        "database_origin": "expanded"
    },

    # VEGETABLE FAT
    {
        "name": "Vegetable fat",
        "eNumbers": [],
        "synonyms": ["vegetable oil", "plant fat", "vegetable oils", "plant oil", "non-hydrogenated vegetable fat"],
        "category": "fat",
        "group": "other",
        "origin": "plant",
        "overview": "Fats extracted from various plant sources",
        "what_it_is": "Fats extracted from plants such as palm, coconut, rapeseed, sunflower, or other oil-bearing crops",
        "why_its_used": "Provides texture, mouthfeel, and shelf stability in processed foods at lower cost than butter",
        "where_it_comes_from": "Extracted and refined from various plant sources including palm, coconut, sunflower, rapeseed seeds or fruits",
        "typicalUses": "Baked goods, confectionery, spreads, fried foods, processed snacks",
        "effectsVerdict": "neutral",
        "effectsSummary": "Plant-derived fats that are refined and processed. Quality depends on source and processing method.",
        "concerns": "Often refined and may be high in saturated fat (palm, coconut). Processing level varies. Check for hydrogenation.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "NHS: Different fats - the facts",
                "url": "https://www.nhs.uk/live-well/eat-well/food-types/different-fats-nutrition/",
                "covers": "Health impacts of different types of fats"
            }
        ],
        "processingPenalty": 8,
        "novaGroup": 3,
        "database_origin": "expanded"
    },

    # VEGETABLE OIL (SUNFLOWER)
    {
        "name": "Sunflower oil",
        "eNumbers": [],
        "synonyms": ["sunflower seed oil", "refined sunflower oil"],
        "category": "fat",
        "group": "other",
        "origin": "plant",
        "overview": "Oil extracted from sunflower seeds",
        "what_it_is": "A light-coloured oil extracted from sunflower seeds, often refined for commercial use",
        "why_its_used": "Neutral-tasting cooking oil and ingredient that is relatively high in unsaturated fats",
        "where_it_comes_from": "Pressed and refined from sunflower seeds (Helianthus annuus)",
        "typicalUses": "Cooking oil, salad dressings, mayonnaise, fried foods, baked goods",
        "effectsVerdict": "safe",
        "effectsSummary": "Refined plant oil, relatively high in unsaturated fats compared to some other oils",
        "concerns": "Refined oils undergo processing. High omega-6 content compared to omega-3.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 3,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # MILK FAT
    {
        "name": "Milk fat",
        "eNumbers": [],
        "synonyms": ["butterfat", "milk solids", "anhydrous milk fat", "dairy fat"],
        "category": "fat",
        "group": "other",
        "origin": "animal",
        "overview": "Natural fat component of milk",
        "what_it_is": "The fatty component naturally present in milk, cream, and butter",
        "why_its_used": "Provides creamy texture, rich flavour, and mouthfeel in dairy products",
        "where_it_comes_from": "Naturally occurring in milk from dairy cows, can be concentrated through processing",
        "typicalUses": "Butter, cream, cheese, ice cream, chocolate, dairy products",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural dairy ingredient, though relatively high in saturated fat",
        "concerns": "High in saturated fat. Not suitable for those with dairy allergies or lactose intolerance.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 0,
        "novaGroup": 1,
        "database_origin": "expanded"
    },

    # EGG WHITE POWDER
    {
        "name": "Egg white powder",
        "eNumbers": [],
        "synonyms": ["dried egg white", "egg albumen powder", "powdered egg white", "spray dried egg white"],
        "category": "protein",
        "group": "other",
        "origin": "animal",
        "overview": "Dehydrated egg whites used as a protein and binding agent",
        "what_it_is": "Egg whites that have been spray-dried into a powder form for easy storage and use",
        "why_its_used": "Provides protein, helps bind ingredients, creates structure in baked goods, and can be whipped for aeration",
        "where_it_comes_from": "Made by spray-drying fresh egg whites from chicken eggs",
        "typicalUses": "Baked goods, meringues, protein supplements, processed foods, confectionery",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural animal protein that has been dried for preservation",
        "concerns": "Contains egg allergen. Processing involves heat treatment.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 3,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # MILK PROTEIN
    {
        "name": "Milk protein",
        "eNumbers": [],
        "synonyms": ["milk proteins", "dairy protein", "whey and casein", "total milk protein"],
        "category": "protein",
        "group": "other",
        "origin": "animal",
        "overview": "Proteins naturally found in milk",
        "what_it_is": "The protein components of milk, including both whey and casein proteins in their natural proportions",
        "why_its_used": "Adds nutritional value, improves texture, helps with binding, and provides structure in processed foods",
        "where_it_comes_from": "Extracted from cow's milk through various processing methods",
        "typicalUses": "Protein-enriched foods, dairy products, sports nutrition, infant formula, processed foods",
        "effectsVerdict": "safe",
        "effectsSummary": "Natural dairy protein, though requires processing to concentrate",
        "concerns": "Contains milk allergen. Not suitable for lactose intolerant individuals or vegans.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 5,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # SALT
    {
        "name": "Salt",
        "eNumbers": [],
        "synonyms": ["table salt", "sea salt", "sodium chloride", "cooking salt", "nacl"],
        "category": "preservative",
        "group": "other",
        "origin": "mineral",
        "overview": "Common seasoning and preservative",
        "what_it_is": "Sodium chloride, a mineral compound used for flavouring and preserving food",
        "why_its_used": "Enhances flavour, preserves food, controls fermentation, and improves texture in processed foods",
        "where_it_comes_from": "Mined from underground salt deposits or evaporated from seawater",
        "typicalUses": "All savoury foods, preserving meats, bread, cheese, processed foods, cured products",
        "effectsVerdict": "neutral",
        "effectsSummary": "Essential mineral, but excessive intake associated with high blood pressure and cardiovascular issues",
        "concerns": "High intake linked to high blood pressure and cardiovascular disease. Excessive amounts in processed foods.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [
            {
                "title": "WHO: Salt reduction",
                "url": "https://www.who.int/news-room/fact-sheets/detail/salt-reduction",
                "covers": "Health impacts of salt and recommended intake levels"
            },
            {
                "title": "NHS: Salt in your diet",
                "url": "https://www.nhs.uk/live-well/eat-well/food-types/salt-in-your-diet/",
                "covers": "Health effects of salt and daily recommendations"
            }
        ],
        "processingPenalty": 0,
        "novaGroup": 0,
        "database_origin": "expanded"
    },

    # WHEY POWDER
    {
        "name": "Whey powder",
        "eNumbers": [],
        "synonyms": ["dried whey", "milk whey powder", "whey solids", "lactose and protein from whey (from milk)",
                     "lactose and protein from whey", "whey powder (from milk)"],
        "category": "protein",
        "group": "other",
        "origin": "animal",
        "overview": "Dried whey - the liquid remaining after milk has been curdled and strained",
        "what_it_is": "The dried powder form of whey, the watery part of milk that separates from the curds during cheese making",
        "why_its_used": "Adds protein, improves texture, enhances browning, and provides a source of lactose in processed foods",
        "where_it_comes_from": "By-product of cheese and yogurt production, spray-dried into powder form",
        "typicalUses": "Baked goods, confectionery, processed cheese, protein supplements, infant formula",
        "effectsVerdict": "safe",
        "effectsSummary": "Dairy by-product that undergoes processing. Natural source of protein and lactose.",
        "concerns": "Contains lactose - unsuitable for lactose intolerant individuals. Dairy allergen.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 5,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # SKIMMED MILK POWDER
    {
        "name": "Skimmed milk powder",
        "eNumbers": [],
        "synonyms": ["skim milk powder", "non-fat milk powder", "dried skimmed milk", "milk powder", "powdered milk"],
        "category": "protein",
        "group": "other",
        "origin": "animal",
        "overview": "Milk with fat removed then dried into powder",
        "what_it_is": "Milk that has had the cream removed and then been evaporated to dryness to create a shelf-stable powder",
        "why_its_used": "Adds milk solids, protein, and calcium to foods without adding fat or requiring refrigeration",
        "where_it_comes_from": "Made by removing fat from fresh milk then spray-drying the remaining liquid",
        "typicalUses": "Baked goods, chocolate, confectionery, instant soups, protein drinks, infant formula",
        "effectsVerdict": "safe",
        "effectsSummary": "Processed milk product with fat removed, but retains protein and minerals",
        "concerns": "Requires processing. Contains lactose and milk proteins - unsuitable for dairy allergies or lactose intolerance.",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 3,
        "novaGroup": 2,
        "database_origin": "expanded"
    },

    # FAT REDUCED COCOA
    {
        "name": "Fat reduced cocoa",
        "eNumbers": [],
        "synonyms": ["defatted cocoa", "cocoa powder", "fat reduced cocoa powder", "low fat cocoa"],
        "category": "other",
        "group": "other",
        "origin": "plant",
        "overview": "Cocoa powder with much of the cocoa butter removed",
        "what_it_is": "Cocoa solids with most of the natural cocoa butter fat removed through pressing, leaving a powder rich in cocoa flavour",
        "why_its_used": "Provides intense chocolate flavour without adding much fat, used in baking and chocolate products",
        "where_it_comes_from": "Made by pressing cocoa mass to remove cocoa butter, then grinding the remaining solids into powder",
        "typicalUses": "Chocolate drinks, baking, chocolate products, desserts, confectionery",
        "effectsVerdict": "safe",
        "effectsSummary": "Processed cocoa with fat removed but retaining antioxidants and chocolate flavour",
        "concerns": "Processing reduces fat content but retains beneficial cocoa compounds",
        "hasChildWarning": False,
        "hasPKUWarning": False,
        "hasSulphitesAllergenLabel": False,
        "hasPolyolsWarning": False,
        "isPermittedGB": True,
        "isPermittedNI": True,
        "isPermittedEU": True,
        "sources": [],
        "processingPenalty": 3,
        "novaGroup": 2,
        "database_origin": "expanded"
    }
]

def expand_database(input_path: str, output_path: str):
    """Add missing additives to database"""

    # Load existing database
    print(f"Loading existing database from {input_path}...")
    db = load_database(input_path)
    existing_ingredients = db['ingredients']

    print(f"Current database has {len(existing_ingredients)} ingredients")

    # Create lookup of existing names (lowercased for comparison)
    existing_names = {ing['name'].lower() for ing in existing_ingredients}

    # Add new ingredients
    added_count = 0
    for new_ing in MISSING_ADDITIVES:
        if new_ing['name'].lower() not in existing_names:
            existing_ingredients.append(new_ing)
            added_count += 1
            print(f"✅ Added: {new_ing['name']}")
        else:
            print(f"⏭️  Skipped (exists): {new_ing['name']}")

    # Sort alphabetically
    existing_ingredients.sort(key=lambda x: x['name'])

    # Update metadata
    db['metadata']['total_ingredients'] = len(existing_ingredients)
    db['metadata']['version'] = '2025.5-unified-consolidated-expanded'
    db['metadata']['description'] = 'Comprehensive database of food additives and ultra-processed ingredients with complete coverage of common ingredients'

    # Save
    print(f"\nSaving expanded database to {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Database expansion complete!")
    print(f"   Added: {added_count} new ingredients")
    print(f"   Total: {len(existing_ingredients)} ingredients")

    # Show statistics
    with_enums = sum(1 for ing in existing_ingredients if ing.get('eNumbers', []))
    with_sources = sum(1 for ing in existing_ingredients if ing.get('sources', []))

    print(f"\n📊 Statistics:")
    print(f"   Ingredients with E-numbers: {with_enums}")
    print(f"   Ingredients with sources: {with_sources}")

if __name__ == '__main__':
    expand_database(
        'NutraSafe Beta/ingredients_consolidated.json',
        'NutraSafe Beta/ingredients_consolidated.json'
    )
