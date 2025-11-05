#!/usr/bin/env python3
"""
Clean ingredients batch 10 - M&S Products
"""

import sqlite3
from datetime import datetime

def update_batch10(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 10 (M&S Products)\n")

    clean_data = [
        {
            'id': 'op2vwwTLGPMJlsfJrjOC',
            'name': "Loaded Millionaire's",
            'brand': 'M&S',
            'serving_size_g': 55.0,  # Estimated per piece (4-pack format typical)
            'ingredients': 'Sugar, Butter (Milk), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Milk Chocolate (Sugar, Cocoa Butter, Cocoa Mass, Dried Whole Milk, Dried Skimmed Milk, Emulsifier: Soya Lecithin, Vanilla Flavouring), Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar), Glucose Syrup, Palm Oil, Invert Sugar Syrup, Milk Chocolate Biscuit Balls, Salt, Flavourings, Emulsifier (Soya Lecithin), Raising Agents (E450, Sodium Bicarbonate). All-butter shortbread topped with rich salted caramel and creamy milk chocolate, finished with crisp milk chocolate biscuit balls. Handy four-pack for sharing.'
        },
        {
            'id': 'SRk7Fkn4FD0UDPkRA3qM',
            'name': 'Hoisin No Duck Wrap',
            'brand': 'M&S',
            'serving_size_g': 100.0,  # Estimated wrap weight
            'ingredients': 'Wheatflour, Water, Cucumber (11%), Hoisin Sauce (10%) (Water, Muscovado Sugar, Soybeans, Sugar, Brown Sugar, Concentrated Plum Juice, Tomato Paste, Cornflour, Salt, Black Treacle, Ginger Purée, Red Chilli Purée, Vegetable Oil (Sunflower/Rapeseed), Red Wine Vinegar, Molasses, Rice Vinegar, Five Spices (Cinnamon, Fennel, Ginger, Aniseed, Cloves), Barley Malt Vinegar, Barley Malt Extract, Wheatflour, Acidity Regulator: Acetic Acid), Spinach (7%), Wheat and Pea Protein (5%) (Hydrolysed Wheat (contains Gluten), Pea, Potato), Palm Oil, Spring Onions. Plant Kitchen vegan wrap combining five spice-infused wheat and pea protein with cucumber, hoisin sauce, fresh spinach and spring onions in soft wheat flour tortilla. Vegan and vegetarian.'
        },
        {
            'id': 'SUAIupZRclLy71ckeuBK',
            'name': 'Naked Red Velvet Cake',
            'brand': 'M&S',
            'serving_size_g': 68.75,  # 825g cake / 12 servings
            'ingredients': 'Sugar, Full Fat Soft Cheese (Milk) (16%), Butter (Milk), Wheatflour contains Gluten (with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Pasteurised Egg, Rapeseed Oil, Glucose Syrup, Invert Sugar Syrup, Cornflour, Humectant (Glycerol), Dried Skimmed Milk, Fat Reduced Cocoa Powder, Raising Agent (E450, Sodium Bicarbonate), Salt, Emulsifier (E475, E481, E471), Palm Oil, Rowan Extract, Colour (E120). Red coloured chocolate sponge cake filled and topped with cream cheese frosting, decorated with red coloured chocolate cake crumbs. Serves 12. Contains Cereals Containing Gluten, Eggs, Milk, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': '1MKSZaD8BgtBd1XKXKW2',
            'name': 'Pigs In Blankets Sandwich',
            'brand': 'M&S',
            'serving_size_g': 220.0,  # Full sandwich
            'ingredients': 'British Pork Sausage (29%) (Pork (73%), Wheatflour (Fortified with Calcium, Iron, Vitamin B3 and B1), Pea Protein Isolate, Dextrose, Wheat Starch, Salt, Ground Spices (White Pepper, Coriander, Mace, Nutmeg), Dried Onions, Black Pepper Extract, Yeast Extract, Dried Sage, Raising Agent: E503), Wheatflour (Fortified with Calcium, Iron, Vitamin B3 and B1), Water, Red Onion and Ruby Port Chutney (7%) (Red Onions, Sugar, Red Wine Vinegar, Ruby Port, Muscovado Sugar, Concentrated Lemon Juice, Ground Spices (Nutmeg, Cloves, Allspice, Cinnamon), Coarse Black Pepper, Ground Bay Leaves), Smoked British Bacon (7%) (Pork Belly made with 185g Raw Pork per 100g Cooked Bacon, Curing Salt (Salt, Preservative: Sodium Nitrate, Sodium Nitrite), Sugar, Natural Flavouring, Antioxidant: E301), Rapeseed Oil, Onions, Malted Wheatflakes, Pasteurised Egg, Brown Sugar, Wheat Bran, Butter (Milk), Balsamic Vinegar, Sugar, Salt, Vinegar, Yeast (Yeast, Vitamin D Yeast), Malted Barley Flour, Palm Oil, Cornflour, Dried Yeast, Concentrated Mushrooms, Emulsifier (E471, E472e), Concentrated Lemon Juice, Malted Wheatflour, Dried Fermented Wheatflour, Wheat Gluten, Reduced Sodium Salt, Sage, Concentrated Tomatoes, Dried Mustard, Ground Spices (White Pepper, Allspice, Turmeric), Concentrated Carrot Juice, Mushroom Extract, Seaweed Extract, Dried Mushrooms, Concentrated Onion Juice, Dried Onions, Flour Treatment Agent (Ascorbic Acid), Vegetable Oil (Sunflower/Rapeseed), Natural Flavouring, Tomato Purée, Palm Fat. British pork sausages wrapped in smoked bacon on malted brown bread with mayonnaise and red onion ruby port chutney. Contains Eggs, Gluten, Milk, Mustard, Pork.'
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

    print(f"✨ BATCH 10 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {33 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch10(db_path)
