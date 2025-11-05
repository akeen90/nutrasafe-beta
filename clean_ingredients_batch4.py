#!/usr/bin/env python3
"""
Clean ingredients batch 4 - Ready meals & crisps
"""

import sqlite3
from datetime import datetime

def update_batch4(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 4 (Ready Meals & Crisps)\n")

    clean_data = [
        {
            'id': 'ra7s2Cz75z3D1KymGZZH',
            'name': 'Breaded Chicken Mini Fillets',
            'brand': 'Asda',
            'serving_size_g': 305.0,  # Full pack size
            'ingredients': 'Chicken Breast (70%), Wheat Flour, Palm Oil, Corn Starch, Rice Flour, Sugar, Wheat Gluten, Salt, Spices, Mustard Powder, Onion Powder, Garlic Powder, Raising Agents (E450, E500), Wheat Starch, Dextrose, Tapioca Starch, Fennel, Yeast Extract, Colours (E160c, E100), Yeast, Black Pepper Extract, Soya Flour.'
        },
        {
            'id': '125emWZkULAqE1IyOOI2',
            'name': 'Southern Fried Chicken Wrap',
            'brand': 'Asda',
            'serving_size_g': 220.0,  # Per wrap
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Water, Southern Fried Style Chicken Breast (22%) (Chicken Breast (70%), Wheat Flour, Palm Oil, Corn Starch, Rice Flour, Sugar, Wheat Gluten, Salt, Spices, Mustard Powder, Onion Powder, Garlic Powder, Raising Agents (E450, E500), Wheat Starch, Dextrose, Tapioca Starch, Fennel, Yeast Extract, Colours (E160c, E100), Yeast, Black Pepper Extract, Soya Flour), Pepper (5%), Vegetable Oils (Rapeseed, Palm), Lettuce, Cabbage, Carrots, Onions, Sugar, Spirit Vinegar, Molasses, Cornflour, Raising Agents (E500, E450, E296), Tomato Paste, Pasteurised Whole Egg, Salt, Stabilisers (E412, E415), Smoke Flavouring, Black Pepper, Garlic Powder, Mustard Flour, Wheat Starch, Paprika Powder, Onion Powder.'
        },
        {
            'id': 'DJCxWp4Ia7WJMEnPtPCF',
            'name': 'Spanish Style Chicken & Chorizo Casserole',
            'brand': 'Asda',
            'serving_size_g': 130.0,  # Current serving size
            'ingredients': 'Chicken Drumsticks and Thighs (76%), Red Onions (8%), Red Bell Peppers (5%), Chorizo (5%) (Pork (91%), Water, Salt, Smoked Paprika, Dextrose, Garlic Paste, Antioxidant (Sodium Ascorbate), Nutmeg, Preservative (Sodium Nitrite), Oregano), Sugar, Spices, Maize Starch, Herbs, Tomato Powder, Garlic Powder, Salt, Green Bell Peppers, Thickener (Guar Gum), Flavourings, Colour (Paprika Extract). No artificial colours, flavours or hydrogenated fat.'
        },
        {
            'id': 'hha1tSbsCSYOdCDLd7fO',
            'name': 'Oven Baked Crisps',
            'brand': 'Walkers',
            'serving_size_g': 22.0,  # Multipack bag size (also available in 37.5g)
            'ingredients': 'Potato Flakes, Starch, Rapeseed Oil, Sugar, Emulsifier (Lecithins), Sea Salt Seasoning (Sea Salt, Salt, Flavourings), Sunflower Oil, Colour (Annatto Norbixin). 50% less fat than regular potato crisps. No added MSG, artificial colours or preservatives.'
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

    print(f"✨ BATCH 4 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {10 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch4(db_path)
