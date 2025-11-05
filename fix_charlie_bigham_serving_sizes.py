#!/usr/bin/env python3
"""
Fix Charlie Bigham's product serving sizes
Many products incorrectly have 100g when they should have accurate meal weights
"""

import sqlite3
from datetime import datetime

def fix_charlie_bigham_servings(db_path: str):
    """Update Charlie Bigham's products with correct serving sizes"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Correct serving sizes based on research from retailer websites
    serving_fixes = [
        {
            'id': 'L1u1sM2AaW54aD0gnhNx',
            'name': 'Bread & Butter Pudding',
            'old_serving': 100.0,
            'new_serving': 362.0,
            'source': 'Waitrose/M&S - full pack'
        },
        {
            'id': '4U4NyEvbfUebfRoC5u52',
            'name': 'Butter Chicken Curry',
            'old_serving': 100.0,
            'new_serving': 228.0,
            'source': 'FatSecret - 1 serving (half of 456g pack)'
        },
        {
            'id': 'k3H9WSaaAPLYlUXolIj5',
            'name': 'Charlie Bigham\'s Butter Chicken Curry & Pilau Rice',
            'old_serving': 100.0,
            'new_serving': 402.5,
            'source': 'Typical curry & rice serving (half of 805g pack)'
        },
        {
            'id': 'uOhe9ULQ6BrU1iOSY8Bf',
            'name': 'Charlie Bigham\'s Coq Au Vin',
            'old_serving': 100.0,
            'new_serving': 402.5,
            'source': 'Tesco/Sainsbury\'s - half of 805g pack'
        },
        {
            'id': 'PaPsNGAYa1mo6ja8o9tf',
            'name': 'Chicken Madras',
            'old_serving': 100.0,
            'new_serving': 228.5,
            'source': 'OpenFoodFacts - half of 457g pack'
        },
        {
            'id': 'q8OxIBcrVNJtGvLt9MBY',
            'name': 'Chicken Satay Curry & Fragrant Rice',
            'old_serving': 100.0,
            'new_serving': 402.5,
            'source': 'Tesco/Waitrose - half of 805g pack'
        },
        {
            'id': 'JGPuLAxcs9nLmt0zoNtP',
            'name': 'Chicken Tikka Masala',
            'old_serving': 100.0,
            'new_serving': 228.0,
            'source': 'Typical curry serving (half of 456g pack)'
        },
        {
            'id': 'ksU9VLr9MrmXMtRUrt0d',
            'name': 'Chilli Con Carne And Mexican Rice',
            'old_serving': 100.0,
            'new_serving': 420.0,
            'source': 'FatSecret - half of 840g pack'
        },
        {
            'id': 'etPBqS39UsBCTnQROrKv',
            'name': 'Moussaka',
            'old_serving': 100.0,
            'new_serving': 327.0,
            'source': 'FatSecret - half of 654g pack'
        },
        {
            'id': 'L2V3gJP5bNmbCBI4EeSF',
            'name': 'Paella With Chicken, King Prawns & Chorizo',
            'old_serving': 100.0,
            'new_serving': 400.0,
            'source': 'FatSecret - half of 800g pack'
        },
        {
            'id': 'y6KeZcWH0aN6Bk0aHk5K',
            'name': 'Salmon En Croute',
            'old_serving': 100.0,
            'new_serving': 220.0,
            'source': 'Tesco/Sainsbury\'s - half of 440g pack (2 portions)'
        },
        {
            'id': 'Nu934wGkCaZFA2Yxfr1K',
            'name': 'Smoked Haddock Gratin',
            'old_serving': 100.0,
            'new_serving': 325.0,
            'source': 'Tesco/Sainsbury\'s - half of 650g pack'
        },
        {
            'id': 'HzFgLguyVwX0ja8s6r3z',
            'name': 'Sweet Potato & Bean Chilli With Mexican Rice',
            'old_serving': 100.0,
            'new_serving': 420.0,
            'source': 'Typical rice meal serving (half pack)'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())
    fixed_count = 0

    print("🔧 FIXING CHARLIE BIGHAM'S SERVING SIZES\n")

    for product in serving_fixes:
        cursor.execute("""
            UPDATE foods
            SET serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (
            product['new_serving'],
            current_timestamp,
            product['id']
        ))

        if cursor.rowcount > 0:
            print(f"✅ {product['name']}")
            print(f"   Old: {product['old_serving']}g → New: {product['new_serving']}g")
            print(f"   Source: {product['source']}\n")
            fixed_count += 1
        else:
            print(f"⚠️  {product['name']} - ID not found in database\n")

    conn.commit()
    conn.close()

    print(f"✨ COMPLETE: {fixed_count} products updated with correct serving sizes")
    return fixed_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("=" * 60)
    print("CHARLIE BIGHAM'S SERVING SIZE FIX")
    print("=" * 60)
    print()

    fixed = fix_charlie_bigham_servings(db_path)

    print()
    print("=" * 60)
    print(f"All Charlie Bigham's products now have accurate serving sizes!")
    print("=" * 60)
