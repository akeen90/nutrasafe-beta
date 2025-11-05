#!/usr/bin/env python3
"""
Clean ingredients batch 48 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch48(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 48\n")

    clean_data = [
        {
            'id': '0v5tW7vTrh3rJZeIKjoh',
            'name': 'Potato And Onion Tortilla',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (56%), Pasteurised Egg (28%), Onions (11%), Sunflower Oil, Salt, Olive Oil. Contains Eggs.'
        },
        {
            'id': '0wxR3MOGIDWk8z2o4tXU',
            'name': 'Chocolaté Digestive Biscuits',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (29%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Emulsifier (Lecithins (Soya)), Flavouring), Oat Flour, Vegetable Margarine (Palm Fat, Rapeseed Oil, Water, Palm Oil, Salt, Emulsifier (Mono- and Diglycerides of Fatty Acids)), Muscovado Sugar, Oat Bran, Soya Flour, Cornflour, Golden Syrup, Salt, Raising Agent (Sodium Hydrogen Carbonate). Contains Milk, Oats, Soybeans. May Contain Nuts.'
        },
        {
            'id': '0xTksGq5pdC5cCuYEZHS',
            'name': 'Dry Sausage',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Meat (134g of Pork Meat and 15g of Beef per 100g of Finished Product), Salt, Spices, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite). May Contain Celery, Milk, Mustard, Soybeans.'
        },
        {
            'id': '0y1pxRmO4YPeOzWTp1yE',
            'name': 'Tuna Chunks In Spring Water',
            'brand': 'Aldi The fishmonger',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack Tuna (Katsuwonus Pelamis) (Fish), Spring Water. Contains Fish.'
        },
        {
            'id': '0zZJ9CWeyyNvgOnmXRbJ',
            'name': 'Burger Pickle',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Gherkins (23%) (Gherkins, Water, Salt, Acidity Regulator (Acetic Acid), Firming Agent (Calcium Chloride), Preservative (Potassium Metabisulphite)), Sugar, White Wine Vinegar, Onion, Dried Onions, Modified Maize Starch, Brown Mustard Seeds, White Wine Vinegar, Brown Mustard Flour, Lemon Juice Concentrate, Garlic Purée, Dried Garlic, Salt, Ground Turmeric, Wheat Flour, Sea Salt, Yellow Mustard Flour, Dill, Ground Cinnamon, Acid (Citric Acid), Dried Pimento, Natural Dill Flavouring. Contains Cereals Containing Gluten, Mustard, Sulphites, Wheat.'
        },
        {
            'id': '0ziVkU276PHf28Jb69rS',
            'name': 'Chargrilled Wraps',
            'brand': 'Mission',
            'serving_size_g': 61.0,
            'ingredients': 'Fortified Wheat Flour, Water, Rapeseed Oil, Humectant (Glycerol), Acid (Malic Acid), Sugar, Emulsifier (Mono- and Diglycerides of Fatty Acids), Raising Agent (Sodium Carbonates), Salt, Preservatives (Potassium Sorbate, Calcium Propionate). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '10RpzOxWfFW1HEUGMy3N',
            'name': '2 Garlic Baguettes',
            'brand': 'Carlos',
            'serving_size_g': 50.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Wheat Gluten, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Garlic Purée (2.5%), Palm Oil, Salt, Yeast, Parsley, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Polyglycerol Polyricinoleate), Colour (Carotenes), Preservative (Potassium Sorbate), Stabiliser (Sodium Alginate), Concentrated Lemon Juice, Vitamin A, Vitamin D, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat. May Contain Milk.'
        },
        {
            'id': '0tf1vqppe31I16sX7yAK',
            'name': 'Strawberry Flavour Jelly',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose-Fructose Syrup, Sugar, Water, Pork Gelatine, Acids (Citric Acid, Acetic Acid), Acidity Regulator (Sodium Citrates), Flavouring, Colours (Carmine, Curcumin Extract).'
        },
        {
            'id': '12UOGL1XAo1atZxRoznd',
            'name': 'Peppered Salami',
            'brand': 'Dulano',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Black Peppercorns (3%), Salt, Pork Gelatine, Glucose Syrup, Spices, Garlic, Antioxidant (Sodium Ascorbate), Acidity Regulator (Sodium Acetate), Acid (Acetic Acid), Preservative (Sodium Nitrite). Made with 127g of Pork per 100g of Finished Product. May Contain Mustard.'
        },
        {
            'id': '12eDvREawzeahW0LrFB3',
            'name': 'Smokin\' BBQ Chicken & Bacon Classic Crust',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, BBQ Chicken (9%) (Chicken, Water, Tomato Paste, Sugar, Glucose Syrup, Spirit Vinegar, Cane Molasses, Salt, Cornflour, Caramelised Sugar, Smoked Water, Onion Powder, Allspice, Preservative (Potassium Sorbate), Garlic Purée, Oregano, Clove), Mozzarella Cheese (Cows\' Milk), Cheddar Cheese (Cows\' Milk), Tomato Purée, Red Onion, Smoked Bacon (3%) (Pork Belly, Salt, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Green Pepper, Sugar, Tomato, Rapeseed Oil, Tomato Paste, Red Pepper, Glucose Syrup, Spirit Vinegar, Semolina (Wheat), Salt, Yeast, Cane Molasses, Cornflour, Caramelised Sugar, Maize Starch, Wheat Flour, Smoked Water, Onion Powder, Allspice, Wheat Gluten, Preservative (Potassium Sorbate), Garlic Purée, Garlic Powder, Oregano, Clove, Black Pepper, Basil. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '14P2RmYPzOxHCVdwgRMq',
            'name': 'Goodlife Mushroom & Spinach Kiev',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mushroom (16%), Garlic Cheese Sauce (14%) (Mature Cheddar Cheese (Milk), Soft Cheese (Milk), Water, Cream Cheese (Milk), Unsalted Butter (Milk), Garlic Powder, Parsley, Salt, Corn Flour), Multiseed Breader (13%) (Crumb (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast, Salt), Maize Flour, Linseed, Millet, Sunflower Seed, Poppy Seed, Malted Rye Flake, Malted Barley, Toasted Wheat Grains), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cooked Brown Rice, Onion, Spinach (8%), Rapeseed Oil, Dried Potato, Tapioca Starch, Egg White Powder, Breadcrumb (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Salt, Yeast), Garlic Powder, Onion Powder, Yeast Extract, Salt, Thyme. Contains Barley, Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': '15LtwYprQHvVvISpwLBt',
            'name': 'French Salad Dressing',
            'brand': 'Deluxe Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil (35%), Water, Cider Vinegar (11%), Sugar, Dijon Mustard (8%) (Water, Mustard Seeds, Spirit Vinegar, Salt), White Wine Vinegar, Wholegrain Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Cornflour, Concentrated Lemon Juice, Garlic Purée, Salt, Parsley, Chives, Cracked Black Pepper, Preservative (Potassium Sorbate). Contains Mustard.'
        },
        {
            'id': '160Jd24RjXAG3FeZQcO7',
            'name': 'Extremely Cheesy Combo Mix',
            'brand': 'M&S',
            'serving_size_g': 30.0,
            'ingredients': 'Dried Potatoes (35%), Sunflower Oil, Potato Starch, Corn Grits (13%), Salt, Dried Whey (Milk), Dried Cheese (Milk) (2%), Lactose (Milk), Dried Cheddar Cheese (Milk) (1%), Dried Yeast Extract, Sugar, Dried Cream (Milk), Dried Skimmed Milk, Colour (Paprika Extract, E100). Contains Milk.'
        },
        {
            'id': '18H7JtiUpFgqfYhwnOSE',
            'name': 'French Stick',
            'brand': 'Co-op',
            'serving_size_g': 90.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Salt, Yeast, Wheat Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '18JPfijr8ClDFnYA9mL7',
            'name': 'Belgian Dark Chocolate',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Sunflower Lecithin). Dark Chocolate Contains Cocoa Solids 54% Minimum. May Contain Milk, Nuts.'
        },
        {
            'id': '19GYLmF1JeilVt44dwZQ',
            'name': 'Mature Cheddar Coleslaw',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Mayonnaise (38%) (Rapeseed Oil, Water, Spirit Vinegar, Pasteurised Liquid Egg Yolk, Sugar, Salt, Mustard Powder, Stabiliser (Xanthan Gum)), Cabbage (29%), Carrot (14%), Barber\'s Mature Cheddar Cheese (Milk) (8%), Coloured Cheddar Cheese (7%) (Cheese (Milk), Colour (Carotenes)), Onion (3%), Chives. Contains Eggs, Milk, Mustard.'
        },
        {
            'id': '1AvwYRhToQNbUs3swkWF',
            'name': 'The Cheese And Spring Onion Sandwich',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Malted Bread (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flour, Wheat Gluten, Barley Malt Flour, Salt, Wheat Flakes, Yeast, Carrier (E516, Wheat Flour, Potato Starch), Soya Flour, Preservative (E282), Sugar, Emulsifier (E472e), Buckwheat, Flour Treatment Agent (E300), Processing Aid (Enzymes, Sunflower Oil), Folic Acid), Grated Mozzarella and Cheddar Cheese (19%) (Mozzarella Cheese (Milk), Cheddar Cheese (Milk), Anti-Caking Agent (Potato Starch)), Mayonnaise (Water, Rapeseed Oil, Spirit Vinegar, Stabiliser (E1414), Sugar, Salt, Free Range Pasteurised Egg, Stabiliser (E415), Preservative (E202)), Red Leicester Cheese (5%) (Milk), Spring Onions (3%). Contains Barley, Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': '1D9dhoMPFATY8Xx8zIFQ',
            'name': 'Hollandaise Sauce',
            'brand': 'Sainsbury\'s Taste The Difference',
            'serving_size_g': 15.0,
            'ingredients': 'Rapeseed Oil, Water, Salted Butter (Cows\' Milk) (5%), White Wine Vinegar, Glucose Fructose Syrup, Dried Egg Yolk, Sugar, Salt, Skimmed Cows\' Milk Powder, Stabiliser (Xanthan Gum), Acidity Regulator (Citric Acid), Preservative (Potassium Sorbate), Cornflour, Colour (Lutein), Lemon Oil. Contains Eggs, Milk.'
        },
        {
            'id': '1DtgOz3VXgIMOAcDgxFD',
            'name': 'Cumberland Chipolatas',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (90%), Water, Fat, Spices, Salt, Parsley, Stabilizer (Triphosphate), Preservative (Sodium Metabisulphite), Antioxidants (Ascorbate, Sodium Citrates). Sausage Filled in a Natural Sheep or Beef Collagen Casing. Contains Sulphites.'
        },
        {
            'id': '1E2Y34K1Wel6v5nQWpH7',
            'name': 'Udon Noodle Bowl Spicy Kung Pao',
            'brand': 'Sun Hee',
            'serving_size_g': 240.0,
            'ingredients': 'Udon Noodles (78%) (Water, Wheat Flour, Thickener (Acetylated Starch), Salt, Wheat Gluten, Acidity Regulator (Lactic Acid), Thickener (Sodium Alginate)), Kung Pao Sauce (20%) (Sugar, Soya Bean Paste (Water, Wheat, Soya Bean, Salt), Soya Sauce (Water, Soya Bean, Salt), Soya Bean Oil, Water, Chilli Sauce (Water, Chilli, Salt, Rice Vinegar), Ginger, Peanut Butter, Garlic, Sesame Paste, Salt, Sesame Oil, Thickener (Acetylated Distarch Phosphate), Acidity Regulator (Glucono-Delta-Lactone), Colour (Ammonia Caramel), Yeast Extract, Spices, Acidity Regulator (Citric Acid), Thickener (Xanthan Gum)), Dehydrated Vegetables (1%) (Carrot, Green Onion), Roasted Sesame Seeds (1%). Contains Cereals Containing Gluten, Peanuts, Sesame, Soybeans, Wheat.'
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

    total_cleaned = 591 + updates_made

    print(f"✨ BATCH 48 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Breaking 600 milestone check
    if total_cleaned >= 600:
        print(f"\n🎉🎉🎉 600 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")

    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch48(db_path)
