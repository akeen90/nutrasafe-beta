#!/usr/bin/env python3
"""
Clean ingredients for batch 84 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch84(db_path: str):
    """Update batch 84 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 84: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'DUI2oQuutlsWsiN0NLdL',
            'name': 'Tiramisu Cheesecake',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British Full Fat Soft Cheese 23% (Full Fat Soft Cheese (Cows\' Milk), Sea Salt), British Whipping Cream (Cows\' Milk), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Brown Sugar, Granulated Sugar, Pasteurised Whole Egg, British Soured Cream (Cows\' Milk), British Single Cream (Cows\' Milk), Rapeseed Oil, Fat Reduced Cocoa Powder, Invert Sugar Syrup, Maize Starch, British Whole Cows\' Milk, Caster Sugar, Pasteurised Egg Yolk, Instant Coffee 0.5%, Glucose, Gelling Agent (Pectin), Raising Agent (Sodium Hydrogen Carbonate).'
        },
        {
            'id': 'DUL17NHai6k74lpL7z2Z',
            'name': 'Acti Leaf Chilled Oat Drink No Added Sugar 1l',
            'brand': 'Acti Leaf',
            'serving_size_g': 250.0,
            'ingredients': 'Water, OATS (10%), Rapeseed Oil, Chicory Root Fibre, Maltodextrin, Acidity Regulator (Potassium Phosphates), Calcium Carbonate, Calcium Phosphates, Salt, Stabiliser (Gellan Gum), Riboflavin, Iodine (Potassium Iodide), Vitamin B12, Vitamin D.'
        },
        {
            'id': 'DLyyEirnNs6AmXGB5sIH',
            'name': 'Wraps Wholemeal',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour 21% (wheat flour, calcium carbonate, iron, niacin, thiamin), wholemeal wheat flour 21%, water, rapeseed oil, humectant (glycerine), raising agents (disodium diphosphate, sodium bicarbonate), emulsifier (mono-and diglycerides of fatty acids), acidity regulator (malic acid), salt, stabilisers (guar gum, carboxymethycellulose), preservatives (calcium propionate, potassium sorbate), flour treatment agent (l-cysteine hydrochloride).'
        },
        {
            'id': 'DLtsiU0OZsII7eXppIAW',
            'name': 'Moo & Blue',
            'brand': 'Pieminister',
            'serving_size_g': 100.0,
            'ingredients': 'British beef (25%), wheat flour (wheat, calcium, iron, niacin, thiamine), water, onion, Stilton cheese (8%), identity preserved palm oil, carrot, red wine, cornflour, tomato puree, salt, polenta, yeast extract, Worcester sauce (water, spirit vinegar, cane molasses, tamarind paste, salt, onion powder, cayenne, garlic, clove), garlic, sugar, Dijon mustard (water, mustard seeds, spirit vinegar, salt), herbs, barley malt extract, leek, wheat protein, green peppercorn, mushroom, caramelised sugar, black pepper, flavouring, butter, rapeseed oil.'
        },
        {
            'id': 'DUowQx3U1T7lbN56Bw0W',
            'name': 'Wholegrain Wraps',
            'brand': 'Fitbakes',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat gluten, Wheat fibre, Whole grain Wheat flour, Vegetable palm fat, Modified Wheat starch, Wheat bran (1.3%), Emulsifier: mono-and Diglycerides of Fatty Acids, Salt, Acidifiers: Malic acid, Citric acid, Raising agents: disodium pyrophosphate, sodium bicarbonate, Preservatives: Potassium sorbate, Calcium Propionate, Stabilizer: Guar Gum, Inactive yeast.'
        },
        {
            'id': 'DVzPaoHf0GaaL0ebx111',
            'name': 'Raspberry & Almond Butter Pressed Fruit & Nut Bar',
            'brand': 'M&S',
            'serving_size_g': 35.0,
            'ingredients': 'Date Paste, Almonds (20%), Roasted Almond Paste (11%), Sultanas, Freeze-Dried Raspberries (3.5%), Chicory Fibre.'
        },
        {
            'id': 'DX4MLImLnGCJqEsYTmDQ',
            'name': 'Napolina Light And Mild Olive Oil',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Olive Oil.'
        },
        {
            'id': 'DXPO4g4KUQe0mNdX28pw',
            'name': 'Free From Red Berry Granola',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten-free oats 69%, Golden syrup, Rapeseed oil, Freeze dried berries 3% (strawberry, blackcurrant, raspberry), Glucose syrup, Concentrated cranberry juice.'
        },
        {
            'id': 'DYL9ezqkkA0jcUJ3fUHE',
            'name': 'Eastman\'s Coleslaw',
            'brand': 'Vimto',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (58%), water, rapeseed oil, carrot (8%), single cream (milk), spirit vinegar, onion, pasteurised egg of which yolk, sugar, white wine vinegar, salt, stabilisers (guar gum, xanthan gum).'
        },
        {
            'id': 'DYWQoLFokmjp1Bn7mMzK',
            'name': 'Skinny Chocaholic Spread Hazelnut 2 Years Prod',
            'brand': 'Skinny',
            'serving_size_g': 5.0,
            'ingredients': 'Sweeteners: maltitols, steviol glycosides; vegetable fats (shea, rapeseed), hazelnuts 10%, whole milk whey powder (from milk), emulsifier: lecithins (sunflower), fat-reduced cocoa powder 4.8%, flavourings.'
        },
        {
            'id': 'DYYBcTSp9D5UysT3YqXa',
            'name': 'Prime Cuts Roast Beef',
            'brand': 'Tesco',
            'serving_size_g': 23.0,
            'ingredients': 'Beef, mineral sea salt, stabilisers (potassium triphosphate, pentasodium triphosphate).'
        },
        {
            'id': 'DYYzXljFPZGNZUr9lPWz',
            'name': 'MILD Cheddar',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mild Cheddar cheese.'
        },
        {
            'id': 'DYxrC5Hp8Y5BWEwkFduO',
            'name': 'Cereal Lion',
            'brand': 'Nestlé',
            'serving_size_g': 100.0,
            'ingredients': 'Cereal grains (whole grain wheat 41%, wheat flour), sugar, glucose syrup, caramel paste 6.3% (sweetened condensed milk, sugar, glucose syrup, caramelised sugar syrup, salt), sunflower oil, chocolate 4.2% (sugar, cocoa powder, cocoa mass, fat-reduced cocoa powder), vitamins and minerals (calcium, niacin, pantothenic acid, iron, vitamin D, vitamin B6, thiamin, riboflavin, folic acid), salt, flavourings, emulsifier: sunflower lecithin, caramelised sugar syrup.'
        },
        {
            'id': 'DZyHjkEMPqccjSf9t0tL',
            'name': 'Muesli With Cocoa And Berries',
            'brand': 'IKEA',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain oat flakes (61%), oligofructose syrup, wholegrain spelt wheat flakes (9%), sunflower oil (sunflower oil, antioxidant E306), coconut chips (3%), cocoa powder (1.9%), freeze-dried strawberries (1%), freeze-dried raspberries (1%), palm kernel oil, concentrated apple juice, salt.'
        },
        {
            'id': 'DUbkJGEme7tqyJK3XUjk',
            'name': 'Sauce Mix Cheese',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato starch, palm fat, maltodextrin, cheese powder 6% (milk), modified maize starch, dried glucose syrup, palm oil, sugar, flavourings (contain milk), whey powder (milk), acidity regulator (trisodium citrate), ground mustard seeds, milk proteins, milk powder (milk), lactose (milk), emulsifier (soya lecithin), stabilisers (dipotassium phosphate, sodium polyphosphate), flavour enhancer (monosodium glutamate), black pepper extract, colour (paprika extract), turmeric extract, onion oil, rosemary extract.'
        },
        {
            'id': 'DayKX5brCpwTCnS5VbDm',
            'name': 'Chorizo',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Gouda cheese (milk) (60%), chorizo pork sausage slices (pork, salt, lactose (milk), paprika, dextrose, sugar, smoked paprika, milk proteins, garlic, paprika extract, acidity regulator (sodium citrates), antioxidants (sodium erythorbate, extracts of rosemary), preservatives (sodium nitrite, potassium nitrate), black pepper, oregano).'
        },
        {
            'id': 'DcI87mOPIu5o4hxiVphM',
            'name': 'Seeded Sourdough Flatbreads',
            'brand': 'Peter\'s Yard',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (Calcium, Iron, Thiamin, Niacin), wholemeal wheat flour, sourdough 19% (rye flour, water), rapeseed oil, seeds 9% (pumpkin seeds, sunflower seeds, poppy seeds, nigella seeds), muscovado sugar, sea salt. Topping: Sea salt, Halen Môn PDO.'
        },
        {
            'id': 'DcI8LHCi7QpYLBI7cSS7',
            'name': 'Vim20',
            'brand': 'Vimto',
            'serving_size_g': 100.0,
            'ingredients': 'Spring water 97%, fruit juices from concentrate 1% (grape, blackcurrant, raspberry), acid (citric acid), Vimto flavouring (including natural extracts of fruits, herbs and spices), preservatives (potassium sorbate, dimethyl dicarbonate, sodium benzoate), sweeteners (sucralose, acesulfame-k).'
        },
        {
            'id': 'Dcjbn5pR7KmVZ9IVV6zI',
            'name': 'Galaxy Ripple (3 Bars)',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Milk chocolate, sugar, cocoa butter, cocoa mass, vegetable fats, whole milk powder, whey powder (from milk), lactose (from milk), emulsifiers (soya lecithins, E476), flavourings.'
        },
        {
            'id': 'Dcr0J2QXa2Xc0b7xx8sV',
            'name': 'Butchers Select 6 Chicken Sausages',
            'brand': 'Aldi',
            'serving_size_g': 98.0,
            'ingredients': 'CHICKEN (80%), Water, Rice Flour, Chickpea Flour, Potato Fibre, Sea Salt, Stabiliser: Diphosphates, Black Pepper, Cornflour, Flavouring, Dextrose, Preservative: Sodium Metabisulphite, Antioxidant: Ascorbic Acid.'
        },
        {
            'id': 'Dd35fEt8tiqKpHMdmMaE',
            'name': 'Heinz By Nature Sweet Potato & Tender Chicken',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetables (53%: sweet potato (18%), tomato (16%), carrot (15%), onion (4%)), rice (27%), water, chicken (8%), extra virgin olive oil.'
        },
        {
            'id': 'Ddg48xcSLcTwXUA933Qt',
            'name': 'Asda Reduced Ketchup',
            'brand': 'Asda',
            'serving_size_g': 20.0,
            'ingredients': 'Tomatoes (189g per 100g of ketchup), spirit vinegar, sugar, modified maize starch, salt, sweetener (steviol glycosides from stevia), flavouring.'
        },
        {
            'id': 'De4pCspNs11m3UNyKTzK',
            'name': 'Popcorners',
            'brand': 'Butterkist',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Rapeseed Oil, Sweet & Salty Flavour (Sugar, Maltodextrin, Salt, Natural Flavouring, Potassium Chloride, Dried Yeast Extract, Emulsifier: Sunflower Lecithins).'
        },
        {
            'id': 'DeFh2nbLIXdvsaDN3j2v',
            'name': 'Cranberries',
            'brand': 'Alesto',
            'serving_size_g': 100.0,
            'ingredients': '62% cranberries, sugar, sunflower oil.'
        },
        {
            'id': 'Df9uUfivIcZYcjm7naUm',
            'name': 'Crunchy Coleslaw Kit',
            'brand': 'Morrisons',
            'serving_size_g': 300.0,
            'ingredients': 'Carrot, white cabbage, red cabbage, mayonnaise (oil, water, pasteurised liquid egg yolk, spirit vinegar from concentrate, salt, sugar, mustard flour).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 84\n")

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

    updated = update_batch84(db_path)

    print(f"✨ BATCH 84 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1486 + updated} products cleaned")

    # Check if we hit the 1500 milestone
    total = 1486 + updated
    if total >= 1500:
        print("\n🎉🎉 1500 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
