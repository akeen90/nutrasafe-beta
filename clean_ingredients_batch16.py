#!/usr/bin/env python3
"""
Clean ingredients batch 16 - Mixed Brands (Greggs, M&S, Morrisons)
"""

import sqlite3
from datetime import datetime

def update_batch16(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 16 (Mixed Brands)\n")

    clean_data = [
        {
            'id': 'CFyed65YBu4xkq9UxuTL',
            'name': 'Festive Bakes',
            'brand': 'Greggs',
            'serving_size_g': 158.0,  # Per bake (316g pack contains 2 bakes)
            'ingredients': 'Water, Fortified Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Cooked Diced Chicken Breast (10%) (Chicken Breast, Salt, Dextrose), Sage and Onion Stuffing Balls (5%) (Water, Rusk (Wheat), Dried Herbs, Dried Onions, Salt, Flavouring, Sunflower Oil, Yeast Extract), White Sauce with Sage (Modified Starch, Dried Onion, Skimmed Milk Powder, Salt, Dried Sage, Yeast Extract, Cream Powder (Milk), Whey Powder (Milk), Flavouring), Cooked Diced Sweetcure Streaky Bacon with Smoke Flavouring (3%) (Pork Belly, Sugar, Salt, Emulsifier (Triphosphates), Smoke Flavouring, Honey, Preservative (Sodium Nitrite)), Cranberry and Red Onion Relish (2%) (Sugar, Water, Cranberries, Caramelised Red Onions (Red Onions, Sugar, Barley Malt Vinegar), Concentrated Redcurrant Juice, White Wine Vinegar, Dehydrated Onion, White Balsamic Vinegar (White Wine Vinegar, Concentrated Grape Must), Modified Starch, Salt, Ground Black Pepper), Seasoned Crumb Topping (Rusk (Wheat), Cheese Powder (Milk), Palm Oil, Potato Powder, Dried Parsley, Mustard Powder, Ground White Pepper, Flavouring, Colour (Paprika Extract)), Glaze (Water, Sunflower Oil, Rapeseed Oil, Modified Starch, Milk Protein, Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Mono- and Diglycerides of Fatty Acids), Skimmed Milk Powder, Stabiliser (Carboxy Methyl Cellulose, Carrageenan, Cellulose), Acidity Regulator (Sodium Phosphates), Colour (Carotenes)), Cream Powder (Milk), Rapeseed Oil, Sweetened Dried Cranberries (1%) (Cranberries, Sugar, Sunflower Oil), Wheat Gluten, Modified Starch, Salt, Stabiliser (Hydroxypropyl Methyl Cellulose). Contains Gluten, Milk, Mustard. May Contain Celery, Eggs, Soybeans, Sulphur Dioxide.'
        },
        {
            'id': 'k5ZjNNaobacWbrWDk7N6',
            'name': 'M&S Naked Chicken Katsu',
            'brand': 'M&S',
            'serving_size_g': 250.0,  # Estimated full salad pack size
            'ingredients': 'Chicken Breast (16%), Curried Mayonnaise Dressing (15%), Chinese Leaf, Cauliflower, Edamame Soybeans (8%), Cabbage, Cooked Lentils (Lentils, Water), Spinach, Carrots, Peppers, Chickpeas, Water, Spring Onions, Ginger Purée, Coriander, Tomato Paste, Coconut Cream (Coconut Extract, Water), Black Sesame Seeds, Sesame Seeds, Curry Powder (Coriander Seeds, Turmeric, Fenugreek Seeds, Cumin Seeds, Black Pepper, Salt, Dried Chillies, Dried Garlic, Dried Ginger, Caraway Seeds, Dried Onions), Salt, Red Chillies, Vegetable Oil (Sunflower/Rapeseed), Turmeric, Lime Juice, Soybeans, Garlic Purée, Potato Starch, Toasted Sesame Oil, Rice, Cornflour, Sugar, Wheat. Dressing: Water, Vegetable Oil, Concentrated Apple Juice, Lime Juice, Rice Vinegar, Coconut Cream, Tomato Paste, Sugar, Curry Powder, Salt, Ginger Purée, Pasteurised Egg Yolk, Garlic Purée, Cornflour, Vinegar, Turmeric, Coriander, Soybeans, Wheat, Dried Egg White. High in protein. Contains Eggs, Gluten, Sesame Seeds, Soybeans, Wheat.'
        },
        {
            'id': 'Zs3PzuRX2AfQ9pt7nHLR',
            'name': 'Chicken And Bacon Caesar',
            'brand': 'Morrisons',
            'serving_size_g': 215.0,  # Estimated sandwich weight
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), British Chicken Breast (18%) (Chicken Breast (98%), Salt, Cornflour), Water, Caesar Dressing (10%) (Rapeseed Oil, Water, Pasteurised Liquid Whole Egg, Milk, White Wine Vinegar, Garlic Purée, Red Wine Vinegar, Concentrated Lemon Juice, Cornflour, Salt, Herbs, Sugar, Anchovy (Fish), Potato Starch, Mustard Seed, Sunflower Oil, Black Pepper, Mustard Flour, Spirit Vinegar), Tomato (7%), Beechwood Smoked Bacon (6%) (Pork, Salt, Smoked Water, Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Potassium Nitrite)), Lettuce (4%), Rapeseed Oil, Italian Hard Cheese PDO (Milk) (2%) (made with unpasteurised milk), Capers, Kibbled Onion. British chicken breast with Caesar dressing, mayonnaise, tomatoes, Beechwood smoked bacon, lettuce, Parmigiano Reggiano PDO cheese and capers on onion bread. Contains Cereals Containing Gluten, Eggs, Fish, Milk, Mustard, Wheat.'
        },
        {
            'id': 'SKlKhqnlJWttB0hPkQAS',
            'name': 'Coronation Chicken Sandwich',
            'brand': 'M&S',
            'serving_size_g': 190.0,  # Estimated sandwich weight
            'ingredients': 'Roast Chicken Breast (24%), Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Water, Spinach (5%), Oatmeal, Rapeseed Oil, Butter (Milk), Sugar, Mango, Sultanas (2%), Coconut Cream (Coconut Extract, Water), Wheat Bran, Cornflour, Single Cream (Milk), Salt, Pasteurised Egg Yolk, Coriander, Ground Spices (Coriander, Cumin, Turmeric, Fenugreek, Nutmeg, Cayenne Pepper, Cinnamon, Black Pepper, Ginger, Cloves), Dried Apricots (contains Sulphites), Yeast (Yeast, Vitamin D Yeast), Dried Glucose, Mango Purée, Dried Egg, Dried Fermented Wheatflour, Dried Tomato, Dried Onions, White Wine Vinegar, Chicken Stock (Water, Chicken Bones, Chicken Skin, Yeast Extract, Seaweed, Shiitake Mushrooms, Sugar), Emulsifiers (E471, E472e), Dried Yeast Extract, Concentrated Lemon Juice, Wheat Gluten, Potato Starch, Vinegar, Dried Garlic, Malted Barley Flour, Garlic Purée, Ginger Purée, Palm Oil, Mustard Extract, Natural Colours (Curcumin, Paprika Extract), Dried Oregano, Vegetable Oil (Sunflower/Rapeseed), Dried Red Peppers, Flour Treatment Agent (Ascorbic Acid), Palm Fat, Coarse Black Pepper, Ground Bay Leaves, Red Chilli Purée. Roast chicken breast in oatmeal bread with spiced mayonnaise, spinach, sultanas, coriander and apricots. May contain bones. Contains Cereals Containing Gluten, Eggs, Gluten, Milk, Oats, Sulphites, Wheat.'
        },
        {
            'id': 'oq044FxZOSjqBvMx3VeV',
            'name': 'Yellow Thai Chicken Noodles',
            'brand': 'M&S',
            'serving_size_g': 350.0,  # Estimated ready meal pack size
            'ingredients': 'Cooked Egg Noodles (18%) (Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Water, Free Range Egg, Salt, Raising Agent (Sodium Bicarbonate, E501), Acidity Regulator (Citric Acid), Turmeric, Paprika), Chicken Thigh (17%), Coconut Cream (13%) (Coconut, Water), Fish and Shellfish Stock (Water, Salt, Cod, Crab, Mussel, Tomato Paste, Concentrated Carrot Juice, Lobster, Onions, Rapeseed Oil, Sugar, Paprika, Turmeric), Edamame Soybeans (8%), Sweet Potatoes (6%), Pak Choi (5%), Water Chestnuts (3%), Onions, Rapeseed Oil, Garlic Purée, Dark Soy Sauce (Water, Soybeans, Wheat, Salt), Ground Spices (Turmeric, Coriander, Cinnamon, Cumin Seeds, Star Anise, Guajillo Chilli Powder, Chilli, White Pepper, Cloves, Chipotle Chilli), White Wine Vinegar, Thai Basil, Brown Sugar, Fish Sauce (Water, Anchovy, Salt, Sugar), Lemongrass, Red Chillies, Tamarind Paste. Contains Crustaceans, Eggs, Fish, Gluten, Molluscs, Soybeans, Wheat.'
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

    print(f"✨ BATCH 16 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {60 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch16(db_path)
