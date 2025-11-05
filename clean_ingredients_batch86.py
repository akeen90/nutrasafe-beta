#!/usr/bin/env python3
"""
Clean ingredients for batch 86 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch86(db_path: str):
    """Update batch 86 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 86: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'EN7ZVrljkZJLuSKxS1wh',
            'name': 'Chocolate Peanut & Raisin Mix',
            'brand': 'Snacking Essentials',
            'serving_size_g': 30.0,
            'ingredients': 'Blanched Peanuts 38%, Raisins 37% (Raisins, Sunflower oil), Milk chocolate coated Peanuts 25% (Milk chocolate (Sugar, Milk powder, Cocoa butter, Cocoa mass, Palm oil, Whey powder (Milk), Emulsifier: Sunflower lecithin, Glazing agents: Gum arabic, Shellac), Peanuts).'
        },
        {
            'id': 'ENz8VwWDQeom2dPV2bBV',
            'name': 'Carrot Cake',
            'brand': 'Co-op',
            'serving_size_g': 62.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Dark Brown Sugar, Carrots 15%, Sugar, Rapeseed Oil, Egg, Sultanas 5%, Full Fat Soft Cheese (Milk) 5%, Butter (Milk), Golden Syrup, Egg White, Cornflour, Humectant (Glycerol - Vegetable), Walnuts 1%, Mixed Spice (Cassia, Nutmeg, Coriander, Ginger, Fennel, Cloves, Cardamom), Raising Agents (Disodium diphosphate, Potassium hydrogen carbonate, Sodium hydrogen carbonate), Preservative (Potassium sorbate).'
        },
        {
            'id': 'EOB56ZxiOuXkT92IEXbE',
            'name': 'Fruit Loaf',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Mixed Fruit (27%) (Raisins, Sultanas), Water, Rapeseed Oil, Orange and Lemon Peel (2%), Wheat Gluten, Invert Sugar Syrup, Yeast, Dextrose, Emulsifiers: Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono-and Diglycerides of Fatty Acids; Palm Oil, Salt, Soya Flour, Maize Starch, Flour Treatment Agent: Ascorbic Acid.'
        },
        {
            'id': 'EOUbPxdsHuk4otgrXGts',
            'name': 'Brownie',
            'brand': 'Cadbury',
            'serving_size_g': 25.0,
            'ingredients': 'Sugar, vegetable oils (palm, rapeseed), eggs, wheat flour, cocoa mass, fat reduced cocoa powder, glucose syrup, dextrose, humectant (glycerol), invert sugar syrup, cocoa butter, emulsifiers (e492, soya lecithins, e442, e473), sweetened condensed skimmed milk, skimmed milk powder, whey permeate (from milk), salt, preservative (potassium sorbate), milk fat, acidity regulators (citric acid, tartaric acid), modified starch, gelling agent (sodium alginate), raising agents (diphosphates, sodium carbonates), flavourings, colour (E150).'
        },
        {
            'id': 'EOssgbbf4ifX9jsiyqFX',
            'name': 'Village Bakery 2 Baked IN Crumpets',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Iron, Calcium Carbonate, Niacin, Thiamin), Water, PEA PROTEIN 5%, Yeast, Raising Agents: Diphosphates, Potassium Carbonates, Salt, Preservative: Potassium Sorbate, WHEAT PROTEIN 2.5%.'
        },
        {
            'id': 'EOtB7IoDWa4gshO7lTgM',
            'name': 'Chicken Dippers',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast, water, maize flour, tapioca starch, rice flour, wheat starch, pea fibre, maize starch, dextrose, raising agents (diphosphates, sodium carbonates), salt, stabiliser (sodium citrates), white pepper, yeast, black pepper extract.'
        },
        {
            'id': 'EPIqoA4ulXbTsv9xuTMZ',
            'name': 'Medium Egg Noodles',
            'brand': 'Manischewitz',
            'serving_size_g': 100.0,
            'ingredients': 'ENRICHED DURUM WHEAT FLOUR (94.5%) [WHEAT FLOUR, NIACIN (VITAMIN B3), IRON (FERROUS SULPHATE), THIAMIN MONONITRATE (VITAMIN B1), RIBOFLAVIN (VITAMIN B2), FOLIC ACID (VITAMIN B9)] AND EGGS (5.5%).'
        },
        {
            'id': 'EPPEnI3T6SWFKrzhuqC4',
            'name': 'Jaffa Cakes 10pk',
            'brand': 'McVitie\'s',
            'serving_size_g': 12.2,
            'ingredients': 'Glucose-Fructose Syrup, Dark Chocolate (19%) (Sugar, Cocoa Mass, Vegetable Fats (Palm, Shea), Butter Oil (Milk), Cocoa Butter, Emulsifiers (Soya Lecithin, E476), Natural Flavouring), Sugar, Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Whole Egg, Water, Dextrose, Concentrated Orange Juice, Glucose Syrup, Vegetable Oils (Sunflower, Palm), Humectant (Glycerine), Gelling Agent (Pectin), Acid (Citric Acid), Raising Agents (Ammonium Bicarbonate, Disodium Diphosphate, Sodium Bicarbonate), Dried Whole Egg, Acidity Regulator (Sodium Citrates), Natural Orange Flavouring, Colour (Curcumin), Emulsifier (Soya Lecithin).'
        },
        {
            'id': 'EQ0D3orttlJQi6SoRRf0',
            'name': 'Fine Egg Noodles',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Egg Yolk Powder (1%), Salt, Raising Agents (Sodium Hydrogen Carbonate, Potassium Hydrogen Carbonate).'
        },
        {
            'id': 'EQb5qBJ5wMX5XKKciu0c',
            'name': 'Orange Smarties',
            'brand': 'Limited Edition',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa butter, Skimmed milk powder, Cocoa mass, Butterfat from Milk, Lactose and proteins from whey from Milk, Wheat flour, Rice starch, Orange oil, Emulsifier (Sunflower lecithin), Fruit and vegetable concentrates (Safflower, Radish, Lemon), Glazing agents (Carnauba wax, Beeswax white), Natural vanilla flavouring.'
        },
        {
            'id': 'EQhv8eR3u2fGNxCP2A3s',
            'name': 'Premium Mini Mix',
            'brand': 'Gelatelli',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Sugar, Liquid Whey Concentrated (Milk), Water, Glucose Syrup, Coconut Fat, Cocoa Mass, Cocoa Butter, Butter Oil (Milk), Skimmed Milk Powder, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Lecithins, Polyglycerol Polyricinoleate), Stabilisers (Locust Bean Gum, Guar Gum, Pectins, Sodium Citrates), Caramelised Sugar Syrup, Condensed Skimmed Milk, Natural Flavourings, Salt, Natural Vanilla Flavouring, Caramelised Glucose Syrup.'
        },
        {
            'id': 'ERe7Bu92Sq0yxxi07fVY',
            'name': 'The Original Potato Crisp',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in Varying Proportions), Salt & Vinegar Seasoning (Salt, Flavourings, Acid (Citric Acid), Sugar, Flavour Enhancer (Monosodium Glutamate, Disodium Guanylate), Potassium Chloride).'
        },
        {
            'id': 'EM30yB7vP9YWWEAa1x3u',
            'name': 'Kabanossi',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, 1.9% sun-dried tomatoes, potato starch, salt, 0.1% dried basil, flavouring, sugar, pork fat, tomato paste, pork protein, antioxidant: sodium ascorbate, preservative: sodium nitrite, edible alginate casing (gelling agent: sodium alginate, stabilisers: cellulose, calcium chloride).'
        },
        {
            'id': 'ESUAhSs4xWWDbiKF8xRf',
            'name': 'Peanuts',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (95%), sunflower oil, salt.'
        },
        {
            'id': 'ESeNZ1q5d5Yn71wktsEx',
            'name': 'Chocolate Rice Cakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Dark chocolate (60%) (sugar, cocoa mass, cocoa butter, emulsifiers (soya lecithin, polyglycerol polyricinoleate), flavouring), brown rice, white rice.'
        },
        {
            'id': 'ESk8UZQtDWJU63ULcd5p',
            'name': 'Vegetable Stock Cubes 12x',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Salt, Potato Starch, Vegetable Oil (Palm Oil, Sunflower Oil), Glucose Syrup, Sugar, Yeast Extract, Herbs, Spices, Celeriac, Roasted Onions, Dried Carrots, Tomato Powder, Onions, Garlic Powder, Dried Leeks, Flavouring, Red Peppers, Caramel Sugar Syrup, Maltodextrin.'
        },
        {
            'id': 'ET9rDY5detXEmuZdjnoc',
            'name': 'Sausage Mix',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, tomato powder, maize starch, potato starch, maltodextrin, onion powder, salt, ground paprika, sugar, yeast extract, sage, palm fat, dried parsley, paprika extract, marjoram, lemon juice powder, natural flavourings, ground black pepper, white wine extract.'
        },
        {
            'id': 'EUFBojcNZYV9UEAqFcpk',
            'name': 'Tesco Prawn Mayonnaise',
            'brand': 'Tesco',
            'serving_size_g': 191.0,
            'ingredients': 'Prawn (crustacean) 39%, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, malted wheat flakes, rapeseed oil, wheat bran, cornflour, spirit vinegar, salt, pasteurised egg, yeast, malted barley flour, sugar, emulsifiers (mono- and diglycerides of fatty acids, mono- and diacetyl tartaric acid esters of mono- and diglycerides of fatty acids), wheat gluten, pasteurised egg yolk, malted wheat flour, concentrated lemon juice, black pepper, flour treatment agent (ascorbic acid), palm oil, brown mustard seeds.'
        },
        {
            'id': 'EUPIZt6yQLfrkdkGWxSe',
            'name': 'Tesco Fruit & Nut Mix',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Jumbo Flame Raisins 20% (Raisins, Sunflower Oil), Almonds, Jumbo Golden Raisins 15% (Raisins, Sunflower Oil, Preservative: Sulphur Dioxide), Brazil Nuts, Hazelnuts, Cashew Nuts, Walnuts, Juice Infused Dried Cranberries (Cranberry, Pineapple Juice from Concentrate, Sunflower Oil).'
        },
        {
            'id': 'EUR4DslQalpnoYaxveR3',
            'name': 'Chicken Satay Skewers',
            'brand': 'The Central Islamic Council Of Thailand',
            'serving_size_g': 10.0,
            'ingredients': 'Chicken breast fillet (84%), palm oil, sugar, maize starch, tapioca starch, glucose, salt, spices (contains: mustard), glucose syrup, yeast extract, stabilisers (sodium bicarbonate, sodium citrate), colour (curcumin), spice extract.'
        },
        {
            'id': 'EUWI1Q4MuhFX04O2weVY',
            'name': 'Potato And Onion Tortilla',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'POTATO 43%, WATER, CHICKPEA 20%, FRIED ONION 9% (ONION, OLIVE OIL, SALT), SUNFLOWER OIL, OLIVE OIL, SALT, STABILISER: CARRAGEENAN, VEGETABLE FIBRE (PEA, SUGAR, BAMBOO).'
        },
        {
            'id': 'EUlKGxR9qUO8Cuf1KTYb',
            'name': 'Pea Snacks Soy & Balsamic',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '72% marrowfat peas, rapeseed oil, white rice flour, soy and balsamic seasoning (dried balsamic vinegar, salt, acids: citric acid, tartaric acid, dried tamari soy sauce (tamari soy sauce, soya beans, salt, spirit vinegar), maltodextrin, salt, sugar, dried spirit vinegar, maltodextrin, spirit vinegar, yeast extract), firming agent: calcium carbonate, antioxidant: extract of rosemary.'
        },
        {
            'id': 'EUpYShmGpADRKKH6k1rV',
            'name': 'Squirty Cream',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (milk) (93%), sugar (4%), emulsifier (mono - and diglycerides of fatty acids), stabiliser (carrageenan), propellent gas (nitrous oxide).'
        },
        {
            'id': 'EVYMcCumDuggkEEg9fZd',
            'name': 'Egg Mayonnaise',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '77% cooked egg (egg, water, preservatives: citric acid, trisodium citrate), 22% reduced fat mayonnaise (water, rapeseed oil, pasteurised liquid whole egg, acidity regulator: acetic acid, sugar, salt, lemon juice, mustard powder, stabilisers: guar gum, xanthan gum, preservative: potassium sorbate), 0.5% parsley, salt, white pepper.'
        },
        {
            'id': 'EWh4tWwoC8Wauo7eeeNU',
            'name': 'Beef Stock Cubes 12x',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Salt, potato starch, palm fat, maltodextrin, sugar, beef fat, beef extract (3%), yeast extract, caramelised sugar syrup, flavourings, carrot powder, roasted onion powder, celery seeds, garlic powder, parsley.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 86\n")

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

    updated = update_batch86(db_path)

    print(f"✨ BATCH 86 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1536 + updated} products cleaned")

    # Check if we hit the 1550 milestone
    total = 1536 + updated
    if total >= 1550:
        print("\n🎉🎉 1550 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
