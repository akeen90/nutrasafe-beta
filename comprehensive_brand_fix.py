#!/usr/bin/env python3
"""
Comprehensive brand name fix - handles ALL variations
Including hyphenated versions, product lines, and misspellings
"""

import sqlite3
from datetime import datetime

def fix_all_brands(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🔧 COMPREHENSIVE BRAND NAME FIX\n")
    print("=" * 80)

    total_updates = 0

    # PATTERN-BASED CORRECTIONS
    # Format: (pattern, correct_brand, description)
    brand_patterns = [
        # ========== M&S / MARKS & SPENCER ==========
        # All M&S product lines should become "M&S [Product Line]"
        ('M-s-plant-kitchen', 'M&S Plant Kitchen', 'M&S Plant Kitchen'),
        ('M-s-gastropub', 'M&S Gastropub', 'M&S Gastropub'),
        ('M-s-bakery', 'M&S Bakery', 'M&S Bakery'),
        ('M-s-the-bakery', 'M&S Bakery', 'M&S Bakery'),
        ('M-s-collection', 'M&S Collection', 'M&S Collection'),
        ('M-s-eat-well', 'M&S Eat Well', 'M&S Eat Well'),
        ('M-seat-well', 'M&S Eat Well', 'M&S Eat Well (typo fix)'),
        ('M-s-best-ever', 'M&S Our Best Ever', 'M&S Our Best Ever'),
        ('M-s-limited-edition', 'M&S Collection', 'M&S Collection'),
        ('M-s-food-c', 'M&S Food Collection', 'M&S Food Collection'),
        ('M-s-foods', 'M&S', 'M&S Foods → M&S'),
        ('M-s-cafe', 'M&S', 'M&S Cafe → M&S'),
        ('M-and-s', 'M&S', 'M-and-s → M&S'),
        ('Simply-m-s', 'M&S', 'Simply-m-s → M&S'),
        ('Cook-with-m-s', 'M&S', 'Cook-with-m-s → M&S'),
        ('Mark-spencer', 'M&S', 'Mark-spencer → M&S'),
        ('Marks-and-spencer', 'M&S', 'Marks-and-spencer → M&S'),
        ('Marks-and-spencer-s', 'M&S', 'Marks-and-spencer-s → M&S'),
        ("Marks & Spencer's", 'M&S', "Marks & Spencer's → M&S"),
        ('Marks & Spencers', 'M&S', 'Marks & Spencers → M&S'),
        ('Marks & Spencer (m&s) Food', 'M&S', 'Marks & Spencer (m&s) Food → M&S'),
        ('Marks & Spencer Collection', 'M&S Collection', 'Marks & Spencer Collection'),
        ('Marks And Spencer Gastropub', 'M&S Gastropub', 'Marks And Spencer Gastropub'),
        ("Marks And Spencer's Best Ever", 'M&S Our Best Ever', "Marks And Spencer's Best Ever"),

        # ========== CHARLIE BIGHAM ==========
        ('Charlie-bigham-s', "Charlie Bigham's", 'Charlie-bigham-s hyphenated fix'),
        ('Charlie-bigham-sp', "Charlie Bigham's", 'Charlie-bigham-sp abbreviated fix'),
        ('Charlie Bigham', "Charlie Bigham's", 'Charlie Bigham missing apostrophe'),

        # ========== BAKER TOM'S ==========
        ('Baker-tom-s', "Baker Tom's", "Baker-tom-s hyphenated fix"),

        # ========== SAINSBURY'S ==========
        # Keep sub-brands as "Sainsbury's [Sub-brand]"
        ('By-sainsbury-s', "Sainsbury's", "By-sainsbury-s → Sainsbury's"),
        ('By-sainsburys', "Sainsbury's", "By-sainsburys → Sainsbury's"),
        ('Free-from-by-sainsbury-s', "Sainsbury's Free From", "Free-from-by-sainsbury-s"),
        ('Free-from-by-sainsbury\'s', "Sainsbury's Free From", "Free-from-by-sainsbury's"),
        ('Sainsbury-s-bakery', "Sainsbury's Bakery", 'Sainsbury-s-bakery hyphenated'),
        ('Sainsbury-s-basic', "Sainsbury's", 'Sainsbury-s-basic → Sainsbury\'s'),
        ('Sainsbury-s-be-good-to-yourself', "Sainsbury's Be Good To Yourself", 'Sainsbury-s-be-good-to-yourself'),
        ('Sainsbury-s-free-from', "Sainsbury's Free From", 'Sainsbury-s-free-from'),
        ('Sainsbury-s-pizza', "Sainsbury's", 'Sainsbury-s-pizza → Sainsbury\'s'),
        ('Sainsbury-s-plant-pioneers', "Sainsbury's Plant Pioneers", 'Sainsbury-s-plant-pioneers'),
        ('Sainsbury-s-sourdough-bloomer', "Sainsbury's", 'Sainsbury-s-sourdough-bloomer → Sainsbury\'s'),
        ('Sainsburys-plant-pioneers', "Sainsbury's Plant Pioneers", 'Sainsburys-plant-pioneers'),
        ('Sainsburys-taste-the-difference', "Sainsbury's Taste The Difference", 'Sainsburys-taste-the-difference'),
        ('Taste-the-difference-sainsburys', "Sainsbury's Taste The Difference", 'Taste-the-difference-sainsburys'),
        ('By Stamford Street Co Sainsbury\'s', "Sainsbury's", 'By Stamford Street Co Sainsbury\'s'),

        # ========== OTHER COMMON BRANDS ==========
        ('Cadburys', 'Cadbury', 'Cadburys → Cadbury'),
        ('Kelloggs', "Kellogg's", 'Kelloggs → Kellogg\'s'),
        ('Nestle', 'Nestlé', 'Nestle → Nestlé'),
        ('Muller', 'Müller', 'Muller → Müller'),
        ('Mueller', 'Müller', 'Mueller → Müller'),
        ('McVities', "McVitie's", 'McVities → McVitie\'s'),
        ('Warburton', 'Warburtons', 'Warburton → Warburtons'),
        ('Coop', 'Co-op', 'Coop → Co-op'),
        ('Co-operative', 'Co-op', 'Co-operative → Co-op'),
        ('Morrison', 'Morrisons', 'Morrison → Morrisons'),
    ]

    print("\n🔄 Applying pattern-based corrections...\n")

    for old_brand, new_brand, description in brand_patterns:
        # Use exact match with COLLATE NOCASE for case-insensitive but preserving the pattern
        cursor.execute("""
            UPDATE foods
            SET brand = ?, updated_at = ?
            WHERE brand = ? COLLATE NOCASE
        """, (new_brand, int(datetime.now().timestamp()), old_brand))

        count = cursor.rowcount
        if count > 0:
            print(f"✅ {description}: {count} foods")
            total_updates += count

    conn.commit()

    print("\n" + "=" * 80)
    print(f"✨ TOTAL UPDATES: {total_updates} foods\n")

    # Verification queries
    print("🔍 VERIFICATION:\n")

    # Check for remaining M&S variations
    cursor.execute("""
        SELECT DISTINCT brand
        FROM foods
        WHERE (brand LIKE '%m-s%' OR brand LIKE '%mark%' OR brand LIKE '%M&S%')
        AND brand != 'M&S'
        AND brand NOT LIKE 'M&S %'
        AND brand NOT LIKE 'Market%'
        AND brand NOT LIKE '%market%'
        COLLATE NOCASE
        ORDER BY brand
    """)

    remaining_ms = cursor.fetchall()
    if remaining_ms:
        print("⚠️  Remaining M&S variations that need manual review:")
        for row in remaining_ms:
            cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (row[0],))
            count = cursor.fetchone()[0]
            print(f"   - {row[0]} ({count} foods)")
    else:
        print("✅ All M&S variations fixed!")

    # Check for remaining Charlie Bigham variations
    cursor.execute("""
        SELECT DISTINCT brand
        FROM foods
        WHERE brand LIKE '%bigham%' COLLATE NOCASE
        ORDER BY brand
    """)

    charlie_brands = cursor.fetchall()
    print(f"\n📊 Charlie Bigham brands: {len(charlie_brands)}")
    for row in charlie_brands:
        cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (row[0],))
        count = cursor.fetchone()[0]
        print(f"   - {row[0]} ({count} foods)")

    # Check for remaining Baker variations
    cursor.execute("""
        SELECT DISTINCT brand
        FROM foods
        WHERE brand LIKE '%baker-tom%' COLLATE NOCASE
        ORDER BY brand
    """)

    baker_brands = cursor.fetchall()
    if baker_brands:
        print(f"\n⚠️  Remaining Baker-tom variations:")
        for row in baker_brands:
            cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (row[0],))
            count = cursor.fetchone()[0]
            print(f"   - {row[0]} ({count} foods)")
    else:
        print("\n✅ All Baker Tom's variations fixed!")

    # Check for remaining Sainsbury's variations
    cursor.execute("""
        SELECT DISTINCT brand
        FROM foods
        WHERE brand LIKE '%sainsbury%' COLLATE NOCASE
        AND brand NOT LIKE 'Sainsbury\'s%'
        AND brand != 'Sainsbury\'s'
        ORDER BY brand
    """)

    remaining_sainsburys = cursor.fetchall()
    if remaining_sainsburys:
        print(f"\n⚠️  Remaining Sainsbury's variations that need review:")
        for row in remaining_sainsburys:
            cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (row[0],))
            count = cursor.fetchone()[0]
            print(f"   - {row[0]} ({count} foods)")
    else:
        print("\n✅ All Sainsbury's variations fixed!")

    # Show final major brand counts
    print("\n" + "=" * 80)
    print("📊 FINAL BRAND COUNTS (Major Brands):\n")

    major_brands = [
        'M&S', 'M&S Plant Kitchen', 'M&S Gastropub', 'M&S Bakery', 'M&S Collection',
        "Charlie Bigham's", "Baker Tom's",
        "Sainsbury's", "Sainsbury's Taste The Difference", "Sainsbury's Free From",
        'Tesco', 'Asda', 'Morrisons', 'Waitrose', 'Aldi', 'Lidl', 'Co-op'
    ]

    for brand in major_brands:
        cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (brand,))
        count = cursor.fetchone()[0]
        if count > 0:
            print(f"  {brand}: {count}")

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_all_brands(db_path)
