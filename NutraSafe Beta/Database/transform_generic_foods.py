#!/usr/bin/env python3
"""
Transform generic foods database:
1. Remove ", raw" from fruits and vegetables
2. Create small/medium/large size variants for applicable items
3. Set brand to "Generic" for all items
4. Keep nutrition per 100g with dynamic serving sizes
"""

import sqlite3
import uuid
from typing import List, Tuple

DB_PATH = "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafe Beta/Database/nutrasafe_foods.db"

# Items that should have size variants (fruits and some vegetables)
SIZE_VARIANT_ITEMS = {
    'apple', 'banana', 'orange', 'pear', 'peach', 'plum', 'nectarine',
    'apricot', 'avocado', 'tomato', 'potato', 'carrot', 'onion',
    'pepper', 'courgette', 'aubergine', 'cucumber'
}

# Serving sizes for small/medium/large variants (in grams)
SIZE_SERVINGS = {
    'apple': {'small': 100, 'medium': 150, 'large': 200},
    'banana': {'small': 80, 'medium': 118, 'large': 150},
    'orange': {'small': 100, 'medium': 150, 'large': 200},
    'pear': {'small': 100, 'medium': 150, 'large': 200},
    'peach': {'small': 100, 'medium': 150, 'large': 200},
    'plum': {'small': 50, 'medium': 75, 'large': 100},
    'nectarine': {'small': 100, 'medium': 140, 'large': 180},
    'apricot': {'small': 50, 'medium': 75, 'large': 100},
    'avocado': {'small': 100, 'medium': 150, 'large': 200},
    'tomato': {'small': 75, 'medium': 120, 'large': 180},
    'potato': {'small': 100, 'medium': 150, 'large': 200},
    'carrot': {'small': 50, 'medium': 75, 'large': 100},
    'onion': {'small': 75, 'medium': 110, 'large': 150},
    'pepper': {'small': 100, 'medium': 150, 'large': 200},
    'courgette': {'small': 100, 'medium': 150, 'large': 200},
    'aubergine': {'small': 150, 'medium': 225, 'large': 300},
    'cucumber': {'small': 100, 'medium': 150, 'large': 200}
}

def get_base_name(name: str) -> str:
    """Remove ', raw' and other preparation suffixes from fruit/veg names"""
    # Remove ", raw" suffix
    if name.endswith(', raw'):
        name = name[:-5]
    return name

def needs_size_variants(name: str) -> bool:
    """Check if this item should have size variants"""
    base = name.lower().split(',')[0].strip()

    # Check for variety names (e.g., "Apple, fuji" -> "apple")
    first_word = base.split()[0]

    return first_word in SIZE_VARIANT_ITEMS

def get_item_key(name: str) -> str:
    """Get the key for size servings lookup"""
    base = name.lower().split(',')[0].strip()
    return base.split()[0]  # First word (e.g., "apple" from "Apple, fuji")

def create_size_variant(row: dict, size: str) -> dict:
    """Create a new row for a specific size variant"""
    new_row = row.copy()

    # Generate new ID
    new_row['id'] = f"generic-{uuid.uuid4()}"

    # Update name to include size (capitalize first letter)
    base_name = get_base_name(row['name'])
    size_capitalized = size.capitalize()
    new_row['name'] = f"{base_name} ({size_capitalized})"

    # Set brand to "Generic"
    new_row['brand'] = 'Generic'

    # Update serving size based on size variant
    item_key = get_item_key(row['name'])
    if item_key in SIZE_SERVINGS:
        new_row['serving_size_g'] = SIZE_SERVINGS[item_key][size]
        # Update serving description to match size
        new_row['serving_description'] = f"1 {size}"

    return new_row

