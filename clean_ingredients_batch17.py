#!/usr/bin/env python3
"""
Clean ingredients batch 17 - M&S & Morrisons Products
"""

import sqlite3
from datetime import datetime

def update_batch17(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 17 (M&S & Morrisons)\n")

    clean_data = [
        {
            'id': '8ioETnOaSAdn00cpyOzZ',
            'name': 'Golden Chicken And Grain Salas',
            'brand': 'M&S',
            'serving_size_g': 280.0,  # Full pack
            'ingredients': 'Cos Lettuce, Turmeric Yogurt Dressing (16%) (Greek Style Yogurt (Milk), Maple Syrup, Lemon Juice, Water, Ginger, Roasted Garlic Purée, Vegetable Oil (Sunflower/Rapeseed), Salt, Coriander, Chicory Fibre, Citrus Fibre, Oat Fibre, Curry Powder (Coriander Seeds, Turmeric, Fenugreek Seeds, Cumin Seeds, Ground Black Pepper, Salt, Dried Chillies, Dried Garlic, Dried Ginger, Caraway Seeds, Dried Onions), Turmeric, Ground Black Pepper), Cooked Chicken (15%), Cooked Quinoa (12%) (Water, Quinoa Seeds), Cooked Rice (7%) (Water, Red Rice, Wild Rice), Tomatoes, Cooked Chickpeas (5%) (Chickpeas, Water), Cucumber, Lime Infused Red Onions (Red Onions, Lime), Cumin Seeds, Fennel Seeds, Dried Ginger, Dill Seeds, Cloves, Cornflour, Red Chillies, Rapeseed Oil. Topped with almonds. Not suitable for those with a Nut, Peanut, or Sesame allergy. Contains Milk, Nuts, Oats.'
        },
        {
            'id': 'Il2XQqHGSmrXl31BfLXM',
            'name': 'Fish Pie Mix 340g',
            'brand': 'Morrisons',
            'serving_size_g': 113.0,  # One third of 340g pack
            'ingredients': 'Salmon (Fish) (50%), White Fish (25%), Smoked Haddock (Fish) (24%), Water, Salt, Colour (Curcumin). Chunks of salmon, whitefish and smoked haddock ready to pop in a pie. Contains Fish.'
        },
        {
            'id': '18mDsykujqctLzIOOPvC',
            'name': 'Free From Gluten Spicy Chicken Pizza',
            'brand': 'Morrisons',
            'serving_size_g': 250.0,  # Full pizza
            'ingredients': 'Water, Mozzarella Cheese (14%) (Cheese (Milk), Acidity Regulator (Citric Acid)), Tomato Purée (13%) (Tomato, Acidity Regulator (Citric Acid)), Roasted Chicken (10%) (Chicken Breast Fillet (92%), Water, Corn Starch, Salt, Dextrose), Maize Starch, Potato Starch, Rice Flour, Sunflower Oil, Red Onion, Roquito® Peppers (3%) (Jalapeño Pepper, Sugar, Acidity Regulator (Acetic Acid), Salt), Tapioca Starch, Raising Agents (Diphosphates, Sodium Carbonates), Thickeners (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Buckwheat Flour, Sugar, Pea Flour, Flavouring, Millet Flour, Flaxseed Meal, Pea Fibre, Potato Fibre, Rice Fibre, Psyllium Fibre, Salt, Modified Maize Starch, Garlic, Onion, Basil, Paprika, Coriander, Oregano, Cumin Powder, Chilli Powder, Coriander Powder, Black Pepper. Gluten free. Contains Milk. May Contain Soybeans.'
        },
        {
            'id': 'WCm1ukGnNA4T6iZYwlpU',
            'name': 'Iced Christmas Cake',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,  # Per portion (900g cake serves ~16)
            'ingredients': 'Dried Vine Fruits (30%) (Sultanas, Raisins, Currants), Sugar, Marzipan (Sugar, Almonds, Glucose Syrup, Invert Sugar Syrup), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Egg, Glacé Cherries (5%) (Cherries, Glucose-Fructose Syrup, Plant Concentrates (Carrot, Aronia), Acidity Regulator (Citric Acid)), Cognac (5%), Unsalted Butter (Milk) (4%), Glucose Syrup, Orange Zest, Apricot Jam (Sugar, Glucose-Fructose Syrup, Concentrated Apricot Purée, Gelling Agent (Pectins), Acid (Citric Acid), Acidity Regulator (Sodium Citrates)), Humectant (Glycerol), Raisin Juice Concentrate, Golden Syrup, Palm Oil, Caramelised Sugar Syrup, Maize Starch, Spices, Molasses, Invert Sugar Syrup, Palm Kernel Oil, Rapeseed Oil, Barley Malt Extract, Concentrated Orange Juice, Emulsifier (Mono- and Diglycerides of Fatty Acids), Stabiliser (Xanthan Gum), Egg White Powder. All-butter fruit cake made with plump vine fruits and orange zest, infused with Cognac. Contains Almonds, Barley, Eggs, Milk, Wheat. May Contain Brazil Nuts, Cashew Nuts, Hazelnuts, Macadamia Nuts, Nuts, Peanuts, Pecan Nuts, Pistachio Nuts, Walnuts.'
        },
        {
            'id': 'hOq7fGsmAnCaQyjdO1C5',
            'name': 'Wood Fire Pizza',
            'brand': 'M&S',
            'serving_size_g': 176.0,  # Estimated half pizza serving
            'ingredients': 'Wheatflour (Fortified with Calcium, Iron, Vitamin B3 and B1), Mozzarella Cheese (Milk) (26%), Water, Tomatoes, Rapeseed Oil, Dried Fermented Wheatflour, Tomato Puree, Durum Wheat Semolina, Yeast, Salt, Cornflour, Yeast Extract, Basil, Olive Oil, White Vinegar, Wheat Gluten, Sugar, Garlic Purée, Malted Wheatflour. 24-hour fermented, stonebaked dough topped with Italian tomato sauce and creamy mozzarella. Contains Cereals Containing Gluten, Milk, Wheat.'
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

    print(f"✨ BATCH 17 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {65 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch17(db_path)
