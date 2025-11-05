#!/usr/bin/env python3
"""
Clean ingredients for batch 97 of messy products - DOUBLED BATCH SIZE (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch97(db_path: str):
    """Update batch 97 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 97: Products with cleaned ingredients (50 products - doubled batch size!)
    clean_data = [
        {
            'id': '8rDEHlck24WN0dOkLngY',
            'name': 'Slow Cooked Sweet Chilli Wings',
            'brand': 'Tesco',
            'serving_size_g': 190.0,
            'ingredients': 'Chicken wings (78%), sweet chilli glaze (water, sugar, glucose syrup, spirit vinegar, cornflour, red chilli purée, garlic purée, red pepper, dried garlic, sea salt, paprika extract), sugar, fructose, maize starch, spirit vinegar powder, salt, chilli flakes, garlic powder, citric acid, cayenne pepper, dried red pepper, thickener (xanthan gum), chilli powder, flavouring, paprika extract, capsicum extract, garlic extract, ginger extract, fennel extract.'
        },
        {
            'id': '8rMUWkQzbE3xyY5EKaS7',
            'name': 'Co-op Scotch Pancakes',
            'brand': 'Co-op',
            'serving_size_g': 31.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, sugar, rapeseed oil, raising agents (disodium diphosphate, sodium bicarbonate), dried whole egg, salt, natural flavouring.'
        },
        {
            'id': '8rp0RSbfZ1128K76mq3l',
            'name': '50% Reduced Sugar & Salt Tomato Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (249g per 100g of ketchup), spirit vinegar, sugar, salt, flavourings (contain celery), sweetener (steviol glycosides), spice, garlic powder.'
        },
        {
            'id': '8s5oL5E1W6fA8jOVuaqn',
            'name': 'Walkers Extra Flamin\' Hot',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, vegetable oils (sunflower, rapeseed in varying proportions), extra flamin\' hot seasoning (sugar, flavouring, acidity regulators: citric acid, malic acid, dried garlic, salt, potassium chloride, flavour enhancer: monosodium glutamate, dried onion, smoked paprika powder, vegetable concentrate, jalapeño pepper powder, spices, herbs, smoked sunflower oil, smoked maltodextrin, colour: paprika extract), antioxidants (rosemary extract, ascorbic acid, tocopherol rich extract, citric acid).'
        },
        {
            'id': '8s8jK31oZABizGILlNfF',
            'name': 'Chicken Noodle',
            'brand': 'Baxters',
            'serving_size_g': 100.0,
            'ingredients': 'Water, pasta (22%) (water, durum wheat semolina), chicken (7%), onions, carrot (5%), cornflour, flavouring, chicken fat, ginger purée, red chillies, lemon juice, roast chicken stock paste (water, roast chicken stock, yeast extract, salt, sugar, tomato purée, cornflour, vegetable juice concentrates: onion, carrot, leek, parsley), salt, spices.'
        },
        {
            'id': '8sXtVFvWCGuy0eQLCkT8',
            'name': 'Long Grain Rice Japanese Katsu Curry',
            'brand': 'Naked',
            'serving_size_g': 258.0,
            'ingredients': 'Dried rice, potato starch, natural flavourings (celery), palm oil, maltodextrin, sugar, garlic powder, curry powder (2%) (coriander, turmeric, salt, pimento, ginger, fenugreek, garlic powder, black pepper, cumin, red pepper, bay), onion powder, carrot powder, dried chicken, garam masala (coriander, cinnamon, garlic powder, black cardamom, ginger, pimento, clove, cumin, black pepper, turmeric), rapeseed oil, green cardamom, cayenne pepper, spice extracts, ground bay.'
        },
        {
            'id': '8mnB6PZdvYoX49ifzVqm',
            'name': 'Grenade High Protein Oreo',
            'brand': 'Grenade',
            'serving_size_g': 35.0,
            'ingredients': 'Protein blend (calcium caseinate (milk), whey protein isolate (milk)), milk chocolate with sweetener (20%) (sweetener: maltitol, cocoa butter, whole milk powder, cocoa mass, emulsifier: soya lecithin, natural flavouring), bovine collagen hydrolysate, humectant: glycerol, sweeteners (maltitol, sucralose), palm oil, water, fat-reduced cocoa powder (3%), wheat flour, wheat starch, rapeseed oil, bulking agent: polydextrose, sea salt, emulsifier: soya lecithin, raising agents (ammonium carbonates, sodium carbonates), acidity regulator: sodium hydroxide, flavouring.'
        },
        {
            'id': '8mqlxRMrTwygAaBQufsm',
            'name': 'Danish Lighter White Bread',
            'brand': 'Warburtons',
            'serving_size_g': 25.8,
            'ingredients': 'Wheat flour with calcium, iron, niacin (vitamin B3) and thiamin (B1), water, yeast, salt, dextrose, emulsifiers (E472e, E471), soya flour, preservative: calcium propionate, flour treatment agents (ascorbic acid (vitamin C), E920).'
        },
        {
            'id': '8sd7C2MeSsawbnE6SiZL',
            'name': 'Roast Chicken & Bacon',
            'brand': 'M&S',
            'serving_size_g': 200.0,
            'ingredients': 'Roast chicken breast (25%), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, smoked British bacon (11%) (pork belly, curing salt: salt, preservative (sodium nitrate, sodium nitrite), sugar, natural flavouring, antioxidant: E301), rapeseed oil, malted wheat flakes, butter (milk), wheat bran, chicken stock (water, chicken bones, seaweed, yeast extract, shiitake mushrooms, chicken skin, salt, sugar), cornflour, salt, pasteurised egg yolk, yeast (yeast, vitamin D yeast), malted barley flour, vinegar, palm oil, pasteurised egg, emulsifiers (E471, E472e), cracked black pepper, malted wheat flour, concentrated lemon juice, dried fermented wheat flour, potato starch, wheat gluten, sugar, mustard seeds, dried mustard, flour treatment agent: ascorbic acid, palm fat.'
        },
        {
            'id': '8tuKeZe6Q8hUYDyYDN5x',
            'name': 'Crumpets',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), water, sugar, yeast, raising agents (diphosphates, sodium carbonates), spirit vinegar, salt, preservative (potassium sorbate).'
        },
        {
            'id': '8u6w3Go1rO14Mrc1RujZ',
            'name': 'Three Cheese Tender Cauliflower & Broccoli',
            'brand': 'Waitrose',
            'serving_size_g': 210.0,
            'ingredients': 'Whole milk, cauliflower florets (30%), broccoli florets (17%), extra mature cheddar cheese (milk), West Country cheddar cheese (milk), single cream (milk), pecorino cheese (sheep\'s milk), Emmental cheese (milk), wheat flour (wheat flour, calcium carbonate, folic acid, iron, niacin, thiamin), cornflour, salt, mustard powder, parsley, thyme, yeast.'
        },
        {
            'id': '8vhIuxBGGk7TJyer5xYi',
            'name': 'Prawn Cocktail Crisps',
            'brand': 'Snackrite',
            'serving_size_g': 25.0,
            'ingredients': 'Potatoes, sunflower oil, prawn cocktail seasoning (dried whey (milk), sugar, salt, flavourings, citric acid, tomato powder, garlic powder, onion powder, colour: paprika extract), sucralose, black pepper extract.'
        },
        {
            'id': '8wIlfFjaTxYWgPzVrOMa',
            'name': 'Turkish Delight Milk Chocolate',
            'brand': 'Mister Choc',
            'serving_size_g': 100.0,
            'ingredients': '65% milk chocolate (sugar, cocoa butter, whole milk powder, cocoa mass, emulsifier: sunflower lecithins, vanilla extract), glucose syrup, sugar, water, gelling agent: pectins, acidity regulators (sodium citrates, citric acid), colour: anthocyanins, natural flavouring.'
        },
        {
            'id': '91ZviBUMUIGYr2xsFiaV',
            'name': 'Scrambled Oggs',
            'brand': 'Alternative Foods London Ltd',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sunflower oil, chickpea protein, maize starch, thickener (methyl cellulose), nutritional yeast (dried inactive yeast), emulsifier (sunflower lecithin), acid (lactic acid), firming agent (calcium lactate, calcium carbonate), sugar, gelling agent (gellan gum), acidity regulator (sodium citrate), natural flavouring, black pepper, maltodextrin, black salt, colour (beta-carotene).'
        },
        {
            'id': '9DCvvcwX3kx8ti5QBTBb',
            'name': 'Nozeco Still Merlot',
            'brand': 'Nozeco',
            'serving_size_g': 100.0,
            'ingredients': 'Dealcoholised Merlot wine (EU) (93%), rectified concentrated grape must (6%), natural flavourings, carbon dioxide, preservatives (potassium sorbate, dimethyl dicarbonate, potassium bisulfite (sulphites)).'
        },
        {
            'id': '9DYuDxcYPd2WClgLeTPx',
            'name': 'Extra Tasty Half Roast Chicken',
            'brand': 'Asda',
            'serving_size_g': 225.0,
            'ingredients': 'Chicken, salt, dextrose, demerara sugar, white sugar, cane molasses, stabilisers (triphosphates, polyphosphates), yeast extract, black pepper extract, sugar, flavourings, spices, sage extract, dehydrated onion, cornflour, red pepper, parsley, dehydrated garlic, onion extract, rapeseed oil, garlic oil.'
        },
        {
            'id': '9EQJNnuELLbLqETQGQiK',
            'name': 'Deluxe Chunky Breaded Haddock Fishfingers',
            'brand': 'Lidl',
            'serving_size_g': 106.0,
            'ingredients': '60% haddock (fish), breadcrumbs (wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), wheat starch, salt, rice flour, raising agents: sodium carbonates, ammonium carbonates, diphosphates, sugar, yeast extract, dried garlic, mustard, dried onion), sunflower oil, milk protein, glucose syrup, black pepper, rapeseed oil.'
        },
        {
            'id': '9F30oMSQvUx0ijXfVfkR',
            'name': 'Gastro Tempura Battered Fish Fillets',
            'brand': 'Young\'s',
            'serving_size_g': 130.0,
            'ingredients': 'Alaska pollock fillet (58%) (fish), wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), rapeseed oil, water, gram flour, potato starch, wheat starch, salt, maltodextrin, raising agents (diphosphates, sodium bicarbonate), mustard flour, wheat gluten, cocoa butter, onion powder, garlic powder, yeast extract, flavouring (contains mustard), sunflower oil, spice extract.'
        },
        {
            'id': '9FBEVCtwvki7quogAGDJ',
            'name': 'Chickpeas',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chickpeas.'
        },
        {
            'id': '9H3cd8LqG709Rgxaqr3S',
            'name': 'Candyland Black Jack Aniseed Chews',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose syrup, sugar, palm oil, colour (vegetable carbon), hydrolysed pea protein, acid (citric acid), aniseed oil, acidity regulator (sodium citrate).'
        },
        {
            'id': '9HHlliiq5Xf26hZVNIla',
            'name': 'Tikka Masala Curry Paste',
            'brand': 'Ready Set Cook',
            'serving_size_g': 185.0,
            'ingredients': 'Ground spices (16%) (paprika, cumin, coriander, turmeric, ginger, fenugreek, cinnamon, fennel, black pepper, chilli, cardamom), rapeseed oil, spirit vinegar, sugar, tomato paste, salt, crushed coriander seeds, dried onions (1.5%), ginger purée, garlic purée, modified maize starch, paprika extract, coriander leaf.'
        },
        {
            'id': '9HU6d6BlJyFwlHuJeowU',
            'name': 'Chocolate & Orange',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), glucose-fructose syrup, pasteurised free range egg, butter (milk), fat reduced cocoa powder, oranges, pasteurised free range egg white, humectant: glycerol, dried skimmed milk, concentrated orange juice, dried glucose syrup, emulsifiers (E471, soya lecithin), raising agents (E450, sodium bicarbonate), salt, acid: citric acid, gelling agent: pectin (from fruit), flavourings (orange, lemon), acidity regulator: E331, palm oil, caramelised sugar.'
        },
        {
            'id': '9Iw9KgPZr2Px32wa4fGj',
            'name': '8 Dark Choc Ices',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Partially reconstituted skimmed milk concentrate, dark chocolate flavour coating (27%) (coconut oil, sugar, fat reduced cocoa powder, emulsifier: soya lecithins), glucose syrup, sugar, emulsifiers (mono-and di-glycerides of fatty acids), stabilisers (guar gum, carob gum), flavouring, colour (carotenes).'
        },
        {
            'id': '9JrKpmqzHSgMkZLAFNlc',
            'name': 'Organix Soft Oaty Bar',
            'brand': 'Organix',
            'serving_size_g': 23.0,
            'ingredients': 'Wholegrain oats (50.2%), raisins (contains sunflower oil) (19.1%), apple juice concentrate (12.0%), sunflower oil (10.5%), agave fibre (inulin) (8.0%), orange oil (0.2%).'
        },
        {
            'id': '9Ku6zAf5s08HyYEq9AFz',
            'name': 'Parsley Sauce Mix',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato starch, palm fat, maltodextrin, dried glucose syrup, palm oil, milk powder, cornflour, salt, sugar, yeast extract (contains barley), milk proteins, dried parsley, stabilisers (dipotassium phosphate, sodium polyphosphate), emulsifier (soya lecithin), flavour enhancer (monosodium glutamate), flavourings (contain milk), black pepper extract, colour (paprika extract), turmeric extract, onion oil, rosemary extract.'
        },
        {
            'id': '9KvdbmFmrPPZaVXM0qNB',
            'name': 'Koka Beef Noodles',
            'brand': 'Koka',
            'serving_size_g': 100.0,
            'ingredients': 'Noodles (wheat flour, palm oil, salt), seasoning (salt, sugar, hydrolysed soya protein, beef flavouring (contains celery), flavour enhancer: E621, chives, spices).'
        },
        {
            'id': '9KwtgPCwm3oRjeQBXPvo',
            'name': 'Extra Tasty Chicken Slices',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast, sugar, maltodextrin, cornflour, salt, red bell peppers, yeast extract, garlic powder, stabiliser (triphosphates), onion powder, black pepper, barley malt extract, sunflower oil, parsley, flavourings.'
        },
        {
            'id': '9LiRyFRu2VPLLUKVV64O',
            'name': 'Chicken Katsu Bites',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (48%), mayonnaise (rapeseed oil, water, pasteurised free range egg and egg yolk, spirit vinegar, sugar, salt, lemon juice from concentrate, antioxidant: calcium disodium edta, flavouring, colour: paprika extract), wheat flour, teriyaki sauce (water, sugar, soya beans, wheat, salt, modified maize starch, onion purée, spirit vinegar, apple juice concentrate, garlic powder, lime juice concentrate, alcohol), rapeseed oil, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), rice wine, salt, yeast.'
        },
        {
            'id': '9LqTviVLXNlTGRrWoMi3',
            'name': 'Beef Brisket Joint In Gravy',
            'brand': 'Tesco',
            'serving_size_g': 168.0,
            'ingredients': 'Beef brisket (75%), water, red wine (sulphites), onion, corn starch, sugar, sunflower oil, flavouring, salt, colour (plain caramel), rice flour, onion powder, rapeseed oil, allspice.'
        },
        {
            'id': '9NRbZoOl2HPG7bVVBLgJ',
            'name': 'Apple And Blueberry Flavour Porridge Pot',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flakes, skimmed milk powder, sugar, flavourings.'
        },
        {
            'id': '9NiUrllHsPvRgeVWidPY',
            'name': 'Shake N Bake BBQ Chicken',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Maize starch, roasted onion powder, garlic, salt, coriander powder, yeast extract, cayenne pepper (2.5%), dried parsley, flavouring, cumin (1.4%), dried thyme, dried rosemary, smoke flavouring.'
        },
        {
            'id': '9ODycAWyFQyv3MkvI7KL',
            'name': 'Grissini Breadsticks',
            'brand': 'Rivercote',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, 6.9% olive oil (refined olive oils, virgin olive oils), barley malt extract, yeast, iodised salt (salt, potassium iodate), natural flavouring.'
        },
        {
            'id': '9OKeGt7Z1ALsO3Lh9sGj',
            'name': 'Munchy Bars Choc Chips',
            'brand': 'Aldi',
            'serving_size_g': 32.0,
            'ingredients': 'Oat flakes (25%), milk chocolate (24%) (sugar, cocoa butter, whole milk powder, cocoa mass, lactose (milk), emulsifier: lecithins (soya, sunflower), flavouring), glucose syrup, whole wheat flakes (12%) (whole wheat, barley malt extract, salt), palm oil, rice flour, honey, wheat flour, stabiliser: sorbitols, dextrose, colour: plain caramel, salt, emulsifier: sucrose esters of fatty acids.'
        },
        {
            'id': '9V6sIfmqmKkDwstsJWcq',
            'name': 'Red Leicester Cheese',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Red leicester cheese (cheese (pasteurised milk), colour: beta carotene).'
        },
        {
            'id': '9VD8llKuvoBrqN5tSfgF',
            'name': 'British Chicken, Leek & Petit Pois Soup',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, potato (sulphites), carrots (7%), onions, swede (6%), British chicken (5%), leeks (4%), petits pois (3%), British single cream (3%) (cows\' milk), roasted chicken stock (2%) (water, British chicken bones, salt), British chicken stock (water, British chicken bones, onions, carrots, leeks, parsley, garlic, white pepper, bay leaf), salt, cornflour, parsnips (2%), British chicken fat, garlic purée, thyme, sage, black pepper.'
        },
        {
            'id': '9WwCqNyHHPgFgBFJmPC3',
            'name': 'Redcurrant Jelly',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose-fructose syrup, redcurrant juice from concentrate, sugar, gelling agent (pectin), citric acid, acidity regulator (sodium citrate).'
        },
        {
            'id': '9X9aWIyLXxsTMx0RoXw5',
            'name': 'Multiseed Sandwich Slices',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, tapioca starch, rice flour, rapeseed oil, sunflower seed (4%), linseed (4%), psyllium husk powder, potato flakes, humectant (glycerol), treacle, yeast, stabiliser (hydroxypropyl methyl cellulose), maize flour, sugar, salt, millet seeds, poppy seeds, millet flakes, sugar beet fibre, fermented rice flour, fat reduced cocoa powder.'
        },
        {
            'id': '9YkGOqL4uskldPqkGhKf',
            'name': 'Squirty Squash',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, acid: citric acid, orange fruit from comminute (10%), acidity regulator: sodium citrate, sweetener: sucralose, flavouring, colour: carotenes, emulsifier: gum arabic, preservatives (potassium sorbate, sodium metabisulphite, potassium metabisulphite), coconut oil.'
        },
        {
            'id': '9ZMp9xoEWiDZ1qZBjcnM',
            'name': 'Super Berry Granola',
            'brand': 'Jordans',
            'serving_size_g': 100.0,
            'ingredients': 'British wholegrain oat flakes (76%), sugar, vegetable oils (rapeseed and sunflower in varying proportions), freeze dried berries (2.5%) (whole redcurrants, whole blackcurrants, whole blueberries, sliced cranberries), pumpkin seeds (2%), sliced almonds (1.5%), sunflower seeds (1%), honey (1%), natural flavouring.'
        },
        {
            'id': '9a8siAZinfehUAK5zF0H',
            'name': 'Apple, Celery And Walnut Slaw',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (28%), Granny Smith apples (20%), celery (15%), rapeseed oil, raisins (7%), walnuts (6%), water, soured cream (milk), lemon juice, fromage frais (milk), white wine vinegar, pasteurised egg yolk, cornflour, parsley, sugar, salt, vinegar, dried mustard, ground spices (black pepper, allspice, turmeric), mustard bran.'
        },
        {
            'id': '9aTuSJnTMCBTIGflgL37',
            'name': 'All Butter Flapjack',
            'brand': 'Tesco',
            'serving_size_g': 50.0,
            'ingredients': 'Oat flakes (42%), partially inverted sugar syrup, butter (milk) (17%), soft brown sugar, skimmed milk, sugar, salt.'
        },
        {
            'id': '9bmE4ulMecW43hv4wyNK',
            'name': 'Flavourful Reduced Fat Beef Steak Mince',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Reduced fat beef mince (100%).'
        },
        {
            'id': '9cQ6RcsjiGUu4C5bN1bV',
            'name': 'Skittels Stix',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted skimmed milk, sugar, coconut oil, glucose syrup, whey powder (milk), strawberry juice from concentrate (1.2%), coloured sugar pearls (sugar, vegetable fats: shea, palm, concentrates: safflower, lemon, spirulina, apple, radish, blackcurrant, paprika, carrot, hibiscus, emulsifier: E322), skimmed milk powder, red beet juice concentrate, emulsifier (E471), acidity regulator (E330), stabilisers (E410, E412), flavouring, colours (curcumin, annatto norbixin), spirulina concentrate.'
        },
        {
            'id': '9ckW4GpOE9JYjkox3qfp',
            'name': 'Chocolate And Nut Ice Cream Cones',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, glucose syrup, wheat flour, vegetable oils (coconut oil, sunflower oil) in varying proportions, hazelnuts (2.5%), pea protein, fat reduced cocoa powder, emulsifiers (mono-and diglycerides of fatty acids, lecithins), flavouring, stabilisers (locust bean gum, guar gum), sugar cane fibre, salt, colour: plain caramel.'
        },
        {
            'id': '9cs3o4gwVGREPXpMEC6T',
            'name': 'Madeira Party Cake',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '22% vanilla flavour buttercream (sugar, butter (milk), tapioca starch, water, dried glucose syrup, humectant: glycerol, dextrose, maize starch, emulsifier: mono-and diglycerides of fatty acids, flavouring, acidity regulator: sodium hydroxide), sugar, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), egg, rapeseed oil, 9% raspberry jam (glucose-fructose syrup, raspberries, sugar, gelling agent: pectins, concentrated lemon juice), water, 4% edible decorations (sugar, cocoa mass, wheat starch, cocoa butter, coconut oil, rice flour, maize starch, water, palm oil, shea oil, colours: curcumin, carmines, copper complexes of chlorophyll, titanium dioxide, anthocyanins, beetroot red, lutein, paprika extract, fruit, plant and vegetable concentrates: safflower, spirulina, radish, apple, blackcurrant, glazing agents: beeswax, carnauba wax, shellac, stabiliser: acacia gum, thickener: carboxy methyl cellulose, glucose syrup, emulsifier: soya lecithin, flavouring), humectant: glycerol, skimmed milk powder, raising agents (diphosphates, sodium carbonates), maize starch, dried glucose syrup, emulsifier (sodium stearoyl-2-lactylate), preservative: potassium sorbate, acidity regulator: citric acid, flavouring.'
        },
        {
            'id': '9djhcZQ1tdwbx6z8rrJk',
            'name': 'Japanese Style Chicken Curry',
            'brand': 'My Protein Kitchen',
            'serving_size_g': 325.0,
            'ingredients': 'Chicken (35%) (chicken breast, salt), water, onion purée (13%), long grain rice (8%), katsu paste (4%) (yeast extract, salt, rapeseed oil, water, salt, ground spices: turmeric, coriander, fenugreek, cumin, ginger, fennel, star anise, black pepper).'
        },
        {
            'id': '9gGm6Qleg1Bo874Y1ACz',
            'name': 'Lollies',
            'brand': 'Tesco',
            'serving_size_g': 70.0,
            'ingredients': 'Water, fruit juices from concentrate (19%) (orange, pineapple, blackcurrant), sugar, glucose syrup, strawberry purée, stabiliser (guar gum), citric acid, flavourings, colours (anthocyanins, beetroot red, carotenes).'
        },
        {
            'id': '9gM99N16KLNCo2v7iU9c',
            'name': 'Bacon',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'British pork (87%), water, salt, preservatives (sodium nitrite, potassium nitrate), antioxidant (sodium ascorbate).'
        },
        {
            'id': '9h1Mal4UnAkgTBX3EqN5',
            'name': 'Lentil & Vegetable Bolognese',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Red lentils (28%), tomato (14%), onion, red pepper (10%), carrot (8%), tomato purée, tomato juice, mushroom (4%), modified maize starch, maize starch, garlic purée, rapeseed oil, basil, red wine, yeast extract, mushroom extract, salt, sugar, oregano, water, colour (paprika extract), black pepper, leek concentrate, white pepper.'
        },
        {
            'id': '9h4mnVgkVdu9P1NaL0yW',
            'name': 'Aubergine, Mushroom, Edamame Pillows',
            'brand': 'Waitrose',
            'serving_size_g': 25.0,
            'ingredients': 'Wheat flour, aubergine (17%), oyster mushrooms (9%), refined soya bean oil, water, garlic, edamame beans (soya) (3%), shiitake mushrooms (3%), sugar, onion, corn starch, shallot, spring onion, red chilli, ginger, salt, yeast, soya bean, sesame seed oil, parsley, black pepper.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 97 (DOUBLED BATCH SIZE!)\n")

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

    updated = update_batch97(db_path)

    print(f"✨ BATCH 97 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1836 + updated} products cleaned")

    # Check if we hit the 1850 milestone
    total = 1836 + updated
    if total >= 1850:
        print("\n🎉🎉 1850 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
