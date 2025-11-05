#!/usr/bin/env python3
"""
Add missing Charlie Bigham's products to the database
"""

import sqlite3
from datetime import datetime
import uuid

def add_charlie_bigham_products(db_path: str):
    """Add missing Charlie Bigham's products"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    current_timestamp = int(datetime.now().timestamp())

    # New products to add
    new_products = [
        {
            'name': 'Shepherd\'s Pie for 1',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 325.0,
            'ingredients': 'Potatoes, Lamb (32%), Carrots, Onions, Red Wine, Celery, Cornflour, Butter (Milk), Double Cream (Milk), Breadcrumbs (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast, Salt, Caramelised Sugar, Colours (Paprika Extract, Turmeric Extract)), Lamb Stock (Lamb Bones, Yeast Extract, Water, Salt, Sugar, Cornflour, Onion Juice Concentrate, Rosemary, Thyme), Tomato Purée, Red Wine Stock (Red Wine Concentrate, Yeast Extract, Dried Potatoes, Salt, Sugar, Dried Onions, Rapeseed Oil, Ground Black Pepper, Thyme), Beef Stock (Water, Beef Bones, Yeast Extract, Salt, Molasses, Tomato Purée, Rapeseed Oil, Dried Onions, Ground Black Pepper), Free-Range Egg Yolk, Rapeseed Oil, Garlic Purée, Dijon Mustard (Water, Mustard Seeds, Vinegar, Salt), Rosemary, Parsley, Salt, Vegetable Stock (Salt, Sugar, Dried Onions, Dried Leeks, Rapeseed Oil, Ground Turmeric, Ground Black Pepper), Thyme, Black Pepper, White Pepper, Ground Bay Leaves, Ground Star Anise.'
        },
        {
            'name': 'Shepherd\'s Pie for 2',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 325.0,
            'ingredients': 'Potatoes, Lamb (32%), Carrots, Onions, Red Wine, Celery, Cornflour, Butter (Milk), Double Cream (Milk), Breadcrumbs (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast, Salt, Caramelised Sugar, Colours (Paprika Extract, Turmeric Extract)), Lamb Stock (Lamb Bones, Yeast Extract, Water, Salt, Sugar, Cornflour, Onion Juice Concentrate, Rosemary, Thyme), Tomato Purée, Red Wine Stock (Red Wine Concentrate, Yeast Extract, Dried Potatoes, Salt, Sugar, Dried Onions, Rapeseed Oil, Ground Black Pepper, Thyme), Beef Stock (Water, Beef Bones, Yeast Extract, Salt, Molasses, Tomato Purée, Rapeseed Oil, Dried Onions, Ground Black Pepper), Free-Range Egg Yolk, Rapeseed Oil, Garlic Purée, Dijon Mustard (Water, Mustard Seeds, Vinegar, Salt), Rosemary, Parsley, Salt, Vegetable Stock (Salt, Sugar, Dried Onions, Dried Leeks, Rapeseed Oil, Ground Turmeric, Ground Black Pepper), Thyme, Black Pepper, White Pepper, Ground Bay Leaves, Ground Star Anise.'
        },
        {
            'name': 'Spaghetti Bolognese for 1',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 360.0,
            'ingredients': 'Cooked Pasta (Water, Durum Wheat Semolina), Beef (26%), Tomatoes, Red Wine, Onions, Carrots, Celery, Tomato Purée, Cornflour, Garlic Purée, Beef Stock, Rapeseed Oil, Basil, Salt, Oregano, Black Pepper.'
        },
        {
            'name': 'Spaghetti Bolognese for 2',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 377.5,
            'ingredients': 'Cooked Pasta (Water, Durum Wheat Semolina), Beef (26%), Tomatoes, Red Wine, Onions, Carrots, Celery, Tomato Purée, Cornflour, Garlic Purée, Beef Stock, Rapeseed Oil, Basil, Salt, Oregano, Black Pepper.'
        },
        {
            'name': 'Sticky Toffee Pudding',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 218.0,
            'ingredients': 'Sticky Toffee Sauce (42%) (Sugar, Double Cream (Milk), Butter (Milk), Black Treacle, Water, Cornflour, Salt), Sugar, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Dates (12%), Pasteurised Free Range Egg, Water, Invert Sugar Syrup, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Black Treacle, Flavouring, Salt.'
        },
        {
            'name': 'Cherry Bakewell Pudding',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 204.5,
            'ingredients': 'Cherry Compote (32%) (Cherries (60%), Sugar, Glucose Syrup, Water, Cornflour, Concentrated Lemon Juice, Flavouring), Sugar, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Pasteurised Free Range Egg, Ground Almonds (6%), Water, Flaked Almonds (2%), Madagascan Vanilla Extract, Almond Extract, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate).'
        },
        {
            'name': 'Brasserie Beef Wellington',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 283.5,
            'ingredients': 'Beef Fillet (35%), Puff Pastry (26%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Water, Salt), Chestnut Mushrooms, Chicken Liver, Water, Butter (Milk), Porcini Mushrooms, Free Range Egg Yolk, Pedro Ximénez Sherry, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Cornflour, Tarragon, Thyme, Rapeseed Oil, Garlic Purée, Salt, Black Pepper.'
        },
        {
            'name': 'Brasserie Salmon Wellington',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 278.5,
            'ingredients': 'Salmon (Fish) (37%), Puff Pastry (26%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Water, Salt), Spinach, Ricotta Cheese (Milk), Double Cream (Milk), Free Range Egg Yolk, Lemon Zest, Dill, Cornflour, Rapeseed Oil, Garlic Purée, Salt, Black Pepper, Nutmeg.'
        },
        {
            'name': 'Brasserie Venison Bourguignon',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 450.0,
            'ingredients': 'Venison (42%), Red Wine (18%), Button Mushrooms, Smoked Lardons (Pork, Salt, Preservative (Sodium Nitrite)), Shallots, Carrots, Cornflour, Butter (Milk), Venison Stock, Tomato Purée, Garlic Purée, Rapeseed Oil, Thyme, Bay Leaves, Salt, Black Pepper.'
        },
        {
            'name': 'King Prawn & Scallop Risotto',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 350.0,
            'ingredients': 'Cooked Risotto Rice (Water, Arborio Rice), Lobster Bisque (18%) (Water, Tomatoes, Lobster (Crustacean), White Wine, Double Cream (Milk), Cornflour, Butter (Milk), Tomato Purée, Brandy, Rapeseed Oil, Garlic Purée, Salt, Paprika, Black Pepper, Cayenne Pepper), King Prawns (Crustacean) (9%), Scallops (Mollusc) (3%), White Wine, Parmesan Cheese (Milk), Butter (Milk), Mascarpone Cheese (Milk), Parsley, Lemon Juice, Rapeseed Oil, Garlic Purée, Salt, Black Pepper.'
        }
    ]

    added_count = 0

    print("➕ ADDING CHARLIE BIGHAM'S PRODUCTS\n")

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

        # Insert new product
        cursor.execute("""
            INSERT INTO foods (id, name, brand, serving_size_g, ingredients, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            product_id,
            product['name'],
            product['brand'],
            product['serving_size_g'],
            product['ingredients'],
            current_timestamp,
            current_timestamp
        ))

        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Serving: {product['serving_size_g']}g")
        print(f"   ID: {product_id}\n")
        added_count += 1

    conn.commit()
    conn.close()

    return added_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("=" * 60)
    print("ADDING MISSING CHARLIE BIGHAM'S PRODUCTS")
    print("=" * 60)
    print()

    added = add_charlie_bigham_products(db_path)

    print()
    print("=" * 60)
    print(f"✨ COMPLETE: {added} new Charlie Bigham's products added!")
    print("=" * 60)
