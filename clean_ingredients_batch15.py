#!/usr/bin/env python3
"""
Clean ingredients batch 15 - M&S Products
"""

import sqlite3
from datetime import datetime

def update_batch15(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 15 (M&S Products)\n")

    clean_data = [
        {
            'id': 'NJY4cpAVOJ0JIDCcAlVu',
            'name': 'Chargrilled Chicken, King Prawn & Chorizo Paella',
            'brand': 'M&S',
            'serving_size_g': 400.0,  # Half of 800g pack (serves 2)
            'ingredients': 'Cooked Spanish Rice (28%) (Water, Rice), Chicken Thighs (15%), King Prawns (Crustacean) (10%), Onions, Chorizo (5%) (Pork (90%), Water, Curing Salt (Salt, Preservative: Potassium Nitrate, Sodium Nitrite), Ground Smoked Paprika, Garlic Purée, Dextrose, Antioxidant: E301, Ground Nutmeg, Oregano), Tomatoes, White Wine (3.5%), Peas (3.5%), Piquillo Peppers (3.5%) (Piquillo Peppers, Water, Sugar, Salt), Extra Virgin Olive Oil, Red Peppers, Chicken Stock (Water, Chicken Bones, Onions, Carrots, Leeks, Parsley, Garlic, Ground White Pepper, Ground Bay Leaves), Sherry, Rapeseed Oil, Carrots, Garlic Purée, Salt, Fish and Shellfish Stock (Water, Fish Bones, Prawns (Crustacean), Onions, White Wine, Carrots, Langoustine (Crustacean), Salt, Leeks, Tomato Paste, Fennel, Lemon Juice, Parsley, Garlic, Dried Thyme, Ground Bay Leaves, White Peppercorns, Black Peppercorns), Ground Spices (Smoked Paprika, Turmeric, Fennel Seeds, Paprika, Black Pepper, White Pepper), Lemon Juice, Cornflour, Whole Milk, Olive Oil, Red Chillies, Pork Gelatine, Sundried Tomatoes, White Wine Vinegar, Dried Garlic, Rosemary, Vegetable Oil (Sunflower/Rapeseed), Lemon Zest, Thyme, Saffron, Ground Rosemary, Dried Basil. Contains Crustaceans, Fish, Milk, Sulphites.'
        },
        {
            'id': 'GGvMAhZfLKCU9OYSV2eE',
            'name': 'Gluten Free Prosciutto Ricotta Cappelletti',
            'brand': 'M&S',
            'serving_size_g': 125.0,  # Half of 250g pack
            'ingredients': 'Gluten Free Egg Pasta (60%) (Potato Starch, Pasteurised Egg, Water, Vegetable Fibre, Pasteurised Egg White, Maize Starch, Rice Flour, Buckwheat Flour, Extra Virgin Olive Oil, Salt, Yeast Extract, Flavouring, Thickening Agent: E412, Guar Gum), Mortadella (12%) (Pork (97%), Curing Salt (Salt, Preservative: Sodium Nitrite), Dried Garlic, Antioxidant: E301), Prosciutto (10%) (Pork (99%), Salt), Ricotta Cheese (Milk) (5%), Cornflour, Lactose (Milk), Salt, Skimmed Milk Powder, Medium Fat Hard Cheese (Milk), Caramelised Sugar. Italian free-range egg pasta parcels filled with prosciutto, mortadella and ricotta cheese. Gluten free. Made in Tuscany. Contains Eggs, Milk. May Contain Nuts, Peanuts.'
        },
        {
            'id': 'UWPXI6lVGYY8RBE2mZ9b',
            'name': 'Indian Starter Selection',
            'brand': 'M&S',
            'serving_size_g': 100.0,  # Per portion (4 samosas, 4 bhajis, 4 pakoras in 300g pack)
            'ingredients': 'Vegetable Samosas (4): Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Cooked Potatoes (21%), Onions, Water, Rapeseed Oil, Peas (7%), Carrots (7%), Coriander, Tomato Paste, Salt, Ground Spices (Coriander, Cayenne Pepper, Fenugreek Seeds, Turmeric, Cardamom), Green Chilli Purée, Ginger Purée, Garlic Purée, Ground Garam Masala (Roasted Cumin, Cardamom, Roasted Coriander, Black Pepper, Sweet Cinnamon (Cassia), Mace, Cloves). Onion Bhajis (4): Onions (71%), Chickpea Flour, Rice Flour, Rapeseed Oil, Coriander, Ground Spices (Roasted Cumin, Chilli Powder, Turmeric, Fennel Seeds), Salt, Cumin Seeds, Green Chilli Purée, Onion Seeds, Ginger Purée, Concentrated Lemon Juice, Raising Agent: E450, Sodium Bicarbonate. Vegetable Pakoras (4): Onions, Chickpea Flour, Rapeseed Oil, Carrots (11%), Cauliflower (11%), Peas (8%), Red Peppers (7%), Raisins, Coriander, Cornflour, Green Chilli Purée, Ground Spices (Roasted Cumin, Roasted Coriander, Turmeric), Salt, Raising Agent: E450, Sodium Bicarbonate, Onion Seeds, Dried Mango, Rice Flour, Sunflower Oil. Contains Cereals Containing Gluten. Not suitable for those with a Milk allergy.'
        },
        {
            'id': 'bAWWjtPSkD1kyxcePX4q',
            'name': 'Singapore Noodles',
            'brand': 'M&S',
            'serving_size_g': 400.0,  # Full ready meal pack
            'ingredients': 'Cooked Rice Noodles (34%) (Water, Rice Flour), Beansprouts (11%), Chicken Thighs (6%), Carrots, Red Peppers (5%), Water, Coconut Cream (Coconut Extract, Water), Pork (5%), Rapeseed Oil, Cooked King Prawns (Crustacean) (3.5%), Cabbage, Toasted Sesame Oil, Dark Soy Sauce, Ground Spices (Turmeric, Paprika, Coriander, Cumin, Ginger, Fennel Seeds, Chilli Powder, Coriander Seeds, White Pepper, Cloves, Cayenne Pepper, Fenugreek Seeds, Fennel, Cinnamon, Star Anise), Red Chillies. Fine rice noodles with vegetables, chargrilled chicken thighs, pork and prawns in spicy coconut and tamarind sauce. Contains Crustaceans, Sesame, Soya.'
        },
        {
            'id': 'ZD4qJld2zLVO9gD0Dy0s',
            'name': 'Triple Layered Banoffee Mousse Cakes',
            'brand': 'M&S',
            'serving_size_g': 73.0,  # Per cake (145g pack contains 2 cakes)
            'ingredients': 'Double Cream (Milk) (26%), Salted Caramel (17%) (Double Cream (Milk), Brown Sugar, Sugar, Butter (Milk), Cornflour, Salt), Sugar, Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Rapeseed Oil, Banana Puree (6%), White Chocolate (4.5%) (Sugar, Cocoa Butter, Dried Whole Milk, Dried Skimmed Milk, Emulsifier: Soya Lecithin, Natural Vanilla Flavouring), Pasteurised Egg, Whole Milk, Milk Chocolate (3%) (Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Lactose (Milk), Emulsifier: Soya Lecithin), Dark Chocolate (3%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier: Soya Lecithin), Humectant: Glycerol. Light banana sponge on chocolate wafer base filled with salted caramel and white chocolate mousse, topped with fudge pieces and salted caramel drizzle. Contains Cereals Containing Gluten, Eggs, Milk, Soya, Wheat.'
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

    print(f"✨ BATCH 15 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {55 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch15(db_path)
