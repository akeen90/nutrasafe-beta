#!/usr/bin/env python3
"""
Clean ingredients batch 49 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch49(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 49\n")

    clean_data = [
        {
            'id': '1R2dn90Ojalvo2ooYOu1',
            'name': 'BBQ Crispy Peanuts',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (48%), Modified Maize Starch, Potato Starch, Sunflower Oil, Sugar, Rice Flour, Chickpeas, Salt, Yellow Split Peas, Raising Agent (Diphosphates), Barley Malt Vinegar Powder, Yeast Extract Powder, Smoked Paprika, Acidity Regulator (Sodium Carbonates), Glazing Agent (Acacia Gum), Dextrose, Onion Powder, Tomato Powder, Garlic Powder, Anti-Caking Agents (Silicon Dioxide, Calcium Phosphates), Chilli Powder, Citric Acid, Flavouring, Black Pepper Powder, Colour (Paprika Extract). Contains Barley, Cereals Containing Gluten, Peanuts. May Contain Sesame.'
        },
        {
            'id': '1SEmxqZpDazFpjzSJdEF',
            'name': 'Golden Nuggets',
            'brand': 'Nestlé',
            'serving_size_g': 30.0,
            'ingredients': 'Whole Grain Wheat (35.3%), Wheat Flour (26.5%), Sugar, Maize Semolina, Whole Grain Maize Flour, Glucose Syrup, Honey, Invert Sugar Syrup, Calcium Carbonate, Salt, Molasses, Sunflower Oil, Colour (Carotene), Antioxidant (Tocopherols), Iron, Flavouring, Vitamin B3, B5, B9, B6, B2. Contains Cereals Containing Gluten, Wheat. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': '1TVgH9tE7nOsYMHFtdoF',
            'name': '5 New York Style Sesame Bagels',
            'brand': 'Rowan Hill',
            'serving_size_g': 85.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Sesame Seeds (3%), Rye Flour, Sugar, Yeast, Rapeseed Oil, Maize, Salt, Preservative (Calcium Propionate), Wheat Gluten, Malted Barley, Spirit Vinegar, Flour Treatment Agent (Ascorbic Acid). Contains Barley, Cereals Containing Gluten, Sesame, Wheat.'
        },
        {
            'id': '1Tbq0Em7yJvUOgGMtFxz',
            'name': 'Baby Potatoes With Tikka Marinade',
            'brand': 'Tesco',
            'serving_size_g': 125.0,
            'ingredients': 'Potato, Mango Chutney (6%) (Mango, Caster Sugar, Glucose Syrup, Spirit Vinegar, Water, Salt), Maize Starch, Paprika, Coriander, Fenugreek, Turmeric, Cayenne Pepper, Allspice, Cinnamon, Black Pepper, Cumin, Nutmeg, Cardamom, Olive Oil, Rapeseed Oil, Palm Fat, Parsley, Coriander, Fenugreek, Cumin, Garlic Powder, Sea Salt, Sugar, Chilli, Cayenne Pepper, Paprika, Garlic, Onion Powder, Turmeric, Nigella Seeds, Colour (Paprika Extract), Ginger, Antioxidant (Citric Acid), Flavouring.'
        },
        {
            'id': '1PIGunBD2sLq7rBpeZmS',
            'name': 'Tuna',
            'brand': 'Princes',
            'serving_size_g': 60.0,
            'ingredients': 'Tuna Fish (93%), Spring Water. Contains Fish.'
        },
        {
            'id': '1Th2J2YwBmroWd8RN5lk',
            'name': 'Thai Sweet Chilli Egg Noodles',
            'brand': 'Aldi Asian Inspired',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Egg Noodles (73%) (Wheat Flour, Durum Wheat Semolina, Egg, Salt, Acidity Regulator (Potassium Carbonate)), Sugar, Potato Starch, Flavourings, Garlic Powder, Dried Spring Onion, Dried Red Pepper, Soy Sauce Powder (Soy Sauce (Soya Beans, Wheat, Salt)), Salt, Onion Powder, Ground Ginger, Chilli Powder, Colour (Paprika Extract), Citric Acid, Maltodextrin. Contains Cereals Containing Gluten, Eggs, Soybeans, Wheat. May Contain Other Gluten Sources.'
        },
        {
            'id': '1UwaYWlpXaYWIROeD207',
            'name': 'Whole Chia Seeds',
            'brand': 'Natural Selection',
            'serving_size_g': 15.0,
            'ingredients': 'Chia (Salvia Hispanica) Seeds. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': '1WZL8X2ZBJvfapPzgWU8',
            'name': 'Gorgonzola DOP Picante',
            'brand': 'Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Gorgonzola DOP Piccante, Pasteurised Semi-Soft Full Fat Blue Cheese (Milk). Contains Milk.'
        },
        {
            'id': '1WhkS6zQvKA6sQt6SkU4',
            'name': 'Savoury Sauce',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable Stock (Water, Salt, Yeast Extract, Maltodextrin, Sugar, Onion, Carrot, Tomato, Lovage), Vegetable Oil (Sunflower), Modified Starch, Vegetable Oil (Rapeseed), Flavouring, Soya Flour, Onion Juice Concentrate, Yeast Extract, Colour (Plain Caramel), Salt. Contains Soybeans.'
        },
        {
            'id': '1X8iPpxZxk5evRnNcKoY',
            'name': 'Strawberry Jam',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Strawberries, Water, Acidity Regulators (Citric Acid, Sodium Citrates), Gelling Agent (Pectins). Prepared with 35g of Fruit per 100g, Total Sugar Content 61g per 100g.'
        },
        {
            'id': '1XJc8ibZuCVTs0YNMyy2',
            'name': 'Eat Natural Maple Syrup, Pecan And Peanuts Bar',
            'brand': 'Eat Natural',
            'serving_size_g': 45.0,
            'ingredients': 'Peanuts (46%), Mixed Seeds (14%) (Sunflower Seeds, Linseeds), Glucose Syrup, Maple Syrup (10%), Pecan Nuts (10%), Crisped Rice (Rice, Sugar), Sea Salt. Contains Nuts, Peanuts.'
        },
        {
            'id': '1XzpZxDkCwPCTtab1c6o',
            'name': 'Meatster Original',
            'brand': 'Eat Go',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Dextrose, Spices, Spice Extracts, Preservative (Sodium Nitrite), Antioxidant (Sodium Ascorbate). Made with 150g of Raw Pork per 109g of Finished Product. May Contain Celery, Milk, Mustard, Nuts.'
        },
        {
            'id': '1YHFM90wBRp94RJHjVY4',
            'name': 'Deluxe Vindaloo',
            'brand': 'Lidl',
            'serving_size_g': 120.0,
            'ingredients': 'Water, Tomato (7%), Onion (5%), Rapeseed Oil, Barley Malt Vinegar, Concentrated Crushed Tomato (3%), Spice Cap (3%) (Rice Flour, Coriander, Onion Powder, Garlic Powder, Cumin, Sugar, Ginger, Cardamom, Turmeric, Dried Fenugreek Leaf, Fenugreek, Black Pepper, Anti-Caking Agent (Tricalcium Phosphate), Turmeric Extract, Flavouring), Concentrated Tomato Purée (3%), Sugar, Modified Maize Starch, Garlic Purée, Ginger Purée, Coriander (1.5%), Cumin, Dried Onion (0.7%), Colour (Paprika Extract), Chilli, Paprika, Salt, Chilli Flakes, Cinnamon, Turmeric, Star Anise, Fenugreek, Acidity Regulator (Citric Acid), Black Pepper, Clove. Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': '1UElCqo7vscjeS4BlyQk',
            'name': 'Mango And Apricot Biscotti',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Sugar, Sustainable Palm Oil, Soluble Fibre, Skimmed Milk Powder, Mango Purée (4%), Apricot, Barley Malt Extract, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Calcium Carbonate, Natural Flavourings, Iron Fumarate, Zinc Sulphate, Niacin, Vitamin E, Thiamin, Vitamin B6, Vitamin A, Folic Acid, Vitamin K, Vitamin B12. Contains Barley, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '1ZPwtwCVNnmj6lnnyiZS',
            'name': 'Falafel, Avo And Chipotle Flatbread',
            'brand': 'Pret A Manger',
            'serving_size_g': 265.0,
            'ingredients': 'Avocado (28%), Flatbread (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin, Water, Sugar, Yeast, Salt), Sweet Potato Falafel (16%) (Sweet Potato, Cooked Chickpeas, Water, Onion, Dried Potato, Coriander Leaf, Red Pepper, Salt, Cumin Powder, Concentrated Lemon Juice, Rapeseed Oil, Paprika, Water, Smoked Paprika, Black Pepper, Dried Garlic, Coriander Powder, Chilli Flakes), Red Pepper, Chipotle Ketchup (8%) (Red Pepper, Muscovado Sugar, Red Wine Vinegar, Onion, Chipotle Peppers in Adobo Sauce, Water, Tomato Paste, Salt, Sugar, Onion, Acidity Regulator, Vegetable Oil, Tomato Paste, Maize Starch, Water, Garlic, Salt, Black Pepper, Cayenne Pepper), Pickled Onions (Red Onion, Cider Vinegar, Rice Vinegar, Sugar), Sweetcorn, Black Turtle Beans, Coriander, Lime Juice, Olive Oil, Salt, Black Pepper. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '1bdGphiWl9Ug9yhf9Aqc',
            'name': 'German Smoked Cheese With Ham Slices',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cheese (69%) (Milk), Reformed Ham Pieces (9%) (Pork (96%), Salt, Dextrose, Stabiliser (Diphosphates), Antioxidant (Sodium Ascorbate), Acidity Regulator (Sodium Citrates), Preservative (Sodium Nitrite)), Water, Butter (Milk), Whey Powder (Milk), Emulsifying Salts (Potassium Phosphates, Polyphosphates), Milk Proteins. Contains Milk. May Contain Nuts.'
        },
        {
            'id': '1bjN2XkFtcSjL8opmCmq',
            'name': 'Sweet Chilli Crisps - The Best',
            'brand': 'Morrisons',
            'serving_size_g': 25.0,
            'ingredients': 'Potato, Vegetable Oils (Rapeseed, Sunflower), Sugar, Salt, Garlic Powder, Onion Powder, Soybeans, Spirit Vinegar, Tomato Powder, Parsley, Red Bell Pepper Powder, Cayenne Pepper, Coriander Powder, Chilli Powder (Chilli, Cumin, Salt, Oregano, Garlic), Yeast Extract, Coconut Milk, Maltodextrin, Colour (Paprika Extract), Chilli Extract, Star Anise, Sodium Caseinate (Milk), Capsicum Extract. Contains Milk, Soybeans.'
        },
        {
            'id': '1dLFkRH3Rkfdd9rjpMbH',
            'name': 'Shuk Up Chocolate',
            'brand': 'Cowbelle',
            'serving_size_g': 330.0,
            'ingredients': '1.5% Fat Milk (90%), Sugar, Buttermilk Powder, Fat Reduced Cocoa Powder, Modified Corn Starch, Stabilisers (Cellulose, Carrageenan, Sodium Carboxymethyl Cellulose, Guar Gum), Salt. Contains Milk.'
        },
        {
            'id': '1dNcxHa9tGL6cU969YQH',
            'name': 'Omega Seed Mix',
            'brand': 'Grapetree',
            'serving_size_g': 1.0,
            'ingredients': 'Sunflower Seeds (44%), Golden Linseed (22%), Brown Linseed (22%), Pumpkin Seed (12%). May Contain Barley, Cereals Containing Gluten, Eggs, Milk, Nuts, Peanuts, Sesame, Soybeans, Sulphites, Wheat.'
        },
        {
            'id': '1eecYT6LpxQ1q88STEP1',
            'name': 'Granola Nut & Seed No Added Sugar',
            'brand': 'M&S',
            'serving_size_g': 45.0,
            'ingredients': 'Oat Flakes (70%), Chicory Fibre, Hazelnuts (5%), Rapeseed Oil, Almonds (4%), Sunflower Seeds (3.5%), Pumpkin Seeds (3.5%). Contains Nuts, Oats. Not Suitable for Nut Allergy Sufferers.'
        },
        {
            'id': '1ZqiyT2JqHEAPDcUr3qf',
            'name': 'Curry In A Naan Chicken Korma',
            'brand': 'Tuk In',
            'serving_size_g': 180.0,
            'ingredients': 'Naan Bread (42%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Palm Oil, Yogurt (Milk), Yeast, Sugar, Rapeseed Oil, Salt, Calcium Propionate (Preservative)), Chicken (19%), Onion (15%), Single Cream (Milk), Coconut Milk (6%), Rapeseed Oil, Water, Tomato Paste, Spices (Celery), Garlic, Ginger, Desiccated Coconut, Cornflour, Sugar, Coriander, Salt. Contains Celery, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '1fQ524yZ7Xfe7WX5mtwt',
            'name': 'Bourneville Easter Egg',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Mass, Palm Oil, Cocoa Butter, Emulsifiers (Soya Lecithins, E476). Cocoa Solids: 36% Minimum. May Contain Nuts. Not Suitable for Someone with a Milk Allergy. Contains Vegetable Fats in Addition to Cocoa Butter.'
        },
        {
            'id': '1h2CfgFQdmwJO51WroXJ',
            'name': 'Garlic Baguette',
            'brand': 'Hearty Food Co',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Palm Oil, Rapeseed Oil, Garlic, Salt, Yeast, Concentrated Lemon Juice, Dried Parsley, Emulsifier (Mono- and Di-Glycerides of Fatty Acids), Flour Treatment Agent (Ascorbic Acid), Flavouring, Colour (Beta-Carotene). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '1hPH7HWexU0MRhxBzbq7',
            'name': 'Gluten Free 4 Triple Seeded Rolls',
            'brand': 'Genius',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Mixed Seeds (17%) (Sunflower, Linseed, Flaxseed, Millet, Poppy), Starches (Tapioca, Potato), Rice Flour, Bamboo Fibre, Rapeseed Oil, Humectant (Vegetable Glycerol), Psyllium Husk, Dried Egg White, Yeast, Stabiliser (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Sugar, Iodised Salt (Salt, Potassium Iodate), Fermented Maize Starch, Active Cultures (Bacillus Coagulans Unique IS2), Vitamins & Minerals (Calcium Carbonate, Niacin, Iron, Riboflavin, Thiamin, Folic Acid). Contains Eggs.'
        },
        {
            'id': '1i1X3zcjnKiPoVFL2UIf',
            'name': 'Frijj',
            'brand': 'Müller',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk (60%), Whole Milk (29%), Sugar Syrup, Buttermilk Powder, Modified Maize Starch, Cocoa Powder, Fructose, Stabilisers (Cellulose, Cellulose Gum, Carrageenan), Flavourings. Contains Milk.'
        }
    ]

    updates_made = 0
    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g\n")
            updates_made += 1

    conn.commit()
    conn.close()

    total_cleaned = 611 + updates_made

    print(f"✨ BATCH 49 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch49(db_path)
