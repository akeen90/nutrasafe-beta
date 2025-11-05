#!/usr/bin/env python3
"""
Clean ingredients for batch 98 of messy products - DOUBLED BATCH SIZE (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch98(db_path: str):
    """Update batch 98 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 98: Products with cleaned ingredients (50 products - doubled batch size!)
    clean_data = [
        {
            'id': 'B1Xgh6AiggMYCEK8BTdt',
            'name': 'Ruskoline',
            'brand': 'Generic',
            'serving_size_g': 70.0,
            'ingredients': 'Wheat flour (with added calcium, iron, niacin, thiamin), salt, yeast, colour (paprika extract).'
        },
        {
            'id': 'AvXKBwU9GM3W4mP3EJzD',
            'name': 'Belgian Orange Cocoa Dusted Truffles',
            'brand': 'Moser Roth',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable oils (coconut fat, palm kernel oil), sugar, reduced fat cocoa powder, whey (milk), lactose (milk), emulsifier (sunflower lecithin), natural orange flavouring.'
        },
        {
            'id': 'B55IPTyU2KeVLB0tQtfQ',
            'name': 'Tropical Peach',
            'brand': 'Hip Pop',
            'serving_size_g': 330.0,
            'ingredients': 'Water, apple cider vinegar, chicory root fibre, apple, peach, and mango juices from concentrate, natural flavourings, living cultures (bacillus coagulans).'
        },
        {
            'id': 'B58EjRpcACRfqUsKCzMF',
            'name': 'Grenade Oreo Protein Bite',
            'brand': 'Grenade',
            'serving_size_g': 100.0,
            'ingredients': 'Protein blend (calcium caseinate (milk), whey protein isolate (milk)), milk chocolate with sweetener (20%) (sweetener: maltitol, cocoa butter, whole milk powder, cocoa mass, emulsifier: soya lecithin, natural flavouring), bovine collagen hydrolysate, humectant: glycerol, sweeteners (maltitol, sucralose), palm oil, water, fat-reduced cocoa powder (3%), wheat flour, wheat starch, rapeseed oil, bulking agent: polydextrose, sea salt, emulsifier: soya lecithin, raising agents (ammonium carbonates, sodium carbonates), acidity regulator: sodium hydroxide, flavouring.'
        },
        {
            'id': 'B5QwiG7A2GpeCaV32T7g',
            'name': 'Wholemeal & Rye Bread',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal wheat flour, water, rye flour (5%), sunflower seeds (5%), wheat protein, toasted rye flakes (2%), yeast, dried roasted barley malt extract, fermented wheat flour, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), molasses sugar, salt, vegetable oils and fat (rapeseed oil, palm fat, palm oil), soya flour, spirit vinegar, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'B5axwtC7rfDPZ5d4pbZp',
            'name': 'Caramel Latte',
            'brand': 'Nescafe',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, skimmed milk powder (21%), glucose syrup, coconut oil, coffee (7.5%) (instant coffee (7%), roast and ground coffee), lactose (milk), natural flavourings, acidity regulators (sodium bicarbonate, citric acid), salt.'
        },
        {
            'id': 'B7hOgB73KtftsUFN56Ur',
            'name': 'Bourbon Creams',
            'brand': 'Waitrose Essential',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, sugar, palm oil, fat reduced cocoa powder, glucose syrup, dextrose, wheat starch, raising agents (ammonium hydrogen carbonate, sodium hydrogen carbonate), salt, flavouring.'
        },
        {
            'id': 'B80IY5M6ZojHs35NXztJ',
            'name': 'Unsmoked Rashers',
            'brand': 'Jolly Hog',
            'serving_size_g': 100.0,
            'ingredients': 'British outdoor bred RSPCA Assured pork (96%), sea salt, sugar, preservatives (potassium nitrate, sodium nitrite).'
        },
        {
            'id': 'B8Gf9vIJgm59UXKLPk1i',
            'name': 'Greek Style Salad Cheese',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Full fat soft cheese (milk).'
        },
        {
            'id': 'B8eOVOam1mAnOdHmT2cF',
            'name': 'Cumberland Sausages',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': '72% British pork, water, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), spices (black pepper, white pepper, coriander, nutmeg, mace), salt, emulsifiers (diphosphates, triphosphates), potato starch, dried parsley, preservative (sodium metabisulphite), antioxidant (ascorbic acid), yeast extract, raising agent (ammonium carbonate).'
        },
        {
            'id': 'B9HUWBONbdyne1daHPRn',
            'name': 'Cool Tortilla Chips',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Corn, rapeseed oil, cool original seasoning (whey powder (milk), salt, onion powder, sugar, flavourings, garlic powder, potassium chloride, yeast extract powder, citric acid, lactic acid).'
        },
        {
            'id': 'B9OlMTWlNIQlyeFA9JAo',
            'name': 'Fruit & Nuts',
            'brand': 'M&S',
            'serving_size_g': 35.0,
            'ingredients': 'Cashew nuts (30%), flame raisins (18%), golden raisins (16%), red raisins (15%), pecan nuts (10%), pistachio nuts (10%), sunflower oil, preservative: E220 (sulphites).'
        },
        {
            'id': 'B3OnRtyOUHf79h5ge8Yq',
            'name': 'Deep Crinkle Cut Chips',
            'brand': 'Albert Bartlett',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (92%), sunflower oil, maize starch, rice flour, pea flour, salt, dextrose, turmeric, paprika extract.'
        },
        {
            'id': 'BAz4IFlESyZq8q6BXtNA',
            'name': 'Salad Cream',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, rapeseed oil, sugar, spirit vinegar, modified maize starch, dried egg yolk, mustard powder, salt, stabilisers (guar gum, xanthan gum), preservative (potassium sorbate), colour (riboflavin).'
        },
        {
            'id': 'BOok4nPzmSeio6y9YGdS',
            'name': 'Wafer Thin Honey Cured Ham',
            'brand': 'Spar',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (79%), water, preservatives (potassium lactate, sodium acetates, sodium nitrite), honey, salt, sugar, stabilisers (diphosphates, triphosphates, polyphosphates), antioxidant (sodium ascorbate), demerara sugar, pork extract, dried glucose syrup.'
        },
        {
            'id': 'BR9VFWJBgaEdZEuuD3DR',
            'name': 'Coleslaw',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (32%), mayonnaise (35%) (rapeseed oil, water, sugar, white wine vinegar, spirit vinegar, pasteurised whole egg, stabilisers: guar gum, xanthan gum, salt, mustard powder), carrots (13%), water, double cream (milk) (2%), onions (1%), white wine vinegar, sugar, salt, rapeseed oil, stabilisers (guar gum, xanthan gum), preservative (potassium sorbate), colour (carotenes), flavouring.'
        },
        {
            'id': 'BRCz2UJKLXs8aKH4pxYD',
            'name': 'Just Chicken Mayonnaise',
            'brand': 'Raynor\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Softgrain bread (wheat flour with added calcium, niacin, iron, thiamin, water, malted wheat, kibbled rye, yeast, salt, spirit vinegar, wheat protein, soya flour, emulsifiers: E471, E472e, vegetable oils: rapeseed, palm, flour treatment agent: E300, palm fat, wheat starch, wheat flour), chicken (27%) (chicken, water, salt), seasoned mayonnaise (22%) (water, rapeseed oil, spirit vinegar, stabiliser: E1414, sugar, salt, free range pasteurised egg yolk, stabiliser: E415, black pepper, preservative: E202).'
        },
        {
            'id': 'BRJFjkALut43A32BJPWl',
            'name': 'Madagascan Vanilla Yogurt',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), Madagascan vanilla sauce (18%) (water, sugar, cornflour, glucose syrup, sweetened condensed skimmed milk: skimmed milk, sugar, milk sugar, flavourings, concentrated lemon juice, vanilla powder), sugar.'
        },
        {
            'id': 'BRuRGubAACRkfVcfPam0',
            'name': 'Thai Green Curry Paste',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Water, minced lemongrass (11%), garlic purée (11%), sugar, rapeseed oil, onion purée, minced galangal, modified maize starch, green bird\'s eye chillies (3%), Thai basil (2.5%), soybean paste (water, soya beans, rice, salt), coriander leaf, salt, lime leaves (1.5%), spices (coriander, black pepper, cumin, turmeric), yeast extract, acidity regulator (citric acid), colour (chlorophylls).'
        },
        {
            'id': 'BSFEENbZlk6eJ8Mw6rlz',
            'name': 'Country Grain Loaf',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, water, barley flakes, barley malt flour, wheat protein, rye, vegetable oil (palm, rapeseed), yeast, sugar, fermented cane sugar, starter culture (wheat), salt, oats, sunflower seeds.'
        },
        {
            'id': 'BUZfQ96XAnz9caUUJ7Xi',
            'name': 'Chocolate & Salted Caramel Rice Cakes',
            'brand': 'Tesco',
            'serving_size_g': 21.0,
            'ingredients': 'Milk chocolate (49%) (sugar, cocoa butter, soya lecithins, natural vanilla flavouring), brown rice, salted caramel pieces (15%) (sugar, glucose syrup, butter (milk), salt, cream (milk), water, raising agent: sodium bicarbonate, natural flavouring).'
        },
        {
            'id': 'BWZ5rKXWTgPoFozwadrD',
            'name': 'Roasted Pork Loin Slices',
            'brand': 'Balcerzak',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (92%), salt, stabilizers (E326, E261, E451), fat dextrin, flavours, dextrose, spices, antioxidant: E301, preservative: E250.'
        },
        {
            'id': 'BXaKtIt5jJvXNkY3xTUm',
            'name': 'Raspberry Conserve',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, raspberries, lemon juice from concentrate, gelling agent (pectins), acidity regulators (sodium citrates, citric acid).'
        },
        {
            'id': 'BYIXNk1iGQG6JZaYW9ct',
            'name': 'Fruity Water',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, acid: citric acid, flavourings, acidity regulator: sodium citrates, preservative (dimethyl dicarbonate), sweeteners (acesulfame K, sucralose).'
        },
        {
            'id': 'BYON8fXPkodRHu8aoy6S',
            'name': 'Falafels With Houmous Dip',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Falafels (60%) (chickpeas (27%), water, onions, broad beans (19%), rapeseed oil, chickpea flour, rice flour, coriander, parsley, garlic purée, ground spices: cumin, coriander, black pepper, ginger, cayenne pepper, salt, lemon zest, green chilli purée, cornflour, dextrose), reduced fat houmous (40%) (chickpeas (50%), water, tahini (sesame seed paste) (15%), rapeseed oil, concentrated lemon juice, extra virgin olive oil, salt, garlic).'
        },
        {
            'id': 'Bb07d7HbMnjcFKtUqNzj',
            'name': 'Berry Muesli',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Barley flakes, raisins, wholegrain oat flakes, sultanas, wholegrain wheat flakes, blackcurrant flavoured barley flakes (6%) (barley flakes, sugar, carrot concentrate, blackcurrant concentrate, flavouring), freeze-dried fruits (2%) (blackcurrants, raspberries, strawberries), pumpkin seeds, sunflower seeds, barley malt extract.'
        },
        {
            'id': 'BbePLiuFUTcerl6LITrM',
            'name': 'Apple & Strawberry Juice Drink',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, apple juice from concentrate (36%), citric acid, strawberry juice from concentrate (4%), acidity regulator (sodium citrate), malic acid, sweeteners (sucralose, acesulfame K), colour (anthocyanins), preservatives (potassium sorbate, sodium metabisulphite), flavourings.'
        },
        {
            'id': 'Bdh2vj1INcI010ck9kH5',
            'name': 'Minestrone Soup',
            'brand': 'Baxters',
            'serving_size_g': 100.0,
            'ingredients': 'Water, tomatoes (21%), pasta (durum wheat semolina, water) (14%), carrots, onions, swede, potatoes, peas, haricot beans, cabbage, yellow peas, cornflour, red peppers, leeks, salt, yeast extract, medium fat hard cheese (milk), rapeseed oil, modified maize starch, herbs (parsley, basil, oregano, marjoram, thyme, sage), garlic purée, flavourings, acidity regulator (citric acid), black pepper.'
        },
        {
            'id': 'BeSS471XeO2fwvovQSKU',
            'name': 'Beetroot Salad',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Beetroot (66%), water, carrot, sugar, spirit vinegar, white wine vinegar, red onion, rapeseed oil, cornflour, salt, roasted garlic purée, mustard flour, sea salt, mustard husk, ground pimento, ground turmeric.'
        },
        {
            'id': 'Bek0thpEL3PXUbJJZH55',
            'name': 'Conchiglie Rigate',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Durum wheat semolina.'
        },
        {
            'id': 'Bel3wk3AADjTmLgWr2i2',
            'name': 'Quality Pork Sausages',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork cuts (80%) (pork shoulder (46.5%), pork belly (33.5%)), water, rusk (wheat flour with added calcium carbonate, iron, niacin, thiamin, salt), spices, herbs, emulsifier (E450, E451), citrus fibre, preservative (E223) (sulphite), anti-oxidant (E301).'
        },
        {
            'id': 'BfPqMnB9PIwSNwmaQsbO',
            'name': 'Carrot And Coriander Soup',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Water, carrot (40%), julienne carrot (10%), onion, single cream (milk), cornflour, rapeseed oil, salt, orange juice from concentrate, coriander leaf, ground coriander, garlic powder.'
        },
        {
            'id': 'BgCpnvu9iGBw6bcuLBJe',
            'name': 'Bellarom Gold Unsweetened Cappuccino',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '31% skimmed milk powder, glucose syrup, lactose (milk), 16% coffee blend (instant coffee, finely ground roasted coffee), coconut oil, stabilisers (potassium phosphates, polyphosphates), natural flavourings, salt, anti-caking agent (silicon dioxide).'
        },
        {
            'id': 'C1y6LyQvbIE1yS0NKobL',
            'name': 'Plant Based Oat Granola',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flakes (69%), sugar, barley flakes (5%), soya protein isolate (5%), freeze dried berries (4%) (blackcurrants, raspberries, strawberry pieces), palm oil, flavouring.'
        },
        {
            'id': 'C38KxT8SiLjJGCqFlUCS',
            'name': 'French Croissant',
            'brand': 'Rowan Hill Bakery',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat flour, palm fat, water, sugar, 3.5% concentrated butter (milk), emulsifiers (mono-and diglycerides of fatty acids, mono-and diacetyl tartaric acid esters of mono-and diglycerides of fatty acids), dried skimmed milk, yeast, wheat gluten, salt, natural flavouring (contains alcohol), lactose (milk), thickener: xanthan gum, preservative: calcium propionate, acidity regulator: citric acid, wheat fibre, colour: carotenes, antioxidant: ascorbic acid, egg.'
        },
        {
            'id': 'C46PPjGZKZwUSsBqpTyS',
            'name': 'Red Thai Chicken Curry',
            'brand': 'Asda',
            'serving_size_g': 400.0,
            'ingredients': 'Jasmine rice (38%) (water, rice), cooked chicken breast pieces (18%) (chicken breast fillet, dextrose, potato starch, salt), coconut, water, water chestnuts, red peppers, lemongrass, sugar, fish sauce (anchovy extract (fish), salt, sugar, water), tomato paste, ginger purée, garlic purée, rapeseed oil, lime leaf, lime juice, paprika, red chillies, cornflour, coriander leaf, gelling agent (pectins), colour (paprika extract).'
        },
        {
            'id': 'C5Km7CnequNZtkaGlohG',
            'name': 'Myprotein Pudding Chocolate',
            'brand': 'Müller',
            'serving_size_g': 200.0,
            'ingredients': 'Milk protein concentrate, cream, cocoa powder (2%), modified maize starch, maize starch, acidity regulators (sodium phosphates, sodium carbonates), sweeteners (acesulfame K, sucralose), stabilisers (carrageenan, cellulose gum).'
        },
        {
            'id': 'C5fSrrGlTyiyps5gnr44',
            'name': 'Tuna Chunks',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack tuna (fish), sunflower oil, salt.'
        },
        {
            'id': 'C5jxDPLHF1SujrWckFpy',
            'name': 'Free From Choc Orange Bar',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, cocoa mass, rice syrup, rice starch, inulin, flavouring, rice flour, emulsifier (lecithins).'
        },
        {
            'id': 'C5sCndsmpeyWUCfd1wp7',
            'name': 'Sultanas',
            'brand': 'Belbake',
            'serving_size_g': 70.0,
            'ingredients': 'Sultanas, sunflower oil.'
        },
        {
            'id': 'C8KzyICkGwpL5abkMAro',
            'name': 'Sweet Pancakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, wheat flour, sugar, pasteurised whole egg, rapeseed oil, skimmed milk powder, coconut oil, spirit vinegar, flavourings, acidity regulator (potassium lactate), preservative (potassium sorbate), emulsifier (lecithins), raising agent (sodium carbonates), salt.'
        },
        {
            'id': 'C8WwFvg6rXwJrzIZf9aH',
            'name': 'Pulled Beef With Chianti Sauce And Dumplings',
            'brand': 'Tesco Finest',
            'serving_size_g': 276.0,
            'ingredients': 'Water, cooked pulled beef (21%) (beef, cornflour, sugar, cumin, smoked paprika, garlic powder, mustard powder, smoked onion powder, black pepper), dumplings (wheat flour, water, cheddar cheese (milk), beef fat, raising agents: disodium diphosphate, potassium carbonate, garlic purée, parsley, thyme, salt, white pepper), rapeseed oil, Parisian carrot, borettane onion, Chianti red wine (4%), red wine (4%), beef extract, cornflour, wine vinegar, rapeseed oil, wheat flour, dark muscovado sugar, beef gelatine, garlic purée, concentrated grape must, sugar, tomato paste, salt, concentrated onion juice, beef fat, porcini mushroom powder, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin).'
        },
        {
            'id': 'C8dOMAmCZ3hS5I5ECiUU',
            'name': 'Brazil Nuts Dark Chocolate',
            'brand': 'Biona Organic',
            'serving_size_g': 100.0,
            'ingredients': 'Dark chocolate (58%) (cocoa mass, cane sugar, cocoa butter, natural vanilla aroma), Brazil nuts (40%), glazing agent: gum arabic, sugar, honey.'
        },
        {
            'id': 'C8ka8c7dj6AdAW8W49hu',
            'name': 'Raw Activate',
            'brand': 'Mockingbird Raw Press',
            'serving_size_g': 150.0,
            'ingredients': 'Pressed apples, pressed guava, coconut water, crushed white grapes, pressed passion fruit, chicory root fibre, lime juice, spirulina, vitamins (A, B1, B6, B12, C (ascorbic acid), D3).'
        },
        {
            'id': 'C2TajEkeToOhXE8fMzYF',
            'name': 'Whole Cashews',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic cashew nuts.'
        },
        {
            'id': 'C8mFDgMz3O926RPWsFa0',
            'name': 'Spicy Chicken Fajita',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 322.0,
            'ingredients': 'Fortified wheat flour, tomato, tomato purée, mozzarella cheese, British chicken breast, red pepper, water, cheddar cheese, jalapeño pepper, semolina, red onion, rapeseed oil, yeast, malted wheat flour, red chilli, salt, sugar, basil, lime juice, cayenne pepper, cumin powder, paprika, garlic powder, black pepper, oregano, thyme.'
        },
        {
            'id': 'C9wYC8x7vQ8xIfYLIrwU',
            'name': 'Avocado Oil Spread',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Water, avocado oil (23%), rapeseed oil, palm oil, salt (0.7%), emulsifier: E471, colour: carotenes, vitamin A, vitamin D.'
        },
        {
            'id': 'CAmNtvZR47f5CpsClhxf',
            'name': 'Finest Swiss Milk Chocolate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, dried whole milk, cocoa butter, cocoa mass, hazelnut, emulsifier (soya lecithins), flavouring.'
        },
        {
            'id': 'CAwQiOokXuwqLb7LULnd',
            'name': 'Vanilla Ice Cream With Milk Chocolate Pieces',
            'brand': 'Cadbury Dairy Milk',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted skimmed milk concentrate, milk chocolate (15%) (milk, sugar, cocoa mass, cocoa butter, whey powder (from milk), vegetable fats: palm, shea, emulsifier: E442, E476), glucose syrup, sugar, coconut oil, water, invert sugar syrup, sweetened condensed skimmed milk, whey powder (from milk), fat reduced cocoa powder, emulsifier (E471, E472), stabilisers (E412, E410), flavourings, fructose, carotenes.'
        },
        {
            'id': 'CAz5rwJLQqcWm74ynNqJ',
            'name': 'Mexican Lime & Elderflower Sparkling Fruit Crush',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated water, 4% apple juice from concentrate, 1% Mexican lime juice from concentrate, acid: citric acid, flavourings, sweeteners (aspartame, acesulfame K), preservatives (potassium sorbate, dimethyl dicarbonate).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 98 (DOUBLED BATCH SIZE!)\n")

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

    updated = update_batch98(db_path)

    print(f"✨ BATCH 98 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1886 + updated} products cleaned")

    # Check if we hit the 1900 milestone
    total = 1886 + updated
    if total >= 1900:
        print("\n🎉🎉 1900 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
