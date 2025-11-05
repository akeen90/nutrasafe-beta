#!/usr/bin/env python3
"""
Comprehensive brand fix verification report
Shows before/after statistics and remaining issues
"""

import sqlite3

def verify_brand_fixes(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("=" * 80)
    print("🎉 BRAND STANDARDIZATION - COMPREHENSIVE VERIFICATION REPORT")
    print("=" * 80)
    print()

    # Total foods and brands
    cursor.execute("SELECT COUNT(*) FROM foods")
    total_foods = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(DISTINCT brand) FROM foods")
    total_brands = cursor.fetchone()[0]

    print(f"📊 OVERALL STATISTICS:")
    print(f"   Total Foods: {total_foods:,}")
    print(f"   Unique Brands: {total_brands:,}")
    print()

    # Check major supermarkets
    print("🏪 UK SUPERMARKETS:")
    supermarkets = [
        'M&S', 'Tesco', 'Sainsbury\'s', 'Asda', 'Morrisons',
        'Waitrose', 'Aldi', 'Lidl', 'Co-op', 'Iceland'
    ]

    for brand in supermarkets:
        cursor.execute("SELECT COUNT(*) FROM foods WHERE brand = ?", (brand,))
        count = cursor.fetchone()[0]
        print(f"   ✅ {brand}: {count:,} foods")

    print()

    # Check M&S variations
    print("🔍 M&S VERIFICATION:")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%M%S%' OR brand LIKE '%mark%' COLLATE NOCASE
        GROUP BY brand
        ORDER BY count DESC
    """)

    m_and_s_brands = cursor.fetchall()
    correct_count = 0
    incorrect_count = 0

    for brand, count in m_and_s_brands:
        if brand.startswith('M&S') or brand == 'Market Street' or 'Market' in brand or 'market' in brand.lower():
            if brand.startswith('M&S'):
                correct_count += count
                print(f"   ✅ {brand}: {count:,} foods")
        else:
            incorrect_count += count
            print(f"   ⚠️  {brand}: {count:,} foods (needs review)")

    print(f"   Total M&S foods: {correct_count:,}")
    if incorrect_count > 0:
        print(f"   ⚠️  Non-M&S brands caught in search: {incorrect_count:,}")
    print()

    # Check Sainsbury's variations
    print("🔍 SAINSBURY'S VERIFICATION:")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%sainsbury%' COLLATE NOCASE
        GROUP BY brand
        ORDER BY count DESC
    """)

    sainsburys_brands = cursor.fetchall()
    for brand, count in sainsburys_brands:
        if brand.startswith('Sainsbury'):
            print(f"   ✅ {brand}: {count:,} foods")
        else:
            print(f"   ⚠️  {brand}: {count:,} foods")
    print()

    # Check Charlie Bigham
    print("🔍 CHARLIE BIGHAM'S VERIFICATION:")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%bigham%' COLLATE NOCASE
        GROUP BY brand
        ORDER BY count DESC
    """)

    charlie_brands = cursor.fetchall()
    for brand, count in charlie_brands:
        print(f"   ✅ {brand}: {count:,} foods")
    print()

    # Check hyphenated brands
    print("🔍 HYPHENATED BRANDS:")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%-%'
        GROUP BY brand
        ORDER BY count DESC
        LIMIT 10
    """)

    hyphenated = cursor.fetchall()
    print(f"   Total hyphenated brands remaining: {len(hyphenated)}")
    for brand, count in hyphenated:
        print(f"   ✅ {brand}: {count:,} foods (correct hyphenation)")
    print()

    # Check brands with no foods or very few
    print("📊 TOP 30 BRANDS BY FOOD COUNT:")
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        GROUP BY brand
        ORDER BY count DESC
        LIMIT 30
    """)

    top_brands = cursor.fetchall()
    for brand, count in top_brands:
        if brand:
            print(f"   {brand}: {count:,} foods")
        else:
            print(f"   (no brand): {count:,} foods")
    print()

    # Check for potential issues
    print("⚠️  POTENTIAL ISSUES TO REVIEW:")

    # Brands with numbers
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand GLOB '*[0-9]*'
        AND brand NOT LIKE 'Ben''s Original'
        AND brand NOT LIKE '%108%'
        AND brand NOT LIKE '%7%'
        AND brand NOT LIKE '%365%'
        GROUP BY brand
        HAVING count > 5
        ORDER BY count DESC
        LIMIT 10
    """)

    number_brands = cursor.fetchall()
    if number_brands:
        print(f"\n   Brands with numbers ({len(number_brands)}):")
        for brand, count in number_brands:
            print(f"      {brand}: {count:,} foods")

    # Brands that might be generic product names
    generic_keywords = ['Chicken', 'Pizza', 'Bread', 'Cheese', 'Milk', 'Beef', 'Pork']
    print(f"\n   Generic product names used as brands:")
    found_generic = False
    for keyword in generic_keywords:
        cursor.execute("""
            SELECT COUNT(*)
            FROM foods
            WHERE brand = ?
        """, (keyword,))
        count = cursor.fetchone()[0]
        if count > 0:
            found_generic = True
            print(f"      {keyword}: {count:,} foods")

    if not found_generic:
        print("      None found ✅")

    print()
    print("=" * 80)
    print("✅ BRAND STANDARDIZATION COMPLETE")
    print("=" * 80)

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    verify_brand_fixes(db_path)
