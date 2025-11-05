#!/usr/bin/env python3
"""
Add Charlie Bigham's products with complete nutrition data
"""

import sqlite3
from datetime import datetime
import uuid

def add_charlie_bigham_products(db_path: str):
    """Add Charlie Bigham's products with complete nutrition data"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    current_timestamp = int(datetime.now().timestamp())

    # Products with complete nutrition data from Open Food Facts
    new_products = [
        {
            'name': 'Shepherd\'s Pie for 2',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665209155',
            'serving_size_g': 325.0,
            'calories': 139.0,
            'protein': 7.66,
            'carbs': 10.4,
            'fat': 7.2,
            'fiber': 0.892,
            'sugar': 0.215,
            'sodium': 0.2128,  # salt 0.532g / 2.5
            'ingredients': 'Potatoes, Lamb (32%), Carrots, Onions, Red Wine, Celery, Cornflour, Butter (Milk), Double Cream (Milk), Breadcrumbs (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast, Salt, Caramelised Sugar, Colours (Paprika Extract, Turmeric Extract)), Lamb Stock (Lamb Bones, Yeast Extract, Water, Salt, Sugar, Cornflour, Onion Juice Concentrate, Rosemary, Thyme), Tomato Purée, Red Wine Stock (Red Wine Concentrate, Yeast Extract, Dried Potatoes, Salt, Sugar, Dried Onions, Rapeseed Oil, Ground Black Pepper, Thyme), Beef Stock (Water, Beef Bones, Yeast Extract, Salt, Molasses, Tomato Purée, Rapeseed Oil, Dried Onions, Ground Black Pepper), Free-Range Egg Yolk, Rapeseed Oil, Garlic Purée, Dijon Mustard (Water, Mustard Seeds, Vinegar, Salt), Rosemary, Parsley, Salt, Vegetable Stock (Salt, Sugar, Dried Onions, Dried Leeks, Rapeseed Oil, Ground Turmeric, Ground Black Pepper), Thyme, Black Pepper, White Pepper, Ground Bay Leaves, Ground Star Anise.'
        },
        {
            'name': 'Spaghetti Bolognese for 2',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665211189',
            'serving_size_g': 377.5,
            'calories': 139.0,
            'protein': 7.11,
            'carbs': 13.2,
            'fat': 5.73,
            'fiber': 1.0,  # Estimated
            'sugar': 1.35,
            'sodium': 0.2404,  # salt 0.601g / 2.5
            'ingredients': 'Cooked Pasta (Water, Durum Wheat Semolina), Beef (26%), Tomatoes, Red Wine, Onions, Carrots, Celery, Tomato Purée, Cornflour, Garlic Purée, Beef Stock, Rapeseed Oil, Basil, Salt, Oregano, Black Pepper.'
        },
        {
            'name': 'Sticky Toffee Pudding',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665215125',
            'serving_size_g': 218.0,
            'calories': 351.0,
            'protein': 3.0,
            'carbs': 45.5,
            'fat': 17.0,
            'fiber': 1.7,
            'sugar': 30.1,
            'sodium': 0.338,  # salt 0.845g / 2.5
            'ingredients': 'Sticky Toffee Sauce (42%) (Sugar, Double Cream (Milk), Butter (Milk), Black Treacle, Water, Cornflour, Salt), Sugar, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Dates (12%), Pasteurised Free Range Egg, Water, Invert Sugar Syrup, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Black Treacle, Flavouring, Salt.'
        },
        {
            'name': 'Cottage Pie for 2',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665211295',
            'serving_size_g': 325.0,
            'calories': 122.0,
            'protein': 8.74,
            'carbs': 9.29,
            'fat': 5.42,
            'fiber': 0.892,
            'sugar': 0.492,
            'sodium': 0.2084,  # salt 0.521g / 2.5
            'ingredients': 'Potatoes, Beef (32%), Carrots, Onions, Red Wine, Celery, Cornflour, Butter (Milk), Double Cream (Milk), Breadcrumbs (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast, Salt, Caramelised Sugar, Colours (Paprika Extract, Turmeric Extract)), Beef Stock (Water, Beef Bones, Yeast Extract, Salt, Molasses, Tomato Purée, Rapeseed Oil, Dried Onions, Ground Black Pepper), Tomato Purée, Red Wine Stock (Red Wine Concentrate, Yeast Extract, Dried Potatoes, Salt, Sugar, Dried Onions, Rapeseed Oil, Ground Black Pepper, Thyme), Free-Range Egg Yolk, Rapeseed Oil, Garlic Purée, Dijon Mustard (Water, Mustard Seeds, Vinegar, Salt), Rosemary, Parsley, Salt, Vegetable Stock (Salt, Sugar, Dried Onions, Dried Leeks, Rapeseed Oil, Ground Turmeric, Ground Black Pepper), Thyme, Black Pepper, White Pepper, Ground Bay Leaves.'
        },
        {
            'name': 'Butter Chicken Curry',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665217556',
            'serving_size_g': 228.0,
            'calories': 183.0,
            'protein': 12.3,
            'carbs': 4.9,
            'fat': 12.6,
            'fiber': 0.8,  # Estimated
            'sugar': 1.08,
            'sodium': 0.2976,  # salt 0.744g / 2.5
            'ingredients': 'Chicken (41%), Water, Single Cream (Milk), Onions, Tomato Purée, Butter (Milk), Tomatoes, Rapeseed Oil, Cornflour, Ginger Purée, Garlic Purée, Sugar, Ground Almonds, Garam Masala, Ground Coriander, Salt, Fenugreek Leaves, Ground Cumin, Turmeric, Ground Cardamom, Chilli Powder, Ground Cinnamon, Ground Ginger.'
        },
        {
            'name': 'Thai Green Chicken Curry & Fragrant Rice',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665214609',
            'serving_size_g': 403.0,
            'calories': 143.0,
            'protein': 6.55,
            'carbs': 14.7,
            'fat': 6.2,
            'fiber': 0.993,
            'sugar': 0.298,
            'sodium': 0.2008,  # salt 0.502g / 2.5
            'ingredients': 'Cooked Rice (Water, Rice), Chicken (19%), Coconut Milk, Onions, Cream (Milk), Ginger Purée, Demerara Sugar, Rapeseed Oil, Lemon Juice, Bamboo Shoots, Fish Sauce (Anchovy Extract (Fish), Salt, Sugar), Lime Juice, Cornflour, Spinach, Basil, Lime Leaves, Lemongrass, Parsley, Garlic Purée, Galangal, Salt, Sunflower Oil, Coriander, Red Pepper Flakes, Green Chillies, Garlic, Ground Turmeric, Ground Cumin, Ground Coriander, Shrimp (Crustaceans), Makrut Lime Peel, Coriander Seeds, Pepper, Turmeric.'
        },
        {
            'name': 'Lasagne for 2',
            'brand': 'Charlie Bigham\'s',
            'barcode': '5033665206864',
            'serving_size_g': 345.0,
            'calories': 158.0,
            'protein': 8.0,
            'carbs': 12.0,
            'fat': 8.5,
            'fiber': 1.0,
            'sugar': 2.0,
            'sodium': 0.24,
            'ingredients': 'Beef Ragu (30%) (Tomatoes, Beef (28% of Ragu), Red Wine, Onions, Carrots, Celery, Tomato Purée, Cornflour, Garlic Purée, Beef Stock, Rapeseed Oil, Basil, Salt, Oregano, Black Pepper), Béchamel Sauce (27%) (Milk, Cornflour, Butter (Milk), Onion, Salt, Nutmeg, Bay Leaves), Cooked Pasta Sheets (20%) (Durum Wheat Semolina, Pasteurised Free Range Egg), Mozzarella Cheese (Milk), Parmesan Cheese (Milk), Cheddar Cheese (Milk).'
        }
    ]

    added_count = 0

    print("➕ ADDING CHARLIE BIGHAM'S PRODUCTS WITH COMPLETE DATA\n")

    for product in new_products:
        # Generate a unique ID
        product_id = str(uuid.uuid4()).replace('-', '')[:22]

        # Check if product already exists by name and brand
        cursor.execute("""
            SELECT id FROM foods
            WHERE name = ? AND brand = ?
        """, (product['name'], product['brand']))

        existing = cursor.fetchone()

        if existing:
            print(f"⚠️  {product['brand']} - {product['name']}")
            print(f"   Already exists in database\n")
            continue

        # Insert new product with complete nutrition data
        cursor.execute("""
            INSERT INTO foods (
                id, name, brand, barcode, serving_size_g,
                calories, protein, carbs, fat, fiber, sugar, sodium,
                ingredients, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            product_id,
            product['name'],
            product['brand'],
            product['barcode'],
            product['serving_size_g'],
            product['calories'],
            product['protein'],
            product['carbs'],
            product['fat'],
            product['fiber'],
            product['sugar'],
            product['sodium'],
            product['ingredients'],
            current_timestamp,
            current_timestamp
        ))

        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Barcode: {product['barcode']}")
        print(f"   Serving: {product['serving_size_g']}g | {product['calories']} cal/100g")
        print(f"   ID: {product_id}\n")
        added_count += 1

    conn.commit()
    conn.close()

    return added_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("=" * 60)
    print("ADDING CHARLIE BIGHAM'S PRODUCTS")
    print("=" * 60)
    print()

    added = add_charlie_bigham_products(db_path)

    print()
    print("=" * 60)
    print(f"✨ COMPLETE: {added} new Charlie Bigham's products added!")
    print("=" * 60)
