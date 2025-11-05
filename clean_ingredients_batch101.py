#!/usr/bin/env python3
"""
Clean ingredients for batch 101 of messy products - DOUBLED BATCH SIZE (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch101(db_path: str):
    """Update batch 101 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 101: Products with cleaned ingredients (50 products - doubled batch size!)
    clean_data = [
        {
            'id': 'FudG67bRQuBOKtVRM5q4',
            'name': 'Sweet Chilli Sauce',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Water, red chillies (20%), sugar, glucose-fructose syrup, ground garlic (6%), pickled garlic (5%) (garlic, water, salt, acid: acetic acid), modified tapioca starch, acid (acetic acid), salt.'
        },
        {
            'id': 'FvHA29Qatmx5pCUHvMdS',
            'name': 'Plant-powdered Honeycomb Blast',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, glucose syrup, cocoa butter, rice powder, rice syrup, rice starch, rice flour, cocoa mass, raising agent (carbon dioxide), emulsifiers (sunflower lecithin, rapeseed lecithin), natural flavourings.'
        },
        {
            'id': 'FvftdoJsHly8bC3w5s6q',
            'name': 'Gut Glory',
            'brand': 'Gut Glory',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), sugar, water, invert sugar syrup, maize starch, butter (milk), flavourings, colour (plain caramel), live cultures, sea salt, concentrated lemon juice.'
        },
        {
            'id': 'FvuCitrM3P6XgMd7xn6w',
            'name': 'Glaze With Balsamic Vinegar Of Modena',
            'brand': 'Bella',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, wine vinegar (contains sulphites), balsamic vinegar of Modena (13%) (wine vinegar, concentrated grape must (contains sulphites), colour: E150d), modified maize starch.'
        },
        {
            'id': 'Fw8h5RLzLlUg6j6Ddzpq',
            'name': 'Seasonal Fairy Cakes',
            'brand': 'Fiona Cairns',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, water, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), rapeseed oil, wheat glucose syrup, dried free-range egg, emulsifiers (mono-and diglycerides of fatty acids, sodium stearoyl-2-lactylate, polyglycerol esters of fatty acids, lactic acid esters of mono-and diglycerides of fatty acids), raising agents (diphosphates, sodium carbonates), salt, milk whey powder, wheat dextrose, palm oil, humectant (vegetable glycerine), preservatives (potassium sorbate), colours (titanium dioxide, curcumin, beetroot, paprika, copper complexes of chlorophyllins), stabilizer (tragacanth), dried free-range egg albumen, spirulina concentrate, flavouring.'
        },
        {
            'id': 'FwV539NF8rPRhHZ4RQAO',
            'name': 'Chocolate Chip Brioche Rolls',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), chocolate chips (12%) (sugar, cocoa mass, cocoa butter, emulsifier: soya lecithin), levain (11%) (wheat flour: wheat flour, calcium carbonate, iron, niacin, thiamin, water, salt), sugar, palm fat, water, rapeseed oil, dried egg, emulsifier (E471, E481), yeast, dried whole milk, salt, thickener (locust bean gum), milk protein, vanilla flavouring, flour treatment agent (ascorbic acid), wheat gluten.'
        },
        {
            'id': 'FrNNOwsrVUFsNztSuDWb',
            'name': 'Rice Cakes With Milk Chocolate Coating',
            'brand': 'Harvest Morn',
            'serving_size_g': 17.0,
            'ingredients': 'Milk chocolate (60%) (sugar, whole milk powder, cocoa mass, cocoa butter, emulsifier: lecithins), rice, brown rice, sea salt, emulsifier (lecithins).'
        },
        {
            'id': 'FxAlvX9a3HiIRYwasz3W',
            'name': 'Sourdough',
            'brand': 'Warburtons',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat flour (with calcium, iron, niacin (B3) and thiamin (B1)), water, yeast, sourdough (fermented wheat flour, water), wholegrain rye flour, vegetable oils (rapeseed and sustainable palm), wheat gluten, salt, fermented wheat flour, soya flour, flour treatment agent (ascorbic acid (vitamin C)).'
        },
        {
            'id': 'G1KE8CPRPTRBel5iwOWS',
            'name': 'Wholegrain Oat Flakes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Whole grain oat flakes (69.8%), sugar, barley malt extract, dried apple (4.9%), pumpkin seeds (4.9%), dried cranberries (4.3%), oat fibre, humectant (glycerol), glucose syrup, salt, Bifidobacterium lactis cultures, antioxidant (tocopherols), acidity regulator (citric acid), natural flavouring.'
        },
        {
            'id': 'G1yTULMLqRFYhutO6u9f',
            'name': 'Monster Energy Ultra Paradise',
            'brand': 'Monster',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated water, acid (citric acid), taurine (0.4%), acidity regulator (sodium citrates), panax ginseng root extract (0.08%), flavourings, preservatives (potassium sorbate, sodium benzoate), sweeteners (acesulfame K, sucralose), maltodextrin, caffeine (0.03%), vitamins (B3, B5, B6, B12), L-carnitine L-tartarate (0.015%), sodium chloride, safflower extract, vegetable oils (coconut, rapeseed), modified starch, inositol, colour (E133).'
        },
        {
            'id': 'G4OwILMBUzH7THuerleX',
            'name': 'Exceptional Madagascan Vanilla Yoghurt',
            'brand': 'Exceptional',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (68%) (whole milk, sugar, water, maize starch, concentrated lemon juice, live bacterial cultures: bifidobacterium, lactobacillus acidophilus, streptococcus thermophilus), whipping cream (milk) (13%), glucose syrup, sweetened condensed skimmed milk (skimmed milk, sugar), flavourings, vanilla powder.'
        },
        {
            'id': 'G55WrlM5RpjPD7PPVm2I',
            'name': 'Dry Cured Honey Roast Ham',
            'brand': 'Farmfoods',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, salt, honey, white sugar, stabilisers (diphosphates, triphosphates), brown sugar, smoke flavouring, antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': 'G66tDN73KZt2hGBSjHyF',
            'name': 'Mini Flapjacks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Oats (38%), golden syrup (12%), sweetened condensed skimmed milk (skimmed milk, sugar), sugar, unsalted butter (milk), glucose syrup, palm oil, rapeseed oil, coconut oil, maltodextrin, salt, emulsifier (mono-and diglycerides of fatty acids), flavouring.'
        },
        {
            'id': 'G6BkDXldsjWz7b7Qp1Y4',
            'name': 'Chocolate Orange Whip Bars',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Milk chocolate (27%) (sugar, cocoa butter, whole milk powder, cocoa mass, skimmed milk powder, emulsifiers: soya lecithin, E476), bulking agent (polydextrose), glucose syrup, sugar, water, crisped cereal (6%) (rice flour, sugar, salt), fibre, vegetable fats (palm, palm kernel), candied orange peel (2.1%) (orange peel, sugar, glucose-fructose syrup, acidity regulator: citric acid), natural flavouring, dried egg white, skimmed milk powder, fat reduced cocoa powder (1.1%), flavouring, emulsifier (sunflower lecithin), natural orange oil.'
        },
        {
            'id': 'G6Q8iTLDttlwWn0T03hX',
            'name': 'King Edward Potato Croquettes',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (70%), water, vegetable oil (sunflower/rapeseed), cornflour, rice flour, chickpea flour, maize flour, potato starch, raising agent (E450, E500), ground white pepper, dextrose.'
        },
        {
            'id': 'G6iIBYOVfpt1Zva4mAZu',
            'name': 'Frazzles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Corn (maize), rapeseed oil, bacon flavour seasoning (salt, hydrolysed vegetable protein (contains soya), dextrose, flavour enhancers: monosodium glutamate, disodium 5\'-ribonucleotides, potassium chloride, sugar, yeast powder, flavourings (contains soya), lactose (from milk), colours: paprika extract, sulphite ammonia caramel, yeast extract, dried yeast, whey powder (from milk), smoked maltodextrin, carob flour, antioxidant: rosemary extract, colour: beetroot red).'
        },
        {
            'id': 'G6uSrllqTpSDGIAJxV7T',
            'name': 'Sticky Toffee Pudding',
            'brand': 'Cartmel',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, salted butter (milk, salt), self raising flour (fortified wheat flour: wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1), raising agents: diphosphates, sodium carbonates), whipping cream (milk), dates, free range eggs, raising agent (sodium bicarbonate), vanilla extract.'
        },
        {
            'id': 'GJELVcezfvbHu9ICX3hW',
            'name': 'Beef Burgers',
            'brand': 'Birchwood',
            'serving_size_g': 100.0,
            'ingredients': '86% British beef, water, crumb (rice flour, gram flour, maize starch, salt, dextrose), seasoning (sea salt, black pepper, preservative: sodium metabisulphite, rosemary extract).'
        },
        {
            'id': 'GJdX8QtFpsKbClw1Zd6B',
            'name': 'Mature Cheddar & Red Onion Hand Cooked Crisps',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, rapeseed oil, buttermilk powder (milk), mature cheddar cheese powder, onion powder, red onion powder, yeast extract powder, salt, yeast powder, dried chives, colour (paprika extract).'
        },
        {
            'id': 'GJgPycYHH8c49xjxmNRx',
            'name': 'Christmas Tree Biscuits',
            'brand': 'Aldi',
            'serving_size_g': 25.0,
            'ingredients': 'Wheat flour, milk chocolate (23%) (sugar, cocoa mass, whole milk powder, cocoa butter, palm fat, whey powder (milk), emulsifier: lecithins), palm fat, shea fat, mango fat, sugar, palm fat, whole milk powder, skimmed milk powder, rapeseed oil, wheat starch, glucose syrup, raising agents (sodium carbonates, potassium tartrates, ammonium carbonates), invert sugar syrup, egg powder, emulsifier (lecithins), salt, fruit and plant extracts (blackcurrant concentrate, radish concentrate, lemon concentrate, safflower concentrate, spirulina concentrate), flavouring, coconut oil, glazing agent (beeswax, white and yellow).'
        },
        {
            'id': 'GJzFGxOltXW2HKhXT8dt',
            'name': 'Thai Jungle Curry',
            'brand': 'Sharwood\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, tomatoes (14%), onion (8%), red pepper (7%), coconut milk (coconut extract, water), red pepper purée, chilli purée (3.5%), Thai red curry paste (garlic, red chilli, lemongrass, salt, galangal, onion, coriander leaf, kaffir lime peel, rice vinegar, ground black pepper, ground coriander seeds, ground cumin seeds), mango purée, modified maize starch, ginger purée, lemongrass, potato starch, chilli, concentrated lemon juice (contains sulphites), garlic purée, basil, fish paste (fish sauce: water, anchovy (fish), salt, sugar, fish powder, sunflower oil, salt, water, garlic powder, onion powder, sugar, ground bay leaf), sugar, salt, vegetable bouillon (salt, yeast extract (contains barley), leek powder, sugar, onion powder, garlic powder, flavouring), colour (paprika extract).'
        },
        {
            'id': 'GKBxesiR4qR8WX9UpSkv',
            'name': 'Salsiccia Toscana',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork meat (97%), sea salt, natural flavours, dextrose, sucrose, acidity regulator (E262), antioxidant (E300), garlic (0.05%).'
        },
        {
            'id': 'GKwRbpttYjoJAzujtMY9',
            'name': 'Galaxy Salted Caramel',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, glucose syrup, skimmed milk powder, cocoa butter, palm fat, cocoa mass, milk fat, whey permeate (milk), salt, emulsifier (soya lecithin).'
        },
        {
            'id': 'GLsGIs06CvjHzlHHIGDr',
            'name': 'Shadowhey Isolate',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Protein matrix (whey protein isolate, hydrolyzed whey protein isolate, cross-flow & ultrafiltered whey protein concentrate), skimmed cocoa powder (9%), flavourings, sweeteners (sucralose, acesulfame-K), vanilla crystal.'
        },
        {
            'id': 'GMPREE4IaSsHf07JL1KK',
            'name': 'Chicken Sausage',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken meat (93%) (including 71% chicken breast meat), salt, soya protein, chicken fat, spices, flavour enhancer (monosodium glutamate), glucose syrup, hydrolyzed vegetable protein (corn), spice extracts, stabilizer (sodium citrates), preservative (sodium nitrite).'
        },
        {
            'id': 'GMWou7cElvfHvOubQUBk',
            'name': 'Dairy Fudge',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, glucose syrup, palm oil, unsalted butter from milk (3.8%), sweetened condensed skimmed milk (skimmed milk, sugar), salt, butter oil (from milk), humectant (sorbitols), colour (plain caramel), flavourings, emulsifier (soya lecithins).'
        },
        {
            'id': 'GMqOpDcqXWW3x1mS8FLy',
            'name': 'Sweet Chilli & Garlic Stir Fry Sauce',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, white rice vinegar (6%), glucose-fructose syrup, modified maize starch, red chilli paste (3.5%) (red chilli peppers, salt, acidity regulator: acetic acid), garlic purée (3%), ginger purée, concentrated tomato paste, rapeseed oil, salt, chilli flakes, paprika extract.'
        },
        {
            'id': 'GN9WP3GHL1mTPdfe2u6n',
            'name': 'Deli Meats',
            'brand': 'Asda',
            'serving_size_g': 30.0,
            'ingredients': 'Prosciutto (33%) (pork leg, salt), Milano style salami (33%) (pork, salt, dextrose, white wine, white pepper, black pepper, antioxidant: sodium ascorbate, garlic, preservatives: potassium nitrate, sodium nitrite), chorizo (33%) (pork, salt, smoked paprika, milk powder, dextrose, garlic paste, antioxidant: sodium ascorbate, preservatives: sodium nitrite, potassium nitrate, nutmeg, oregano).'
        },
        {
            'id': 'GNV6eJzD5iYYZ2uaF54q',
            'name': 'Spices Apple Hot Cross Buns',
            'brand': 'Waitrose',
            'serving_size_g': 70.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), soaked sultanas (19%) (sultanas, water), water, candied apple (9%) (apple, sugar, glucose-fructose syrup, acidity regulator: citric acid), spiced Bramley apple compote (5%) (Bramley apple, water, sugar, ginger, cardamom, cinnamon, clove, pimento, black pepper), yeast, invert sugar syrup, rapeseed oil, sugar, wheat gluten, salt, emulsifier (mono-and diglycerides of fatty acids), potato starch, flavourings, mixed spices, ground cinnamon, palm fat, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'GO4y085FFB99tOnxznUJ',
            'name': 'Tomato & Olive Sauce',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato purée, black olives (21%), green olives, sunflower oil, water, olive oil, onion, basil, sugar, garlic purée, capers, sea salt, acidity regulators (lactic acid, citric acid), flavouring, salt, black pepper.'
        },
        {
            'id': 'GOUtmQxdQw6gyqiIDru8',
            'name': 'Chicken Oxo',
            'brand': 'Oxo',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour with added calcium, iron, niacin, thiamin, salt, dried glucose syrup, flavour enhancer (monosodium glutamate), yeast extract, flavourings, chicken fat (3%), potato starch, sugar, concentrated chicken extract (2%), colour (ammonia caramel).'
        },
        {
            'id': 'GOiDHzjFnP8hBRbjXIX6',
            'name': 'Prosciutto Platter',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pork leg, salt, preservative (potassium nitrate).'
        },
        {
            'id': 'GOsgFUDelau60nHOYRNx',
            'name': 'Grated Grana Padano',
            'brand': 'Asda',
            'serving_size_g': 30.0,
            'ingredients': 'Grana Padano cheese (milk), preservative (egg lysozyme).'
        },
        {
            'id': 'GPzqFISh50j1UGWYZhNy',
            'name': 'Crunchy Peanut Butter',
            'brand': 'Maribel',
            'serving_size_g': 100.0,
            'ingredients': '96% roasted peanuts, palm oil, sugar, 1% peanut oil, salt.'
        },
        {
            'id': 'GQO71J9NvGHVnEQv3dpx',
            'name': 'Kimichi',
            'brand': 'Korean Style',
            'serving_size_g': 100.0,
            'ingredients': 'Chinese cabbage (83%), water, radish, salt, sugar, garlic, turmeric powder (0.5%), ginger (0.5%), corn malt syrup, miso paste (water, soya beans, rice flour, salt, alcohol), rice flour.'
        },
        {
            'id': 'GQSwF1VvOPrh2iAXcAAi',
            'name': 'Tortilla Chips Lightly Salted',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Maize flour, sunflower oil, salt.'
        },
        {
            'id': 'GQWob7pw4ZuoZcSNqQ8z',
            'name': 'Raisin & Almond Granola',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flakes (64%), sugar, raisins (13%), rapeseed oil, almonds (3%), honey (1%), sunflower seeds, flavouring.'
        },
        {
            'id': 'GR2UwMQ3Nb93RVAK8s8B',
            'name': 'Peri Chicken',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (79%), water, sugar, mango purée, cider vinegar, lemon juice, red chilli purée, salt, rapeseed oil, spirit vinegar, lime zest, onions, lemon zest, lime juice, garlic purée, maize starch, dried garlic, tomato paste, chilli powder, lime juice concentrate, ground paprika, lemon juice powder, red pepper powder, garlic powder, chilli flakes, parsley, cornflour, paprika powder, acid (citric acid), turmeric powder, smoked paprika powder, citrus fibre, ground thyme, stabiliser (guar gum), rubbed parsley, oregano, cayenne pepper, capsicum extract, smoked salt, lemon oil, paprika extract, black pepper, flavouring, lime oil.'
        },
        {
            'id': 'GREqKkJvJxtPT63MsYLt',
            'name': 'Garlic & Herb Dip',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed oil, water, spirit vinegar, sugar, modified maize starch, salt, acidity regulator (lactic acid), mustard flour, dried parsley, 0.15% garlic powder, natural flavouring, stabilisers (guar gum, xanthan gum), preservative (potassium sorbate), lemon juice concentrate.'
        },
        {
            'id': 'GSNDsw7OVIZzW8r44cdT',
            'name': 'French Salad Dressing',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': '35% rapeseed oil, water, 11% cider vinegar, sugar, 8% dijon mustard (water, mustard seeds, spirit vinegar, salt), white wine vinegar, wholegrain mustard (water, mustard seeds, spirit vinegar, salt), cornflour, concentrated lemon juice, garlic purée, salt, parsley, chives, cracked black pepper, preservative (potassium sorbate).'
        },
        {
            'id': 'GSOvyMOdT9y1PEYx2fa6',
            'name': 'Tomato Soup',
            'brand': 'Gourmet',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato (53%), water, onion, sugar, potato starch, glucose syrup, vegetable oils (palm, sunflower), salt, whole milk, emulsifiers (mono-and diacetyltartaric acid esters of mono-and diglycerides of fatty acids, pentasodium triphosphate), flavourings, yeast extract (contains barley), acid (citric acid), colours (beetroot red, beta carotene), black pepper extract.'
        },
        {
            'id': 'GTKcdtbzxBUAx8SJVkxb',
            'name': 'Tartare Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed oil, water, gherkins, spirit vinegar, sugar, pasteurised egg yolk, cornflour, capers, salt, mustard seeds, dill, preservative (potassium sorbate).'
        },
        {
            'id': 'GTWATH45T3YhVnCN6q6R',
            'name': 'Free From Chocolate And Nut Cones',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, coconut fat, potato starch, chocolate (cocoa mass, sugar, cocoa butter, emulsifier: soya lecithins), glucose-fructose syrup, chickpea flour, toasted almonds (2%), soya protein isolate, fat reduced cocoa powder, bulking agent (polydextrose), maize flour, rice flour, emulsifiers (mono-and diglycerides of fatty acids, rapeseed lecithins), stabilisers (locust bean gum, guar gum, carrageenan), caramelised sugar syrup, colour (annatto norbixin), salt, flavouring.'
        },
        {
            'id': 'GPdbaXCy6DViKstUbfL0',
            'name': 'Wholegrain Seeded Bread Flour',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, wheat flakes, sunflower seeds (6%), wheat gluten, oats (4%), malted wheat flour (malted barley flour, malted rye flour), pumpkin seed (2.6%), linseed (2%), malted barley flour, sugar.'
        },
        {
            'id': 'GVjuJeeqAol9a7yYMLjl',
            'name': 'Skyr Strawberry Icelandic Style Yogurt',
            'brand': 'Graham\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Skyr yogurt with live cultures (milk) (86%), strawberries (7%), sugar, water, rice starch, natural flavouring, concentrated lemon juice.'
        },
        {
            'id': 'GXUlAwC8jaARCLuuZAFW',
            'name': '2 Salmon Fillets',
            'brand': 'Stamford Street Co',
            'serving_size_g': 120.0,
            'ingredients': 'Salmon Salmo salar (fish) (100%).'
        },
        {
            'id': 'GXwGNWUDscAimADeExS7',
            'name': 'The Big 21 Seeds & Grains',
            'brand': 'Warburtons',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal wheat flour, water, seeds and grains blend (18%) (millet seed, malted wheat flakes, oats, sunflower seed, kibbled toasted rye, malted barley flour, brown linseed, sesame seed, kibbled wholemeal einkorn (wheat), kibbled wholemeal emmer (wheat), malted rye flakes, buckwheat, barley flakes, spelt (wheat) flakes, white rice flakes, maize, white quinoa, pumpkin seed, red quinoa, black quinoa, chia seed, golden linseed, poppy seed), wheat gluten, yeast, demerara sugar, salt, glaze (water, pea protein, glucose syrup, rice flour), vegetable oils (rapeseed and sustainable palm), soya flour, emulsifiers (E472e, E471), preservative (calcium propionate), caramelised sugar, flour treatment agent (ascorbic acid (vitamin C)).'
        },
        {
            'id': 'GZFjuYjD7EUwnRmDho6K',
            'name': 'Screwballs',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Syrup, palm oil, vanilla flavour ice cream (partially reconstituted skimmed milk concentrate, guar gum, sodium alginate, water, glucose, anthocyanins, sugar, dextrose powder, emulsifier: mono-and diglycerides of fatty acids, stabiliser: sodium alginate, flavouring, colours: beetroot red, carotenes), raspberry sauce (9%) (syrup, raspberry purée, cornflour, acidity regulators: citric acid, sodium citrates, gelling agent: pectins, flavouring), bubblegum ball (sugar, gum base, glucose, wax, shellac, beetroot red, carotenes, curcumin, emulsifier: gum arabic, glazing agents: carnauba).'
        },
        {
            'id': 'GZmDviFAKvWHf37OtLYl',
            'name': 'Marry Me Chicken Wrap',
            'brand': 'Tesco',
            'serving_size_g': 200.0,
            'ingredients': 'Wheat flour (wheat flour, calcium, folic acid, iron, niacin, thiamin), chicken breast (22%), water, lettuce, rapeseed oil, tomato, palm oil, cornflour, sugar, pasteurised egg yolk, humectant (glycerol), tomato powder, wheat fibre, salt, parmigiano reggiano cheese (milk), spirit vinegar, raising agents (sodium bicarbonate, disodium diphosphate), red wine vinegar, tomato purée, garlic purée, yeast extract, bell pepper powder, paprika, sunflower oil, concentrated lemon juice, acidity regulator (malic acid), sundried tomatoes, basil, white wine vinegar, onion powder, dried basil, garlic, oregano, thyme, black pepper, rosemary, wheat starch, natural basil flavouring, mushroom extract powder, lemon juice powder, garlic oil.'
        },
        {
            'id': 'Ga6Xa85xLLu3Aum3Szn3',
            'name': 'Harissa Paste',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Red pepper purée (62%), rapeseed oil, water, red peppers (4%), red chilli purée (3%), garlic purée, chilli flakes (2%), concentrated lemon juice, smoked paprika, rose petals, paprika extract, sunflower oil, chipotle chilli powder, coriander, caraway, cloves.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 101 (DOUBLED BATCH SIZE!)\n")

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'], current_timestamp, product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g\n")
            updated_count += 1

    conn.commit()
    conn.close()

    return updated_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    updated = update_batch101(db_path)

    print(f"✨ BATCH 101 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {2036 + updated} products cleaned")

    # Check if we hit the 2050 or 2075 milestones
    total = 2036 + updated
    if total >= 2075:
        print("\n🎉🎉 2050 AND 2075 MILESTONES ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
    elif total >= 2050:
        print("\n🎉🎉 2050 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
