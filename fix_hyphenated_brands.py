#!/usr/bin/env python3
"""
Fix ALL hyphenated brand names to proper spelling
Convert hyphenated-versions to Proper Capitalization
"""

import sqlite3
from datetime import datetime

def fix_hyphenated_brands(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🔧 FIXING HYPHENATED BRAND NAMES\n")
    print("=" * 80)

    total_updates = 0

    # Comprehensive hyphenated brand fixes
    # Format: (hyphenated, correct)
    hyphenated_fixes = [
        # Supermarket own brands
        ('Specially-selected', 'Specially Selected'),
        ('Aldi-specially-selected', 'Specially Selected'),
        ('Harvest-morn', 'Harvest Morn'),
        ('Chef-select', 'Chef Select'),
        ('Deluxe-lidl', 'Deluxe'),
        ('Essential-waitrose', 'Essential Waitrose'),
        ('Rowan-hill-bakery', 'Rowan Hill Bakery'),
        ('Village-bakery', 'Village Bakery'),
        ('Aldi-village-bakery', 'Village Bakery'),
        ('The-foodie-market', 'The Foodie Market'),
        ('The-foodie-market-aldi', 'The Foodie Market'),

        # Major food brands
        ('Crosta-mollica', 'Crosta & Mollica'),
        ('Plant-menu', 'Plant Menu'),
        ('Bio-me', 'Bio&Me'),
        ('Birds-eye', 'Birds Eye'),
        ('Blue-dragon', 'Blue Dragon'),
        ('Pret-a-manger', 'Pret A Manger'),
        ('Old-el-paso', 'Old El Paso'),
        ('Chicago-town', 'Chicago Town'),
        ('Yeo-valley', 'Yeo Valley'),
        ('Mr-organic', 'Mr Organic'),
        ('Mcvitie-s', "McVitie's"),
        ('Jacob-s', "Jacob's"),
        ('Haagen-dazs', 'Häagen-Dazs'),
        ('Biona-organic', 'Biona Organic'),
        ('Savour-bakes', 'Savour Bakes'),
        ('Kp-snacks', 'KP Snacks'),
        ('The-collective', 'The Collective'),
        ('Graham-s', "Graham's"),
        ('Moser-roth', 'Moser Roth'),
        ('Meadow-fresh', 'Meadow Fresh'),
        ('Eat-natural', 'Eat Natural'),

        # More brands
        ('New-york-bakery', 'New York Bakery Co'),
        ('New-york-bakery-co', 'New York Bakery Co'),
        ('Baker-street', 'Baker Street'),
        ('Baker-boys', 'Baker Boys'),
        ('Black-sheep-craft-bakery', 'Black Sheep Bakery'),
        ('Clay-oven-bakery', 'Clay Oven Bakery'),
        ('Co-op-bakery', 'Co-op'),
        ('Gail-s-bakery', "Gail's Bakery"),
        ('Island-bakery', 'Island Bakery'),
        ('Island-bakery-organics', 'Island Bakery Organics'),
        ('Studio-bakery', 'Studio Bakery'),
        ('The-bakery', 'The Bakery'),
        ('The-bakery-at-asda', 'Asda'),
        ('The-village-bakery', 'The Village Bakery'),
        ('The-wiltshire-bakery', 'The Wiltshire Bakery'),
        ('The-kindness-bakery', 'The Kindness Bakery'),
        ('Bertinet-bakery', 'Bertinet Bakery'),
        ('Argyll-bakeries', 'Argyll Bakeries'),
        ('Ritz-bakery', 'Ritz Bakery'),
        ('Roberts-bakery', "Robert's Bakery"),
        ('Cohens-bakery', "Cohen's Bakery"),
        ('Connell-bakery', 'Connell Bakery'),
        ('Hunts-bakery', "Hunt's Bakery"),
        ('Modens-bakery', "Moden's Bakery"),
        ('Original-biscuit-bakers', 'Original Biscuit Bakers'),

        # Restaurant/takeaway brands
        ('Wagamama-frozen', 'Wagamama'),
        ('Itsu-supermarket-range', 'Itsu'),
        ('Yo-sushi', 'YO! Sushi'),

        # Drinks brands
        ('Fever-tree', 'Fever-Tree'),  # This one is actually correct with hyphen
        ('Coca-cola', 'Coca-Cola'),
        ('Schweppes-mixers', 'Schweppes'),

        # Snack brands
        ('Kettle-chips', 'Kettle Chips'),
        ('Tyrell-s', "Tyrrell's"),
        ('Popchips', 'Popchips'),
        ('Pom-bear', 'Pom-Bear'),
        ('Nom-eat', 'Nom'),

        # Dairy brands
        ('Yeo-valley-organic', 'Yeo Valley'),
        ('Alpro-soya', 'Alpro'),
        ('Arla-organic', 'Arla'),

        # Meat/protein brands
        ('The-meatless-farm-company', 'The Meatless Farm Co'),
        ('Moving-mountains', 'Moving Mountains'),
        ('Quorn-foods', 'Quorn'),

        # International brands
        ('Lee-kum-kee', 'Lee Kum Kee'),
        ('Lingham-s', "Lingham's"),
        ('Hk-dim-sum', 'HK Dim Sum'),
        ('Kikkoman-soy-sauce', 'Kikkoman'),

        # Store locations that should just be store names
        ('Morrisons-on-market-street', 'Morrisons'),
        ('Morrisons-cake-shop-on-market-street', 'Morrisons'),
        ('Cake-shop-on-market-street', 'Morrisons'),
        ('The-fish-market', 'The Fish Market'),
        ('The-foodie-market', 'The Foodie Market'),

        # Other common hyphenated brands
        ('Farm-fresh', 'Farm Fresh'),
        ('Gibsons-farm-shop', "Gibson's Farm Shop"),
        ('Sharpham-farm', 'Sharpham Farm'),
        ('Doves-farm-foods', "Dove's Farm"),
        ('Glebe-farm-foods', 'Glebe Farm'),
        ('Kingdom-dairy', 'Kingdom Dairy'),
        ('Slim-fast', 'SlimFast'),
        ('Slim-lilly', 'Slim Lilly'),
        ('Optimum-nutrition', 'Optimum Nutrition'),
        ('The-gym-kitchen', 'The Gym Kitchen'),
        ('Team-rh', 'Team RH'),
        ('Rhythm-108', 'Rhythm 108'),
        ('Rythm-108', 'Rhythm 108'),
        ('Jim-jams', 'JimJams'),
        ('Fortnum-mason', 'Fortnum & Mason'),
        ('Botham-s-of-whitby', "Botham's of Whitby"),
        ('Tim-s-dairy', "Tim's Dairy"),
        ('I-am-nut-ok', 'I Am Nut OK'),
        ('Free-from-fellows', 'Free From Fellows'),
        ('Fabulous-freefrom-factory', 'Fabulous FreeFrom Factory'),
        ('Braham-murray', 'Braham & Murray'),
    ]

    print("🔄 Applying hyphenated brand fixes...\n")

    for old_brand, new_brand in hyphenated_fixes:
        cursor.execute("""
            UPDATE foods
            SET brand = ?, updated_at = ?
            WHERE brand = ? COLLATE NOCASE
        """, (new_brand, int(datetime.now().timestamp()), old_brand))

        count = cursor.rowcount
        if count > 0:
            print(f"✅ {old_brand} → {new_brand}: {count} foods")
            total_updates += count

    conn.commit()

    print("\n" + "=" * 80)
    print(f"✨ TOTAL UPDATES: {total_updates} foods\n")

    # Count remaining hyphenated brands
    cursor.execute("""
        SELECT COUNT(DISTINCT brand)
        FROM foods
        WHERE brand LIKE '%-%'
        AND brand NOT IN (
            'Co-op', 'Fever-Tree', 'Coca-Cola', 'M&S',
            'Pom-Bear', 'Ben''s Original'
        )
    """)

    remaining_hyphenated = cursor.fetchone()[0]
    print(f"📊 Remaining hyphenated brands: {remaining_hyphenated}")

    # Show top remaining hyphenated brands
    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM foods
        WHERE brand LIKE '%-%'
        AND brand NOT IN (
            'Co-op', 'Fever-Tree', 'Coca-Cola', 'M&S',
            'Pom-Bear', 'Ben''s Original'
        )
        GROUP BY brand
        HAVING count > 3
        ORDER BY count DESC
        LIMIT 20
    """)

    remaining = cursor.fetchall()
    if remaining:
        print("\n⚠️  Top remaining hyphenated brands (need manual review):")
        for row in remaining:
            print(f"   - {row[0]}: {row[1]} foods")

    # Show total unique brands remaining
    cursor.execute("SELECT COUNT(DISTINCT brand) FROM foods")
    total_brands = cursor.fetchone()[0]
    print(f"\n📊 Total unique brands in database: {total_brands}")

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_hyphenated_brands(db_path)
