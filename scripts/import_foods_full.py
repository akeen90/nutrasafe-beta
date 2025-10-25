#!/usr/bin/env python3
"""
Import foods from foods_full.db into NutraSafe database.
Maps the complete schema with sugar, sodium, and ingredients.
"""

import sqlite3
import uuid
import time
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
SOURCE_DB = Path("/Users/aaronkeen/Desktop/foods_full.db")
TARGET_DB = PROJECT_ROOT / "NutraSafe Beta/Database/nutrasafe_foods.db"

def import_foods():
    """Import foods from source database to NutraSafe database."""

    # Connect to both databases
    source_conn = sqlite3.connect(SOURCE_DB)
    target_conn = sqlite3.connect(TARGET_DB)

    source_cursor = source_conn.cursor()
    target_cursor = target_conn.cursor()

    # Get all foods from source database
    source_cursor.execute("""
        SELECT
            name,
            category,
            serving_description,
            serving_size_g,
            calories_per_100g,
            protein_g_per_100g,
            carbs_g_per_100g,
            fat_g_per_100g,
            fibre_g_per_100g,
            sugar_g_per_100g,
            sodium_mg_per_100g,
            ingredients
        FROM foods
        ORDER BY name
    """)

    foods = source_cursor.fetchall()
    total = len(foods)

    print(f"📊 Found {total} foods to import\n")

    imported_count = 0
    skipped_count = 0

    for idx, food_data in enumerate(foods, 1):
        (name, category, serving_desc, serving_size,
         calories, protein, carbs, fat, fiber, sugar, sodium, ingredients) = food_data

        print(f"[{idx}/{total}] Processing: {name}")

        # Check if food already exists (avoid duplicates)
        target_cursor.execute(
            "SELECT id FROM foods WHERE name = ? AND brand IS NULL",
            (name,)
        )

        if target_cursor.fetchone():
            print(f"   ⏭️  Already exists")
            skipped_count += 1
            continue

        # Generate unique ID
        food_id = f"generic-{uuid.uuid4()}"

        # Get current timestamp
        now = int(time.time())

        try:
            # Insert into NutraSafe database
            # Note: NutraSafe uses 'fiber' not 'fibre', and sodium is in mg (already correct)
            target_cursor.execute("""
                INSERT INTO foods (
                    id, name, brand, barcode,
                    calories, protein, carbs, fat, fiber, sugar, sodium,
                    serving_description, serving_size_g,
                    ingredients,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                food_id,
                name,
                None,  # brand - generic foods have no brand
                None,  # barcode
                calories,
                protein,
                carbs,
                fat,
                fiber,
                sugar,
                sodium,  # Already in mg
                serving_desc,
                serving_size,
                ingredients,
                now,  # created_at
                now   # updated_at
            ))

            print(f"   ✅ Imported (Sugar: {sugar:.1f}g, Sodium: {sodium:.0f}mg)")
            imported_count += 1

        except Exception as e:
            print(f"   ❌ Error: {e}")
            continue

    # Commit and close
    target_conn.commit()
    source_conn.close()
    target_conn.close()

    return imported_count, skipped_count

def main():
    print("🍎 NutraSafe Foods Import (foods_full.db)")
    print("=" * 50)

    # Check source database exists
    if not SOURCE_DB.exists():
        print(f"❌ Error: Source database not found at {SOURCE_DB}")
        return

    # Check target database exists
    if not TARGET_DB.exists():
        print(f"❌ Error: Target database not found at {TARGET_DB}")
        return

    print(f"📄 Source: {SOURCE_DB}")
    print(f"💾 Target: {TARGET_DB}\n")

    # Import foods
    imported, skipped = import_foods()

    print("\n" + "=" * 50)
    print(f"✅ Import complete!")
    print(f"   Imported: {imported}")
    print(f"   Skipped:  {skipped}")
    print(f"   Total:    {imported + skipped}")

if __name__ == "__main__":
    main()
