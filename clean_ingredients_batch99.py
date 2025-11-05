#!/usr/bin/env python3
"""
Clean ingredients for batch 99 of messy products - DOUBLED BATCH SIZE (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch99(db_path: str):
    """Update batch 99 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 99: Products with cleaned ingredients (50 products - doubled batch size!)
    clean_data = [
        {
            'id': 'DGlsjBnU2PXovvaoDH1j',
            'name': 'Grated Cheddar',
            'brand': 'Co-op',
            'serving_size_g': 30.0,
            'ingredients': 'Vegetarian cheddar cheese (milk) (98%), colour (annatto norbixin), anti-caking agent (potato starch).'
        },
        {
            'id': 'DHJTPeqa7gDvwYBuKf5N',
            'name': 'Crunch Mix Salt & Pepper',
            'brand': 'Tesco',
            'serving_size_g': 25.0,
            'ingredients': 'Maize, soya beans, black soya beans, almonds, cashew nuts, sunflower oil, rapeseed oil, black pepper, sea salt, rice flour, sugar, chicory fibre, salt, yeast extract powder, white pepper, flavouring, acid (citric acid).'
        },
        {
            'id': 'DICTTlKMet7OjqqHuWHt',
            'name': '6 Pains Au Chocolat',
            'brand': 'St. Pierre',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, palm fat, chocolate (12%) (sugar, cocoa paste, cocoa butter, emulsifier: lecithins), water, sugar, rapeseed oil, yeast, emulsifiers (mono-and diglycerides of fatty acids, mono and diacetyl tartaric acid esters of mono and diglycerides of fatty acids), salt, wheat gluten, flavourings, heat treated wheat flour, pea protein, deactivated yeast, thickener (cellulose gum), rice flour, glucose syrup.'
        },
        {
            'id': 'DIeXItTAzTOvFOIwGHIB',
            'name': 'Kombucha Raspberry Flavour',
            'brand': 'Lipton',
            'serving_size_g': 250.0,
            'ingredients': 'Carbonated water, sugar, kombucha powder (0.2%) (maltodextrin, kombucha fermented black tea), cider vinegar, acids (malic acid, citric acid), black tea extract (0.12%), natural flavourings, sweetener (steviol glycosides from stevia), antioxidant (ascorbic acid), living cultures (bacillus coagulans).'
        },
        {
            'id': 'DIsm7RwEAmATCAVJx9gF',
            'name': 'Cranberry And Pumpkin Loaf',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, water, pumpkin seed, sugar, cranberry, wholemeal wheat flour, salt, yeast, malted barley flour, rapeseed oil, citric acid.'
        },
        {
            'id': 'DL18BrMIapxgVtrk9ocA',
            'name': 'Honey Roast Ham',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, mineral sea salt, honey, sugar, stabiliser (pentasodium triphosphate), caramelised sugar syrup, salt, flavouring, antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': 'DLI9bmQ204fguYQV2JXf',
            'name': 'Plain Instant Mash Potato',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Potato, palm oil, dried skimmed milk, flavourings (contain milk), milk sugar, milk proteins, salt, black pepper, antioxidant (rosemary extract), colours (algal carotenes, curcumin (contains milk)).'
        },
        {
            'id': 'DMdzLa2pX30iWISPPz8L',
            'name': 'Triple Chocolate Ice Cream',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted skimmed cows\' milk concentrate, chocolate sauce (12%) (water, sugar, glucose syrup, chocolate: cocoa mass, sugar, fat reduced cocoa powder, cocoa butter, emulsifier: soya lecithin), skimmed cows\' milk concentrate, cornflour, whipping cream (cows\' milk), butter (cows\' milk), fat reduced cocoa powder, salt, tapioca starch, glucose syrup, water, sugar, coconut oil, whey powder (cows\' milk), chocolate shavings (1.5%) (sugar, cocoa mass, butteroil (cows\' milk), cocoa butter, emulsifier: soya lecithin), vanilla extract, chocolate (cocoa mass, sugar, cocoa butter, fat reduced cocoa powder, emulsifier: soya lecithin), cocoa mass, milk chocolate (sugar, whole cows\' milk powder, cocoa butter, cocoa mass, whey powder (cows\' milk), skimmed cows\' milk powder, emulsifier: soya lecithin), flavouring, emulsifier (mono-and diglycerides of fatty acids), stabilisers (guar gum, locust bean gum).'
        },
        {
            'id': 'DMtV7TVWyyNI7NwO7Dj2',
            'name': 'Peanut Butter Batons',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 24.0,
            'ingredients': 'Cocoa solids (cocoa butter, cocoa mass), sugar, full cream milk powder, peanut butter paste (10%) (peanuts, sea salt), skimmed milk powder, caramelised sugar, emulsifiers (sunflower lecithin, soya lecithin), sea salt, flavourings, natural colour (paprika).'
        },
        {
            'id': 'DNiwp46WDcg27HKN6apG',
            'name': '4 Beef Quarter Pounders',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Beef (76%), pea flakes, water, cracked black pepper, salt, sea salt, preservative (sodium metabisulphite), coarse Tellicherry pepper, antioxidant (ascorbic acid), rapeseed oil.'
        },
        {
            'id': 'DPdHJvKU7tsGXqEpdvyu',
            'name': 'Cheese & Onion Crispbakes',
            'brand': 'Morrisons Veggie',
            'serving_size_g': 100.0,
            'ingredients': 'Potato, onion (14%), water, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), spring onion (9%), potato flake, mozzarella cheese (milk) (6%), mature cheddar cheese (milk) (6%), medium fat soft cheese (milk) (6%), full fat soft cheese (milk) (5%), rapeseed oil, salt, dextrose, onion powder, spices, yeast.'
        },
        {
            'id': 'DQkV3wunLP1RElecRCTg',
            'name': 'Old School Cake Mix',
            'brand': 'Dr. Oetker',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, wheat flour, rice starch, emulsifiers (polyglycerol esters of fatty acids, mono-and diglycerides of fatty acids), modified starch, raising agents (diphosphates, sodium carbonates), flavouring, thickener (xanthan gum), salt, vegetable oil (coconut), glucose syrup, colouring foods (concentrates from safflower, radish, sweet potato, lemon), anti-caking agent (talc), colour (brilliant blue FCF).'
        },
        {
            'id': 'DR3ZSaXBwwKigzBOaCBv',
            'name': 'Real Mayonnaise',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed oil, water, pasteurised free range egg (6%), spirit vinegar, pasteurised free range egg yolk (1.5%), salt, sugar, concentrated lemon juice, flavourings (contains mustard), stabiliser (xanthan gum).'
        },
        {
            'id': 'DR9CFfv8bRk6jVxXfUi0',
            'name': 'Diet Cola',
            'brand': 'Tesco',
            'serving_size_g': 250.0,
            'ingredients': 'Carbonated water, colour (caramel E150d), acid (phosphoric acid), sweeteners (aspartame, acesulfame K), natural flavourings including caffeine, acidity regulator (sodium citrate).'
        },
        {
            'id': 'DRIBvM1JO8ddkpAQByp1',
            'name': 'Bubblegum Lollies',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Water, skimmed milk concentrate, sugar, dextrose, glucose syrup, vegetarian whey powder (milk), coconut oil, invert sugar syrup, flavouring, emulsifier (mono-and diglycerides of fatty acids-vegetable), stabilisers (guar gum, xanthan gum, locust bean gum), spirulina concentrate, colours (beetroot red, curcumin), acid (citric acid).'
        },
        {
            'id': 'DRQzboqOpolNdd4eYYiq',
            'name': 'Anchovies Fillets In Olive Oil',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Anchovy fillets, Engraulis encrasicolus (fish) (50%), olive oil (40%), salt.'
        },
        {
            'id': 'DSQyggn6AxA3shzTR1RQ',
            'name': 'Plain Flour',
            'brand': 'McDougalls',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (with added calcium, iron, niacin, thiamin).'
        },
        {
            'id': 'DSh6QXAiJBjer6ve0E24',
            'name': 'Orange Dark Chocolate',
            'brand': 'Asda Extra Special',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa mass, cocoa butter, candied orange peel (7%) (orange peel, glucose-fructose syrup, sugar, dextrose, lemon juice from concentrate), emulsifier (soya lecithins), orange oil, vanilla extract.'
        },
        {
            'id': 'DSu8mvpTePzmpU8v8Cga',
            'name': 'Cheddar Ploughman\'s No Mayo',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), tomato, mature cheddar cheese (milk) (18%), water, lettuce, malted wheat flakes, butter (milk), sugar, carrot, spirit vinegar, wheat bran, onion, swede, cauliflower, salt, malt vinegar (barley), wheat gluten, malted barley flour, yeast, emulsifiers (mono-and di-glycerides of fatty acids, mono-and di-acetyl tartaric acid esters of mono-and di-glycerides of fatty acids), courgette, cornflour, date, rapeseed oil, gherkin, apple purée, tomato paste, malted wheat flour, colour (plain caramel), garlic purée, spices, malted barley extract, rice flour, garlic powder, onion powder, concentrated lemon juice, acetic acid, black pepper, flour treatment agent (ascorbic acid), palm oil.'
        },
        {
            'id': 'DU0F8sMJkHa1wsG2BncV',
            'name': 'Ricola Original Swiss Herb',
            'brand': 'Ricola',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, glucose syrup, extract (1%) of Ricola\'s herb mixture (plantain, marshmallow, peppermint, thyme, sage, lady\'s mantle, elder, cowslip, yarrow, burnet, speedwell, mallow, horehound), colour (plain caramel), peppermint oil, mint oil, menthol.'
        },
        {
            'id': 'Ddg48xcSLcTwXUA933Qt',
            'name': 'Reduced Sugar & Salt Ketchup',
            'brand': 'Asda',
            'serving_size_g': 20.0,
            'ingredients': 'Tomatoes (189g per 100g of ketchup), spirit vinegar, sugar, modified maize starch, salt, sweetener (steviol glycosides from stevia), flavouring.'
        },
        {
            'id': 'DfhDPmsl3aAeGOLbn45d',
            'name': 'Protein Vanilla Flavour Milkshake',
            'brand': 'Cowbelle',
            'serving_size_g': 330.0,
            'ingredients': 'Skimmed milk (93%), milk protein (4%), skimmed milk powder, stabilisers (cellulose, cellulose gum, carrageenan), corn flour, natural flavourings, acidity regulator (sodium phosphates), sweeteners (acesulfame K, sucralose).'
        },
        {
            'id': 'DflpUfNOObn0MP0rfuES',
            'name': 'Lentilles Et Légumes',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Water, red lentils (22%), carrots (15%), potato (6%), onions, maize starch, tomato paste, modified maize starch, yeast extract, flavouring, sea salt, garlic purée, vegetable bouillon (salt, sugar, yeast extract, onion powder, potato starch, nutmeg, white pepper, turmeric, acidity regulator: citric acid, lovage extract), onion powder, madras curry powder (black pepper, coriander, cumin, fenugreek, ginger, pimento, red chilli pepper, salt, turmeric, garlic powder, bay, sunflower oil), parsley, turmeric, black pepper.'
        },
        {
            'id': 'DgkrVs5Q0yU30Luu89Tl',
            'name': 'Mini Gingerbread Biscuits',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), butter (milk) (23%), sugar, partially inverted sugar syrup, treacle, ground ginger, salt, raising agent (sodium bicarbonate).'
        },
        {
            'id': 'Dgv1fUuaoeexEf3jDJFr',
            'name': 'Finest Dry Cured Bacon',
            'brand': 'Tesco',
            'serving_size_g': 80.0,
            'ingredients': 'Pork, salt, sugar, preservatives (sodium nitrite, sodium nitrate), antioxidant (sodium ascorbate).'
        },
        {
            'id': 'DbBz3eDKOfCynhMmk9Oi',
            'name': 'Toulouse Style Pork Sausages',
            'brand': 'Lidl',
            'serving_size_g': 120.6,
            'ingredients': '78% British pork, 11% dry cured smoked bacon (95% British pork, sea salt, sugar, preservatives: sodium nitrite, sodium nitrate, antioxidant: sodium ascorbate), water, 2% red wine (sulphites), parsley, salt, dextrose, sage, garlic purée, marjoram, ground nutmeg, ground white pepper, dried onion, ground sage, stabiliser (triphosphates), ground coriander, preservative (sodium metabisulphite), antioxidant (ascorbic acid).'
        },
        {
            'id': 'Di1Mmpc6lH9qicNbBybM',
            'name': 'Cold Milled Flaxseed, Sunflower, Pumpkin & Chia Seeds & Goji Berries',
            'brand': 'Linwoods',
            'serving_size_g': 100.0,
            'ingredients': '46% organic flaxseed, 15% organic sunflower seeds, 10% organic sun-dried goji berries, waxy maize starch, 15% organic pumpkin seeds, 12.5% organic chia (Salvia hispanica).'
        },
        {
            'id': 'DjBFYY0mYS8wCAzuHVtA',
            'name': 'Titan Spread',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Caramel flavoured spread (50%) (sugar, vegetable oil: rapeseed oil, palm oil, caramelised skimmed milk powder (5%): skimmed milk powder, sugar, fat reduced cocoa powder, whole milk powder, whey powder (milk), emulsifier: lecithins (rapeseed, sunflower), ground hazelnuts, flavourings), white hazelnut spread (50%) (sugar, vegetable oil: rapeseed oil, palm oil, whey powder (milk), maltodextrin, ground hazelnuts (1%), emulsifier: lecithins (rapeseed, sunflower), fat reduced cocoa powder).'
        },
        {
            'id': 'DjBQj6AGSrxqalFCguPm',
            'name': 'Tarka Dal',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, split chickpeas (24%), onion, tomato, rapeseed oil, diced garlic, ginger purée, lemon juice, green chilli, salt, chopped coriander, cumin, cumin seeds, asafoetida, turmeric, chilli powder.'
        },
        {
            'id': 'DjLm02LUbUVuck217UVe',
            'name': 'Black Olives',
            'brand': 'Morrisons',
            'serving_size_g': 15.0,
            'ingredients': 'Water, black olives, salt, stabiliser (ferrous gluconate).'
        },
        {
            'id': 'DlOptdyL8bWD39ct5vlv',
            'name': 'Shredded Beef Chilli',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, cherry tomato, red pepper, black turtle beans, sweetcorn, beef (9%), pulled beef (8%) (beef (98%), pea starch, salt), onion, basmati rice, tomato paste, red kidney beans, rapeseed oil, spices, lemon juice, coriander sprigs, garlic purée, chipotle chilli, salt, cocoa powder, mushroom concentrate, cornflour, colour (plain caramel), onion juice concentrate, sugar.'
        },
        {
            'id': 'DiJXSPZljtaVDQveyd9T',
            'name': 'Chip Shop Curry',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Palm oil, potato starch, maltodextrin, caster sugar, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), tomato powder, salt, onion powder, curry powder (coriander, turmeric, fenugreek, paprika, black pepper, cumin, cardamom, bay leaf powder, cloves, cayenne pepper), flavourings (contain wheat), cumin, garlic powder, yeast extract (contain barley), colour (plain caramel), emulsifier (soya lecithins).'
        },
        {
            'id': 'DmmwMPc16aAg17MTyJlz',
            'name': 'Sourdough Seeded',
            'brand': 'Asda Exceptional',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (calcium carbonate, iron, niacin (B3), thiamin (B1)), water, rye flour, sunflower seeds (4%), pumpkin seeds (4%), wholemeal wheat flour, rapeseed oil, malted wheat flake, rice flour, golden linseeds (2%), brown linseeds (2%), malted barley flour, malted barley extract, yeast extract, salt, fermented wheat flour, malted wheat flour.'
        },
        {
            'id': 'DnHqVI1dnB4No44nu2U4',
            'name': 'Belgian Chocolate Brazil Nuts',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Belgian dark chocolate (60%) (sugar, cocoa mass, cocoa butter, vanilla extract, emulsifier: sunflower lecithins), Brazil nuts (39%), tapioca starch, glazing agent (shellac).'
        },
        {
            'id': 'DnU6hy61QBj1CDZgnwp0',
            'name': 'Sourdough Spelt',
            'brand': 'Bertinet Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, sea salt, wholemeal spelt flour (wheat).'
        },
        {
            'id': 'DsJffCQgQsb0TLVmojgo',
            'name': 'Fully Loaded Chilli Cheese Peanuts',
            'brand': 'Snackrite',
            'serving_size_g': 30.0,
            'ingredients': 'Peanuts (90%), rapeseed oil, lactose (milk), sea salt, sugar, yeast extract, onion, chilli powder (0.5%), dried cheese (milk) (0.5%), whole milk powder, acidity regulators (lactic acid, calcium lactate, citric acid), garlic powder, ground smoked paprika, flavouring, tomato powder, ground cumin, ground white pepper, ground turmeric.'
        },
        {
            'id': 'DtKWyFYedCcTcJSziRVF',
            'name': 'Chicken Chipolatas',
            'brand': 'Lidl',
            'serving_size_g': 33.0,
            'ingredients': '85% British chicken, water, 2% chopped sun-dried tomatoes (tomatoes, salt), rice flour, 1% mozzarella cheese (milk), chopped basil, gram flour, salt, dried tomato, garlic purée, demerara sugar, ground black pepper, stabilizer (phosphates), preservative (sodium metabisulphite), white pepper, maize starch, antioxidant (ascorbic acid), rubbed oregano, dextrose.'
        },
        {
            'id': 'DtP6MdjIuAVLHNxbtHjD',
            'name': 'Chicken Satay',
            'brand': 'Taste Original',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (96%), vegetable oil (rapeseed, sunflower), mustard flour, salt, spices (paprika, cayenne pepper, chilli, cumin, coriander, mustard seeds, ginger, galangal, celery seed, lemongrass in variable proportions), sugar, flavourings (contains wheat), stabilizers (diphosphates, triphosphates, polyphosphates), onion powder, yeast extract.'
        },
        {
            'id': 'EBQNcxBbBPsZjMc6mjQ9',
            'name': 'Tex Mex Dip Selection',
            'brand': 'Hardys',
            'serving_size_g': 100.0,
            'ingredients': 'Chilli cheese dip (25%) (mayonnaise (36%): water, rapeseed oil, cornflour, spirit vinegar, egg powder, sugar, antioxidant: citric acid, salt, mature cheddar cheese (milk), tomato, onion, chilli powder, garlic purée), tomato salsa (25%), guacamole (25%) (avocado, tomato, onion, red chilli, coriander), sour cream and chive (25%) (soured cream, mayonnaise, chives).'
        },
        {
            'id': 'ECIgBnjnXM0v7wrkBcve',
            'name': 'Butternut Squash And Sage Risotto Soup',
            'brand': 'Tesco Finest',
            'serving_size_g': 300.0,
            'ingredients': 'Water, butternut squash (17%), risotto rice (8%), onion, single cream (milk), vegetable stock (water, carrot, celery, onion, tomato paste, bay leaf, thyme), arborio rice, butter (milk), white wine (contains sulphites), parmesan cheese (milk), sage, garlic, salt, black pepper.'
        },
        {
            'id': 'ECbEG2u7MCvebiQDcAJc',
            'name': 'Plain Tortilla Wraps',
            'brand': 'Stamford Street Co',
            'serving_size_g': 66.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, niacin, iron, thiamin), water, palm oil, humectant: glycerol, sugar, raising agent: sodium hydrogen carbonate, emulsifier: mono-and diglycerides of fatty acids, acidity regulator: citric acid, salt, preservative: calcium propionate, wheat starch, wheat flour, flour treatment agent: L-cysteine.'
        },
        {
            'id': 'EDVKCUZ7o8tbD4zREBw7',
            'name': 'Peppered Ham Slices',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, salt, sugar, pepper, stabilisers (triphosphates), antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': 'EEH1j0k7EThOPIY91UHC',
            'name': '3 Cheese Pasta Bake',
            'brand': 'Tesco',
            'serving_size_g': 400.0,
            'ingredients': 'Tomato (43%), cooked pasta (durum wheat semolina, water), water, mozzarella, full fat soft cheese (milk) (4%), mature cheddar cheese (milk) (2%), red leicester cheese with colour: annatto norbixin (milk) (2%), onion, tomato purée, cornflour, garlic purée, basil, sugar, salt, black pepper.'
        },
        {
            'id': 'EEvHOroYxOAKzVoO55Ky',
            'name': 'Nduja & Burrata Mezzelune',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': '55% filling (22% ricotta cheese (milk), whey powder (milk), 4.4% sausage: pork, pork fat, salt, spices, acerola powder, leek powder, spice extract, antioxidant: extracts of rosemary, smoke, sunflower oil, breadcrumbs: wheat flour, water, olive oil, salt, yeast, water, mozzarella cheese (milk), 2.2% cheese (milk), cornflour, salt, spices, natural flavourings, parsley, garlic), 45% tomato and egg pasta (durum wheat semolina, 9% whole egg, water, 0.9% tomato powder).'
        },
        {
            'id': 'EGThMf2hqA0FDouaHAy2',
            'name': 'Moroccan Vegetable And Goats Cheese Wellington',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Water, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), vegetable fat spread (vegetable oils: palm oil, rapeseed oil, water, salt, emulsifier: mono-and diglycerides of fatty acids), 8% chickpeas, 4% sweet potato, 4% red pepper, 3.5% goats\' cheese (milk), red lentils, spinach, coconut milk (coconut, water), chopped tomatoes (diced tomatoes, tomato juice, acidity regulator: citric acid), whipping cream (milk), modified maize starch, seasoning (sugar, ground spices: ginger, paprika, cinnamon, cumin, allspice, turmeric, black pepper, chilli, coriander, nutmeg, salt, dried tomato, dried garlic, spice extract), apricots (apricots, rice flour, preservative: sulphur dioxide), dates (dates, rice flour), ginger purée, garlic purée, potato flake (potato, emulsifier: mono-and diglycerides of fatty acids), seasoning (glucose syrup, cheese powder (milk), yeast extract, salt, natural flavouring (milk), sunflower oil), stabiliser (hydroxypropyl methylcellulose), coriander, yeast extract, salt, dried glucose syrup, cornflour, milk proteins, colour (carotenes).'
        },
        {
            'id': 'EHBFWXN7u5l1KXQMxWYn',
            'name': 'Plain Crackers (Gluten Free)',
            'brand': 'Tesco',
            'serving_size_g': 3.8,
            'ingredients': 'Corn starch, rice flour, sunflower oil, modified maize starch, pasteurised egg, sugar, salt, dextrose, thickener (guar gum), pea fibre, raising agents (sodium bicarbonate, monocalcium phosphate, ammonium hydrogen carbonate), potato fibre, psyllium fibre, flavourings, bamboo fibre, flax seed fibre.'
        },
        {
            'id': 'EHmE0ejCbfArJFnGHMNM',
            'name': 'Sour Blue Lollies',
            'brand': 'Gianni\'s',
            'serving_size_g': 72.0,
            'ingredients': 'Water, sugar, glucose syrup, raspberry juice from concentrate (3.5%), acids (citric acid, malic acid), flavouring, stabiliser (guar gum), plant extract (spirulina concentrate).'
        },
        {
            'id': 'EIxB7aXSbtKT2ItfqENU',
            'name': 'Kendamil Organic First Infant Milk',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic whole milk, organic demineralised milk whey protein powder, organic skimmed milk, organic vegetable oils (sunflower, coconut, rapeseed), organic galacto-oligosaccharides (from milk), calcium citrate, sodium citrate, potassium chloride, calcium lactate, magnesium chloride, oil from the microalgae Schizochytrium sp., vitamin C, potassium hydroxide, choline bitartrate, inositol, oil from Mortierella alpina, taurine, nucleotides (cytidine-5\'-monophosphate, disodium uridine-5\'-monophosphate, adenosine-5\'-monophosphate, disodium inosine-5\'-monophosphate, disodium guanosine-5\'-monophosphate), iron pyrophosphate, zinc sulphate, vitamin E, niacin, pantothenic acid, copper sulphate, thiamin, riboflavin, vitamin A, vitamin B6, manganese sulphate, folic acid, potassium iodide, sodium selenite, vitamin K, vitamin D3, biotin, vitamin B12.'
        },
        {
            'id': 'EJX8yjE1XQR2UoSOGVH4',
            'name': 'Replenish Raspberry & Rose',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated water, fruit juices from concentrate (25%) (apple (23%), raspberry (2%)), acid (citric acid), minerals (calcium lactate gluconate, magnesium citrate), natural raspberry and rose flavourings with other natural flavourings, botanical extracts (damiana, oak bark, Chinese ginseng), vitamins (C, niacin, thiamin, B6, riboflavin, B12), preservative (potassium sorbate), sweetener (steviol glycosides), natural colour (anthocyanins).'
        },
        {
            'id': 'EKqiJ9zVurOOEO9kyDhX',
            'name': 'Mint Sauce',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fresh English mint (42%), spirit vinegar, sugar, water, balsamic vinegar, white wine vinegar, salt, stabiliser (xanthan gum), antioxidant (ascorbic acid), mint oil.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 99 (DOUBLED BATCH SIZE!)\n")

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

    updated = update_batch99(db_path)

    print(f"✨ BATCH 99 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1936 + updated} products cleaned")

    # Check if we hit the 1950 milestone
    total = 1936 + updated
    if total >= 1950:
        print("\n🎉🎉 1950 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