def main():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Get all generic foods
    cursor.execute("""
        SELECT * FROM foods WHERE id LIKE 'generic-%'
    """)

    generic_foods = [dict(row) for row in cursor.fetchall()]
    print(f"Found {len(generic_foods)} generic foods")

    # Track items to delete and add
    items_to_delete = []
    items_to_add = []

    for food in generic_foods:
        original_id = food['id']

        # Check if this item needs size variants
        if needs_size_variants(food['name']):
            # Mark original for deletion
            items_to_delete.append(original_id)

            # Create three size variants
            for size in ['small', 'medium', 'large']:
                new_item = create_size_variant(food, size)
                items_to_add.append(new_item)

            print(f"Creating size variants for: {food['name']}")
        else:
            # Just update the name and brand
            base_name = get_base_name(food['name'])

            # Update in place if name changed or brand needs to be set
            if base_name != food['name'] or food['brand'] != 'Generic':
                cursor.execute("""
                    UPDATE foods
                    SET name = ?, brand = 'Generic'
                    WHERE id = ?
                """, (base_name, original_id))
                print(f"Updated: {food['name']} -> {base_name}")

    # Delete original items that need size variants
    print(f"\nDeleting {len(items_to_delete)} original items...")
    for item_id in items_to_delete:
        cursor.execute("DELETE FROM foods WHERE id = ?", (item_id,))

    # Insert new size variants
    print(f"Inserting {len(items_to_add)} new size variants...")
    for item in items_to_add:
        cursor.execute("""
            INSERT INTO foods (
                id, name, brand, barcode, serving_description, serving_size_g,
                calories, fat, protein, carbs, fiber, sugar, sodium,
                vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
                thiamin_b1, riboflavin_b2, niacin_b3, pantothenic_b5, vitamin_b6,
                biotin_b7, folate_b9, vitamin_b12, choline,
                calcium, iron, magnesium, phosphorus, potassium, zinc,
                copper, manganese, selenium, chromium, molybdenum, iodine,
                ingredients, processing_score, processing_grade, processing_label,
                is_verified, verified_by, verified_at, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            item['id'], item['name'], item['brand'], item.get('barcode'),
            item['serving_description'], item['serving_size_g'],
            item.get('calories'), item.get('fat'), item.get('protein'), item.get('carbs'),
            item.get('fiber'), item.get('sugar'), item.get('sodium'),
            item.get('vitamin_a'), item.get('vitamin_c'), item.get('vitamin_d'),
            item.get('vitamin_e'), item.get('vitamin_k'), item.get('thiamin_b1'),
            item.get('riboflavin_b2'), item.get('niacin_b3'), item.get('pantothenic_b5'),
            item.get('vitamin_b6'), item.get('biotin_b7'), item.get('folate_b9'),
            item.get('vitamin_b12'), item.get('choline'),
            item.get('calcium'), item.get('iron'), item.get('magnesium'),
            item.get('phosphorus'), item.get('potassium'), item.get('zinc'),
            item.get('copper'), item.get('manganese'), item.get('selenium'),
            item.get('chromium'), item.get('molybdenum'), item.get('iodine'),
            item.get('ingredients'), item.get('processing_score'),
            item.get('processing_grade'), item.get('processing_label'),
            item.get('is_verified'), item.get('verified_by'), item.get('verified_at'),
            item.get('created_at'), item.get('updated_at')
        ))

    # Commit changes
    conn.commit()

    # Verify results
    cursor.execute("SELECT COUNT(*) FROM foods WHERE id LIKE 'generic-%'")
    final_count = cursor.fetchone()[0]
    print(f"\n✅ Transformation complete!")
    print(f"Original count: {len(generic_foods)}")
    print(f"Final count: {final_count}")
    print(f"Deleted: {len(items_to_delete)}")
    print(f"Added: {len(items_to_add)}")

    # Show sample results
    print("\n📋 Sample results:")
    cursor.execute("""
        SELECT name, brand, serving_description, serving_size_g
        FROM foods
        WHERE id LIKE 'generic-%'
        AND name LIKE '%Banana%'
        ORDER BY name
    """)
    for row in cursor.fetchall():
        print(f"  {row[0]} | {row[1]} | {row[2]} | {row[3]}g")

    conn.close()

if __name__ == '__main__':
    main()
