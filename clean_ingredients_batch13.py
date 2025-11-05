#!/usr/bin/env python3
"""
Clean ingredients batch 13 - Mixed Brands (Reaching 50 Products Milestone!)
"""

import sqlite3
from datetime import datetime

def update_batch13(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 13 (Mixed Brands)\n")

    clean_data = [
        {
            'id': 'elLWYtdx5FChUwY3OoZV',
            'name': 'Big Bros Enchiladas',
            'brand': 'Wicked Kitchen',
            'serving_size_g': 450.0,  # Updated full pack weight
            'ingredients': 'Oat Drink (Water, Oats, Rapeseed Oil, Calcium Carbonate, Salt, Stabiliser (Gellan Gum), Riboflavin, Vitamin B12, Folic Acid, Potassium Iodate, Vitamin D), Sweet Potato (14%), Cooked Rice (Water, Long Grain Rice), Plain Tortilla (Wheat Flour, Water, Palm Oil, Rapeseed Oil, Sugar, Raising Agents (Sodium Bicarbonate, Disodium Diphosphate, Malic Acid), Salt), Beans (10%) (Black Turtle Beans, Pinto Beans), Cabbage, Tomato Passata, Sweetcorn And Red Pepper Salsa (6%) (Sweetcorn, Red Pepper, Rapeseed Oil, Paprika Flakes, Chipotle Chilli Powder, Salt, Cracked Black Pepper), Tomato, Onion, Rapeseed Oil, Jalapeño Chilli, Cornflour, Tomato Juice, Garlic Purée, Modified Potato Starch, Coconut Oil, White Wine Vinegar, Extra Virgin Olive Oil, Salt, Smoked Paprika, Muscovado Sugar, Yeast Extract, Paprika Flakes, Cumin Seed, Sea Salt. Mexican style spiced beans and rice, roasted sweet potato in soft flour tortillas with wicked jalapeños, topped with spiced red pepper and corn salsa. Vegan. Plant-based. Contains cereals containing gluten.'
        },
        {
            'id': 'vbgA8uIesS73w2NHel6r',
            'name': 'Fruity Favourites Yoghurts',
            'brand': 'Yeo Valley',
            'serving_size_g': 110.0,  # Per pot (4 x 110g multipack)
            'ingredients': 'Organic Whole Milk Yogurt, Organic Fruit (5%) (Strawberry/Raspberry/Blackcurrant/Apricot depending on variety), Organic Sugar (4.9-5%), Organic Maize Starch, Natural Flavouring, Organic Concentrated Elderberry Juice (in some varieties), Organic Concentrated Lemon Juice. Contains live cultures: Bifidobacterium, Lactobacillus Acidophilus, Streptococcus Thermophilus. Multipack contains 1x Strawberry, 1x Raspberry, 1x Apricot, 1x Blackcurrant. No gluten-containing ingredients. May contain fruit stones. Organic.'
        },
        {
            'id': 'S1Rx12JXzwgUyuRhu0RC',
            'name': 'MSC Crispy Californian Dragon Rolls',
            'brand': 'Yo',
            'serving_size_g': 184.0,  # Full pack (181-186g variations)
            'ingredients': 'Cooked Rice (Water, Rice, Sugar, Spirit Vinegar, Rice Vinegar, Salt, Rapeseed Oil, Fructose-Glucose Syrup, Cane Molasses), MSC Seafood Chunks (10%) (Surimi (MSC Alaska Pollock (Theragra Chalcogramma) (Fish) and/or Hake (Merluccius Productus) (Fish), Sugar, Stabilizers (Sorbitol, Di, Tri and Polyphosphates)), Water, Reconstituted Pasteurised Free Range Egg White Powder, Wheat Starch, Rapeseed Oil, Pea Starch, Soya Protein, Salt, Sugar, Modified Potato Starch, Natural Flavouring (contains Crustaceans), Colour (Lycopene)), Red Pepper, Kabayaki Sauce Sachet (6%) (Water, Glucose Syrup, Sugar, Soy Sauce (Water, Soya Beans, Salt, Alcohol), Mirin, Cornflour, Salt), Crispy Onions (Onions, Palm Oil, Wheat Flour, Salt), Mayonnaise (Rapeseed Oil, Water, Pasteurised Free Range Egg, Pasteurised Free Range Egg Yolk, Spirit Vinegar, Sugar, Salt, Lemon Juice from Concentrate, Preservative (Potassium Sorbate), Antioxidant (Calcium Disodium EDTA), Colour (Paprika Extract)), Rocket, Black and White Sesame Seeds. 7 MSC seafood stick rolls with red pepper & rocket, coated in black & white sesame seeds, with kabayaki sauce & crispy onions. Contains Crustaceans, Eggs, Fish, Sesame, Soya, Wheat.'
        },
        {
            'id': 'zCBxjgNXJzMCgfsCycoL',
            'name': 'Chorizo Carbonara',
            'brand': 'Zizzi',
            'serving_size_g': 400.0,  # Full ready meal pack
            'ingredients': 'Cooked Spaghetti Pasta (27%) (Water, Durum WHEAT Semolina), Single Cream (12%) (MILK), Cooked Diced Smoked Pancetta (7%) (Pork Belly, Water, Salt, Glucose Syrup, Maltodextrin, Spice Extracts, Antioxidants: Sodium Ascorbate, Sodium Citrates; Preservatives: Sodium Nitrite, Potassium Nitrate), Mature Cheddar Cheese (MILK), Diced Chorizo (6%) (Pork, Salt, Pork Fat, Dextrose, Spices (Paprika Powder, Coriander Powder, Pepper, Chilli Powder), Spice Extracts, Antioxidants: Sodium Ascorbate, Ascorbic Acid; Yeast Extract, Garlic Powder, Acidity Regulator: Citric Acid; Preservative: Sodium Nitrite), Unsalted Butter (MILK), Dried Whole MILK, Wheat Flour (WHEAT Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pecorino Cheese (Sheep MILK), Regato Cheese (MILK), Sunflower Oil, Modified Maize Starch, Medium Fat Hard Cheese (MILK), Cheese Stock (Processed Cheese Powder (MILK), Emulsifying Salt: Sodium Phosphates, Dried Glucose Syrup, Water, Yeast Extract, Salt, Sunflower Oil, Natural Flavouring). Cooked spaghetti pasta with smoked chorizo and diced smoked pancetta in creamy carbonara sauce. Contains MILK, WHEAT, Pork.'
        },
        {
            'id': 'n1yfnh5I3r4066dU54kQ',
            'name': 'Thai Green Chicken Noodles Soup',
            'brand': 'Yorkshire Provender',
            'serving_size_g': 600.0,  # Full soup pack
            'ingredients': 'Water, Vegetables (35%) (Potato, Onion, Butternut Squash, Carrot, Mixed Peppers, Spinach), Chicken (5%), Creamed Coconut, Rice Noodles (2%) (Rice Flour, Water), Thai Green Curry Paste (Water, Salt, Rapeseed Oil, Onion Juice Concentrate, Spinach Powder, Garlic Powder, Lime Juice from Concentrate, Jalapeño Powder, Cumin, Ginger, Lemongrass, Coriander, Galangal, Turmeric, Black Pepper), Ginger Purée, Vegetable Bouillon (Salt, Potato Starch, Dried Vegetables (Celeriac (Celery), Onion, Garlic, Tomato), Spices (Celery, Turmeric, Black Pepper, Mace, Nutmeg), Herbs (Lovage, Parsley)), Fresh Yorkshire Coriander (subject to seasonal availability May-October), Lime Juice, Lemongrass, Garlic Purée, Red Chilli, Ground Coriander, Lime Leaves, Ground Cumin, Salt. 1 of 5 a day per portion. Source of protein. Low in fat. Gluten free. Contains Celery.'
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

    print(f"✨ BATCH 13 COMPLETE: {updates_made} products cleaned")
    print(f"🎉 MILESTONE REACHED: 50 / 681 PRODUCTS CLEANED!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch13(db_path)
