#!/usr/bin/env python3
"""
Fix remaining hyphenated brands - Round 2
"""

import sqlite3
from datetime import datetime

def fix_remaining_hyphenated(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🔧 FIXING REMAINING HYPHENATED BRANDS - ROUND 2\n")
    print("=" * 80)

    total_updates = 0

    # More hyphenated brand fixes
    fixes = [
        # Major remaining brands
        ('Häagen-Dazs', 'Häagen-Dazs'),  # This is actually correct with hyphen
        ('Haagen-Dazs', 'Häagen-Dazs'),   # But fix non-umlaut version
        ('Moo-free', 'Moo Free'),
        ('Go-ahead', 'Go Ahead'),
        ('Deli-kitchen', 'Deli Kitchen'),
        ('Bon-appetit', 'Bon Appétit'),
        ('Asia-specialities', 'Asia Specialities'),
        ('Wicked-kitchen', 'Wicked Kitchen'),
        ('Waitrose-partners', 'Waitrose'),
        ('Tower-gate', 'Tower Gate'),
        ('Tony-s-chocolonely', "Tony's Chocolonely"),
        ('The-deli', 'The Deli'),
        ('Snack-a-jacks', 'Snack a Jacks'),
        ('Rowan-hill', 'Rowan Hill Bakery'),
        ('John-west', 'John West'),
        ('Hartley-s', "Hartley's"),
        ('Goodfella-s', "Goodfella's"),
        ('Gianni-s', "Gianni's"),
        ('Deliciously-ella', 'Deliciously Ella'),
        ('Valley-spire', 'Valley Spire'),
        ('Strong-roots', 'Strong Roots'),

        # More common patterns
        ('Aunt-bessie-s', "Aunt Bessie's"),
        ('Aunt-bessies', "Aunt Bessie's"),
        ('Ben-jerry-s', "Ben & Jerry's"),
        ('Ben-jerrys', "Ben & Jerry's"),
        ('Birds-eye-green-cuisine', 'Birds Eye Green Cuisine'),
        ('Bonne-maman', 'Bonne Maman'),
        ('Brew-dog', 'BrewDog'),
        ('Cathedral-city', 'Cathedral City'),
        ('Charlie-bingham-s', "Charlie Bigham's"),
        ('Charlie-binghams', "Charlie Bigham's"),
        ('Clover', 'Clover'),
        ('Dr-oetker', 'Dr. Oetker'),
        ('Eat-real', 'Eat Real'),
        ('El-azteca', 'El Azteca'),
        ('Fray-bentos', 'Fray Bentos'),
        ('Fruity-king', 'Fruity King'),
        ('Go-cat', 'Go-Cat'),
        ('Green-giant', 'Green Giant'),
        ('Graze', 'Graze'),
        ('Hovis-best-of-both', 'Hovis Best of Both'),
        ('Innocent', 'Innocent'),
        ('Jus-rol', 'Jus-Rol'),
        ('Kettle-chips', 'Kettle Chips'),
        ('Kingsmill-50-50', 'Kingsmill 50/50'),
        ('Kit-kat', 'KitKat'),
        ('La-zuppa', 'La Zuppa'),
        ('Lindt-lindor', 'Lindt'),
        ('Little-moons', 'Little Moons'),
        ('Love-corn', 'Love Corn'),
        ('Mars', 'Mars'),
        ('Mary-berry', 'Mary Berry'),
        ('Mega-monster-munch', 'Monster Munch'),
        ('Monster-munch', 'Monster Munch'),
        ('Mr-kipling', 'Mr Kipling'),
        ('Nakd', 'Nakd'),
        ('Nando-s', "Nando's"),
        ('Nature-valley', 'Nature Valley'),
        ('New-covent-garden', 'New Covent Garden Soup Co'),
        ('New-covent-garden-soup', 'New Covent Garden Soup Co'),
        ('Oatly', 'Oatly'),
        ('Paxo', 'Paxo'),
        ('Peroni-nastro-azzurro', 'Peroni'),
        ('Pete-s', "Pete's"),
        ('Pip-nut', 'Pip & Nut'),
        ('Planet-organic', 'Planet Organic'),
        ('Pop-tarts', 'Pop-Tarts'),
        ('Pot-noodle', 'Pot Noodle'),
        ('Pret', 'Pret A Manger'),
        ('Propercorn', 'Propercorn'),
        ('Rachel-s', "Rachel's"),
        ('Ragu', 'Ragú'),
        ('Real-handful', 'Real Handful'),
        ('Ritter-sport', 'Ritter Sport'),
        ('Rude-health', 'Rude Health'),
        ('Rustlers', 'Rustlers'),
        ('Schwartz', 'Schwartz'),
        ('Sea-salt', 'Sea Salt'),
        ('Seeds-of-change', 'Seeds of Change'),
        ('Sharwood-s', "Sharwood's"),
        ('Simply-cook', 'Simply Cook'),
        ('Skinny-food-co', 'The Skinny Food Co'),
        ('Soreen', 'Soreen'),
        ('Stokes', 'Stokes'),
        ('Sweet-freedom', 'Sweet Freedom'),
        ('Tasteology', 'Tasteology'),
        ('The-co-operative', 'Co-op'),
        ('The-cooperative', 'Co-op'),
        ('Tribe', 'Tribe'),
        ('Tropicana', 'Tropicana'),
        ('Uncle-ben-s', "Ben's Original"),
        ('Uncle-bens', "Ben's Original"),
        ('Urban-eats', 'Urban Eats'),
        ('Vegan-bowl', 'Vegan Bowl'),
        ('Wagamama', 'Wagamama'),
        ('Wall-s', "Wall's"),
        ('Warburton-s', 'Warburtons'),
        ('Weight-watchers', 'WeightWatchers'),
        ('Weetabix-on-the-go', 'Weetabix'),
        ('Whittard', 'Whittard'),
        ('Yo-sushi', 'YO! Sushi'),
        ('Young-s', "Young's"),
    ]

    print("🔄 Applying remaining hyphenated brand fixes...\n")

    for old_brand, new_brand in fixes:
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

    # Show totals
    cursor.execute("SELECT COUNT(DISTINCT brand) FROM foods")
    total_brands = cursor.fetchone()[0]
    print(f"📊 Total unique brands: {total_brands}")

    cursor.execute("""
        SELECT COUNT(DISTINCT brand)
        FROM foods
        WHERE brand LIKE '%-%'
        AND brand NOT IN (
            'Co-op', 'Fever-Tree', 'Coca-Cola', 'M&S',
            'Pom-Bear', 'Ben''s Original', 'Häagen-Dazs',
            'Go-Cat', 'Jus-Rol', 'Pop-Tarts'
        )
    """)

    remaining_hyphenated = cursor.fetchone()[0]
    print(f"📊 Remaining hyphenated brands: {remaining_hyphenated}")

    conn.close()

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    fix_remaining_hyphenated(db_path)
