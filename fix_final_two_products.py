#!/usr/bin/env python3
"""
Fix the final 2 corrupted products with correct IDs
"""

import sqlite3
from datetime import datetime

def fix_final_two(db_path: str):
    """Update the final 2 products with correct IDs"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Verified nutrition data with CORRECT IDs
    verified_products = [
        {
            'id': 'RHjsIgPDQRkSmPcq1r2Z',  # Correct ID
            'name': 'Abernethy Biscuits',
            'brand': 'Simmers',
            'calories': 495,
            'protein': 6.2,
            'carbs': 65.6,
            'fat': 22.7,
            'fiber': 2.0,
            'sugar': 20.7,
            'source': 'FatSecret UK, Tesco'
        },
        {
            'id': 'qOiob6hKs2vtO0ToJbc2',  # Correct ID
            'name': 'Pickled Sliced Beetroot',
            'brand': 'Waitrose',
            'calories': 48,
            'protein': 1.2,
            'carbs': 9.0,
            'fat': 0.5,
            'fiber': 1.5,
            'sugar': 8.0,
            'source': 'Waitrose website'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    print("🔧 FIXING FINAL 2 CORRUPTED PRODUCTS\n")

    for product in verified_products:
        cursor.execute("""
            SELECT name, brand, calories, protein, carbs, fat
            FROM foods WHERE id = ?
        """, (product['id'],))

        current = cursor.fetchone()
        if current:
            name, brand, old_cal, old_protein, old_carbs, old_fat = current

            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   OLD: {old_cal} cal, {old_protein}g P, {old_carbs}g C, {old_fat}g F")
            print(f"   NEW: {product['calories']} cal, {product['protein']}g P, {product['carbs']}g C, {product['fat']}g F")
            print(f"   Source: {product['source']}\n")

            cursor.execute("""
                UPDATE foods
                SET calories = ?, protein = ?, carbs = ?, fat = ?,
                    fiber = ?, sugar = ?, updated_at = ?
                WHERE id = ?
            """, (
                product['calories'],
                product['protein'],
                product['carbs'],
                product['fat'],
                product['fiber'],
                product['sugar'],
                current_timestamp,
                product['id']
            ))

    conn.commit()
    conn.close()

    print("✅ Fixed final 2 products!\n")

    # Verify
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("""
        SELECT COUNT(*) FROM foods
        WHERE calories > 1000 OR protein > 100 OR carbs > 100 OR fat > 100
    """)
    remaining = cursor.fetchone()[0]

    cursor.execute("""
        SELECT name, brand, calories FROM foods
        WHERE calories > 1000 OR protein > 100 OR carbs > 100 OR fat > 100
        ORDER BY calories DESC
    """)
    remaining_products = cursor.fetchall()

    conn.close()

    print(f"📊 FINAL VERIFICATION:")
    print(f"   - Remaining corrupted: {remaining}")

    if remaining_products:
        print(f"\n⚠️  Still needs manual review:")
        for name, brand, calories in remaining_products:
            print(f"   - {brand} - {name} ({calories} cal)")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_final_two(db_path)
