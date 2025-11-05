#!/usr/bin/env python3
"""
Clean ingredients batch 5 - Biscuits & Cakes
"""

import sqlite3
from datetime import datetime

def update_batch5(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 5 (Biscuits & Cakes)\n")

    clean_data = [
        {
            'id': 'KJS8pZpkXfqn2QbuFfqA',
            'name': 'Wagon Wheels 6 Jammie',
            'brand': "Burton's Biscuits",
            'serving_size_g': 39.0,  # Per wheel (6 pack)
            'ingredients': 'Wheat Flour (with Calcium Carbonate, Iron, Niacin and Thiamin), Chocolate Flavoured Coating (23%) (Sugar, Vegetable Fats (Sustainable Palm Kernel, Sustainable Palm, Shea), Dried Whey (Milk), Fat Reduced Cocoa Powder, Emulsifiers (E476, Soya Lecithin)), Mallow (19%) (Glucose Syrup, Gelling Agent (Beef Gelatine), Acidity Regulator (Citric Acid)), Sugar, Vegetable Oil (Sustainable Palm), Raspberry Flavoured Apple Jam (5%) (Glucose-Fructose Syrup, Apples, Sugar, Humectant (Glycerol), Acid (Citric Acid), Acidity Regulator (Sodium Citrates), Flavourings, Colours (Anthocyanins, Annatto Norbixin), Gelling Agent (Pectin)), Invert Sugar Syrup, Glucose Syrup, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Humectant (Glycerol), Salt, Flavouring.'
        },
        {
            'id': 'gewTAKFYYF92bhqBg5X3',
            'name': 'Mini Eggs Choc Cake',
            'brand': 'Cadbury',
            'serving_size_g': 62.0,  # 370g / 6 cakes
            'ingredients': 'Chocolate Flavour Creme (35%) (Sugar, Vegetable Oils (Palm, Rapeseed), Water, Glucose Syrup, Fat Reduced Cocoa Powder, Emulsifiers (E471, Soya Lecithin), Preservative (Potassium Sorbate), Flavouring), MILK Chocolate (17%) (Sugar, Cocoa Mass, Cocoa Butter, Dried Skimmed MILK, MILK Fat, Vegetable Fat (Palm), Dried Whey (from MILK), Emulsifier (Soya Lecithin)), WHEAT Flour (with added Calcium, Iron, Niacin, Thiamin), Glucose Syrup, Sugar, Mini EGGS (5%) (Sugar, MILK, Cocoa Butter, Cocoa Mass, Dried Skimmed MILK, Dried Whey (from MILK), Vegetable Fats (Palm, Shea), MILK Fat, Modified Maize and Tapioca Starches, Emulsifiers (E442, E476), Flavourings, Maltodextrin, Colours (Anthocyanins, Beetroot Red, Paprika Extract, Carotenes)), MILK Chocolate Curls (5%) (Sugar, Cocoa Butter, Dried Whole MILK, Cocoa Mass, Dried Whey (from MILK), Lactose (MILK), Emulsifier (Soya Lecithin), Flavouring), Humectant (Glycerine), Water, Rapeseed Oil, Whole EGG, Starch, Dried Whey (MILK), Emulsifiers (E481, E471, E477, E475), Fat Reduced Cocoa Powder, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Salt, Preservatives (Potassium Sorbate, Sorbic Acid).'
        },
        {
            'id': '8TcIjeh8lMZP4jAwdago',
            'name': 'Club Mint',
            'brand': "McVitie's",
            'serving_size_g': 22.0,  # Per bar (7 pack)
            'ingredients': 'Milk Chocolate Flavour Coating (49%) (Sugar, Vegetable Oils (Palm, Shea), Cocoa Mass, Dried Whey (Milk), Dried Skimmed Milk, Butter Oil (Milk), Emulsifier (Soya Lecithin), Natural Flavouring), Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Palm Oil, Sugar, Glucose Syrup, Raising Agents (Sodium Bicarbonate, Disodium Diphosphate, Ammonium Bicarbonate), Salt, Natural Mint Flavouring.'
        },
        {
            'id': 'INYW10Ob1jNobt09onQn',
            'name': 'Jaffa Jonuts',
            'brand': "McVitie's",
            'serving_size_g': 43.0,  # Per individual pack (4 x 43g multipack)
            'ingredients': 'Orange Flavoured Filling (21%) (Sugar, Water, Glucose Syrup, Dextrose, Invert Sugar Syrup, Concentrated Orange Juice, Stabiliser (Pectin), Acidity Regulators (Citric Acid, Sodium Citrates), Natural Orange Flavouring, Preservative (Potassium Sorbate)), Wheat Flour, Dark Chocolate (14%) (Sugar, Cocoa Mass, Vegetable Fats (Palm, Shea), Butter Oil (Milk), Cocoa Butter, Emulsifiers (Soya Lecithin, E476), Natural Flavouring), Water, Sugar, Vegetable Oil (Sunflower), Humectants (Glycerine, Sorbitol), Glucose Syrup, Whole Egg, Starch, Dried Whey (Milk), Emulsifiers (E481, E477, E471, E475), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Salt, Natural Orange Flavouring, Invert Sugar Syrup, Preservatives (Sorbic Acid, Potassium Sorbate).'
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

    print(f"✨ BATCH 5 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {14 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch5(db_path)
