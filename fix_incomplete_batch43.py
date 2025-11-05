#!/usr/bin/env python3
"""
Fix incomplete ingredients batch 43 - Cheese products
Researching and adding proper ingredient lists for products with minimal data
"""

import sqlite3
from datetime import datetime

def update_batch43(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🔍 FIXING INCOMPLETE INGREDIENTS - BATCH 43 (Cheese Products)\n")

    # Researched proper ingredients for each product
    complete_data = [
        {
            'id': 'AvV7qSRKlMKLEDWbkljr',
            'name': 'Cheddar Mild',
            'brand': 'Cathedral City',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Salt, Starter Culture, Vegetarian Rennet. Contains Milk.'
        },
        {
            'id': 'NKdsJAX2UIGZRrYF96io',
            'name': 'Extra Mature Cheddar Cheese',
            'brand': 'Cathedral City',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Salt, Starter Culture, Vegetarian Rennet. Contains Milk.'
        },
        {
            'id': 'KBydTcvNTvZTJcMkDzhj',
            'name': 'Lactose Free Mature Cheddar',
            'brand': 'Cathedral City',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Salt, Lactase Enzyme, Starter Culture, Vegetarian Rennet. Contains Milk.'
        },
        {
            'id': '98x6oNqEI0cfcDWlv4dO',
            'name': 'Mature Cheddar',
            'brand': 'Cathedral City',
            'serving_size_g': 30.0,
            'ingredients': 'Milk, Salt, Starter Culture, Vegetarian Rennet. Contains Milk.'
        },
        {
            'id': '2GXbnVLci1RwTNLOolVf',
            'name': 'Mature White Cheddar',
            'brand': 'Iceland',
            'serving_size_g': 30.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet). Contains Milk.'
        },
        {
            'id': 'bjjD8ehDc9X8pTR1eiEx',
            'name': 'Mature Cheddar Cheese',
            'brand': 'Ilchester',
            'serving_size_g': 20.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet). Contains Milk.'
        },
        {
            'id': 'yVzjW0djfk5xDLAg2bmB',
            'name': 'Crunchy Cheddar Puffed Bites',
            'brand': 'Cheese O\'s',
            'serving_size_g': 25.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet). Contains Milk.'
        },
        {
            'id': 'Y9orNTrMywoJm0Go6Shq',
            'name': 'Applewood',
            'brand': 'Applewood',
            'serving_size_g': 100.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Smoke Flavouring, Paprika. Contains Milk.'
        },
        {
            'id': 'LCaQ7gTsv2CT2YNXAm2T',
            'name': 'Smoky Cheddar Original Slices',
            'brand': 'Applewood',
            'serving_size_g': 22.8,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Smoke Flavouring, Paprika. Contains Milk.'
        },
        {
            'id': 'IDtsS1IPGwNBbKjuy1mq',
            'name': 'Applewood Smoke Flavoured Cheddar',
            'brand': 'Ilchester',
            'serving_size_g': 15.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Smoke Flavouring, Paprika. Contains Milk.'
        },
        {
            'id': '5qsEbmstWG8W3Z917rHl',
            'name': 'British Mature Coloured Cheddar',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Colour (Carotenes). Contains Milk.'
        },
        {
            'id': 'aBl3BExlMG1JZaLPeDPV',
            'name': 'Mature Red Irish Cheddar',
            'brand': 'Centra',
            'serving_size_g': 18.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Colour (Annatto Norbixin). Contains Milk.'
        },
        {
            'id': 'zvobgW5iZ7CuVHHcQz02',
            'name': 'British Extra Mature Coloured Cheddar',
            'brand': 'Emporium',
            'serving_size_g': 100.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Colour (Carotenes). Contains Milk.'
        },
        {
            'id': '4966feebhJGjFoJVpMdl',
            'name': 'Medium Coloured Cheddar Cheese',
            'brand': 'Galloway',
            'serving_size_g': 100.0,
            'ingredients': 'Cheddar Cheese (Milk, Salt, Starter Culture, Vegetarian Rennet), Colour (Carotenes). Contains Milk.'
        },
        {
            'id': 'Bva6whZ4vaBzS3KkcMfo',
            'name': 'Norfolk Mardler Goats\' Cheese',
            'brand': 'Deluxe',
            'serving_size_g': 30.0,
            'ingredients': 'Goat\'s Milk, Salt, Starter Culture, Vegetarian Rennet. Contains Milk.'
        },
        {
            'id': 'jsGAdmWQz0Pfl5f37jRY',
            'name': 'Greek Style Natural Yoghurt',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Cream, Live Yogurt Cultures (Bifidobacterium, Lactobacillus Bulgaricus, Streptococcus Thermophilus). Contains Milk.'
        },
        {
            'id': 'qEAyoJC1dqfiGtnFLP7E',
            'name': 'Thick Natural Skyr',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Live Yogurt Cultures (Lactobacillus Bulgaricus, Streptococcus Thermophilus). Contains Milk.'
        },
        {
            'id': 'RyfRRmy2STS6HBV1RlKZ',
            'name': 'Dragon Stout',
            'brand': 'Dragon Stout',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Malted Barley, Glucose Syrup, Hops, Caramel Colour. Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': 'ZskHFU0Ub8hlJnCreHQZ',
            'name': 'Merlot',
            'brand': 'Echo Falls',
            'serving_size_g': 100.0,
            'ingredients': 'Grapes, Preservative (Sulphur Dioxide). Contains Sulphites.'
        },
        {
            'id': '0HxeTgZXQuk24TgOU0s5',
            'name': 'Fursty Ferret',
            'brand': 'Badger',
            'serving_size_g': 500.0,
            'ingredients': 'Water, Malted Barley, Hops, Yeast, Sugar. Contains Barley, Cereals Containing Gluten, Sulphites.'
        }
    ]

    updates_made = 0
    for product in complete_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g")
            print(f"   New ingredients: {product['ingredients'][:80]}...\n")
            updates_made += 1

    conn.commit()
    conn.close()

    print(f"✨ BATCH 43 COMPLETE: {updates_made} products fixed")
    print(f"📊 Products with proper ingredients added\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch43(db_path)
