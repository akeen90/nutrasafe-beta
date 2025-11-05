#!/usr/bin/env python3
"""
Clean ingredients for batch 95 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch95(db_path: str):
    """Update batch 95 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 95: Products with cleaned ingredients
    clean_data = [
        {
            'id': '55rEnnWujS0o8xIylOIL',
            'name': 'Funyuns',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Corn (maize), rapeseed oil, onion seasoning (flavourings, onion powder, milk powder, flavour enhancer: monosodium glutamate, dextrose, celery powder), sugar, salt.'
        },
        {
            'id': '55t4OZRHtcmu90dyXlJv',
            'name': 'Roast Potatoes',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (85%), sunflower oil, rapeseed oil, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), salt, modified maize starch, raising agents (disodium diphosphate, sodium bicarbonate), rice flour, dextrose.'
        },
        {
            'id': '56FlANgKdXgsnIKRnygL',
            'name': 'Wafers',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, sugar, vegetable oils (palm, coconut), glucose-fructose syrup, fat-reduced cocoa powder (5%), emulsifier (soya lecithin), raising agent (sodium bicarbonate), salt, flavouring.'
        },
        {
            'id': '56xvxDFfbH1WimL31OqC',
            'name': 'Twisted Sweet & Spicy',
            'brand': 'Cheetos',
            'serving_size_g': 85.0,
            'ingredients': 'Corn (maize), rapeseed oil, sweet & spicy flavour (sugar, acids: sodium acetates, malic acid, flavour enhancers: monosodium glutamate, disodium 5\'-ribonucleotide, flavouring (contains soya, wheat), salt, onion powder, colour: paprika extract, smoked paprika, yeast extract powder).'
        },
        {
            'id': '57ZgToLCKiT5cZfyez8H',
            'name': 'Hash Browns',
            'brand': 'Co-op',
            'serving_size_g': 90.0,
            'ingredients': 'Potato (80%), sunflower oil, potato flakes, onion (3%), potato starch, pea fibre, salt, onion powder, white pepper, dextrose, flavouring, turmeric, antioxidant (ascorbic acid).'
        },
        {
            'id': '57f4dlmcy0vANsZpG7AW',
            'name': 'Vegetable Snack Selection',
            'brand': 'Tesco',
            'serving_size_g': 27.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), onion, rapeseed oil, coriander, tomato purée, salt, ginger purée, coriander powder, cumin powder, concentrated lemon juice, cayenne pepper, poppy seeds, cumin seed, onion seeds, water, yeast.'
        },
        {
            'id': '585T8UxV7duH8BmFar0X',
            'name': 'Cream Of Petits Pois & Bacon Soup',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, petits pois (30%), potatoes, double cream (milk) (4%), smoked bacon (2.0%) (pork, water, salt, dextrose monohydrate, preservative: sodium nitrite), maize starch, butter (milk), skimmed milk powder, salt, yeast extract, sugar, black pepper, natural flavouring.'
        },
        {
            'id': '58HRtVHbwNtfroY1LQXN',
            'name': 'Chunky Chicken Breast',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (96%), acidity regulators (potassium acetate, acetic acid), corn starch, salt, stabiliser (triphosphates), dextrose, glucose syrup.'
        },
        {
            'id': '58HX9dYZBwimjx5AMLfu',
            'name': 'Malt Loaf',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), water, raisins (14%), partially inverted sugar syrup (partially inverted sugar syrup, colour: plain caramel), malt extract (5%), rapeseed oil, salt, yeast, emulsifier (mono-and diglycerides of fatty acids).'
        },
        {
            'id': '5CxUB8nd4YXbLcHAdF4e',
            'name': 'Tomato Ketchup Smokey Bacon Flavour',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g tomato ketchup), spirit vinegar, sugar, salt, flavourings, smoke flavouring, spice and herb extracts (contain celery), spice.'
        },
        {
            'id': '5FLJRpPd5SwjWuumhKL2',
            'name': 'Heinz Tomato Ketchup Imp',
            'brand': 'Heinz',
            'serving_size_g': 15.0,
            'ingredients': 'Tomatoes (200g per 100g tomato ketchup), spirit vinegar, lemon juice from concentrate, potassium chloride, acid (malic acid), citrus fibre, spice and herb extracts (contain celery), sweetener (sucralose).'
        },
        {
            'id': '5KF4NAT5VlT7X1bUdqP4',
            'name': 'Mexican Inspired Fajitas Chicken',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken thighs (91%), sugar, water, paprika, cornflour, salt, garlic powder, maltodextrin, spirit vinegar, onion powder, coriander seed, red chilli purée, tomato purée, tomato powder, cumin, olive oil, ginger purée, lime juice, cayenne pepper, oregano.'
        },
        {
            'id': '5KTyU9CL994E8eJ0qhIt',
            'name': 'Mint Humbugs',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose syrup, sugar, sweetened condensed skimmed milk (skimmed milk, sugar), palm oil, invert sugar syrup, cocoa powder, colour (plain caramel), butter oil (milk), salt, flavouring, emulsifier (soya lecithin).'
        },
        {
            'id': '5L8gq39DIGGoqKCsZLVG',
            'name': 'Taylors Potato Crisps Sea Salt',
            'brand': 'Taylors Snacks Ltd',
            'serving_size_g': 30.0,
            'ingredients': 'Potatoes, high oleic sunflower oil, sea salt.'
        },
        {
            'id': '5LAUVXyrbEkVM6CARTYj',
            'name': 'Spinach And Ricotta Girasoli',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Ricotta and spinach filling (60%) (ricotta cheese (30%) (milk), spinach (10.8%), whey powder (milk), sunflower oil, breadcrumbs (wheat flour, water, olive oil, yeast, salt), dried potato, natural flavourings, salt, nutmeg, black pepper), durum wheat semolina, water, pasteurised egg.'
        },
        {
            'id': '5Lu0uBHBstWMZDFdY9X3',
            'name': 'Cheese And Onion Potato Skins',
            'brand': 'Lidl',
            'serving_size_g': 61.0,
            'ingredients': 'Potato (76%), mature cheddar cheese (10%) (milk), water, onion (4%), sunflower oil, monterey jack cheese (1%) (milk), chives, parsley, mustard powder, salt, garlic, ground black pepper.'
        },
        {
            'id': '5NA1nfGwQHkkhw1MBlxs',
            'name': 'Proviact',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fat free yogurt (80%) (milk), water, peach (8%), modified maize starch, sweeteners (aspartame, acesulfame K), flavouring, colour (carmine), bifidobacterium cultures (BB-12), acidity regulator (citric acid).'
        },
        {
            'id': '5Nc2TpPeEhOyRZXnvH6O',
            'name': 'Huel Ready-to-drink - Iced Coffee Caramel',
            'brand': 'Huel',
            'serving_size_g': 500.0,
            'ingredients': 'Water, pea protein, tapioca starch, rapeseed oil, gluten-free oat flour, ground flaxseed, medium-chain triglyceride powder (from coconut), natural flavourings, soluble vegetable fibre (chicory, corn), sunflower oil powder, minerals (potassium citrate, potassium chloride, calcium carbonate, magnesium phosphate, potassium phosphate), vitamins (C, niacin, E, pantothenic acid, B6, riboflavin, thiamin, folic acid, biotin, K, D, B12), stabiliser (gellan gum), sweetener (sucralose).'
        },
        {
            'id': '5O01eH8mR7GWaGaBVBTB',
            'name': 'Ginger Preserve',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, water, glucose-fructose syrup, ginger, treacle, gelling agent (pectin), citric acid.'
        },
        {
            'id': '5O9cCJK3nKgOvkRlp0eS',
            'name': 'Milk Chocolate Raisins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Milk chocolate coating (58%) (sugar, milk powder, cocoa butter, cocoa mass, palm oil, whey (from milk), emulsifier: sunflower lecithin, glazing agents: gum arabic, shellac), raisins (42%) (raisins, sunflower oil).'
        },
        {
            'id': '5P7WI6tGiL0vv8E0QcIX',
            'name': 'Dark Berry Sugar Free Imp',
            'brand': 'Tango',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated water, fruit juices from concentrate (3%) (blackcurrant (1%), blackberry (1%), raspberry), acids (citric acid), carrot and hibiscus concentrate, acidity regulator (sodium citrate), natural raspberry flavouring with other natural flavourings, sweeteners (aspartame, acesulfame K), preservative (potassium sorbate).'
        },
        {
            'id': '5bVWZ4shXbJyKibMkNvk',
            'name': 'Tomato Ketchup',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g tomato ketchup), spirit vinegar, sugar, salt, spice and herb extracts (contain celery), spice.'
        },
        {
            'id': '5gvRenzPc5ivTS9yy0ng',
            'name': 'Tomato Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g of ketchup), spirit vinegar, sugar, modified maize starch, salt, flavouring.'
        },
        {
            'id': '5pZiNMBQaKSeFKv9epLe',
            'name': '6 Wholemeal Floured Baps',
            'brand': 'Waitrose',
            'serving_size_g': 62.0,
            'ingredients': 'Wholemeal wheat flour, water, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), yeast, rapeseed oil, wheat gluten, salt, sugar, emulsifier (mono-and diacetyl tartaric acid esters of mono-and diglycerides of fatty acids), flour treatment agent (ascorbic acid).'
        },
        {
            'id': '5qETUg2n9YKDuV8p3EnW',
            'name': 'Chow Mein Stir Fry Sauce',
            'brand': 'Co-op',
            'serving_size_g': 150.0,
            'ingredients': 'Water, soy sauce (water, soya beans, salt, wheat), sugar, ginger, garlic, modified maize starch, rice vinegar, sesame oil, salt, colour (plain caramel), yeast extract, preservative (potassium sorbate).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 95\n")

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

    updated = update_batch95(db_path)

    print(f"✨ BATCH 95 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1761 + updated} products cleaned")

    # Check if we hit the 1775 milestone
    total = 1761 + updated
    if total >= 1775:
        print("\n🎉🎉 1775 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
