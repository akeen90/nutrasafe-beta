#!/usr/bin/env python3
"""
Clean ingredients batch 6 - Ice cream & Snacks
"""

import sqlite3
from datetime import datetime

def update_batch6(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 6 (Ice Cream & Snacks)\n")

    clean_data = [
        {
            'id': '04PqqDa2D24sRXDhvtUa',
            'name': 'Brookies & Cream',
            'brand': "Ben & Jerry's",
            'serving_size_g': 100.0,  # 465ml tub, approx 4-5 servings
            'ingredients': 'CREAM (27%), Water, Sugar, Concentrated Low-Fat MILK, Flours (WHEAT, Whole WHEAT), Coconut Fat, EGG Yolk, Vegetable Oils (Soya, Rapeseed, Sunflower), Corn Starch, Low-Fat Cocoa Powder, MILK Powder, Vanilla Extract, Cocoa Butter, Salt, Emulsifier (Soya Lecithin), Thickeners (Guar Gum, Carrageenan), Concentrated BUTTER, Molasses, Raising Agent (Sodium Carbonates). Vanilla ice cream with brownie style dough (9%) and cookie swirl (9%), topped with chocolate whipped ice cream, sea salt chocolate swirls (6.5%) and white chunks (3.5%). Fairtrade certified sugar, cocoa, and vanilla. Kosher and Halal certified.'
        },
        {
            'id': 'kvUpDhEj2bPN1rQ0NQf4',
            'name': 'Fruitastic Lollies',
            'brand': 'Aldi',
            'serving_size_g': 65.0,  # Rainbow lolly variant (pack contains mixed sizes)
            'ingredients': 'Rainbow Lollies: Water, Fruit Juices from Concentrate 25% (Pineapple, Raspberry, Orange, Lemon, Blackcurrant, Apple), Sugar, Glucose Syrup, Flavourings, Acids (Malic Acid, Citric Acid), Stabiliser (Guar Gum), Plant Extracts (Safflower, Spirulina Concentrate), Beetroot Juice, Turmeric Extract, Colour (Carotenes). Multipack also contains Tropical Cooler and Watermelon varieties.'
        },
        {
            'id': 'XBSIXcVDCzguEbYqnHnN',
            'name': 'Alpen Chocolate Caramel & Shortbread Imp',
            'brand': 'Alpen',
            'serving_size_g': 24.0,  # Per bar (5 x 24g multipack)
            'ingredients': 'Cereals (40%) (Oats, Rice, Wheat), Oligofructose Syrup, Milk Chocolate (14%) (Sugar, Cocoa Butter (Rainforest Alliance Certified), Skimmed Milk Powder, Cocoa Mass (Rainforest Alliance Certified), Milk Powder, Milk Fat, Emulsifier: Soya Lecithin), Cereal Flours (Rice, Wheat, Malted Barley), Caramel Pieces (4.5%) (Sugar, Glucose Syrup, Condensed Milk, Palm Oil, Shea Kernel Oil, Maize Starch, Humectant: Glycerol, Palm Stearin, Flavouring, Emulsifiers (Glycerol Monostearate, Sunflower Lecithin), Salt), Plain Chocolate (4.5%) (Sugar, Cocoa Mass (Rainforest Alliance Certified), Cocoa Butter (Rainforest Alliance Certified), Emulsifier: Soya Lecithin, Flavouring), Glucose Syrup, Humectant: Glycerol, Shortbread Pieces (1.5%) (Fortified Wheat Flour (Wheat, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Shea Kernel, Rapeseed), Sugar, Invert Sugar Syrup, Tapioca Starch, Salt, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Emulsifier: Sunflower Lecithin), Vegetable Oils (contains Sunflower and/or Rapeseed), Sugar, Flavouring, Salt, Emulsifier: Soya Lecithin.'
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

    print(f"✨ BATCH 6 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {18 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch6(db_path)
