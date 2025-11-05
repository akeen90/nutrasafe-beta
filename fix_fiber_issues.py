#!/usr/bin/env python3
"""
Fix fiber values that were incorrectly set during cleanup
Meats, bacon, ham, and very low-carb items should have 0 or minimal fiber
"""

import sqlite3
from datetime import datetime

def fix_fiber_issues(db_path: str):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    print("🔧 Fixing incorrect fiber values for meats and low-carb items...")

    # Get foods where fiber > carbs and carbs are very low (< 1g)
    # These are likely meats/proteins that shouldn't have fiber
    cursor.execute("""
        SELECT id, name, brand, carbs, fiber
        FROM foods
        WHERE fiber > carbs
        AND carbs < 1.0
        AND (
            LOWER(name) LIKE '%bacon%' OR
            LOWER(name) LIKE '%ham%' OR
            LOWER(name) LIKE '%beef%' OR
            LOWER(name) LIKE '%chicken%' OR
            LOWER(name) LIKE '%turkey%' OR
            LOWER(name) LIKE '%pork%' OR
            LOWER(name) LIKE '%lamb%' OR
            LOWER(name) LIKE '%fish%' OR
            LOWER(name) LIKE '%salmon%' OR
            LOWER(name) LIKE '%tuna%' OR
            LOWER(name) LIKE '%corned beef%' OR
            LOWER(name) LIKE '%lardons%' OR
            LOWER(name) LIKE '%breast%' OR
            LOWER(name) LIKE '%squash%' OR
            LOWER(name) LIKE '%kombucha%' OR
            LOWER(name) LIKE '%spread%'
        )
    """)

    foods_to_fix = cursor.fetchall()

    for food in foods_to_fix:
        # Set fiber to 0 for meats and very low carb items
        cursor.execute("""
            UPDATE foods
            SET fiber = 0, updated_at = ?
            WHERE id = ?
        """, (int(datetime.now().timestamp()), food['id']))

        print(f"✅ {food['name']} ({food['brand'] or 'No brand'}): fiber {food['fiber']:.1f}g → 0g")

    conn.commit()

    print(f"\n✅ Fixed {len(foods_to_fix)} foods with incorrect fiber values")

    # Verify the fix
    cursor.execute("""
        SELECT COUNT(*) as remaining
        FROM foods
        WHERE fiber > carbs * 2
    """)

    remaining = cursor.fetchone()['remaining']
    print(f"📊 Remaining high-fiber foods: {remaining}")

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_fiber_issues(db_path)
