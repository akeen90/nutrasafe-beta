#!/usr/bin/env python3
"""
Clean up duplicate Charlie Bigham's products
"""

import sqlite3

def clean_duplicates(db_path: str):
    """Remove duplicate Charlie Bigham's products"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # IDs to remove (older duplicates with less descriptive names)
    duplicates_to_remove = [
        {
            'id': 'ZypZkMM0CEO3zEkQo7Rc',
            'name': 'Cottage Pie',
            'reason': 'Duplicate of "Cottage Pie for 2" with same barcode 5033665211295'
        },
        {
            'id': 'vu5oOUIizXEfX38JdFfr',
            'name': 'Charlie Bigham Lasagne',
            'reason': 'Duplicate of "Lasagne for 2" with same barcode 5033665206864'
        }
    ]

    removed_count = 0

    print("🧹 CLEANING DUPLICATE CHARLIE BIGHAM'S PRODUCTS\n")

    for duplicate in duplicates_to_remove:
        # Verify it exists before deleting
        cursor.execute("""
            SELECT name, brand FROM foods WHERE id = ?
        """, (duplicate['id'],))

        result = cursor.fetchone()

        if result:
            # Delete the duplicate
            cursor.execute("DELETE FROM foods WHERE id = ?", (duplicate['id'],))

            print(f"❌ Removed: {result[1]} - {result[0]}")
            print(f"   ID: {duplicate['id']}")
            print(f"   Reason: {duplicate['reason']}\n")
            removed_count += 1
        else:
            print(f"⚠️  Not found: {duplicate['name']} (ID: {duplicate['id']})\n")

    conn.commit()
    conn.close()

    return removed_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("=" * 60)
    print("CHARLIE BIGHAM'S DUPLICATE CLEANUP")
    print("=" * 60)
    print()

    removed = clean_duplicates(db_path)

    print()
    print("=" * 60)
    print(f"✨ COMPLETE: {removed} duplicate products removed!")
    print("=" * 60)
