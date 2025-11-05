#!/usr/bin/env python3
"""
Fix foods with missing brands
Extract brands from food names where possible
"""

import sqlite3
from datetime import datetime
import re

def fix_missing_brands(db_path: str):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    print("🔧 FIXING MISSING BRANDS\n")
    print("=" * 80)

    # Get foods with no brand
    cursor.execute("""
        SELECT id, name, brand
        FROM foods
        WHERE brand IS NULL OR brand = ''
    """)

    foods_no_brand = cursor.fetchall()
    print(f"📊 Found {len(foods_no_brand)} foods with no brand\n")

    # Known brands to extract from names
    known_brands = [
        'M&S', 'Tesco', 'Sainsbury\'s', 'Sainsburys', 'Asda', 'Morrisons',
        'Waitrose', 'Aldi', 'Lidl', 'Co-op', 'Iceland',
        'Cadbury', 'Nestlé', 'Nestle', 'Walkers', 'Heinz', 'Kellogg\'s', 'Kelloggs',
        'Birds Eye', 'Quorn', 'Warburtons', 'McVitie\'s', 'McVities',
        'Müller', 'Muller', 'Galaxy', 'Mars', 'Haribo', 'Mr Kipling',
        'Go Ahead', 'Graze', 'Huel', 'Alpro', 'Innocent', 'Schwartz',
        'Blue Dragon', 'Sharwood\'s', 'Old El Paso', 'Uncle Ben\'s',
        'Ben\'s Original', 'Dolmio', 'Bisto', 'Oxo', 'Paxo',
        'Mr Porky', 'Pom Bear', 'Pombear', 'Kettle', 'Tyrrell\'s',
        'Weetabix', 'Alpen', 'Dorset', 'Rachel\'s', 'Yeo Valley',
        'Cathedral City', 'Seriously', 'Chicago Town',
        'Goodfella\'s', 'Dr Oetker', 'Aunt Bessie\'s',
        'Ben & Jerry\'s', 'Häagen-Dazs', 'Carte D\'Or',
        'Philadelphia', 'Babybel', 'Dairylea', 'Laughing Cow',
        'Lurpak', 'Anchor', 'Flora', 'I Can\'t Believe',
        'Colman\'s', 'Hellmann\'s', 'Branston', 'HP',
        'Carlos', 'Gianni\'s', 'Specially Selected', 'Deluxe',
        'Essential', 'Everyday', 'Smart Price', 'Savers',
        'Taste The Difference', 'Finest', 'Extra Special',
        'Harvest Morn', 'Snackrite', 'Bramwells', 'Crownfield',
        'Chef Select', 'Village Bakery', 'Rowan Hill',
        'Pret', 'Itsu', 'Wagamama', 'Yo! Sushi', 'YO Sushi',
        'Tony\'s', 'Lindt', 'Ferrero', 'Thorntons', 'Green & Black\'s'
    ]

    updates_made = 0
    brand_extraction_count = {}

    for food in foods_no_brand:
        food_id = food['id']
        food_name = food['name']

        # Try to extract brand from name
        extracted_brand = None
        for brand in known_brands:
            # Check if brand name appears at start of food name
            pattern = rf'^{re.escape(brand)}\b'
            if re.search(pattern, food_name, re.IGNORECASE):
                extracted_brand = brand
                break

            # Check if brand name appears anywhere in food name
            pattern = rf'\b{re.escape(brand)}\b'
            if re.search(pattern, food_name, re.IGNORECASE):
                extracted_brand = brand
                break

        if extracted_brand:
            # Normalize brand name
            extracted_brand = normalize_brand(extracted_brand)

            # Update the food with extracted brand
            cursor.execute("""
                UPDATE foods
                SET brand = ?, updated_at = ?
                WHERE id = ?
            """, (extracted_brand, int(datetime.now().timestamp()), food_id))

            updates_made += 1
            brand_extraction_count[extracted_brand] = brand_extraction_count.get(extracted_brand, 0) + 1

    # Set remaining empty brands to 'Generic'
    cursor.execute("""
        UPDATE foods
        SET brand = 'Generic', updated_at = ?
        WHERE brand IS NULL OR brand = ''
    """, (int(datetime.now().timestamp()),))

    generic_count = cursor.rowcount

    conn.commit()

    print("✅ Brand extraction results:\n")
    for brand, count in sorted(brand_extraction_count.items(), key=lambda x: x[1], reverse=True):
        print(f"   {brand}: {count} foods")

    print(f"\n✅ Set {generic_count} foods to 'Generic' brand")
    print(f"\n✨ TOTAL UPDATES: {updates_made + generic_count} foods")

    # Verify
    cursor.execute("SELECT COUNT(*) FROM foods WHERE brand IS NULL OR brand = ''")
    remaining = cursor.fetchone()[0]
    print(f"\n📊 Remaining foods with no brand: {remaining}")

    conn.close()

def normalize_brand(brand: str) -> str:
    """Normalize brand names to standard spelling"""
    brand_map = {
        'sainsburys': 'Sainsbury\'s',
        'kelloggs': 'Kellogg\'s',
        'mcvities': 'McVitie\'s',
        'nestle': 'Nestlé',
        'muller': 'Müller',
        'uncle ben\'s': 'Ben\'s Original',
        'pombear': 'Pom-Bear',
        'yo sushi': 'YO! Sushi',
        'häagen-dazs': 'Häagen-Dazs',
        'haagen-dazs': 'Häagen-Dazs',
        'tony\'s': 'Tony\'s Chocolonely',
        'rachel\'s': 'Rachel\'s',
        'yeo valley': 'Yeo Valley',
        'tyrrell\'s': 'Tyrrell\'s',
        'sharwood\'s': 'Sharwood\'s',
        'colman\'s': 'Colman\'s',
        'hellmann\'s': 'Hellmann\'s',
        'aunt bessie\'s': 'Aunt Bessie\'s',
        'ben & jerry\'s': 'Ben & Jerry\'s',
        'goodfella\'s': 'Goodfella\'s',
        'cathedral city': 'Cathedral City',
        'old el paso': 'Old El Paso',
        'blue dragon': 'Blue Dragon',
        'chicago town': 'Chicago Town',
        'dr oetker': 'Dr. Oetker',
        'green & black\'s': 'Green & Black\'s',
    }

    normalized = brand_map.get(brand.lower(), brand)
    return normalized

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_missing_brands(db_path)
