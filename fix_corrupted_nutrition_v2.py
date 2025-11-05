#!/usr/bin/env python3
"""
Fix corrupted nutrition values - Version 2
Handle decimal point errors (values multiplied by 10 or 100)
"""

import sqlite3
from datetime import datetime

def calculate_calories(protein, carbs, fat):
    """Calculate calories from macros (P×4 + C×4 + F×9)"""
    return round(protein * 4 + carbs * 4 + fat * 9, 1)

def fix_corrupted_nutrition_v2(db_path: str):
    """Fix products with nutrition values multiplied by 10 or 100"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Get products with impossible nutrition values
    cursor.execute("""
        SELECT id, name, brand, serving_size_g, calories, protein, carbs, fat, fiber, sugar, sodium
        FROM foods
        WHERE calories > 1000
           OR protein > 100
           OR carbs > 100
           OR fat > 100
        ORDER BY calories DESC
    """)

    corrupted_products = cursor.fetchall()
    print(f"🔍 Found {len(corrupted_products)} products with corrupted nutrition values\n")

    fixed_count = 0
    manual_review = []

    for product in corrupted_products:
        id, name, brand, serving_size, calories, protein, carbs, fat, fiber, sugar, sodium = product

        # Try dividing by 100 first
        test_protein_100 = protein / 100
        test_carbs_100 = carbs / 100
        test_fat_100 = fat / 100
        calculated_cal_100 = calculate_calories(test_protein_100, test_carbs_100, test_fat_100)

        # Try dividing by 10
        test_protein_10 = protein / 10
        test_carbs_10 = carbs / 10
        test_fat_10 = fat / 10
        calculated_cal_10 = calculate_calories(test_protein_10, test_carbs_10, test_fat_10)

        # Check if dividing by 100 gives reasonable values
        if (test_protein_100 < 100 and test_carbs_100 < 100 and test_fat_100 < 100 and
            200 <= calculated_cal_100 <= 900 and
            abs(calculated_cal_100 - calories/100) < 100):

            # Fix by dividing all values by 100
            new_calories = round(calories / 100, 1)
            new_protein = round(protein / 100, 1)
            new_carbs = round(carbs / 100, 1)
            new_fat = round(fat / 100, 1)
            new_fiber = round(fiber / 100, 1) if fiber else 0
            new_sugar = round(sugar / 100, 1) if sugar else 0
            new_sodium = round(sodium / 100, 4) if sodium else 0

            print(f"✅ Fixing (÷100): {brand} - {name}")
            print(f"   Old: {calories} cal, {protein}g protein, {carbs}g carbs, {fat}g fat")
            print(f"   New: {new_calories} cal, {new_protein}g protein, {new_carbs}g carbs, {new_fat}g fat")
            print(f"   Calculated from macros: {calculated_cal_100} cal\n")

            cursor.execute("""
                UPDATE foods
                SET calories = ?, protein = ?, carbs = ?, fat = ?,
                    fiber = ?, sugar = ?, sodium = ?, updated_at = ?
                WHERE id = ?
            """, (new_calories, new_protein, new_carbs, new_fat,
                  new_fiber, new_sugar, new_sodium,
                  int(datetime.now().timestamp()), id))

            fixed_count += 1

        # Check if dividing by 10 gives reasonable values
        elif (test_protein_10 < 100 and test_carbs_10 < 100 and test_fat_10 < 100 and
              200 <= calculated_cal_10 <= 900 and
              abs(calculated_cal_10 - calories/10) < 100):

            # Fix by dividing all values by 10
            new_calories = round(calories / 10, 1)
            new_protein = round(protein / 10, 1)
            new_carbs = round(carbs / 10, 1)
            new_fat = round(fat / 10, 1)
            new_fiber = round(fiber / 10, 1) if fiber else 0
            new_sugar = round(sugar / 10, 1) if sugar else 0
            new_sodium = round(sodium / 10, 4) if sodium else 0

            print(f"✅ Fixing (÷10): {brand} - {name}")
            print(f"   Old: {calories} cal, {protein}g protein, {carbs}g carbs, {fat}g fat")
            print(f"   New: {new_calories} cal, {new_protein}g protein, {new_carbs}g carbs, {new_fat}g fat")
            print(f"   Calculated from macros: {calculated_cal_10} cal\n")

            cursor.execute("""
                UPDATE foods
                SET calories = ?, protein = ?, carbs = ?, fat = ?,
                    fiber = ?, sugar = ?, sodium = ?, updated_at = ?
                WHERE id = ?
            """, (new_calories, new_protein, new_carbs, new_fat,
                  new_fiber, new_sugar, new_sodium,
                  int(datetime.now().timestamp()), id))

            fixed_count += 1

        else:
            # Cannot determine fix - needs manual review
            print(f"⚠️  Manual review needed: {brand} - {name}")
            print(f"   Current: {calories} cal, {protein}g P, {carbs}g C, {fat}g F")
            print(f"   ÷100 would give: {calculated_cal_100} cal")
            print(f"   ÷10 would give: {calculated_cal_10} cal")
            print(f"   Neither seems right\n")
            manual_review.append((id, name, brand, calories, protein, carbs, fat))

    conn.commit()
    conn.close()

    print(f"\n{'='*70}")
    print(f"✨ SUMMARY:")
    print(f"   - Automatically fixed: {fixed_count} products")
    print(f"   - Need manual review: {len(manual_review)} products")
    print(f"{'='*70}\n")

    if manual_review:
        print("📋 Products requiring manual review:")
        for id, name, brand, cal, protein, carbs, fat in manual_review:
            print(f"   - {brand} - {name}")
            print(f"     Current: {cal} cal, {protein}g P, {carbs}g C, {fat}g F")

    # Verify fix
    print("\n🔍 Verification - checking for remaining corrupted products...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT COUNT(*) FROM foods
        WHERE calories > 1000 OR protein > 100 OR carbs > 100 OR fat > 100
    """)
    remaining = cursor.fetchone()[0]
    conn.close()

    print(f"   Remaining corrupted products: {remaining}")

    return fixed_count, len(manual_review)

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🔧 FIXING CORRUPTED NUTRITION VALUES - V2\n")
    fixed, manual = fix_corrupted_nutrition_v2(db_path)
    print(f"\n✅ Complete! Fixed {fixed} products, {manual} need manual review")
