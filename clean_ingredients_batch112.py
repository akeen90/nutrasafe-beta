#!/usr/bin/env python3
"""
Clean ingredients for batch 112 of messy products - FINAL BATCH (1018 products!)
"""

import sqlite3
from datetime import datetime
import re

def clean_ingredient_text(text):
    """Clean ingredient text by removing common junk patterns"""
    if not text:
        return text

    # Remove common junk patterns
    patterns_to_remove = [
        r'SUITABLE FOR.*?(?=\.|$)',
        r'Allergy [Aa]dvice[:\!].*?(?=\.|$)',
        r'Storage [Ii]nstructions?[:\!].*?(?=\.|$)',
        r'Nutrition[al]?.*?[Vv]alues?.*?(?=\.|$)',
        r'Per 100g.*?(?=\.|$)',
        r'WARNING[:\!].*?(?=\.|$)',
        r'Typical values.*?(?=\.|$)',
        r'Energy.*?kcal.*?(?=\.|$)',
        r'DIETARY ADVICE[:\!].*?(?=\.|$)',
        r'Best [Bb]efore.*?(?=\.|$)',
        r'Keep refrigerated.*?(?=\.|$)',
        r'May contain.*?(?=\.|$)',
        r'ALLERGY ADVICE.*?(?=\.|$)',
        r'For allergens.*?(?=\.|$)',
        r'NUTRITION.*?(?=\.|$)',
        r'\d+kJ.*?(?=\.|$)',
        r'Recycle.*?(?=\.|$)',
        r'Store in.*?(?=\.|$)',
        r'INGREDIENTS?[:\!]',
        r'Packaged in.*?(?=\.|$)',
        r'[Aa]llergy [Aa]dvice',
        r'[Ff]or allergens, see ingredients in bold',
        r'[Mm]ay also contain.*?(?=\.|$)',
    ]

    cleaned = text
    for pattern in patterns_to_remove:
        cleaned = re.sub(pattern, '', cleaned, flags=re.IGNORECASE | re.MULTILINE)

    # Clean up extra spaces and punctuation
    cleaned = re.sub(r'\s+', ' ', cleaned)
    cleaned = re.sub(r'\s*,\s*,\s*', ', ', cleaned)
    cleaned = cleaned.strip(' ,.')

    return cleaned

def update_batch112(db_path: str):
    """Update batch 112 of products with cleaned ingredients - FINAL BATCH!"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Read raw data from file
    with open('/tmp/batch112_raw.txt', 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    clean_data = []
    for line in lines:
        parts = line.strip().split('|')
        if len(parts) >= 5:
            product_id = parts[0]
            name = parts[1]
            brand = parts[2]
            try:
                serving_size = float(parts[3])
            except:
                serving_size = 100.0
            ingredients = '|'.join(parts[4:])  # Join remaining parts in case of pipes in ingredients

            # Clean the ingredients
            cleaned_ingredients = clean_ingredient_text(ingredients)

            # Only add if we have meaningful cleaned ingredients
            if cleaned_ingredients and len(cleaned_ingredients) > 10:
                clean_data.append({
                    'id': product_id,
                    'name': name,
                    'brand': brand,
                    'serving_size_g': serving_size,
                    'ingredients': cleaned_ingredients
                })

    current_timestamp = int(datetime.now().timestamp())
    updated = 0

    for i, product in enumerate(clean_data):
        try:
            cursor.execute("""
                UPDATE foods
                SET ingredients = ?, serving_size_g = ?, updated_at = ?
                WHERE id = ?
            """, (product['ingredients'], product['serving_size_g'], current_timestamp, product['id']))

            if cursor.rowcount > 0:
                updated += 1
                # Only print every 50th product to reduce output
                if updated % 50 == 0:
                    print(f"✅ Progress: {updated} products cleaned...")
        except Exception as e:
            print(f"❌ Error updating {product['name']}: {str(e)}\n")

    conn.commit()
    conn.close()

    print(f"\n✨ BATCH 112 COMPLETE: {updated} products cleaned")

    # Calculate new total
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM foods WHERE updated_at IS NOT NULL AND updated_at > 0")
    total = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM foods WHERE ingredients LIKE '%SUITABLE FOR%' OR ingredients LIKE '%Allergy Advice%' OR ingredients LIKE '%Storage%' OR ingredients LIKE '%Nutrition%' OR ingredients LIKE '%Per 100g%' OR ingredients LIKE '%WARNING%' OR ingredients LIKE '%Typical values%'")
    remaining = cursor.fetchone()[0]
    conn.close()

    print(f"📊 TOTAL CLEANED: {total} products")
    print(f"🎯 REMAINING MESSY: {remaining} products")

    # Check for milestones
    percentage = (total / (total + remaining)) * 100 if (total + remaining) > 0 else 0
    print(f"💪 Progress: {percentage:.1f}% complete")

    if remaining == 0:
        print("\n🎉🎉🎉 100% COMPLETE - ALL INGREDIENTS CLEANED! 🎉🎉🎉")

    print("\n🚀 BATCH 112 - FINAL BATCH COMPLETE! 🚀")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🧹 CLEANING INGREDIENTS - BATCH 112 (FINAL BATCH!)\n")
    update_batch112(db_path)
