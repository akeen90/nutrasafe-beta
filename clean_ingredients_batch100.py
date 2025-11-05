#!/usr/bin/env python3
"""
Clean ingredients for batch 100 of messy products - MILESTONE BATCH! (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch100(db_path: str):
    """Update batch 100 of products with cleaned ingredients - MILESTONE BATCH!"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 100: Products with cleaned ingredients (50 products - MILESTONE BATCH!)
    clean_data = [
        {
            'id': 'EyNMyyAmCORMZJlK9LQ1',
            'name': 'Galaxy',
            'brand': 'Galaxy',
            'serving_size_g': 20.0,
            'ingredients': 'Sugar, skimmed milk powder, cocoa butter, cocoa mass, milk fat, whey permeate (milk), palm fat, emulsifier (soya lecithin).'
        },
        {
            'id': 'EzgH9FNxeu0R6pCMb12u',
            'name': 'Milk Chocolate Bunny',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, whole milk powder, cocoa butter, cocoa mass, lactose (milk), whey powder (milk), emulsifier (lecithins), vanilla extract.'
        },
        {
            'id': 'Es6zXd4cgfOdMszzoLxV',
            'name': 'Skinless Chicken Breast Fillets With Smoked Dry Cure',
            'brand': 'Tesco',
            'serving_size_g': 190.0,
            'ingredients': 'Chicken breast fillet (60%), barbecue sauce sachet (25%) (water, sugar, tomato purée, white wine vinegar, concentrated lemon juice, cornflour, molasses, salt, onion, spirit vinegar, soya bean, black treacle, garlic purée, smoked paprika, black pepper, tamarind concentrate, onion powder, garlic powder, white pepper, pimento, ginger, paprika, clove), smoked dry cure streaky bacon (6%) (pork belly, sea salt, sugar, preservatives: potassium nitrate, sodium nitrite), mild cheddar cheese (milk), red leicester cheese with colour: annatto norbixin (milk).'
        },
        {
            'id': 'EsD5LQwKoCk48t87AkGu',
            'name': 'Honeycomb Caramel Wow Bakes',
            'brand': 'Graze',
            'serving_size_g': 100.0,
            'ingredients': 'Rolled oats (39%), vegetable oils (rapeseed, palm), chicory root fibre, golden syrup, liquid sugar, fat-reduced cocoa powder (3%), oat bran (3%), dark compound coating (2%) (sugar, palm kernel oil, fat-reduced cocoa powder, emulsifier: soya lecithin, natural vanilla flavouring), honeycomb (2%) (sugar, glucose syrup, raising agent: sodium bicarbonate), caramel pieces (2%) (sugar, butterfat (milk), palm oil, whole milk powder, skimmed milk powder, salt, emulsifier: soya lecithin), chocolate (cocoa mass, sugar, cocoa butter, fat-reduced cocoa powder, emulsifier: soya lecithin), salt, stabiliser (xanthan gum), emulsifier (sunflower lecithin), natural vanilla flavouring, cane molasses.'
        },
        {
            'id': 'EsC0aGVx9WgzmYJTfbzL',
            'name': 'Splendid Selection Hand Cooked Crisps',
            'brand': 'Splendid Selection',
            'serving_size_g': 50.0,
            'ingredients': 'Potatoes, rapeseed oil, sugar, dextrose, salt, onion powder, yeast extracts, garlic powder, cayenne, fennel, paprika, natural flavourings, citric acid, tomato powder, paprika extract, basil, liquorice powder, China star anise, spice extracts, garlic oil.'
        },
        {
            'id': 'F0Itfg5SuftLWlPtYPsE',
            'name': 'Lloyd Grossman Bolognese Original',
            'brand': 'Lloyd Grossman',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (44%), tomato paste, water, red wine (7%), carrot, onion, celery, garlic purée, sugar, celery purée, rapeseed oil, sea salt, concentrated lemon juice, extra virgin olive oil, oregano, basil, ground black pepper, thyme, ground nutmeg, ground bay leaf.'
        },
        {
            'id': 'F0a2hAoqNHAXsHEMNxDs',
            'name': 'Cottage Pie Recipe Mix',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), tomato powder, flavourings (contains wheat, barley), onion powder, salt, cornflour, garlic powder, barley malt extract, palm oil, ground bay, ground black pepper.'
        },
        {
            'id': 'F1Aprca9vj93SSjhLoYD',
            'name': 'Activia Yogurt',
            'brand': 'Activia',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), apricot (8%), sugar, tapioca starch, carrot juice concentrate, stabilizer (pectin), milk minerals, natural flavourings.'
        },
        {
            'id': 'F1Bae6w8D00apfPeNPI1',
            'name': 'Chef Select Harissa Chicken Bowl',
            'brand': 'Chef Select',
            'serving_size_g': 380.0,
            'ingredients': '37% harissa sauce (water, garlic purée, tomato, onion, red chilli, lemon juice, brown sugar, harissa paste: red pepper, water, spices (paprika, garlic, cayenne pepper, cumin), salt, rapeseed oil, grape vinegar, chilli, tomato paste, paprika, vegetable stock: vegetable stock (water, onion, carrot juice, tomato, herb), glucose syrup, yeast extracts, salt, chicory extract, sugar, rapeseed oil, natural flavouring, coriander leaf, rapeseed oil, low sodium salt (potassium chloride, salt), cumin, thickener: xanthan gum, zinc, niacin), 24% cooked turmeric rice (rice, water, turmeric), 20% cooked chicken (97% chicken, dextrose, tapioca starch, salt), cooked lentils (lentils, water), 4% grilled aubergine, 4% chickpeas, 4% carrot, 3% peppers, 1.6% sultanas (sultanas, sunflower oil), 1.2% sunflower seeds, parsley.'
        },
        {
            'id': 'F1Cq5AnHNregb7zeali4',
            'name': 'Roasted Mushroom Pâté',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Roasted mushrooms (29%) (mushrooms, rapeseed oil), full fat soft cheese (milk) (20%), double cream (milk) (9%), crème fraîche (milk) (9%), water, onions, extra virgin olive oil, tapioca starch, pasteurised egg, porcini mushroom stock (yeast extract, concentrated mushrooms, water, dried porcini mushrooms, salt, sugar, potato flakes, dried lemon juice), garlic purée, salt, sugar, thyme, lemon juice, rosemary, coarse black pepper, ground nutmeg.'
        },
        {
            'id': 'F3AxUjoxiXEMwMRlgpzE',
            'name': 'Tomato Ketchup',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato, sugar, spirit vinegar, salt, beetroot extract powder, flavourings (contains celery), spice, garlic powder.'
        },
        {
            'id': 'F3MdtRBIxtaGNZLT6Dg3',
            'name': 'Gherkins',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 30.0,
            'ingredients': 'Gherkins, water, salt, preservative (potassium metabisulphite (sulphites)), water, sugar, spirit vinegar, dried onions, mustard seeds, red bell peppers, dill seeds, salt, ginger powder, cinnamon powder.'
        },
        {
            'id': 'F3OHd7KCSMlLx4iL1UpA',
            'name': 'Mature Grated Cheese',
            'brand': 'Creamfields',
            'serving_size_g': 100.0,
            'ingredients': 'Medium fat hard mature cheese (milk), potato starch.'
        },
        {
            'id': 'F3SSKV9P2IChaZTQOxXj',
            'name': 'Red Onion Chutney',
            'brand': 'Asda Extra Special',
            'serving_size_g': 100.0,
            'ingredients': 'Red onions (40%), sugar, apples (10%), white wine vinegar, balsamic vinegar PGI (wine vinegar, grape must), muscovado sugar (5%), black treacle, dried onion (1%), salt, garlic purée, ginger purée.'
        },
        {
            'id': 'F4qaUIAeb7ILCcUmCWbn',
            'name': 'Sundried Tomato & Garlic Couscous',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Dried couscous (83%) (durum wheat semolina), maltodextrin, sundried tomato (2.5%), tomato powder (2%), dried tomato (2%), flavourings (contain barley), palm oil, sugar, dried onion, onion powder, garlic powder, red pepper powder, salt, dried parsley, colour (paprika extract), acid (citric acid).'
        },
        {
            'id': 'F5WVM9ZTWbLIaZhBYF4B',
            'name': 'Hot Salsa',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (38%), water, concentrated tomato paste (15%), onions (11%), mixed peppers (11%), spirit vinegar, modified maize starch, green jalapeño peppers, coriander leaf, salt, sugar, chilli powder, dried garlic.'
        },
        {
            'id': 'F5y4TaebVH75v9Yy86Ye',
            'name': 'Thai Sweet Chicken Crisps',
            'brand': 'McCoys',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, sunflower oil, Thai sweet chicken flavour seasoning (sugar, salt, flavourings, yeast extract powder, onion powder, garlic powder, paprika extract, herbs, spices).'
        },
        {
            'id': 'F6AfB7ZeFpvhJPLdjQx1',
            'name': 'Garlic & Coriander Naan Breads',
            'brand': 'Clay Oven Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, water, salt, vegetable oils (palm, palm stearin, rapeseed oil), garlic, coriander, yeast, sugar, preservative (calcium propionate).'
        },
        {
            'id': 'F6ORG2SA9YOBwMKvtKdI',
            'name': 'Peshwari Mini Naans',
            'brand': 'Sharwood\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour with added calcium, iron, niacin, thiamin, water, sultanas (8%), rapeseed oil, sugar, desiccated coconut (3%), raising agents (diphosphates, potassium carbonates), yeast, salt, preservatives (calcium propionate, potassium sorbate), acid (citric acid), ground cinnamon, yogurt powder (milk).'
        },
        {
            'id': 'F6PIWxCgDaNcBjsOxcZF',
            'name': 'Golden Vegetable Savoury Rice',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Long grain rice (86%), dried vegetables (6%) (peas, carrot, red pepper, onion), maltodextrin, flavourings (contains wheat, celery), palm oil, ground turmeric, salt, dried garlic, onion powder, colour (paprika extract).'
        },
        {
            'id': 'Ezu7PEIH1tXWc8X39RUG',
            'name': 'Multigrain Cheerios',
            'brand': 'Cheerios',
            'serving_size_g': 100.0,
            'ingredients': 'Whole grain oat flour (29.6%), whole grain wheat (29.6%), whole grain barley flour (17.9%), sugar, wheat starch, invert sugar syrup, whole grain maize flour (2.1%), whole grain rice flour (2.1%), molasses, calcium carbonate, sunflower oil, salt, colours (carotene, annatto norbixin, caramelized sugar syrup), antioxidant (tocopherols), iron, vitamin C, B3, B5, B9, B6, B2.'
        },
        {
            'id': 'F7xnYvkwLk4JwERfqkTn',
            'name': 'Yeo Valley Mango & Vanilla Yogurt',
            'brand': 'Yeo Valley',
            'serving_size_g': 100.0,
            'ingredients': 'Organic whole milk yogurt, organic mango purée (5%), organic sugar (5%), organic maize starch, organic concentrated lemon juice, organic vanilla extract, natural flavouring.'
        },
        {
            'id': 'F8Lf2MULfnZ2inSsej9a',
            'name': 'Blood Orange Sparkling Water',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated spring water, acid: citric acid, flavourings (blood orange, orange), acidity regulator: E331, preservative: E202, sweetener (steviol glycosides from stevia).'
        },
        {
            'id': 'F8ZETYglZkEb2hFehSB1',
            'name': 'Chicken Shawarma',
            'brand': 'Chef Select',
            'serving_size_g': 380.0,
            'ingredients': '29% cooked bulgur wheat (water, bulgur wheat), 22% green lentils, 20% turmeric couscous (water, couscous (wheat), turmeric), 20% shawarma chicken (94% cooked chicken: chicken, salt, rapeseed oil, cumin, paprika, mint, coriander), carrot, grilled aubergine, sultanas (sultanas, sunflower oil), salt, parsley, mint, cinnamon, 7% mint yogurt (water, natural yogurt (milk), rapeseed oil, sugar, spirit vinegar, tapioca starch, mint, salt, garlic purée, zinc, niacin), 3% pickled red cabbage (red cabbage, spirit vinegar, water, sugar).'
        },
        {
            'id': 'F8jTE6mUKLB9lTtxaxv8',
            'name': 'Strawberry Shortcake',
            'brand': 'Müller',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), sugar, water, wheat flour, cocoa butter, milk powder, coconut oil, modified starch, flavourings, glazing agents (acacia gum, shellac), whey powder (milk), emulsifier (soya lecithin), salt, stabiliser (pectins), colour (carmines).'
        },
        {
            'id': 'F91Ftn5aNsoVg4TetABP',
            'name': 'Barley Water Lemon Squash',
            'brand': 'Robinsons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, lemon juice from concentrate (17%), barley flour (25%), citric acid, sweetener (saccharin), natural flavouring.'
        },
        {
            'id': 'F9TNx7URCCXjOZfQIrUS',
            'name': 'Chocolate Batons',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa solids (cocoa butter, cocoa mass), sugar, full cream milk powder, emulsifier (soya lecithin).'
        },
        {
            'id': 'F9ipGkVvhUiHcUP1NNQO',
            'name': 'Salted Caramel Churro Flavour Popcorn Light',
            'brand': 'Tesco',
            'serving_size_g': 25.0,
            'ingredients': 'Maize, sugar, rapeseed oil, milk sugar, sea salt, buttermilk powder (milk), yeast extract powder, caramelised sugar, salt, acidity regulator (citric acid), cinnamon, paprika extract, molasses extract, flavouring.'
        },
        {
            'id': 'FBNviluKPkdKI1HDTf5p',
            'name': 'Tomato & Mascarpone Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, tomato (35%), mascarpone cheese (milk) (8%), sugar, modified maize starch, whey powder (milk), salt, garlic purée, basil, flavouring, concentrated carrot juice.'
        },
        {
            'id': 'FBnWysOjbNFGdgAu7NBG',
            'name': 'Pumpkin Crispy Fritters',
            'brand': 'Itsu',
            'serving_size_g': 40.0,
            'ingredients': 'Pumpkin (38%), water, panko breadcrumbs (13%) (wheat flour, salt, yeast, sugar), miso (7%) (water, soya beans, rice, salt, alcohol), wheat flour, edamame beans (soya) (6%), red pepper, onion, linseeds (3%), rapeseed oil, chives, tapioca starch, ginger, yeast extract, black pepper, dried parsley.'
        },
        {
            'id': 'FBvPYuPg7hxGWcZA3R9v',
            'name': 'Puff Pastry',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), vegetable oils (palm, rapeseed), water, salt.'
        },
        {
            'id': 'FDaBKyfJD8D0tRmFLeyq',
            'name': 'Crisp Rice Bar',
            'brand': 'Harvest Morn',
            'serving_size_g': 20.0,
            'ingredients': 'Rice, oligofructose, skimmed milk fat glaze (palm kernel fat, sugar, skimmed milk powder, dried glucose syrup, stabiliser: calcium carbonate, emulsifier: lecithins), glucose syrup, sugar, skimmed milk, palm oil, calcium carbonate, humectant: glycerol, barley malt extract, salt, emulsifier (lecithins), natural vanilla flavouring, vitamin D.'
        },
        {
            'id': 'FEkWN1eap63Dd8691CTo',
            'name': 'Cold Milled Flaxseed, Sunflower, Pumpkin & Chia Seeds & Goji Berries',
            'brand': 'Linwoods',
            'serving_size_g': 20.0,
            'ingredients': '46% organic flaxseed, 15% organic sunflower seeds, 15% organic pumpkin seeds, 12.5% organic chia (Salvia hispanica) seeds, 10% organic sun-dried goji berries, waxy maize starch.'
        },
        {
            'id': 'FF5JelJWKUBCBT42T3e4',
            'name': 'Smoked Salmon And Cream Cheese',
            'brand': 'Tesco Finest',
            'serving_size_g': 200.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), smoked salmon (26%) (salmon (fish), sea salt, demerara sugar), water, full fat soft cheese (milk) (11%), oats, rapeseed oil, barley flakes, wheat bran, cornflour, yeast, pasteurised egg yolk, salt, wheat gluten, white wine vinegar, spirit vinegar, emulsifiers (mono-and di-glycerides of fatty acids, mono-and di-acetyl tartaric acid esters of mono-and di-glycerides of fatty acids), lemon zest, concentrated lemon juice, mustard flour, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'FG0KPYHnkczNINYN3y1Y',
            'name': 'Free Peach Passion Fruit Yogurt',
            'brand': 'Danone',
            'serving_size_g': 115.0,
            'ingredients': 'Yogurt (milk), peach (7%), passion fruit (1%), potato and tapioca starch, modified maize starch, acidity regulators (sodium citrate, lactic acid), stabilisers (carrageenan), sweeteners (acesulfame K, sucralose), flavourings, colour (paprika extract), vitamin D.'
        },
        {
            'id': 'FGWeQhnzTmWIT8w4qPco',
            'name': 'Corned Beef Hash',
            'brand': 'Co-op',
            'serving_size_g': 400.0,
            'ingredients': 'Roasted diced potatoes (29%) (potato, rapeseed oil, black pepper), onion (22%), corned beef (21%) (beef, preservatives: potassium lactate, sodium acetate, sodium nitrite, spirit vinegar, salt), potato (20%), water, cornflour, Worcester sauce (water, spirit vinegar, sugar, tamarind paste, onion, garlic, ginger, concentrated lemon juice, ground cloves, chilli), tomato ketchup (tomato, spirit vinegar, sugar, salt, pepper extract, celery extract, pepper), tomatoes, butter (milk), beef stock (water, beef extract, salt, yeast extract, sugar, beef fat, tomato paste, onion, carrots, onion juice concentrate), tomato purée, Dijon mustard (water, mustard seeds, spirit vinegar, salt), rapeseed oil, black pepper.'
        },
        {
            'id': 'FGaWO4YT8EhvmH1zbxVD',
            'name': 'Luxury Hot Cross Buns',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), 23% orange juice soaked fruits (sultanas, raisins, currants, orange juice from concentrate), water, 7% orange juice soaked flame raisins (flame raisins, orange juice from concentrate), yeast, butter (milk), 2.5% mixed peel (orange, lemon peel), wheat gluten, palm oil, potato dextrin, salt, rapeseed oil, sugar, cane molasses, honey, natural flavouring, palm fat, soya flour, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'FGspzZygJgvPwCJG5trV',
            'name': 'The Ghast BBQ',
            'brand': 'Doritos',
            'serving_size_g': 100.0,
            'ingredients': 'Corn (maize), rapeseed oil, BBQ sweet tang flavour (dextrose, acids: sodium acetates, citric acid, malic acid, tomato powder, paprika powder, onion powder, hydrolysed vegetable protein, sugar, flavour enhancer: monosodium glutamate, potassium chloride, flavouring, garlic powder, salt, molasses powder, smoked maltodextrin, smoked sunflower oil, colour: paprika extract), antioxidants (rosemary extract, ascorbic acid, tocopherol rich extract, citric acid).'
        },
        {
            'id': 'FGtpTM37oD2gu06fWBvW',
            'name': 'Veggie Biryani',
            'brand': 'Ella\'s Kitchen',
            'serving_size_g': 100.0,
            'ingredients': 'Organic sweet potatoes (14%), organic onions (11%), organic tomatoes (11%), organic cooked lentils (7%) (water, organic red lentils), organic mangoes (4%), organic spinach (2%), organic extra virgin olive oil (1%), organic herbs and spices.'
        },
        {
            'id': 'FH040cPTSEowT7bomYVi',
            'name': 'British Banana Flavoured 1% Milk',
            'brand': 'Cowbelle',
            'serving_size_g': 200.0,
            'ingredients': '1% fat milk (95%), sugar, skimmed milk powder, concentrated banana juice, stabilisers (carrageenan, xanthan gum, calcium sulphate), flavourings, colour (carotenes).'
        },
        {
            'id': 'FHKICyBD14uNp8hW4Tq2',
            'name': 'Free From Jammy Wheels',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten free oat flour, sugar, raspberry filling (14%) (fructose, humectant: glycerol, dextrose, glucose syrup, raspberry concentrate, palm oil, acidity regulators: citric acid, sodium citrate, calcium citrate, gelling agent: pectin, colour: anthocyanins, emulsifiers: polyphosphates, polysorbate 60, flavouring), palm fat, potato starch, rapeseed oil, soya flour, tapioca flour, palm oil, partially inverted sugar syrup, flavouring, stabiliser (xanthan gum), raising agent (sodium hydrogen carbonate), salt, emulsifier (mono-and diglycerides of fatty acids-vegetable).'
        },
        {
            'id': 'FHd1lEkhNyq9AFXU17LT',
            'name': 'Hot Smoked Salmon Lemon Herb',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Atlantic salmon Salmo salar (fish) (98%), salt, lemon zest, dried parsley, flavouring.'
        },
        {
            'id': 'FIwIxfVhr6dg06hvE8eT',
            'name': 'Gnocchi',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potato purée (86%) (water, dried potato, turmeric, acidity regulator: citric acid), wheat flour, potato starch, vegetable fibre, salt, lactose (milk), flavouring, acidity regulator (lactic acid), milk protein, cornflour.'
        },
        {
            'id': 'FJ5x5gYxDSUETDgKzO4t',
            'name': 'Garlic & Herb',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, niacin (B3), iron, thiamin (B1)), water, unsalted butter (milk) (4%), rapeseed oil, chopped garlic (2%), durum wheat semolina, salt, yeast, chopped parsley, buttermilk powder, concentrated lemon juice.'
        },
        {
            'id': 'FJF11z75MXl3nw21YE90',
            'name': 'Exceptional 6 Cumberland Pork Sausages With Cracked Black Pepper',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (85%), water, rice flour, chickpea flour, salt, cracked black pepper, dextrose (contains sulphites), white pepper, black pepper, herbs, cornflour, nutmeg, preservative (sodium metabisulphite), mace, onion powder, stabiliser (diphosphates), antioxidant (sodium ascorbate).'
        },
        {
            'id': 'FJdhfcJ3KIGRvG7mWcsr',
            'name': 'Perfect Mash Cheddar Cheese Flavoured',
            'brand': 'Idahoan',
            'serving_size_g': 100.0,
            'ingredients': 'Idaho potatoes (74%), vegetable oils (coconut, sunflower, rapeseed), dried cheese (milk) (6%), maltodextrin, salt, sugar, milk solids, skimmed milk powder, cream (milk), flavourings, preservatives (diphosphates, sodium bisulphite (sulphites)), colour (paprika extract), spice extract, antioxidants (tocopherol-rich extract, citric acid).'
        },
        {
            'id': 'FJknK0FOg8GVxpDaGL5F',
            'name': 'Korma Sauce',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, single cream (milk) (17%), creamed coconut (5%), yogurt (4%) (whole milk, skimmed milk powder), sugar, coconut flour, rapeseed oil, modified maize starch, dried onions, concentrated tomato purée (1.5%), ground blanched almonds (1.0%), ground cumin, ginger purée, acidity regulator (lactic acid, citric acid), salt, garlic purée, ground coriander (0.4%), ground paprika, ground fennel, ground turmeric, ground fenugreek (0.2%), ground cinnamon, ground cardamom.'
        },
        {
            'id': 'FMF6OxLKC0QpchTKDlcK',
            'name': 'Southern Fried Chicken Goujons',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken (61%), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), rapeseed oil, water, maize starch, pea fibre, spices, salt, yeast extract, garlic powder, spirit vinegar powder, onion powder, wheat gluten, sugar, yeast, flavouring (contains barley), dextrose, black pepper extract, paprika extract, lemon oil, concentrated lemon juice, thyme extract, evaporated cane syrup, cumin extract.'
        },
        {
            'id': 'FMZdfQ9m3U4bCBVoTLST',
            'name': 'Creamy Butter Chicken',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Tikka marinated chicken breast (28%) (chicken breast (92%), yogurt powder (milk), rice bran oil, tapioca starch, salt, spices: ground paprika, ground black pepper, mace, black pepper extract, tomato paste, garlic paste, ginger paste, colour: paprika extract), water, cream (milk) (15%), onion, crushed tomato (8%), tomato paste (6%), rapeseed oil, butter (milk) (2.5%), ginger purée, brown sugar, garlic, cornflour, spices, garam masala (ground coriander, ground cumin, ground black pepper, ground cinnamon, ground cloves, ground cardamom), salt.'
        },
        {
            'id': 'FMwIADkYO0c9Esfs7HdT',
            'name': 'Beef Lasagne',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British beef (23%), cooked lasagne pasta (durum wheat semolina, water, egg), whole cows\' milk, water, tomato passata, tomato, red wine (4.5%), carrot, onion, mushroom, tomato purée, mature cheddar cheese (2%) (cows\' milk), cornflour, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), single cream (cows\' milk), garlic purée, rapeseed oil, salt, balsamic vinegar (red wine vinegar, white wine vinegar, grape must concentrate), sugar, rosemary, oregano, black pepper, nutmeg, white pepper, bay leaf.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🎉🎉🎉 CLEANING INGREDIENTS - BATCH 100 - MILESTONE BATCH! 🎉🎉🎉\n")

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

    updated = update_batch100(db_path)

    print(f"✨ BATCH 100 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1986 + updated} products cleaned")

    # Check if we hit the 2000 milestone
    total = 1986 + updated
    if total >= 2000:
        print("\n🎉🎉🎉 🎊 2000 MILESTONE ACHIEVED! 🎊 🎉🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
        print("\n🌟 BATCH 100 - A SPECIAL MILESTONE BATCH! 🌟")
