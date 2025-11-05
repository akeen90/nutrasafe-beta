#!/usr/bin/env python3
"""
Clean ingredients batch 14 - M&S Products
"""

import sqlite3
from datetime import datetime

def update_batch14(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 14 (M&S Products)\n")

    clean_data = [
        {
            'id': 'dnC9sxX3baBTDPAQRUu3',
            'name': 'Chicken & Kimchi Wrap',
            'brand': 'M&S',
            'serving_size_g': 220.0,  # Estimated wrap weight
            'ingredients': 'Wholemeal Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Roast Chicken Breast (20%), Water, White Cabbage Kimchi (5%) (Chinese Cabbage, White Radish, Garlic Purée, Onions, Ginger Purée, Dried Red Peppers, Water, Salt, Soybeans, Chilli Powder), Carrots (5%) (Carrots, Water, Rice Wine Vinegar, Sugar, Salt), Spinach, Red Cabbage, Sauerkraut (White Cabbage, White Wine, Salt), Palm Oil, Rapeseed Oil, Wheat Fibre, Raising Agents, Vinegar. Contains Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'YEfK0UosQXRXIK1kk76p',
            'name': 'Chicken Tikka Masala & Pickled Red Onion Pizza',
            'brand': 'M&S',
            'serving_size_g': 455.0,  # Full pizza
            'ingredients': 'Wheatflour (Fortified with Calcium, Iron, Vitamin B3 and B1), Water, Chicken Breast (7%), Single Cream (Milk), Mozzarella Cheese (Milk) (6%), Chicken Thighs (5%), Coconut Milk (Coconut Extract, Water), Roasted Pickled Red Onions (4%) (Red Onions, Lime Juice, Sugar, Concentrated Beetroot Juice, Vinegar, Salt), Tomatoes, Mango Chutney (3%) (Sugar, Mango Puree, Water, Cornflour, Vinegar, Salt, Garlic Puree, Ground Spices (Cumin, Coriander, Black Pepper, Fenugreek, Cinnamon, Cardamom, Paprika, Ginger, Cloves), Concentrated Lemon Juice, Ginger Puree, Red Chilli Purée, Whole Black Onion Seeds, Dried Red Chillies, Paprika Extract, Cloves), Rapeseed Oil, Ginger Purée, Durum Wheat Semolina, Dried Fermented Wheatflour, Low Fat Yogurt (Milk), Salt, Garlic Purée, Extra Virgin Olive Oil, Yeast (Yeast, Dried Yeast), Cornflour, Unsalted Butter (Milk), Ground Spices (Coriander, Smoked Paprika, Cinnamon, Roasted Coriander, Chilli, Roasted Cumin, Black Pepper, Mace, Roasted Green Cardamom Seeds, Paprika, Ginger, Cloves, Nutmeg, Fennel, Bay Leaves), Dried Wheat Sourdough, Sugar, Yeast Extract, Red Chillies, Smoked Salt, Cumin Seeds, Demerara Sugar, Turmeric, Malted Wheatflour, Fenugreek Leaves, Whole Black Cardamom Seeds, Whole Green Cardamom, Wheat Gluten, Chilli Extract. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'LfM7tuO5YhVe0FlrX3x9',
            'name': 'Coronation Chicken Flatties',
            'brand': 'M&S',
            'serving_size_g': 65.0,  # Per flattie (4-pack)
            'ingredients': 'British Chicken Breast (78%), Coronation Drizzle (8%) (Rapeseed Oil, Water, Crème Fraîche (Milk), Apricot Purée, Sugar, Mango, Ground Spices (Coriander, Turmeric, Cumin, Black Pepper, Paprika, Caraway Seeds, Cayenne Pepper, Fenugreek, Cinnamon, Pimentoes), Vinegar, Egg Yolk, Tomato Paste, Salt, Cornflour, Ginger Purée, Desiccated Coconut, Concentrated Pear Juice, Dried Mustard, Dried Garlic, Sea Salt, Mustard Seed Husk, Dried Oregano), Marinade (Rapeseed Oil, Chicken Stock (Water, Yeast Extract, Chicken Fat, Chicken Bones, Salt), Ground Spices (Coriander, Turmeric, Ginger, Black Pepper, Fenugreek, Cumin, Paprika, Chilli Powder, Caraway Seed, Cloves, Cayenne Pepper), Mango Purée, Sugar, Mango, Desiccated Coconut, Brown Sugar, Yeast Extract, White Wine Vinegar, Dried Garlic, Cider Vinegar, Salt, Water, Roasted Shallots, Red Peppers, Potato Starch, Black Onion Seeds, Green Peppers, Cornflour, Garlic Purée, Ginger Purée, Chillies, Dried Coriander). May contain bones. Contains Eggs, Milk, Mustard.'
        },
        {
            'id': '7PEeqFaHKAL7Dh6VDZUr',
            'name': 'Harissa Chicken Couscous Salad',
            'brand': 'M&S',
            'serving_size_g': 255.0,  # Full pack
            'ingredients': 'Chicken Breast (20%), Cooked Wheatflour Couscous (18%) (Water, Wheatflour (contains Gluten)), Cooked Green Lentils (10%) (Water, Green Lentils), Black-Eyed Beans, Cooked Bulgur Wheat (8%) (Bulgur Wheat (contains Gluten), Water), Chickpeas, Greek Style Yogurt (Milk), Peppers, Tomatoes, Honey, Water, Preserved Lemon (Lemon Peel, Sea Salt, Preservative: E223 (Sulphites)), Sunflower Oil, Garlic Purée, Ground Spices (Cumin, Coriander, Smoked Paprika, Paprika, Turmeric, Black Pepper, Allspice), Red Chilli Purée, Lime Juice, Spinach, Mint, Tomato Paste, Parsley, Lemon Juice, Red Pepper Purée, Salt, Cornflour, White Wine Vinegar, Dill, Rapeseed Oil, Red Wine Vinegar, Extra Virgin Olive Oil, Fromage Frais (Milk), Dried Paprika Flakes, Chicory Fibre, Lemon Zest, Soured Cream (Milk), Pasteurised Egg Yolk, Sugar, Dried Oregano, Dried Mustard, Mustard Bran, Vinegar. High in protein. 1 of 5 a day. Contains Cereals Containing Gluten, Eggs, Milk, Mustard, Sulphites, Wheat.'
        },
        {
            'id': 'SkGM7ikFLhJjreJfiKsF',
            'name': 'Korean Style Chicken Dragon Roll',
            'brand': 'M&S',
            'serving_size_g': 174.0,  # Full pack
            'ingredients': 'Cooked Seasoned Sushi Rice (Rice, Water, Vinegar, Sugar, Salt, Vegetable Oil (Sunflower/Rapeseed), Seaweed Extract), Cooked Marinated Chicken Thighs (16%) (Chicken Thighs (76%), Honey, Water, Cider Vinegar, Garlic Purée, Rice Wine Vinegar, Soybeans, Red Chilli Purée, Cornflour, Dried Onions, Salt, Dried Chillies, Rapeseed Oil, Wheatflour), Mango (4%), Carrots (4%), Fried Onions (Palm Oil, Wheatflour, Onions, Salt), Spinach (2%), Water, Red Chillies, Chives, Sugar, Rapeseed Oil, Vegetable Oil (Sunflower/Rapeseed), Dried Seaweed, Spring Onions, Coriander, Soybeans, Cider Vinegar, Salt, Glucose Syrup, Cornflour, White Wine Vinegar, Fructose, Pasteurised Egg Yolk, Garlic Purée, Vinegar, Concentrated Red Pepper Juice, Ground Spices (Cayenne Pepper, Smoked Paprika, Ground Ginger, Turmeric). Contains Cereals Containing Gluten, Eggs, Sesame, Soya, Wheat.'
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

    print(f"✨ BATCH 14 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {50 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch14(db_path)
