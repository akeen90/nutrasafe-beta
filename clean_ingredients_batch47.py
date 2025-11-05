#!/usr/bin/env python3
"""
Clean ingredients batch 47 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch47(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 47\n")

    clean_data = [
        {
            'id': '0Ra3upN0VGDtJ1RHdmK3',
            'name': 'Golden Blond Chocolate Spread',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil, Sugar, Dried Skimmed Milk, Caramel Powder (10%) (Whey (Milk), Butter (Milk), Maltodextrin, Sugar, Skimmed Milk, Flavouring), Cocoa Butter, Dried Whey (Milk), Wafer Pieces (4%) (Potato Starch, Sugar, Chickpea Flour, Maize Flour, Coconut Fat, Emulsifier (Sunflower Lecithin), Salt, Flavouring), Dried Whole Milk, Lactose (Milk), Milk Fat, Emulsifier (Soya Lecithin), Flavouring, Bourbon Vanilla Extract, Antioxidant (Tocopherol-Rich Extract). Contains Milk, Soybeans. Not Suitable for Those with a Nut and Peanut Allergy.'
        },
        {
            'id': '0SDGEc4NUwQVdIMLfVnX',
            'name': '12 Pork Sausages',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British Pork (72%), Water, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Dextrose, Salt, Stabilisers (Diphosphates, Disodium Diphosphate), Preservatives (Sodium Metabisulphite (Sulphites), Sulphur Dioxide), Raising Agent (Ammonium Carbonate), Herbs (Parsley, Sage), Yeast Extract, Spices (Black Pepper, White Pepper), Antioxidant (Ascorbic Acid), Spice Extracts (Sage Extract, Nutmeg Extract, Mace Extract, Pimento Extract). Sausages Filled into Pork Collagen Casings. Contains Cereals Containing Gluten, Sulphites, Wheat.'
        },
        {
            'id': '0Sfs1PKxgQu99HIZC8vU',
            'name': 'Kansas Style BBQ Sauce',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato Purée (62%), Demerara Sugar, Sugar, Cider Vinegar, Spirit Vinegar, Modified Maize Starch, Salt, Garlic Purée, Roasted Barley Malt Extract, Smoked Maltodextrin, Smoked Paprika, Acidity Regulator (Citric Acid), Chilli Powder. Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': '0TdNzgUQAmxwbNr3JoHE',
            'name': 'Honey Roast Ham',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (76%), Water, Honey (4%), Salt, Dextrose, Stabiliser (Triphosphates), Brown Sugar, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '0OkEwOg6VKrqAJPVRbkK',
            'name': 'Creamy Coleslaw',
            'brand': 'Lidl Deluxe',
            'serving_size_g': 50.0,
            'ingredients': 'Mayonnaise (43.5%) (Rapeseed Oil, Water, Whole Salted Egg, Egg, Salt, Spirit Vinegar, Sugar), White Cabbage (15%), Carrot (37%), Sugar Syrup (Sugar, Water), Diced Onion (1%), Chopped Chives, Stabilisers (Guar Gum, Xanthan Gum), Yellow Mustard Flour, Preservative (Potassium Sorbate). Contains Eggs, Mustard.'
        },
        {
            'id': '0VPWFI2ksp1fVvdBU9bG',
            'name': 'Four Cheese Tortelloni',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Egg Pasta (62%) (Durum Wheat Semolina, Wheat Flour, Egg (15%), Water), Cheese Flavoured Filling (38%) (Ricotta Soft Cheese (47%) (Milk), Breadcrumbs (Wheat Flour, Yeast, Salt), Emmental Semi-Hard Cheese (12%) (Milk), Whey Powder (Milk), Sunflower Oil, Grated Hard Cheese (6%) (Milk), Gorgonzola PDO Cheese (1%) (Milk), Salt, Yeast, Natural Flavouring). Contains Cereals Containing Gluten, Eggs, Milk, Wheat. May Contain Crustaceans, Fish, Molluscs, Mustard, Nuts, Soybeans.'
        },
        {
            'id': '0VRc4gkCMrAN7VW7HAr8',
            'name': 'Pepperoni Delight Stuffed Crust Pizza',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Folic Acid, Iron, Niacin, Thiamin), Mozzarella Cheese (26%) (Cows\' Milk), Water, Pepperoni (8%) (Pork, Durum Wheat Semolina, Salt, Dextrose, Paprika Extract, Cayenne Pepper, Antioxidants (Extracts of Rosemary, Sodium Ascorbate), Garlic Powder, Paprika, Pepper Extract, Preservative (Sodium Nitrite)), Semolina (Wheat), Tomatoes, Tomato Purée, Rapeseed Oil, Maize, Sugar, Potato Starch, Garlic Purée, Salt, Yeast, Wheat Flour, Parsley, Stabiliser (Guar Gum), Garlic Powder, Black Pepper, Basil, Oregano. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '0W7tPksN3HMLY5SAROY3',
            'name': 'Organic Almond',
            'brand': 'Vemondo',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Almonds (2.3%)*, Salt, Stabiliser (Locust Bean Gum*, Gellan Gum), Emulsifier (Lecithins*). *Organically Produced. Contains Almonds, Nuts.'
        },
        {
            'id': '0WqnZAtBNeuVHQg3Wc6e',
            'name': 'Seeded Baguette',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Sunflower Seeds, Rye Flour, Seed Mix (2.5%) (Oat Flakes, Sunflower Seeds, Brown Linseed), Yeast, Brown Linseed, Golden Linseed, Salt, Roasted Barley Malt, Malted Wheat Flour, Wheat Flour. Contains Barley, Cereals Containing Gluten, Oats, Rye, Wheat.'
        },
        {
            'id': '0aCuBLNg45IaR1MC0Tiy',
            'name': 'Chicken Burger',
            'brand': 'Roosters',
            'serving_size_g': 139.0,
            'ingredients': 'Chicken Breast Fillet (77%), Wheat Flour (Wheat Flour, Calcium Carbonate, Folic Acid, Iron, Niacin, Thiamin), Rapeseed Oil, Water, Wheat Starch, Wheat Gluten, Potato Starch, Salt, Raising Agents (Diphosphates, Sodium Carbonates), Yeast Extract, Garlic Powder, Onion Powder, Ground White Pepper, Cayenne Chilli Powder, Yeast, Colour (Paprika Extract), Capsicum Extract. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '0aKWFb7FnVMnD6uXTASW',
            'name': 'Bombay Chicken',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken (116g per 100g finished product), Sugar, Cornflour, Spices, Tomato Powder, Onion Powder, Salt, Brown Sugar, Dextrose, Stabilizer (Triphosphates), Garlic Powder, Black Onion Seed, Bell Pepper, Herbs, Spice Extracts (Turmeric, Paprika), Flavouring.'
        },
        {
            'id': '0aWDKevnjALbsc5uZfQj',
            'name': 'Dreemy',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (39%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Lactose (Milk), Sweet Whey Powder (Milk), Emulsifier (Lecithins (Soya)), Salt, Vanilla Extract), Glucose Syrup, Palm Fat, Barley Malt Extract, Skimmed Milk Powder, Egg White Powder, Lactose (Milk), Salt, Vanilla Extract, Emulsifier (Lecithins (Soya)). Milk Chocolate Contains Cocoa Solids 27% Minimum, Milk Solids 14% Minimum. Contains Barley, Cereals Containing Gluten, Eggs, Milk, Soybeans. May Contain Nuts, Peanuts.'
        },
        {
            'id': '0bbQGiM15E9OWuj5pw4X',
            'name': 'Asda Popped',
            'brand': 'Asda',
            'serving_size_g': 20.0,
            'ingredients': 'Lentil Flour, Cornflour, Vegetable Oils (Rapeseed Oil, Sunflower Oil), Rice Flour, Pea Starch, Potato Starch, Sugar, Salt, Flavouring, Sweet Whey Powder (Milk), Onion Powder, Garlic Powder, Paprika Powder, Green Peppercorns, Potassium Chloride, Maize Starch, Acidity Regulator (Citric Acid), Spices, Smoked Salt, Colour (Paprika Extract). Contains Milk. May Contain Soybeans.'
        },
        {
            'id': '0cWD21LSIaTXyPZiiuwm',
            'name': 'Coleslaw',
            'brand': 'Eastman\'s Deli Foods',
            'serving_size_g': 50.0,
            'ingredients': 'Cabbage (57%), Water, Rapeseed Oil, Carrot (7%), Spirit Vinegar, Sugar, Onion, Pasteurised Egg Yolk, White Wine Vinegar, Salt, Stabilisers (Guar Gum, Xanthan Gum). Contains Eggs.'
        },
        {
            'id': '0d6WJHXECpfZ0dSFQhF7',
            'name': 'Cumberland Venison Sausage',
            'brand': 'Highland Game',
            'serving_size_g': 100.0,
            'ingredients': 'Venison (48%), Pork (16%), Water, Pork Fat, Pea Flour, Salt, Spices, Dextrose, Rubbed Herbs, Stabiliser (Sodium Triphosphate), Yeast Extract, Onion Powder, Preservative (Sodium Metabisulphite), Garlic Powder, Antioxidant (Ascorbic Acid), Beef Collagen Casing. Contains Sulphites.'
        },
        {
            'id': '0dCBw4JvbY6jo0VNnTkh',
            'name': 'Raisins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Raisins, Cottonseed Oil. May Contain Milk, Nuts, Soybeans.'
        },
        {
            'id': '0dQEDXH1HSTdQWuX4Jku',
            'name': '2 Chicken Tikka Slices',
            'brand': 'Chef Select',
            'serving_size_g': 150.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Water, British Chicken (20%), Tomato, Single Cream (Milk), Margarine (Palm Oil, Rapeseed Oil, Water, Salt), Onion, Tikka Seasoning (Tomato, Sugar, Whole Milk Powder, Salt, Garlic, Ground Cumin, Ground Turmeric, Ground Fenugreek, Ground Coriander, Ground Cardamom, Chilli Powder, Rapeseed Oil, Citric Acid, Colour (Paprika Extract), Spice Extract), Modified Maize Starch, Rapeseed Oil, Flour Treatment Agent (L-Cysteine), Tomato Paste, Salt, Glaze (Milk Protein, Dextrose, Rapeseed Oil), Dextrose, Garlic Seasoning (Onion Powder, Natural Garlic Flavouring). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '0f3SoHIW5xiudHBaDF42',
            'name': 'Chicken Jalfrezi With Pilau Rice',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Pilau Rice (Water, Basmati Rice, Rapeseed Oil, Salt, Concentrated Lemon Juice, Cumin Seeds, Colour (Curcumin), Cardamom Pods, Cardamom Powder, Bay Leaf Powder), Chicken Breast (22%), Onion, Tomato Purée, Tomato, Red Pepper, Rapeseed Oil, Ginger Purée, Garlic Purée, Yogurt (Milk), Green Chilli, Sugar, Cornflour, Coriander Powder, Salt, Coriander Leaf, Soya Oil, Palm Oil, Paprika, Lemon Juice, Cumin Powder, Colour (Paprika Extract), Chilli Powder, Turmeric Powder, Fenugreek, Cumin Seeds, Cardamom Powder, Black Pepper, Cinnamon Powder, Clove Powder, Ginger Powder, Mace, Star Anise, Basil Powder, Fennel, Sunflower Oil, Bay Leaf Powder. Contains Milk, Soybeans. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': '0fUX87YHaBvw0SegNl5W',
            'name': 'Pad Thai Kit',
            'brand': 'Blue Dragon',
            'serving_size_g': 133.0,
            'ingredients': 'Rice Noodles (47%) (Rice, Tapioca Starch), Pad Thai Paste (45%) (Sugar, Soybean Oil, Shallot (6%), Tamarind Paste (5.5%) (Tamarind, Water), Tomato Paste, Distilled Vinegar, Garlic (2%), Salt, Colour (Paprika Extract), Antioxidant (Tocopherol Rich Extract), Chilli Extract), Crushed Peanuts (8%). Contains Peanuts, Soybeans. May Contain Nuts.'
        },
        {
            'id': '0gjoOKCEgga4l3AIq8Za',
            'name': 'Flame Grilled Steak Tortilla Chips',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Vegetable Oils (Sunflower, Rapeseed), Flame Grilled Steak Seasoning (Whey Powder (Milk), Salt, Flavourings, Sugar, Yeast Extract Powder, Garlic Powder, Onion Powder, Acid (Citric Acid), Colour (Paprika Extract)). Contains Barley, Cereals Containing Gluten, Milk, Soybeans, Wheat.'
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

    total_cleaned = 571 + updates_made

    print(f"✨ BATCH 47 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch47(db_path)
