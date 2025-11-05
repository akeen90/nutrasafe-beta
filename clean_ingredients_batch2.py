#!/usr/bin/env python3
"""
Clean ingredients batch 2
"""

import sqlite3
from datetime import datetime

def update_batch2(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 2\n")

    clean_data = [
        {
            'id': 'tt8dQ2nAnmFiarDMYg3P',
            'name': 'Cheese Triple Sandwich',
            'brand': 'Tesco',
            'serving_size_g': 249.0,
            'ingredients': 'Cheese and Tomato sandwich: Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Mature Cheddar Cheese (contains Colour: Annatto Norbixin) (Milk) (21%), Tomato, Rapeseed Oil, Cornflour, Spirit Vinegar, Pasteurised Egg, Salt, Sugar, Yeast, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Wheat Gluten, Pasteurised Egg Yolk, Concentrated Lemon Juice, Brown Mustard Seed, Flour Treatment Agent (Ascorbic Acid), Palm Oil. Cheese and Pickle sandwich: Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cheddar Cheese (Milk) (28%), Water, Oatmeal, Sugar, Malt Vinegar (Barley), Wheat Bran, Carrot, Courgette, Onion, Swede, Molasses, Spirit Vinegar, Salt, Yeast, Cornflour, Wheat Gluten, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Rapeseed Oil, Malted Barley Flour, Barley Malt Extract, Spices, Concentrated Lemon Juice, Palm Oil, Flour Treatment Agent (Ascorbic Acid), Black Pepper.'
        },
        {
            'id': 'jNHhKr7zHvADaYArYCF6',
            'name': 'Southern Fried NO Chicken Goujon',
            'brand': "Sainsbury's",
            'serving_size_g': 245.0,  # Estimated pack size based on similar products
            'ingredients': 'Water, Fortified Wheat Flour, Textured Wheat Protein (14%), Rapeseed Oil, Textured Pea Protein (7%), Soya Protein Isolate, Thickener (Methyl Cellulose), Yeast Extract, Wheat Fibre, Flavouring, Onion Powder, Black Pepper, Yeast Powder, Salt, Fennel Powder, White Pepper, Paprika Powder, Sugar, Sage Extract, Sea Salt, Preservative (Potassium Sorbate), Garlic Powder.'
        },
        {
            'id': 'I9jM0mZ4zB2qXv1DzfRT',
            'name': 'Iced & Spiced Fruited Buns',
            'brand': 'M&S',
            'serving_size_g': 85.0,  # Per bun
            'ingredients': 'Wheat Flour (with Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Moistened Dried Vine Fruits (18%) (Sultanas, Raisins, Currants, Water), Water, Palm Fat, Orange and Lemon Peel (1.5%), Rapeseed Oil, Dried Wheat Gluten, Invert Sugar Syrup, Emulsifiers (E472c, E471, E472e, E435, E470a), Yeast, Salt, Ground Sweet Cinnamon (Cassia), Gelling Agent (Agar), Flavourings, Ground Coriander Seeds, Wheat Starch.'
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

    print(f"✨ BATCH 2 COMPLETE: {updates_made} products cleaned\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch2(db_path)
