#!/usr/bin/env python3
"""
Clean ingredients batch 7 - M&S Products
"""

import sqlite3
from datetime import datetime

def update_batch7(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 7 (M&S Products)\n")

    clean_data = [
        {
            'id': '6sZZ6i19DQt6Z4A9iJnA',
            'name': 'Box Of Jewels',
            'brand': 'M&S',
            'serving_size_g': 10.63,  # Individual chocolate piece weight
            'ingredients': 'Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Glucose Syrup, Evaporated Milk, Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar), Water, Coconut Oil, Humectant (Sorbitol), Butter (Milk), Dried Brazilian Coffee, Flavourings, Emulsifier (Lecithins (Soya)), Invert Sugar Syrup, Caramelised Sugar, Maltodextrin, Dried Skimmed Milk, Salt, Acidity Regulator (Citric Acid), Fruit and Plant Concentrates (Spirulina, Apple, Safflower, Lemon), Caramelised Sugar Syrup, Colour (E172), Preservative (E200), Orange Oil, Vanilla Extract. Milk Chocolate contains Cocoa Solids 40% minimum, Milk Solids 20% minimum. Dark Chocolate contains Cocoa Solids 64% minimum. White Chocolate contains Milk Solids 21% minimum.'
        },
        {
            'id': 'h64GDuRipZHT9tafAH3x',
            'name': 'Char Siu Bao Buns',
            'brand': 'M&S',
            'serving_size_g': 60.0,  # Per bun (2 pack)
            'ingredients': 'Wheatflour (contains Gluten), Water, Oyster Mushrooms (9%), Sugar, King Oyster Mushrooms (6%), Water Chestnuts, Cornflour, Dextrose, Wheat Starch (contains Gluten), Carrots, Hoisin Sauce (Water, Sugar, Fermented Soybean Paste (Soybeans, Wheat (contains Gluten), Water, Salt), Natural Colour: Plain Caramel, Garlic, Modified Tapioca Starch, Salt, Vinegar, Chilli Powder, Acidity Regulator: Citric Acid), Onions, Vegetable Oil (Sunflower/Rapeseed), Garlic, Palm Sugar, Salt, Dried Yeast, Wheat Gluten, Soya Flour, Yeast Extract (contains Barley, Gluten), Raising Agent (E450, Sodium Bicarbonate, E341(i)). Vegan-friendly. Microwave in 50 seconds.'
        },
        {
            'id': 'SMN4fXX2QhgC3Qf3YmyE',
            'name': 'Chicken & Bacon Caesar Wrap',
            'brand': 'M&S',
            'serving_size_g': 227.0,  # Per wrap
            'ingredients': 'Wheatflour with Gluten (with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Roast Chicken Breast (18%), Lettuce (12%), Water, Vegetable Oil (Sunflower/Rapeseed), Smoked British Bacon (5%) (Pork Belly made with 185g of Raw Pork per 100g of Cooked Bacon, Curing Salt with Salt and Preservatives Sodium Nitrate and Sodium Nitrite, Sugar, Flavouring, Antioxidant E301), Italian Hard Cheese (Milk), Spinach, Palm Oil, Lemon Juice, Pasteurised Egg Yolk, Humectant (Glycerol), Malted Wheatflakes (contain Gluten), Olive Oil, Sugar, Salt, Raising Agents (Sodium Bicarbonate, E450). British chicken from M&S Select Farms with oak smoked bacon and creamy Caesar dressing.'
        },
        {
            'id': 'ZdwcuxZvOE9ij9EWAMq9',
            'name': 'Chocolate Sandwich Fingers',
            'brand': 'M&S',
            'serving_size_g': 100.0,  # Estimated serving (twin pack available in 150g/250g/300g formats)
            'ingredients': 'Wheatflour contains Gluten (with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Milk Chocolate (29%) (Sugar, Cocoa Mass, Cocoa Butter, Dried Whole Milk, Dried Whey (Milk), Butter Oil (Milk), Dried Skimmed Milk, Emulsifier: Soya Lecithin), Sugar, Butter (Milk) (11%), Palm Oil, Partially Inverted Sugar Syrup, Pasteurised Egg, Salt, Raising Agent (E450, Sodium Bicarbonate, E503), Vanilla Flavouring, Emulsifier (Soya Lecithin). Milk Chocolate contains Cocoa Solids 38% minimum, Milk Solids 18% minimum. Light buttery biscuits with smooth milk chocolate filling.'
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

    print(f"✨ BATCH 7 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {21 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch7(db_path)
