#!/usr/bin/env python3
"""
Clean ingredients batch 8 - M&S & Sainsbury's Products
"""

import sqlite3
from datetime import datetime

def update_batch8(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 8 (M&S & Sainsbury's)\n")

    clean_data = [
        {
            'id': 'wVzxZUUZnDkTilyXJjfE',
            'name': 'Panuts',
            'brand': "Fairtrade By Sainsbury's",
            'serving_size_g': 30.0,  # Typical snack portion
            'ingredients': 'Peanuts (100%). Fairtrade certified, traded, audited and sourced from Fairtrade producers. Not suitable for customers with an allergy to nuts or milk due to manufacturing methods.'
        },
        {
            'id': 'Yp4TnL8uSaTREJoKf4Nd',
            'name': 'Colin The Caterpillar Cake',
            'brand': 'M&S',
            'serving_size_g': 62.5,  # 625g cake serves 10
            'ingredients': 'Milk Chocolate (24%) (Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Lactose, Emulsifier: Soya Lecithin), Sugar, White Chocolate (12%) (Sugar, Dried Whole Milk, Cocoa Butter, Dried Skimmed Milk, Emulsifier: Soya Lecithin, Vanilla Flavouring), Wheatflour (contains Gluten, with Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk), Water, Dark Chocolate (3.5%) (Cocoa Mass, Sugar, Cocoa Butter, Fat Reduced Cocoa Powder, Emulsifier: Soya Lecithin), Pasteurised Egg, Sugar Coated Milk Chocolate Beans (3%), Fat Reduced Cocoa Powder, Dried Glucose Syrup, Rowan Extract, Pasteurised Egg White, Humectant (Glycerol), Dried Skimmed Milk, Dextrose, Emulsifiers (E471, E475, E481, Soya Lecithin, E476), Raising Agents (E450, Sodium Bicarbonate), Cornflour, Salt, Palm Oil, Rapeseed Oil, Dried Whole Milk, Cocoa Butter, Dried Whey (Milk), Flavourings, Colour (Beetroot Red E162), Glazing Agent (Shellac E904), Carnauba Wax, Plant and Vegetable Concentrates (Spirulina, Safflower), Colour (Curcumin). Chocolate sponge roll filled with chocolate buttercream, covered in milk chocolate shell. Contains Eggs, Gluten, Milk, Soybeans.'
        },
        {
            'id': 'oNzkLr2x83hCTx90RVwR',
            'name': 'Chicken Fajita Wrap',
            'brand': 'M&S',
            'serving_size_g': 245.0,  # Per wrap
            'ingredients': 'Wheatflour, Roast Chicken Breast (19%), Water, Avocado, Onions (5%), Black Beans (4.5%), Spinach, Red Peppers (2.5%), Yellow Peppers (2.5%), Full Fat Soft Cheese (Milk), Borlotti Beans (2.5%), Sour Cream (Milk), Palm Oil, Farmhouse Cheddar Cheese (Milk), Rapeseed Oil, Humectant (Glycerol), Vegetable Oil (Sunflower/Rapeseed), Ground Spices (Smoked Paprika, Chillies, Cumin, Black Pepper, Coriander, Chipotle Chillies, Cloves, Cayenne Pepper, Cinnamon), Red Wine Vinegar, Malted Wheatflakes. Succulent chicken from M&S Select Farms with creamy avocado, crisp peppers and black beans in tangy tomato sauce with sour cream and mixed herbs on seeded tortilla.'
        },
        {
            'id': '6kU1GeachkZdKzevSizW',
            'name': 'Chicken Jalfrezi',
            'brand': 'M&S',
            'serving_size_g': 400.0,  # Full ready meal pack
            'ingredients': 'Chicken Breast (50%), Onions, Tomato Paste, Tomatoes (6%), Red Peppers (6%), Rapeseed Oil, Ginger Purée, Butter (Milk), Garlic Purée, Yogurt (Milk), Single Cream (Milk), Coriander, Green Chilli Purée, Salt, Lemon Juice, Ground Coriander, Ground Garam Masala (Roasted Coriander, Roasted Cumin, Cinnamon, Nutmeg, Kashmiri Chilli Powder, Black Pepper, Green Cardamom, Cloves, Bay Leaves), Ground Cumin, Cornflour, Kashmiri Chilli Powder, Turmeric, Cider Vinegar, Cumin Seeds, Ground Fenugreek Seeds. Marinated chargrilled chicken breast with ripe tomatoes and red peppers spiced with coriander leaf and chilli. May contain bones and whole spices/herbs.'
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

    print(f"✨ BATCH 8 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {25 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch8(db_path)
