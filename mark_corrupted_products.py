#!/usr/bin/env python3
"""
Mark products with unfixable corrupted nutrition data
These products need manual data entry or should be deleted
"""

import sqlite3
from datetime import datetime

def mark_corrupted_products(db_path: str):
    """Mark products that couldn't be automatically fixed as corrupted"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # These are the IDs of products that couldn't be fixed automatically
    corrupted_ids = [
        'jteDq1Ne9xYezlbNLhnB',  # Korean Style Chicken On Seeded Bread
        'unk6MNhkpuUb0uxUWiC3',  # Chocolate Chip Salted Caramel Bar
        'wNGeaCeigsITF3AfFGSQ',  # Rice Krispies Squares Gooey Marshmallow
        'iZ1pqA2OKldjcSbkPcEm',  # Brunch Choc Chip
        'rQ6cPhxgvPjdm6om3hP8',  # Toffee Crisp
        '2vhilInQOkvvkqS3RtnJ',  # Honey NUT Flakes
        'HHrfToIRzliugKsBr8Pt',  # Caramel Latte
        'LaGY8wWLhYQj7V3TP66A',  # Protein Salted Caramel Nut
        'MyHtwZ3hKzgub9GPETIx',  # Belgian Milk Chocolate
        '9kqCfkxoJfZ7iyRiEYIc',  # Hazelnut, Pecan & Maple Oat Bars
        'cORPAFwbc99LIywrR7sC',  # Hula Hoops Puft (salted)
        'AJmUK6e4XTXOh4JagYMj',  # Fruit & Fibre Fruity Crunch
        'wMZTxnJZ8qWqQ5fYYhj0',  # Abernethy Biscuits
        'JXxuLhz8Bp1Euf0Qg56e',  # Pickled Sliced Beetroot
    ]

    # Add a note to the ingredients field indicating data quality issue
    updated = 0
    for product_id in corrupted_ids:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ingredients || ' [DATA QUALITY WARNING: Nutrition values appear corrupted - needs manual verification]',
                updated_at = ?
            WHERE id = ? AND ingredients NOT LIKE '%DATA QUALITY WARNING%'
        """, (int(datetime.now().timestamp()), product_id))

        if cursor.rowcount > 0:
            updated += 1

            # Get product details for logging
            cursor.execute("SELECT name, brand FROM foods WHERE id = ?", (product_id,))
            result = cursor.fetchone()
            if result:
                name, brand = result
                print(f"⚠️  Marked: {brand} - {name}")

    conn.commit()
    conn.close()

    print(f"\n✅ Marked {updated} products with data quality warnings")

    return updated

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("⚠️  MARKING CORRUPTED PRODUCTS\n")
    count = mark_corrupted_products(db_path)
    print(f"\n✅ Complete! Marked {count} products needing manual review")
