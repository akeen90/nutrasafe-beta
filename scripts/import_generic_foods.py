#!/usr/bin/env python3
"""
Import generic foods from genericfood.sql into the NutraSafe database.
Maps the simpler schema to the comprehensive NutraSafe schema.
"""

import sqlite3
import re
import uuid
import time
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
GENERIC_SQL = Path("/Users/aaronkeen/Desktop/genericfood.sql")
DB_PATH = PROJECT_ROOT / "NutraSafe Beta/Database/nutrasafe_foods.db"

def parse_generic_foods(sql_file):
    """Parse the generic food SQL file and extract food data."""
    with open(sql_file, 'r') as f:
        content = f.read()

    # Extract all INSERT statements
    # Pattern: ('name', 'category', 'serving', size, cal, prot, carb, fat, fib),
    pattern = r"\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)"

    foods = []
    for match in re.finditer(pattern, content):
        name, category, serving_desc, serving_size, cal, prot, carb, fat, fib = match.groups()

        food = {
            'name': name.strip(),
            'category': category.strip(),
            'serving_description': serving_desc.strip(),
            'serving_size_g': float(serving_size),
            'calories_per_100g': float(cal),
            'protein_per_100g': float(prot),
            'carbs_per_100g': float(carb),
            'fat_per_100g': float(fib),  # Note: fibre is in the fat position in the SQL
            'fiber_per_100g': float(fib)
        }
        foods.append(food)

    return foods

def import_to_database(foods, db_path):
    """Import foods into the NutraSafe database."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    imported_count = 0
    skipped_count = 0

    for food in foods:
        try:
            # Generate a unique ID
            food_id = f"generic-{uuid.uuid4()}"

            # Check if food already exists by name
            cursor.execute("SELECT id FROM foods WHERE name = ? AND brand IS NULL", (food['name'],))
            if cursor.fetchone():
                print(f"⏭️  Skipping '{food['name']}' - already exists")
                skipped_count += 1
                continue

            # Get current timestamp
            now = int(time.time())

            # Insert with mapped fields
            cursor.execute("""
                INSERT INTO foods (
                    id, name, brand, barcode,
                    calories, protein, carbs, fat, fiber, sugar, sodium,
                    serving_description, serving_size_g,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                food_id,
                food['name'],
                None,  # brand
                None,  # barcode
                food['calories_per_100g'],
                food['protein_per_100g'],
                food['carbs_per_100g'],
                food['fat_per_100g'],
                food['fiber_per_100g'],
                0.0,  # sugar (not in generic data)
                0.0,  # sodium (not in generic data)
                food['serving_description'],
                food['serving_size_g'],
                now,  # created_at
                now   # updated_at
            ))

            print(f"✅ Imported: {food['name']}")
            imported_count += 1

        except Exception as e:
            print(f"❌ Error importing '{food['name']}': {e}")
            continue

    conn.commit()
    conn.close()

    return imported_count, skipped_count

def main():
    print("🍎 NutraSafe Generic Food Import")
    print("=" * 50)

    # Check files exist
    if not GENERIC_SQL.exists():
        print(f"❌ Error: {GENERIC_SQL} not found!")
        return

    if not DB_PATH.exists():
        print(f"❌ Error: Database not found at {DB_PATH}")
        return

    print(f"📄 Reading generic foods from: {GENERIC_SQL}")
    foods = parse_generic_foods(GENERIC_SQL)
    print(f"📊 Found {len(foods)} foods to import\n")

    print(f"💾 Importing into: {DB_PATH}")
    imported, skipped = import_to_database(foods, DB_PATH)

    print("\n" + "=" * 50)
    print(f"✅ Import complete!")
    print(f"   Imported: {imported}")
    print(f"   Skipped:  {skipped}")
    print(f"   Total:    {len(foods)}")

if __name__ == "__main__":
    main()
