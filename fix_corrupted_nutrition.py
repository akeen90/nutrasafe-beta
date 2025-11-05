#!/usr/bin/env python3
"""
Fix corrupted nutrition values in the database.
These products have per-package values mistakenly entered as per-100g values.
"""

import sqlite3
from datetime import datetime

def fix_corrupted_nutrition(db_path: str):
    """Fix products with nutrition values that appear to be per-package instead of per-100g"""

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

        # Check if values appear to be for whole package (calories > serving_size)
        if calories > serving_size and serving_size > 0:
            # Calculate per-100g values from per-package values
            multiplier = 100.0 / serving_size

            new_calories = round(calories * multiplier, 1)
            new_protein = round(protein * multiplier, 1)
            new_carbs = round(carbs * multiplier, 1)
            new_fat = round(fat * multiplier, 1)
            new_fiber = round(fiber * multiplier, 1) if fiber else 0
            new_sugar = round(sugar * multiplier, 1) if sugar else 0
            new_sodium = round(sodium * multiplier, 4) if sodium else 0

            # Sanity check: per-100g values should be reasonable
            if new_calories < 900 and new_protein < 100 and new_carbs < 100 and new_fat < 100:
                print(f"✅ Fixing: {brand} - {name}")
                print(f"   Serving size: {serving_size}g")
                print(f"   Old (per-package): {calories} cal, {protein}g protein")
                print(f"   New (per-100g): {new_calories} cal, {new_protein}g protein\n")

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
                # Still unreasonable after conversion - needs manual review
                print(f"⚠️  Manual review needed: {brand} - {name}")
                print(f"   Calculated per-100g would be: {new_calories} cal, {new_protein}g protein")
                print(f"   This still seems wrong - flagging for manual review\n")
                manual_review.append((id, name, brand, calories, new_calories))
        else:
            # Can't determine correction method - needs manual review
            print(f"⚠️  Manual review needed: {brand} - {name}")
            print(f"   Current: {calories} cal, {protein}g protein per 100g")
            print(f"   Cannot determine correct fix automatically\n")
            manual_review.append((id, name, brand, calories, None))

    conn.commit()
    conn.close()

    print(f"\n{'='*70}")
    print(f"✨ SUMMARY:")
    print(f"   - Automatically fixed: {fixed_count} products")
    print(f"   - Need manual review: {len(manual_review)} products")
    print(f"{'='*70}\n")

    if manual_review:
        print("📋 Products requiring manual review:")
        for id, name, brand, old_cal, new_cal in manual_review:
            status = f"Would be {new_cal} cal" if new_cal else "No fix available"
            print(f"   - {brand} - {name} (currently {old_cal} cal, {status})")

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

    print("🔧 FIXING CORRUPTED NUTRITION VALUES\n")
    fixed, manual = fix_corrupted_nutrition(db_path)
    print(f"\n✅ Complete! Fixed {fixed} products, {manual} need manual review")
