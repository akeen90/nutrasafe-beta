#!/usr/bin/env python3
"""
Clean ingredients batch 11 - Kellogg's & Asda Products
"""

import sqlite3
from datetime import datetime

def update_batch11(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 11 (Kellogg's & Asda)\n")

    clean_data = [
        {
            'id': 'EFSm3LJJFFg37fDgs1dA',
            'name': 'Rice Krispies Square Mint',
            'brand': "Kellogg's",
            'serving_size_g': 34.0,  # Per bar (4 x 34g multipack = 136g)
            'ingredients': "Kellogg's Toasted Rice Cereal (28%) (Rice, Sugar, Salt, Barley Malt Extract, Niacin, Iron, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin D, Vitamin B12), Glucose Syrup, Sugar, Fructose, Vegetable Oils (Rapeseed, Certified Sustainable Palm) in varying proportions, Mint Chocolate Flavoured Coating, Chocolate Chunks, Chocolate Drizzle. Rice Krispies cereal combined with delicious mint chocolate flavoured coating with chocolate chunks and drizzle. Contains: Barley, Milk, Soya. May Contain: Cereals Containing Gluten."
        },
        {
            'id': 'zNyVVBJfSUq3u5Sp9wws',
            'name': 'Special K Milk Chocolate',
            'brand': "Kellogg's",
            'serving_size_g': 20.0,  # Per bar (6 x 20g pack = 120g)
            'ingredients': 'Wholegrain Cereals (Wholewheat (31%), Whole Oats (5.5%)), Milk Chocolate (14%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Emulsifiers (Soy Lecithin, E476), Natural Vanilla Flavouring), Cereal Crispies (11%) (Wholewheat Flour, Rice Flour, Sugar, Malted Barley Flour, Malted Wheat Flour, Salt), Oligofructose, Glucose Syrup, Fructose, Sugar, Milk Chocolate Chunks (2.5%) (Sugar, Cocoa Mass, Cocoa Butter, Whole Milk Powder, Skimmed Milk Powder, Emulsifier (Soy Lecithin), Natural Flavouring), Humectants (Sorbitol, Glycerol), Palm Oil, Barley Malt Extract, Dextrose, Salt, Antioxidant (Tocopherol Rich Extract), Natural Flavouring, Emulsifier (Soy Lecithin), Niacin, Iron, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin D, Vitamin B12. 78 kcal per bar. Made with Belgian chocolate. 44% Wholegrains. High in fibre. Suitable for Vegetarians. Halal & Kosher approved. Contains Barley, Milk, Oats, Soya, Wheat. May Contain Cereals Containing Gluten.'
        },
        {
            'id': 'svRgfANWeJ0fuIibKtRW',
            'name': 'Breaded Chicken Steaks',
            'brand': 'Asda',
            'serving_size_g': 117.0,  # Approximate serving size
            'ingredients': 'Chicken Breast (62%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Vegetable Oils (Rapeseed, Extra Virgin Olive, Sunflower), Water, Pea Fibre, Salt, Wheat Starch, Wheat Gluten, Yeast, Cider Vinegar, Yeast Extract, Spirit Vinegar Powder, Sugar, Onion Powder, Paprika, Sage, Garlic Powder, White Pepper, Lemon Powder, Spice Extracts, Thyme Extract. Contains raw chicken. Extra care has been taken to remove bones, although some may remain. For allergens, including cereals containing gluten, see ingredients in bold.'
        },
        {
            'id': 'm1ZI5TKwbEg1twrSedZU',
            'name': 'Chicken Noodle Salad',
            'brand': 'Asda',
            'serving_size_g': 280.0,  # Full pack
            'ingredients': 'Dressed Cooked Free Range Egg Noodles with added Pea Protein (37%) (Water, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pea Protein, Wheat Gluten, Rapeseed Oil, Free Range Whole Egg, Coriander, White Wine Vinegar, Salt, Turmeric), Marinated Cooked Sliced Chicken Breast (16%) (Chicken Breast (87%), Tomato Paste, Water, Red Chillies, Sugar, Garlic Purée, Sweet Paprika, Lime Juice, Coriander, Cornflour, Parsley, Spirit Vinegar), Green Multileaf Lettuce, Sweet Chilli and Mango Dressing Sachet (13%) (Water, Sugar, Rice Wine Vinegar, Red Chillies, Mango Purée, Garlic Purée, Ginger Purée, Cornflour, Fish Sauce (Anchovy, Salt, Sugar), Salt, Coriander, Lime Juice, Acidity Regulator (Citric Acid)), Red Peppers, Carrots, Red Cabbage, Edamame Soya Beans. Crunchy & Fragrant Sweet Chilli Chicken Noodle Salad. Contains Eggs, Soya, Wheat, Fish.'
        }
    ]

    updates_made = 0
    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g\n")
            updates_made += 1

    conn.commit()
    conn.close()

    print(f"✨ BATCH 11 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {37 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch11(db_path)
