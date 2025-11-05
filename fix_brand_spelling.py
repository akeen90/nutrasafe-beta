#!/usr/bin/env python3
"""
Fix ALL brand name spellings to be correct
Standardize UK supermarket names properly
"""

import sqlite3
from datetime import datetime

def fix_brand_spelling(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🏪 Fixing ALL brand name spellings...\n")

    # Comprehensive brand corrections
    # Format: (incorrect_pattern, correct_name)
    brand_corrections = [
        # UK Supermarkets
        ('m-s', 'M&S'),
        ('m&s', 'M&S'),
        ('marks-spencer', 'M&S'),
        ('marks & spencer', 'M&S'),
        ('marks and spencer', 'M&S'),
        ('marks-spencer', 'M&S'),
        ('m&s food', 'M&S'),
        ('m-s-food', 'M&S'),

        ('sainsbury-s', 'Sainsbury\'s'),
        ('sainsburys', 'Sainsbury\'s'),
        ('by sainsbury\'s', 'Sainsbury\'s'),
        ('by sainsburys', 'Sainsbury\'s'),
        ('by-sainsbury-s', 'Sainsbury\'s'),
        ('sainsbury', 'Sainsbury\'s'),

        ('tesco-finest', 'Tesco Finest'),
        ('tesco finest', 'Tesco Finest'),

        ('taste-the-difference', 'Sainsbury\'s Taste The Difference'),
        ('sainsbury-s-taste-the-difference', 'Sainsbury\'s Taste The Difference'),

        ('co-op', 'Co-op'),
        ('coop', 'Co-op'),
        ('co-operative', 'Co-op'),
        ('cooperative', 'Co-op'),

        # Keep standard capitalizations
        ('tesco', 'Tesco'),
        ('asda', 'Asda'),
        ('morrisons', 'Morrisons'),
        ('waitrose', 'Waitrose'),
        ('aldi', 'Aldi'),
        ('lidl', 'Lidl'),
        ('iceland', 'Iceland'),
        ('farmfoods', 'Farmfoods'),

        # Major brands
        ('kellogg\'s', 'Kellogg\'s'),
        ('kelloggs', 'Kellogg\'s'),

        ('cadbury', 'Cadbury'),
        ('cadburys', 'Cadbury'),

        ('mcvitie\'s', 'McVitie\'s'),
        ('mcvities', 'McVitie\'s'),

        ('heinz', 'Heinz'),

        ('nestlé', 'Nestlé'),
        ('nestle', 'Nestlé'),

        ('coca-cola', 'Coca-Cola'),
        ('coca cola', 'Coca-Cola'),
        ('cocacola', 'Coca-Cola'),

        ('pepsi-cola', 'Pepsi'),
        ('pepsicola', 'Pepsi'),

        ('walkers', 'Walkers'),

        ('quorn', 'Quorn'),

        ('hovis', 'Hovis'),

        ('warburtons', 'Warburtons'),

        ('flora', 'Flora'),

        ('anchor', 'Anchor'),

        ('philadelphia', 'Philadelphia'),

        ('ben\'s original', 'Ben\'s Original'),
        ('bens original', 'Ben\'s Original'),
        ('uncle ben\'s', 'Ben\'s Original'),
        ('uncle bens', 'Ben\'s Original'),

        ('muller', 'Müller'),
        ('muller', 'Müller'),

        ('bird\'s eye', 'Birds Eye'),
        ('birds eye', 'Birds Eye'),
        ('birdseye', 'Birds Eye'),

        ('branston', 'Branston'),

        ('colman\'s', 'Colman\'s'),
        ('colmans', 'Colman\'s'),

        ('bisto', 'Bisto'),

        ('weetabix', 'Weetabix'),
    ]

    updates_made = 0

    for old_brand, new_brand in brand_corrections:
        cursor.execute("""
            UPDATE foods
            SET brand = ?, updated_at = ?
            WHERE LOWER(brand) = ?
        """, (new_brand, int(datetime.now().timestamp()), old_brand.lower()))

        if cursor.rowcount > 0:
            print(f"✅ {old_brand} → {new_brand} ({cursor.rowcount} foods)")
            updates_made += cursor.rowcount

    conn.commit()

    print(f"\n🎉 Total updates: {updates_made}")

    # Show final brand counts for major supermarkets
    print("\n📊 Final Brand Counts (Major UK Supermarkets):")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand IN ('M&S', 'Tesco', 'Tesco Finest', 'Sainsbury''s',
                        'Sainsbury''s Taste The Difference', 'Asda', 'Morrisons',
                        'Waitrose', 'Aldi', 'Lidl', 'Co-op', 'Iceland')
        GROUP BY brand
        ORDER BY count DESC
    """)

    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}")

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_brand_spelling(db_path)
