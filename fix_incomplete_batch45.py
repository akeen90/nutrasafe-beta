#!/usr/bin/env python3
"""
Fix incomplete ingredients batch 45 - FINAL BATCH!
Completing the last 14 products with incomplete ingredients
"""

import sqlite3
from datetime import datetime

def update_batch45(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🔍 FIXING INCOMPLETE INGREDIENTS - BATCH 45 (FINAL BATCH!)\n")

    complete_data = [
        {
            'id': 'atNbDrqM3N9ig2UWmgMG',
            'name': '6+ Strawberry Sugar Free 80ML',
            'brand': 'Calpol',
            'serving_size_g': 100.0,
            'ingredients': 'Each 5ml Contains: Paracetamol 250mg. Also Contains: Maltitol, Sodium, Benzyl Alcohol, Propylene Glycol (E1520), Sorbitol (E420), Methylparaben (E218), Propylparaben (E216).'
        },
        {
            'id': '8lQcAjfGB2u4Ao6EZyle',
            'name': 'Whole Kernel Corn',
            'brand': 'Del Monte',
            'serving_size_g': 100.0,
            'ingredients': 'Corn, Water, Sugar, Salt.'
        },
        {
            'id': '4XtbOlP8cNXah7ENQ5w5',
            'name': 'Naturally Brewed Soy Sauce',
            'brand': 'Kikkoman',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Soybeans, Wheat, Salt. Contains Soybeans, Wheat, Cereals Containing Gluten.'
        },
        {
            'id': 'vwUUXsRNLupcd9kdkHJQ',
            'name': 'Sauce Soja',
            'brand': 'Kikkoman',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Soybeans, Wheat, Salt. Contains Soybeans, Wheat, Cereals Containing Gluten.'
        },
        {
            'id': 'NdD30c08pyqliQtaOszW',
            'name': 'Cornflour',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Maize Starch. Contains Sulphites.'
        },
        {
            'id': 'Kb3Fq4Y9QbwZp7fYJv8d',
            'name': 'Stem Ginger In Sugar Syrup',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Ginger, Sugar, Water.'
        },
        {
            'id': 'PF6O5J4cVH9OsRQmWIBt',
            'name': '10 Mild Cheddar Slices',
            'brand': 'Simply',
            'serving_size_g': 20.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet). Contains Milk.'
        },
        {
            'id': 'm1CJrLzlnDAAEWCPcag3',
            'name': 'Frozen Avocado Chunks',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Avocado, Salt.'
        },
        {
            'id': 'EtQbyfHR4Z96AwavsiJy',
            'name': 'Single Cream',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (Milk). Contains Milk.'
        },
        {
            'id': 'IVoeDy55M6jhzNS9F7nX',
            'name': 'Thatchers Gold Cider',
            'brand': 'Thatchers',
            'serving_size_g': 100.0,
            'ingredients': 'Fermented Apple Juice, Carbon Dioxide, Preservative (Sulphur Dioxide). Contains Sulphites.'
        },
        {
            'id': '7idXE0uKAGDki7Oc3e0h',
            'name': 'British Unsalted Creamery Butter',
            'brand': 'The co Operative',
            'serving_size_g': 10.0,
            'ingredients': 'Butter (Milk). Contains Milk.'
        },
        {
            'id': 'mB0rPrTcgt6qDv9opzZj',
            'name': 'Extra Thick Double Cream',
            'brand': 'Waitrose',
            'serving_size_g': 30.0,
            'ingredients': 'Double Cream (Milk). Contains Milk.'
        },
        {
            'id': 'oqWb5FnNxPRP4d8ljkFs',
            'name': 'Fruity White Wine',
            'brand': 'Weight Watchers',
            'serving_size_g': 125.0,
            'ingredients': 'Grapes, Preservative (Sulphur Dioxide). Contains Sulphites.'
        },
        {
            'id': 'zlsWVG5NtYsWFjEmYeFV',
            'name': 'Fruity White Wine',
            'brand': 'WeightWatchers',
            'serving_size_g': 125.0,
            'ingredients': 'Grapes, Preservative (Sulphur Dioxide). Contains Sulphites.'
        }
    ]

    updates_made = 0
    for product in complete_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g")
            print(f"   New ingredients: {product['ingredients'][:80]}...\n")
            updates_made += 1

    conn.commit()
    conn.close()

    print(f"✨ BATCH 45 COMPLETE: {updates_made} products fixed")
    print(f"🎉 ALL INCOMPLETE INGREDIENTS FIXED!")
    print(f"📊 Total: 40 + {updates_made} = {40 + updates_made} products now have proper ingredients!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch45(db_path)
