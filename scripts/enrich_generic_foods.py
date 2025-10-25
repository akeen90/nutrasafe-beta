#!/usr/bin/env python3
"""
Enrich generic foods with USDA FoodData Central data.
Adds sugar, sodium, and ingredients information to the imported generic foods.
"""

import sqlite3
import requests
import time
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
DB_PATH = PROJECT_ROOT / "NutraSafe Beta/Database/nutrasafe_foods.db"

# USDA FoodData Central API
# Get your free API key from: https://fdc.nal.usda.gov/api-key-signup.html
USDA_API_KEY = "DEMO_KEY"  # Replace with your API key for production use
USDA_SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"
USDA_FOOD_URL = "https://api.nal.usda.gov/fdc/v1/food"

def search_usda_food(food_name):
    """Search USDA FoodData Central for a food by name."""
    try:
        params = {
            'api_key': USDA_API_KEY,
            'query': food_name,
            'pageSize': 5,
            'dataType': ['Foundation', 'SR Legacy']  # Prioritize high-quality data
        }

        response = requests.get(USDA_SEARCH_URL, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()

        if data.get('foods'):
            # Return the best match (first result)
            return data['foods'][0]
        return None

    except Exception as e:
        print(f"   ⚠️  USDA search error for '{food_name}': {e}")
        return None

def extract_nutrients(usda_food):
    """Extract sugar and sodium from USDA food data."""
    nutrients = {
        'sugar': 0.0,
        'sodium': 0.0,
        'ingredients': None
    }

    if not usda_food:
        return nutrients

    # Extract nutrients from foodNutrients array
    for nutrient in usda_food.get('foodNutrients', []):
        nutrient_name = nutrient.get('nutrientName', '').lower()
        nutrient_number = nutrient.get('nutrientNumber', '')
        value = nutrient.get('value', 0)

        # Sugar (Total sugars) - Nutrient ID 269
        if 'sugar' in nutrient_name and 'total' in nutrient_name:
            nutrients['sugar'] = value

        # Sodium - Nutrient ID 307
        if nutrient_number == '307' or (nutrient_name == 'sodium'):
            # Convert mg to mg (already in mg per 100g)
            nutrients['sodium'] = value

    # Extract ingredients if available
    if usda_food.get('ingredients'):
        nutrients['ingredients'] = usda_food['ingredients']

    return nutrients

def enrich_database():
    """Enrich generic foods in the database with USDA data."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Get all generic foods (those without brands)
    cursor.execute("""
        SELECT id, name, sugar, sodium, ingredients
        FROM foods
        WHERE brand IS NULL AND id LIKE 'generic-%'
        ORDER BY name
    """)

    foods = cursor.fetchall()
    total = len(foods)

    print(f"📊 Found {total} generic foods to enrich\n")

    enriched_count = 0
    skipped_count = 0
    failed_count = 0

    for idx, (food_id, name, current_sugar, current_sodium, current_ingredients) in enumerate(foods, 1):
        print(f"[{idx}/{total}] Processing: {name}")

        # Skip if already has data
        if current_sugar > 0 and current_sodium > 0:
            print(f"   ⏭️  Already enriched")
            skipped_count += 1
            continue

        # Search USDA database
        usda_food = search_usda_food(name)

        if not usda_food:
            print(f"   ❌ No USDA match found")
            failed_count += 1
            time.sleep(0.5)  # Rate limiting for DEMO_KEY
            continue

        # Extract nutrients
        nutrients = extract_nutrients(usda_food)

        # Update database
        try:
            cursor.execute("""
                UPDATE foods
                SET sugar = ?,
                    sodium = ?,
                    ingredients = ?,
                    updated_at = ?
                WHERE id = ?
            """, (
                nutrients['sugar'],
                nutrients['sodium'],
                nutrients['ingredients'],
                int(time.time()),
                food_id
            ))

            print(f"   ✅ Sugar: {nutrients['sugar']:.1f}g, Sodium: {nutrients['sodium']:.0f}mg")
            enriched_count += 1

        except Exception as e:
            print(f"   ❌ Database update error: {e}")
            failed_count += 1

        # Rate limiting (DEMO_KEY allows 30 requests/hour)
        time.sleep(2)

    conn.commit()
    conn.close()

    return enriched_count, skipped_count, failed_count

def main():
    print("🌾 USDA FoodData Central Enrichment")
    print("=" * 50)

    # Check database exists
    if not DB_PATH.exists():
        print(f"❌ Error: Database not found at {DB_PATH}")
        return

    # Warning about API key
    if USDA_API_KEY == "DEMO_KEY":
        print("⚠️  Using DEMO_KEY (rate limited to 30 requests/hour)")
        print("   Get a free API key at: https://fdc.nal.usda.gov/api-key-signup.html")
        print("   For faster processing, replace USDA_API_KEY in this script\n")

    print(f"💾 Database: {DB_PATH}\n")

    # Enrich foods
    enriched, skipped, failed = enrich_database()

    print("\n" + "=" * 50)
    print(f"✅ Enrichment complete!")
    print(f"   Enriched: {enriched}")
    print(f"   Skipped:  {skipped}")
    print(f"   Failed:   {failed}")
    print(f"   Total:    {enriched + skipped + failed}")

if __name__ == "__main__":
    main()
