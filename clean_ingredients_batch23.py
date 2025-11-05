#!/usr/bin/env python3
"""
Clean ingredients batch 23 - Continuing Large Batches (Co-op Focus)
"""

import sqlite3
from datetime import datetime

def update_batch23(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 23 (Co-op Focus)\n")

    clean_data = [
        {
            'id': 'CW5fBH8AMA7omHMZwI6t',
            'name': 'Co-op Pasta Bowl Chicken & Bacon',
            'brand': 'Co-op',
            'serving_size_g': 270.0,
            'ingredients': 'Cooked Dressed Pasta (37%) (Durum Wheat Semolina, Water, Rapeseed Oil), Mayonnaise Dressing (20%) (Mayonnaise (Water, Rapeseed Oil, Cornflour, Pasteurised Egg Yolk (Egg, Salt), Spirit Vinegar, Sugar, Salt, Lemon Juice, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), White Wine Vinegar), Water, Chives, Cornflour, Onion Granules, Chipotle Paste (Water, Jalapeño Pepper, Spirit Vinegar, Sugar, Salt, Tomato Paste), Brown Sugar, Yeast Extract Powder, Rapeseed Oil, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt, Acidity Regulator (Citric Acid)), Salt, Garlic Purée, White Pepper), Sweetcorn (15%), Cooked Barbecue Marinated Chicken (10%) (Chicken Breast, BBQ Spice Seasoning (Sugar, Tomato Powder, Dried Glucose Syrup, Spices (Ground Paprika, Chilli Powder, Cassia, Turmeric, Cloves, Cumin Powder), Garlic Powder, Onion Powder, Acidity Regulator (Citric Acid), Lemon Juice Powder, Caramelised Sugar Powder, Smoked Salt, Yeast Extract Powder, Spirit Vinegar Powder, Flavouring)), Tomato (10%), Red Pepper, White Onion, Smoked Bacon (2%) (Pork Belly, Salt, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)). Contains Eggs, Mustard, Wheat.'
        },
        {
            'id': 'uq9cyIlXRrqaZJMkOPIq',
            'name': 'Falafel & Houmous',
            'brand': 'Co-op',
            'serving_size_g': 217.0,
            'ingredients': 'Chilli Tortilla Wrap (43%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Chilli Seasoning (Fortified Wheat Flour, Onion Powder, Sugar, Salt, Red Pepper, Chilli Powder, Garlic Powder, Chilli, Spice Extracts, Colour (Paprika Extract)), Sugar, Raising Agents (Sodium Hydrogen Carbonate, Disodium Diphosphate), Acidity Regulator (Malic Acid), Salt, Wheat Starch, Palm Fat), Falafel (19%) (Chick Peas, Rapeseed Oil, Onion, Self Raising Flour (Fortified Wheat Flour, Raising Agents (Calcium Phosphates, Sodium Hydrogen Carbonate)), Rusk (Fortified Wheat Flour, Water, Salt, Raising Agent (Ammonium Carbonates)), Parsley, Dried Onion, Rice Starch, Sugar, Coriander Leaf, Ground Coriander). Contains Wheat.'
        },
        {
            'id': 'vAyiEzIZ0zfcBohRUtW4',
            'name': 'Ham & Cheese Wrap',
            'brand': 'Co-op',
            'serving_size_g': 185.0,
            'ingredients': 'White Tortilla Wrap (49%) (Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Raising Agents (Sodium hydrogen carbonate, Malic acid, Disodium diphosphate), Sugar, Salt, Wheat Starch), Oak Smoked Formed Ham (19%) (Pork, Water, Salt, Stabiliser (Pentasodium triphosphate), Antioxidant (Sodium ascorbate), Preservative (Sodium nitrite)), Real Ale & Onion Chutney (8%) (Onion, Golden Granulated Sugar, Muscovado Sugar, Real Ale (Barley), White Balsamic Vinegar (White Wine Vinegar, Grape Must), Red Wine Vinegar, Salt, Concentrated Lemon Juice, Black Pepper), Reduced Fat Soft Cheese (Milk) (8%), Apollo Lettuce (5%), Medium Mature Cheddar Cheese (Milk) (5%), Soured Cream (Milk) (3%), Medium Fat Hard Cheese (Milk), Cornflour, Black Pepper. Contains Barley, Milk, Wheat.'
        },
        {
            'id': 'gZBHplXcPCJfyZKNHrmB',
            'name': 'Ham & Mature Cheddar With Mayonnaise On Malted Bread Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 167.0,
            'ingredients': 'Malted Bread (49%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes, Wheat Bran, Wheat Protein, Yeast, Malted Barley Flour, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Malted Wheat Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Starch, Wheat Flour), Oak Smoked Formed Ham (24%) (Pork, Salt, Dextrose, Stabilisers (Pentasodium Triphosphate, Pentapotassium Triphosphate, Tetrapotassium Diphosphate), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Medium Mature Cheddar Cheese (Milk) (18%), Mayonnaise (9%) (Water, Rapeseed Oil, Cornflour, Spirit Vinegar, Pasteurised Egg Yolk, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Sugar, White Wine Vinegar, Concentrated Lemon Juice, Salt). Contains Barley, Eggs, Milk, Mustard, Wheat.'
        },
        {
            'id': 'khHRmywIMnWKDyjq26c0',
            'name': 'Ham Cheese & Pickle Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 204.0,
            'ingredients': 'Malted Bread (44%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes, Wheat Bran, Yeast, Malted Barley Flour, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Wheat Protein, Malted Wheat Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Oak Smoked Formed Ham (22%) (Pork, Water, Salt, Stabiliser (Pentasodium Triphosphate), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Mature Cheddar Cheese (Milk) (13%), Mayonnaise (7%) (Water, Rapeseed Oil, Cornflour, Spirit Vinegar, Pasteurised Egg Yolk, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Sugar, White Wine Vinegar, Concentrated Lemon Juice, Salt), Lettuce (5%), Pickle (4%) (Malt Vinegar (Barley), Sugar, Water, Carrot, Swede, Courgette, Onion, Molasses, Cornflour, Non Brewed Condiment (Water, Acidity Regulator (Acetic Acid)), Salt, Spices). Contains Barley, Eggs, Milk, Mustard, Wheat.'
        },
        {
            'id': '2v5QAixWpfiKSxE6azNa',
            'name': 'Harissa Spiced Falafel Wrap',
            'brand': 'Co-op',
            'serving_size_g': 219.0,
            'ingredients': 'White Tortilla Wrap (41%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Raising Agents (Sodium Hydrogen Carbonate, Malic Acid, Disodium Diphosphate), Sugar, Salt, Wheat Starch), Spiced Falafel (18%) (Chick Peas, Red Pepper, Sweet Potato, Bread Rusk (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast), Self Raising Flour (Wheat Flour, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate, Monocalcium Phosphate)), Apple, Onion, Coriander, Red Chilli, Garlic Purée, Potato Flakes, Sultanas (Sultanas, Cottonseed Oil), Salt, Lemon Juice, Cumin, Ground Coriander, Onion Powder, Dried Red Bell Pepper, Smoked Paprika, Ground Paprika, Tomato Purée), Harissa Sauce (10%) (Water, Mango Purée, Red Pepper, White Wine Vinegar, Sugar, Cornflour, Tomato Paste, Extra Virgin Olive Oil, Mint, Cumin, Ginger Purée, Garlic Purée, Dried Chilli, Coriander, Salt, Rose Petals, Ground Coriander, Black Pepper). Contains Wheat.'
        },
        {
            'id': 'v3n7SphWpfH5XTvBIoEN',
            'name': 'Hunter\'s Chicken With Paprika Spiced Potatoes',
            'brand': 'Co-op',
            'serving_size_g': 350.0,
            'ingredients': 'Roasted Diced Potatoes (46%) (Potato, Rapeseed Oil, Paprika, Thyme, Cayenne Pepper, Salt), Marinated Cooked Chicken (20%) (Chicken Breast, Cornflour, Molasses, Garlic Purée, Salt, Smoked Paprika, Black Pepper), Water, Passata, Demerara Sugar, Tomato Ketchup (Tomato, Spirit Vinegar, Sugar, Salt, Pepper Extract, Celery Extract, Pepper), Monterey Jack Cheese (Milk) (2%), Onion, Red Wine Vinegar, Worcester Sauce (Water, Spirit Vinegar, Sugar, Tamarind Paste, Onion, Garlic, Ginger, Concentrated Lemon Juice, Ground Cloves, Chilli), Smoked Bacon Lardons (1%) (Pork, Salt, Water, Antioxidant (Sodium ascorbate), Preservative (Sodium nitrite)), Rapeseed Oil, Cornflour, Molasses, Garlic Purée, Mesquite Seasoning (Sugar, Salt, Dried Glucose Syrup, Yeast Extract, Tomato Powder, Cumin, Turmeric, Smoke Flavouring, Onion Powder, Garlic Powder, Malt Extract (Barley)), Salt, Colour (Plain caramel), Smoked Paprika, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Smoke Flavouring. Contains Barley, Celery, Milk, Mustard.'
        },
        {
            'id': 'YEFiaNubQAfN9iLo0s7b',
            'name': 'Korean Style Chicken Dragon Rolls',
            'brand': 'Co-op',
            'serving_size_g': 188.0,
            'ingredients': 'Cooked Sushi Rice (Water, Rice, Sugar, Rice Vinegar, Salt, Vegetable Oils (Sunflower, Rapeseed), Rice Wine), Sesame Seeds (7%), Chopped and Shaped Chicken Breast (6%), Water, Rapeseed Oil, Korean Style Chilli Sauce (Water, Dark Brown Soft Sugar, Soya Beans, Glucose Syrup, Rice Wine Vinegar, Salt, Ground Paprika, Onion Powder, Smoked Paprika, Molasses, Cayenne Pepper, Concentrated Lemon Juice, Treacle, Cornflour, Habanero Chilli, Dried Chilli, Garlic Powder, Malt Vinegar (Barley), Malt Extract (Barley), Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Wheat Flour, Preservative (Acetic acid)), Spring Onion (3%), Carrot (3%), Red Cabbage (2%), Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Nori Seaweed, Sugar, Cornflour, Spirit Vinegar, Paprika Flakes, Glucose Syrup, Salt, Pasteurised Liquid Egg Yolk, Wheat Starch, Ginger Purée, White Wine Vinegar, Rice Flour, Wheat, Ginger, Garlic Powder, Chilli Powder, Yeast Extract. Contains Barley, Eggs, Sesame, Soya, Wheat.'
        },
        {
            'id': 'BGBcp1KacIJ8yBQqe3Ld',
            'name': 'Loaded Tandoori Spiced Chicken',
            'brand': 'Co-op',
            'serving_size_g': 208.0,
            'ingredients': 'Marinated Chicken (40%) (Chicken Breast, Low Fat Yogurt (Milk), Spices, Cornflour, Rapeseed Oil, Green Chilli Purée, Lemon Juice, Garlic Purée, Ginger Purée, Salt, Colour (Paprika extract), Bay Leaf, Lemon Oil), Tikka Sauce (28%) (Onion, Single Cream (Milk), Water, Tomato Paste, Tomato, Rapeseed Oil, Tomato Juice, Spices, Ginger Purée, Garlic Purée, Cashew Nuts, Honey, Coriander, Cornflour, Butter (Milk), Green Chilli Purée, Salt, Fenugreek, Colour (Paprika extract), Red Chilli Powder, Bay Leaf, Lemon Oil), Vegetable Mix (14%) (Onion, Yellow Pepper, Red Pepper, Green Pepper, Rapeseed Oil, Red Chilli, Coriander Leaf, Lime Juice, Mint), Cheese Mix (9%) (Onion, Cheddar Cheese (Milk), Garlic, Coriander Leaf, Red Chilli, Cumin Seeds, Dried Red Pepper), Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Palm Oil. May Contain Nuts, Peanuts, Sesame. Contains Cashews, Milk, Wheat.'
        },
        {
            'id': 'a57kQOWiOyGjMvkjhgO3',
            'name': 'Luxury Lasagne Al Forno',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Béchamel Sauce (Milk, Single Cream, Grana Padano Medium Fat Hard Cheese, Mozzarella, Cornflour, Extra Mature Cheddar Cheese, Salt, White Pepper), Beef (20%), Cooked Egg Pasta (20%) (Durum Wheat Semolina, Water, Pasteurised Egg), Tomato, White Wine, Tomato Purée, Milk, Onion, Carrot, Beef Stock, Cornflour, Medium Fat Hard Cheese, Water, Olive Oil, Parmigiano Reggiano (1%), Mozzarella (1%), Garlic Purée, Sun-dried Tomato Purée, Sugar, Oregano, Extra Virgin Olive Oil, Salt, Bay Leaf, Black Pepper. Contains Eggs, Milk, Wheat.'
        },
        {
            'id': 'C9nBtdE0WuucvPQTOYho',
            'name': 'Middle Eastern Menu: Spinach & Pine Nut Falafel Wrap',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Tortilla Wrap (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Sugar, Palm Fat, Raising Agents (Sodium Hydrogen Carbonate, Disodium Diphosphate), Acidity Regulator (Malic Acid), Salt, Wheat Starch), Spinach & Pine Nut Falafel (21%) (Peas, Chick Peas, Spinach, Pine Kernels, Potato Flakes, Red Onion, Rapeseed Oil, Self Raising Flour (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate)), Garlic, Salt, Lemon Juice, Cumin, Ground Coriander, Black Pepper, Mint), Steam Roasted Pickled Onion (8%) (Red Onion, Lime Juice, Sugar, Spirit Vinegar, Salt), Spinach (4%), Coconut Oil Derived Greek Style Pieces (4%) (Water, Coconut Oil, Potato Starch, Potato Protein, Sea Salt, Flavouring, Acidity Regulator (Lactic Acid), Olive Fruit Extract), Coconut Oil and Coconut Cream with added Starch Flavourings Calcium and Vitamins D2 and B12 (4%) (Water, Coconut Oil). Contains Nuts, Wheat.'
        },
        {
            'id': 'ZrKBYzPnHFhnIF2UWrT9',
            'name': 'Onion Bhaji & Mango Chutney Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 195.0,
            'ingredients': 'White Bread with Black Onion Seeds (46%) (Wheat Flour (with Calcium Carbonate, Iron, Niacin, Thiamin), Water, Black Onion Seeds, Salt, Yeast, Wheat Protein, Emulsifier (Mono- and Diglycerides of Fatty Acids - Vegetable), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Onion Bhaji (21%) (Onion, Rapeseed Oil, Gram Flour (Maize Flour, Tyson Peas, Yellow Split Peas), Wheat Flour (with Calcium Carbonate, Iron, Niacin, Thiamin), Coriander Leaf, Salt, Ginger Purée, Ground Fenugreek, Garam Masala (Coriander, Cumin, Ginger, Black Pepper, Cloves, Cardamom, Nutmeg, Star Anise), Cumin Powder, Cumin Seeds, Chilli Powder, Raising Agent (Sodium Hydrogen Carbonate), Turmeric), Carrot (9%), Vegan Mint Mayonnaise (6%) (Water, Rapeseed Oil, Mint, Cornflour, Sugar, Spirit Vinegar, Pea Protein, Salt, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Concentrated Lemon Juice), Apollo Lettuce (5%), Mango Chutney (4%) (Mango, Sugar, Spirit Vinegar, Glucose Syrup, Salt, Ground Paprika, Ground Coriander, Ground Cardamom, Ground Cumin). Contains Barley, Mustard, Sulphites, Wheat.'
        },
        {
            'id': 'i59IpkdfTgZsV7Z2B1pb',
            'name': 'Salt & Pepper Chicken Wrap',
            'brand': 'Co-op',
            'serving_size_g': 227.0,
            'ingredients': 'Chilli Tortilla Wrap (40%) (Wheat Flour, Water, Vegetable Oils (Palm, Rapeseed), Red Chilli Seasoning (Fortified Wheat Flour, Onion Powder, Sugar, Salt, Red Pepper, Chilli Powder, Garlic Powder, Chilli, Spice Extracts, Colour (Paprika Extract)), Sugar, Raising Agents, Acidity Regulator, Salt, Wheat Starch), Southern Fried Style Formed Chicken Goujons (22%) (Chopped and shaped chicken breast, Wheat flour, Water, Rapeseed oil, Rice flour, Wheat starch, Salt, Wheat protein, Cornflour, Sugar, Yeast extract, Spices (Black Pepper, Fennel Seed, Nutmeg, White Pepper, Turmeric), Garlic powder, Onion powder, Yeast, Raising agents), Pepper, Spinach, Carrot, Mayonnaise, Spring Onion, Sweet Chilli Sauce, Onion, Seasoning Paste. Contains Eggs, Wheat.'
        },
        {
            'id': 'jp1Z5XLdgWxZV2eTec71',
            'name': 'Sausage And Mash',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (44%), Cooked Pork Sausages (23%)(Pork, Pork Rind, Water, Rusk (Fortified Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Raising Agent (Ammonium carbonates)), Pork Fat, Seasoning (Salt, Fortified Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Potato Starch, Dextrose, Spices (Black Pepper, Coriander, Cumin, Pimento, Cardamom, Turmeric, Nutmeg, Ginger, Cloves, Cassia, Cayenne Pepper), Herbs (Sage, Bay), Stabiliser (Diphosphates), Flavouring, Rapeseed Oil), Fortified Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), Sage), Water, Onion, Butter (Milk), Rapeseed Oil, Beef Stock (Water, Beef Extract, Salt, Yeast Extract, Sugar, Beef Fat, Tomato Paste, Onion, Carrots, Onion Juice Concentrate), Cornflour, Worcestershire Sauce (Water, Spirit Vinegar, Sugar, Tamarind Paste, Onion, Garlic, Concentrated Lemon Juice, Ginger, Ground Cloves, Chilli). Contains Milk, Wheat.'
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

    print(f"✨ BATCH 23 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {152 + updates_made} / 681\n")
    print(f"🎯 MILESTONE WATCH: {200 - (152 + updates_made)} products until 200!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch23(db_path)
