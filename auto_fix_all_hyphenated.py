#!/usr/bin/env python3
"""
Automatically fix ALL remaining hyphenated brands
Convert hyphenated-brands to Proper Capitalization
Handles apostrophes: word-s → Word's
"""

import sqlite3
from datetime import datetime
import re

def auto_fix_all_hyphenated(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🤖 AUTOMATICALLY FIXING ALL HYPHENATED BRANDS\n")
    print("=" * 80)

    # Brands that SHOULD keep hyphens (exceptions)
    keep_hyphens = {
        'Co-op', 'Fever-Tree', 'Coca-Cola', 'M&S', 'Pom-Bear',
        "Ben's Original", 'Häagen-Dazs', 'Go-Cat', 'Jus-Rol',
        'Pop-Tarts', 'Kit-Kat', 'Sugar-Free', 'Gluten-Free',
        'Dairy-Free', 'Wheat-Free', 'Nut-Free', 'Fat-Free',
        'Salt-Free', 'MSG-Free', 'Palm-Oil-Free'
    }

    # Get all hyphenated brands
    cursor.execute("""
        SELECT DISTINCT brand
        FROM foods
        WHERE brand LIKE '%-%'
        ORDER BY brand
    """)

    hyphenated_brands = [row[0] for row in cursor.fetchall()]

    print(f"📊 Found {len(hyphenated_brands)} hyphenated brands\n")

    total_updates = 0
    fixes_made = []

    for old_brand in hyphenated_brands:
        # Skip if this brand should keep hyphens
        if old_brand in keep_hyphens:
            continue

        # Skip if already properly capitalized (has spaces, not hyphens)
        if ' ' in old_brand and '-' not in old_brand:
            continue

        # Convert hyphenated brand to proper spelling
        new_brand = convert_hyphenated_to_proper(old_brand)

        # Only update if the conversion changed something
        if new_brand != old_brand:
            cursor.execute("""
                UPDATE foods
                SET brand = ?, updated_at = ?
                WHERE brand = ?
            """, (new_brand, int(datetime.now().timestamp()), old_brand))

            count = cursor.rowcount
            if count > 0:
                fixes_made.append((old_brand, new_brand, count))
                total_updates += count

    conn.commit()

    # Show all fixes made (limit to first 100 to avoid flooding)
    print("🔄 Fixes applied:\n")
    for old_brand, new_brand, count in fixes_made[:100]:
        print(f"✅ {old_brand} → {new_brand}: {count} foods")

    if len(fixes_made) > 100:
        print(f"\n... and {len(fixes_made) - 100} more fixes\n")

    print("\n" + "=" * 80)
    print(f"✨ TOTAL UPDATES: {total_updates} foods")
    print(f"📊 Total brands fixed: {len(fixes_made)}\n")

    # Final counts
    cursor.execute("SELECT COUNT(DISTINCT brand) FROM foods")
    total_brands = cursor.fetchone()[0]
    print(f"📊 Total unique brands remaining: {total_brands}")

    cursor.execute("""
        SELECT COUNT(DISTINCT brand)
        FROM foods
        WHERE brand LIKE '%-%'
    """)

    remaining_hyphenated = cursor.fetchone()[0]
    print(f"📊 Remaining hyphenated brands: {remaining_hyphenated}")

    # Show example remaining hyphenated brands
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%-%'
        GROUP BY brand
        ORDER BY count DESC
        LIMIT 20
    """)

    print("\n📝 Top remaining hyphenated brands:")
    for row in cursor.fetchall():
        print(f"   - {row[0]}: {row[1]} foods")

    conn.close()

def convert_hyphenated_to_proper(brand: str) -> str:
    """
    Convert hyphenated brand names to proper capitalization
    Examples:
    - word-word → Word Word
    - word-s → Word's
    - word-and-word → Word & Word
    - dr-oetker → Dr. Oetker
    """

    # Split by hyphens
    parts = brand.split('-')

    # Process each part
    converted_parts = []
    for i, part in enumerate(parts):
        # Handle apostrophe cases: word-s → word's
        if part == 's' and i > 0:
            # Previous word gets apostrophe
            converted_parts[-1] = converted_parts[-1] + "'s"
            continue

        # Handle 'and' → '&'
        if part.lower() == 'and':
            converted_parts.append('&')
            continue

        # Handle abbreviations
        if part.lower() == 'dr':
            converted_parts.append('Dr.')
            continue

        if part.lower() == 'st':
            converted_parts.append('St.')
            continue

        if part.lower() == 'mr':
            converted_parts.append('Mr')
            continue

        if part.lower() == 'mrs':
            converted_parts.append('Mrs')
            continue

        # Handle acronyms (all caps, 2-4 letters)
        if len(part) <= 4 and part.isupper():
            converted_parts.append(part)
            continue

        # Handle numbers and mixed alphanumeric
        if part.isdigit() or any(c.isdigit() for c in part):
            converted_parts.append(part.title())
            continue

        # Regular word - capitalize first letter
        if part:
            # Handle special cases like 'mcdonald' → 'McDonald'
            if part.lower().startswith('mc') and len(part) > 2:
                converted_parts.append('Mc' + part[2:].capitalize())
            elif part.lower().startswith('mac') and len(part) > 3:
                converted_parts.append('Mac' + part[3:].capitalize())
            else:
                converted_parts.append(part.capitalize())

    # Join with spaces
    result = ' '.join(converted_parts)

    # Clean up any double spaces
    result = ' '.join(result.split())

    return result

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    auto_fix_all_hyphenated(db_path)
