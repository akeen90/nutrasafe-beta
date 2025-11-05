#!/usr/bin/env python3
"""
Clean ingredients batch 18 - M&S, Morrisons & Tesco Products
"""

import sqlite3
from datetime import datetime

def update_batch18(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 18 (M&S, Morrisons & Tesco)\n")

    clean_data = [
        {
            'id': 'VxXvfiQMc3s3cyjMX7Py',
            'name': 'Mexican Style Fiesta Dips',
            'brand': 'M&S',
            'serving_size_g': 100.0,  # Per portion (400g pack contains 4 dips)
            'ingredients': 'Zesty Guacamole: Avocado Purée (48%), Avocado (26%) (Avocado, Antioxidant: Ascorbic Acid, Rice Starch, Acidity Regulator: Citric Acid), Water, Tomatoes, Lime Juice, Onions, Sugar, Coriander, Salt, Roasted Garlic Purée, Red Chillies. Nacho Chilli Cheese: Rapeseed Oil, Water, Mature Red Cheddar Cheese (15%) (Cheddar Cheese (Milk), Natural Colour: E160b(ii)), Reduced Fat Greek Style Yogurt (Milk) (9%), Full Fat Soft Cheese (Milk) (8%), Jalapeño Chilli (2.5%), Concentrated Lemon Juice, Cornflour, Onions, Sugar, White Wine Vinegar, Pasteurised Egg, Pasteurised Egg Yolk, Salt, Potato Starch, Natural Colour: Paprika Extract, Sunflower Oil. Sour Cream & Chive Dip: Soured Cream (Milk) (56%), Rapeseed Oil, Onions, Chives (2.5%), Cornflour, White Wine Vinegar, Pasteurised Egg, Pasteurised Egg Yolk, Salt, Sugar, Concentrated Lemon Juice. Tangy Tomato Salsa: Tomatoes (60%), Tomato Juice, Tomato Purée, Onions (7%), Rapeseed Oil, Lime Juice, Coriander, Sugar, Salt, Garlic Purée, Stabiliser: Guar Gum, Colour: Paprika Extract, Sunflower Oil. Contains Eggs, Milk.'
        },
        {
            'id': '1rYkCzXBZ4xSvAPazAIb',
            'name': 'New York Style No Salt Beef',
            'brand': 'M&S',
            'serving_size_g': 178.0,  # Full sandwich pack
            'ingredients': 'Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Marinated Wheat and Vegetable Protein (18%) (Hydrolysed Wheat, Pea, Potato, Wheat Gluten, Vegetable Oils (Sunflower, Rapeseed), Beetroot Juice, Spices), Gherkins (Gherkins, Vinegar, Sugar, Salt), Coconut Based Cheese Alternative (Coconut Oil, Creamed Coconut, Modified Potato Starch, Fortified with Vitamin D and B12), Sauerkraut (White Cabbage, White Wine, Salt), Carrots, Spring Onions, Rapeseed Oil, Yeast, Vinegar, Sugar, Wheat Gluten, White Wine Vinegar, Citrus Fibre, Dried Yeast, Cornflour, Cracked Black Pepper, Broad Bean Protein, Concentrated Lemon Juice, Mustard Seeds, Caraway Seeds, Turmeric, Thickener: Xanthan Gum, Malted Wheatflour, Dried Garlic, Potassium Chloride. Plant Kitchen vegan sandwich with plant-based salt-beef flavour and cheese, tangy slaw and dill pickle on pretzel roll. Contains Cereals Containing Gluten, Mustard, Wheat.'
        },
        {
            'id': 'GPb4LaUISU74LJ5QMOIq',
            'name': 'Morrisons Korean Style Chicken Dragon Rolls',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,  # Per portion estimate
            'ingredients': 'Cooked Sushi Rice (Water, Rice, Sushi Vinegar (Sugar, Rice Vinegar, Salt, Water, Rice Wine), Vegetable Oils (Sunflower, Rapeseed)), Chicken Breast (6%), Red Pepper, Sesame Seeds, Water, Red Cabbage, Fried Onion (Palm Oil, Wheat Flour, Onion, Salt), Red Chilli, Rapeseed Oil, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Paprika Flakes, Broccoli Stalks, Mooli, Carrot, Nori Seaweed, Cornflour, Mirin Rice Wine, Red Chilli Purée, Rice Vinegar, Red Onion, Sugar, Spirit Vinegar, Pasteurised Egg Yolk, Wheat Starch, Salt, Garlic Purée, Rice Flour, Wheat Gluten, Citrus Fibre, Spices (Fennel, Black Pepper, Cayenne Pepper, Turmeric, Nutmeg, White Pepper), Yeast Extract, Spirit Vinegar Powder, Paprika, Garlic Powder, Onion Powder, Concentrated Lemon Juice, Chilli Pepper, Raising Agents. Korean style breaded chicken and vegetable sushi rolls with sesame seed coating. Contains Cereals Containing Gluten, Eggs, Sesame, Wheat.'
        },
        {
            'id': '3yZ15VsjYvB5zUbkh6gV',
            'name': 'Tomato & Mascarpone Microwave Pasta',
            'brand': 'Morrisons',
            'serving_size_g': 200.0,  # Full microwave pack
            'ingredients': 'Cooked Fusilli Pasta (57%) (Water, Durum Wheat Semolina, Dried Egg), Passata (9%), Mascarpone Cheese (Milk) (8%), Tomato Paste (6%), Onion, Single Cream (Milk), Tomato (3%), Sunflower Oil, Tomato Juice, Sugar, Yeast Extract Powder, Onion Powder, Basil, Garlic Purée, Colours (Paprika Extract, Curcumin), Salt, Yeast Extract, Stabiliser (Guar Gum), Garlic Powder, Dextrose, Potato Starch, Onion Extract, Herb Extracts (Marjoram, Thyme, Sage), Carrot Powder, Acidity Regulator (Citric Acid), Pepper Extract, Parsley. Ready in 90 seconds. No artificial colours or flavours. Contains Eggs, Milk, Wheat.'
        },
        {
            'id': 'dAL04DK5P0r3oG5M1kdb',
            'name': '12 Piece Chinese Style Selection Pack',
            'brand': 'Tesco',
            'serving_size_g': 127.0,  # Half of 254g pack
            'ingredients': 'Vegetable Wontons (4): Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Carrot (15%), Red Pepper (11%), Rapeseed Oil, Soya Bean, White Cabbage, Rice Flour, Water Chestnut, Spring Onion, Ginger Purée, Potato Starch, Garlic Purée, Sugar, Sesame Oil, Salt, Dextrose, Yeast Extract, Stabiliser (Hydroxypropyl Methyl Cellulose), Wheat Gluten, Wheat, Fennel, Cinnamon Powder, Rice Starch, Cane Molasses, White Pepper, Black Pepper, Maltodextrin, Aniseed, Mushroom Powder, Clove Powder. Vegetable Spring Rolls (4): Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Carrot (15%), Rapeseed Oil, Red Pepper (10%), Rice Flour, Soya Bean, White Cabbage, Water Chestnut, Bean Sprouts, Onion, Ginger Purée, Potato Starch, Water, Sugar, Salt, Sesame Oil, Garlic Purée, Dextrose, Yeast Extract, Stabiliser (Hydroxypropyl Methyl Cellulose), Wheat, Rice Starch, Fennel, Cinnamon Powder, Cane Molasses, Black Pepper, Maltodextrin, White Pepper, Aniseed, Mushroom Powder, Clove Powder. Prawn Toasts (4): Prawn (Crustacean) (32%), Bread (Wheat Flour, Water, Yeast, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid)), Rapeseed Oil, Sesame Seeds, Water Chestnut, Ginger Purée, Dried Egg White, Sesame Oil, Potato Starch, Sugar, Salt, Lemon Juice from Concentrate. Contains Cereals Containing Gluten, Crustaceans, Eggs, Sesame, Soya, Wheat.'
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

    print(f"✨ BATCH 18 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {70 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch18(db_path)
