#!/usr/bin/env python3
"""
Clean ingredients batch 3 - Chocolates & Easter products
"""

import sqlite3
from datetime import datetime

def update_batch3(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 3 (Chocolates)\n")

    clean_data = [
        {
            'id': 'BBltozVo5M6JcmRARJjZ',
            'name': 'Crunchie Honeycomb Ice Cream',
            'brand': 'Cadbury',
            'serving_size_g': 106.0,  # 425ml tub / 4 servings = ~106g per serving
            'ingredients': 'Reconstituted Skimmed Milk Concentrate, Cadbury Milk Chocolate (14%) (Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifier (E442), Flavourings), Glucose Syrup, Sugar, Coconut Oil, Water, Honeycomb Pieces (6.5%) (Sugar, Glucose Syrup, Vegetable Oils (Palm, Palm Kernel), Raising Agent (Sodium Carbonates)), Sweetened Condensed Skimmed Milk, Invert Sugar Syrup, Dried Whey (from Milk), Fat Reduced Cocoa Powder, Emulsifiers (E471, E472b), Flavourings, Stabilisers (E412, E410), Caramelised Sugar Syrup, Dried Fructose, Colours (Carotenes, Beetroot Red).'
        },
        {
            'id': 'SO1l5c9aTbdQSqHC2yS5',
            'name': 'Galaxy Collection',
            'brand': 'Galaxy',
            'serving_size_g': 234.0,  # Full selection box
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Whey Permeate (Milk), Palm Fat, Milk Fat, Emulsifier (Soya Lecithin), Dextrin, Colours (Beetroot Red, Vegetable Carbon, Curcumin), Starch, Glazing Agent (Carnauba Wax), Palm Kernel Oil, Raising Agent (E500), Glucose Syrup, Salt, Vanilla Extract. Contains Milk and Soya. May contain Almonds, Hazelnuts, Peanuts, and Wheat.'
        },
        {
            'id': '0hxEJkUTQV9qXPMUt5Go',
            'name': 'Galaxy Ripple Easter Egg',
            'brand': 'Galaxy',
            'serving_size_g': 286.0,  # Standard Easter egg size
            'ingredients': 'Hollow Egg: Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Palm Fat, Milk Fat, Lactose, Whey Permeate (from Milk), Emulsifier (Soya Lecithin), Vanilla Extract. Galaxy Minstrels: Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Palm Fat, Milk Fat, Lactose, Whey Permeate (from Milk), Emulsifier (Soya Lecithin), Dextrin, Natural Colours (Curcumin, Vegetable Carbon, Beetroot Red), Starch, Glazing Agent (Carnauba Wax), Palm Kernel Oil, Vanilla Extract. Galaxy Ripple: Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Palm Fat, Milk Fat, Lactose, Whey Permeate (from Milk), Emulsifiers (Soya Lecithin, Polyglycerol Polyricinoleate), Vanilla Extract.'
        },
        {
            'id': '5E7HA8bQE4cVXjLIZnw4',
            'name': 'Maltesers Mini Bunny With A Hollow Chocolate Egg',
            'brand': 'Maltesers',
            'serving_size_g': 58.0,  # Mini Bunnies bag size
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Palm Fat, Cocoa Mass, Barley Malt Extract, Lactose, Milk Fat, Whey Permeate (from Milk), Full Cream Milk Powder, Glucose Syrup, Demineralised Whey Powder (from Milk), Shea Fat, Emulsifier (Soya Lecithin), Wheat Flour, Raising Agents (E341, E500, E501), Salt, Wheat Gluten, Whey Powder (from Milk), Vanilla Extract.'
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

    print(f"✨ BATCH 3 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {6 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch3(db_path)
