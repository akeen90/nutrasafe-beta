#!/usr/bin/env python3
"""
Clean ingredients for batch 81 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch81(db_path: str):
    """Update batch 81 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 81: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'CF4NJzD0G7ZNN2t2YjrU',
            'name': 'Abricots Sec',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Partially Rehydrated Dried Apricots (99%), Preservatives: Potassium Sorbate, Sulphur Dioxide.'
        },
        {
            'id': 'CFyed65YBu4xkq9UxuTL',
            'name': 'Greggs Festive Bakes',
            'brand': 'Greggs',
            'serving_size_g': 158.0,
            'ingredients': 'Water, Fortified Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Cooked Diced Chicken Breast (10%) (Chicken Breast, Salt, Dextrose), Sage and Onion Stuffing Balls (5%) (Water, Rusk (Wheat), Dried Herbs, Dried Onions, Salt, Flavouring, Sunflower Oil, Yeast Extract), White Sauce with Sage (Modified Starch, Dried Onion, Skimmed Milk Powder, Salt, Dried Sage, Yeast Extract, Cream Powder (Milk), Whey Powder (Milk), Flavouring), Cooked Diced Sweetcure Streaky Bacon with Smoke Flavouring (3%) (Pork Belly, Sugar, Salt, Emulsifier (Triphosphates), Smoke Flavouring, Honey, Preservative (Sodium Nitrite)), Cranberry and Red Onion Relish (2%) (Sugar, Water, Cranberries, Caramelised Red Onions (Red Onions, Sugar, Barley Malt Vinegar), Concentrated Redcurrant Juice, White Wine Vinegar, Dehydrated Onion, White Balsamic Vinegar (White Wine Vinegar, Concentrated Grape Must), Modified Starch, Salt, Ground Black Pepper), Seasoned Crumb Topping (Rusk (Wheat), Cheese Powder (Milk), Palm Oil, Potato Powder, Dried Parsley, Mustard Powder, Ground White Pepper, Flavouring, Colour (Paprika Extract)), Glaze (Water, Sunflower Oil, Rapeseed Oil, Modified Starch, Milk Protein, Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Mono- and Diglycerides of Fatty Acids), Skimmed Milk Powder, Stabiliser (Carboxy Methyl Cellulose, Carrageenan, Cellulose), Acidity Regulator (Sodium Phosphates), Colour (Carotenes)), Cream Powder (Milk), Rapeseed Oil, Sweetened Dried Cranberries (1%) (Cranberries, Sugar, Sunflower Oil), Wheat Gluten, Modified Starch, Salt, Stabiliser (Hydroxypropyl Methyl Cellulose).'
        },
        {
            'id': 'CGHse9En2uek7ePLSSaf',
            'name': 'Braised Steak Root Mash',
            'brand': 'S W',
            'serving_size_g': 550.0,
            'ingredients': 'Carrot (25%), cooked diced beef (18%) (beef (99%), salt), swede (18%), water, potato (13%), onion purée, roasted onion, garlic purée, beef bouillon (yeast extract, potato starch, salt, flavouring, chicory extract, beef stock (beef extract, onion powder, carrot extract, tomato powder, dried lovage), tomato paste, celery, mushrooms, Worcester sauce (water, white vinegar, sugar, salt, tamarind extract, onion powder, barley malt extract, garlic powder, ground ginger, concentrated lemon juice, clove powder, chilli powder), maize starch, salt, herbs, spices, barley malt extract, seaweed granules.'
        },
        {
            'id': 'CGYUaZy13Amd2afW8DCR',
            'name': 'Marvellous Creations Easter Egg',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, sugar, cocoa butter, glucose syrup, cocoa mass, vegetable fats (palm, shea), maize starch, emulsifiers (E442, E476, soya lecithins, sunflower lecithins), whey powder (from milk), fat reduced cocoa powder, lactose (from milk), whole milk powder, glazing agents (gum arabic, beeswax, shellac, carnauba wax), colours (anthocyanins, E101, carotenes, beetroot red, E171, E172), fibre, acid (citric acid), flavourings.'
        },
        {
            'id': 'CGZK6WgRnDRvdqfdUA9R',
            'name': 'Deli Green Pitted Olives',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Green Olives, Water, Salt, Acidity Regulator: Citric Acid, Antioxidant: Ascorbic Acid.'
        },
        {
            'id': 'CGceOGBlLRTEBj7hw1i6',
            'name': 'Oat Shortbread',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Oats (32%), butter (milk) (32%), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), sugar, salt.'
        },
        {
            'id': 'CHJUHG3fzeG73By0j5hj',
            'name': 'Pate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Roasted Mushrooms 24%, Mushroom, Rapeseed Oil, Full Fat Soft Cheese (Milk) 17%, Water, Crème Fraîche (Milk), Single Cream (Milk), Onion, Lemon Juice, Rapeseed Oil, Tapioca Starch, Pasteurised Egg, Garlic Purée, Spirit Vinegar, Sugar, Salt, Mushroom Concentrate, Yeast Extract, Thyme, Rehydrated Potato, Porcini Mushroom, Black Pepper, Nutmeg, Lemon Juice Powder.'
        },
        {
            'id': 'CHUC38WID8gfrdQeHEe6',
            'name': 'Smoked Bacon',
            'brand': 'Oakhurst',
            'serving_size_g': 43.0,
            'ingredients': 'PORK 87%, Water, Salt, Antioxidant: Sodium Ascorbate, Preservatives: Sodium Nitrite, Potassium Nitrate.'
        },
        {
            'id': 'CHiut3EZL0vZdJz7F0tw',
            'name': 'Muffin',
            'brand': 'The Bakery At Asda',
            'serving_size_g': 66.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, yeast, wheat semolina, wheat protein, sugar, salt, soya flour, spirit vinegar, vegetable oils and fat (palm oil, palm fat, rapeseed oil), preservative (potassium sorbate), flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'CHzmmVVi4DW1UaTZ3oGo',
            'name': 'Protein Pot: Lemon Cheesecake',
            'brand': 'Brooklea',
            'serving_size_g': 200.0,
            'ingredients': 'QUARK (MILK) 89%, Glucose Syrup, Sugar, Flavouring, Salted Butter (Butter (Milk), Salt), Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar), Concentrated Lemon Juice, Thickener: Agar, Lemon Oil, Colour: Carotenes.'
        },
        {
            'id': 'CIRiMYqRsXArkWoR9XyP',
            'name': 'Sauce Granules Cheese',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Palm oil, cornflour, potato starch, skimmed milk powder, maltodextrin, salt, cheese powder (from milk), flavour enhancer (monosodium glutamate), onion powder, yeast extract (contains barley), flavouring (contains milk), emulsifier (soya lecithins), colour (annatto).'
        },
        {
            'id': 'CIehAGSup1GLvYN5UiUh',
            'name': 'Soft Foams',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Maltitols, Steviol Glycosides from Stevia, Erythritol, Modified potato starch, Acid: Citric Acid, Potato Protein, Hydrolysed Pea Protein, fruit, vegetable and Plant Concentrates (Radish, Safflower, Carrot, Blackcurrant), Glazing Agent: Carnauba Wax.'
        },
        {
            'id': 'CJO2Ivn4jz2jlq7nNdhb',
            'name': 'Maggi So Juicy Garlic Chicken 30G',
            'brand': 'Maggi',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetables (potato, tomato, onion 8.5%, parsnip), garlic 24%, table salt, sugar, herbs and spices (parsley 2.5%, black pepper, paprika, ginger, coriander, marjoram, cayenne chili pepper), maize starch, sunflower oil, vinegar, beetroot concentrate, lemon juice concentrate, flavouring.'
        },
        {
            'id': 'CK9dURASQBuFspfHPuwz',
            'name': 'Dairy Milk Box',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, sugar, cocoa butter, glucose syrup, vegetable fats (palm, shea), glucose-fructose syrup, cocoa mass, hazelnuts, whey powder (from milk), emulsifiers (e442, soya lecithin).'
        },
        {
            'id': 'CKmgFGnsas8RhIoNlORg',
            'name': 'Fiery Mayo',
            'brand': 'Batts',
            'serving_size_g': 15.0,
            'ingredients': '55% Rapeseed Oil, Sugar Syrup (Sugar, Water), 10% Chilli Purée (56% Red Peppers, Water, Vinegar, Sugar, Salt), Spirit Vinegar, 2% Garlic Purée, Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol), Water, 3.8% Apple Cider Vinegar, Rice Wine Vinegar, 1% Ginger Purée, Potato Starch, Chilli Flakes, Mustard Flour, Acidity Regulator: Citric Acid, Yeast Extract, Stabiliser: Guar Gum, Modified Maize Starch, Preservatives: Potassium Sorbate, Calcium Disodium EDTA, Concentrated Lemon Juice, Chilli Powder, Mushroom Flavouring, Caramelised Sugar Syrup, Colour: Paprika Extract.'
        },
        {
            'id': 'CLVeu2LLRXd1buCc7E5D',
            'name': 'Free From Cheese Flavour Nachos',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Maize flour, sunflower oil, rice flour, salt, sugar, yeast extract powder, cocoa butter, flavouring, paprika extract, acidity regulator (citric acid), rosemary extract, cayenne pepper extract.'
        },
        {
            'id': 'CLsiCa8jQPXy9N3pOQDd',
            'name': 'Tomato Soup',
            'brand': 'Waitrose',
            'serving_size_g': 300.0,
            'ingredients': 'Water, tomato (24%), single cream (milk) (9%), carrot, onion, tomato purée, sugar, cornflour, sherry vinegar, rapeseed oil, salt, paprika, smoked paprika, white pepper.'
        },
        {
            'id': 'CG8TZdMbVYW2A8HV54nU',
            'name': 'Midget Gems',
            'brand': 'Spar',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Modified Potato Starch, Maize Starch, Water, Acids (Lactic Acid, Acetic Acid), Beef Gelatine, Flavourings, Colours (Anthocyanins, Curcumin, Paprika Extract), Plant Concentrates (Safflower, Spirulina), Sunflower Oil, Glazing Agents (Carnauba Wax, Beeswax).'
        },
        {
            'id': 'CMpddOLqY6inkAojradj',
            'name': 'Beta Fuel Energy Chews',
            'brand': 'Science In Sport',
            'serving_size_g': 60.0,
            'ingredients': 'Sugar, water, glucose syrup, fructose syrup, gelling agent (pectin), colour (carotenes), acidity regulator (citric acid), natural flavouring, glazing agents (coconut oil, carnauba wax).'
        },
        {
            'id': 'CNAKXV1NTvppb1SWOgxK',
            'name': 'Oriental Style Cracker Mix',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Rice, Fermented Soya Bean (Water, Soy Bean, Wheat Flour, Salt), Sugar, Modified Corn Starch, Peanut, Wheat Flour, Corn Syrup, Seaweed, Modified Tapioca Starch, Maltodextrin, Sesame Seed, Colour: Paprika Extract, Plain Caramel, Chlorophyllin; Tapioca Starch, Acidity Regulator: Ammonium Carbonate; Glucose Syrup, Chilli Powder, Potato Starch, Yeast Extract.'
        },
        {
            'id': 'CNMgcEKF9rEapb8bcZBb',
            'name': 'Lightly Salted Rice Cakes',
            'brand': 'Morrisons',
            'serving_size_g': 8.0,
            'ingredients': 'Rice, Sea salt.'
        },
        {
            'id': 'CNaPxEHKSQLr2AiUhSmp',
            'name': 'Salted Caramel Mug Cake',
            'brand': 'Baileys',
            'serving_size_g': 100.0,
            'ingredients': 'WHEAT Flour, Sugar, Raising Agent (E450i, E500ii, E575, E341), Starches, Flavouring.'
        },
        {
            'id': 'CNs6CByFDDGsCWOt4ZAK',
            'name': 'Exotic Fruit Lollies',
            'brand': 'Tropical',
            'serving_size_g': 69.0,
            'ingredients': 'Partially reconstituted skimmed milk concentrate, water, sugar, glucose syrup, coconut oil, mango purée (3.5%), concentrated pineapple juice (2%), concentrated passion fruit juice (2%), fructose, concentrated lemon juice, cornflour, whey powder (milk), stabilisers: guar gum, locust bean gum, xanthan gum, flavourings, citrus fibre, emulsifier: mono - and diglycerides of fatty acids, acidity regulator: citric acid, colour: carotenes.'
        },
        {
            'id': 'CNw1CLritT6wHJOmw471',
            'name': 'Spanish Chorizo 225g',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Smoked Paprika (3%), Dextrose, Garlic, Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Potassium Nitrate), Nutmeg, Oregano, Sausage Casing [Pork Protein, Preservatives (Potassium Sorbate, Natamycin)].'
        },
        {
            'id': 'CNwEWoUQx1ZKQYZAEKv7',
            'name': 'Freshona Chopped Tomatoes Arrabiata',
            'brand': 'Freshona',
            'serving_size_g': 100.0,
            'ingredients': '65% Peeled Chopped Tomatoes, Tomato Juice, 2% Green Pepper, 2% Red Pepper, Sugar, Salt, 0.1% Chilli Pepper, Acidity Regulator: Citric Acid.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 81\n")

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

    updated = update_batch81(db_path)

    print(f"✨ BATCH 81 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1411 + updated} products cleaned")

    # Check if we hit a milestone
    total = 1411 + updated
    if total >= 1425:
        print("\n🎉🎉 1425 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
