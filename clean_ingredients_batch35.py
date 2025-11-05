#!/usr/bin/env python3
"""
Clean ingredients batch 35 - Charging Toward 400!
"""

import sqlite3
from datetime import datetime

def update_batch35(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 35 (Pushing to 400!)\\n")

    clean_data = [
        {
            'id': 'rr8RyEE7gbzOueP1TxyB',
            'name': 'Dry Roasted Peanuts',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (92%), Rice Flour, Salt, Stabiliser (Sorbitol), Potato Maltodextrin, Onion Powder, Gelling Agent (Acacia Gum), Herbs (Oregano, Thyme), Yeast Extract, Spices (Celery Seeds, Cinnamon, Turmeric), Colour (Paprika Extract), Yeast Powder. Contains Celery, Peanuts.'
        },
        {
            'id': 'M7oiIaec8LqI8qHRXivx',
            'name': 'Duck Breast',
            'brand': 'Gressingham',
            'serving_size_g': 100.0,
            'ingredients': 'Duck (59%), Water, Sugar, Red Wine Vinegar, Concentrated Orange Juice (1.7%), Salt, Soya Protein, Glucose Syrup, Cornflour, Orange Liqueur (1%), Flavouring, Orange Zest (0.7%), Stabiliser (E451), Potato Maltodextrin, Wheat, Caramelised Sugar Syrup, Cane Molasses, Soyabean, Yeast Extract, Chicken Fat, Chicken Stock, Rapeseed Oil. Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'tO3by3hfQsMxPpOhFyPL',
            'name': 'Hoisin No Duck Wrap',
            'brand': 'Plant Pioneers',
            'serving_size_g': 204.0,
            'ingredients': 'Tortilla Wrap (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Palm Oil, Raising Agents (Sodium Bicarbonate, Disodium Diphosphate), Rapeseed Oil, Sugar, Acidity Regulator (Malic Acid), Wheat Starch), Texturised Wheat Pieces (22%) (Water, Wheat Gluten, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Wheat Flour, Pea Fibre, Rapeseed Oil, Yeast Extract, Salt, Black Pepper, Coriander Powder, Aniseed, Fennel, Cinnamon Powder, Sugar), Hoisin Sauce (11%) (Water, Sugar, Brown Sugar, Tomato Paste, Cornflour, Salt, Rapeseed Oil, Black Eyed Beans, Soya Beans, Golden Sugar, Black Treacle (Molasses, Invert Sugar Syrup), Red Wine Vinegar, Red Chillies, Ginger Purée, Red Chilli Purée, Cinnamon, Star Anise, Wheat Flour, Rice Flour, Black Pepper, Fennel, Cloves, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Anise, Acidity Regulator (Acetic Acid)), Lettuce, Cucumber (6%), Spring Onion (4%), Water, Cornflour, Coriander, Salt. Contains Cereals Containing Gluten, Soybeans, Wheat. Not Suitable for Sesame Allergy.'
        },
        {
            'id': 'dGgOhSd8pTNo6QTKn3w6',
            'name': 'Cream Wafer Bar White Chocolate',
            'brand': 'Love Raw',
            'serving_size_g': 22.5,
            'ingredients': 'Hazelnut and Almond Filling (48%) (Sugar, Hazelnuts (20%), Almonds (15%), Rice Syrup, Cocoa Liquor, Sunflower Oil, Sunflower Lecithin), Sugar, Vegetable Fat (Coconut, Cocoa Butter), Dried Glucose Syrup, Emulsifier (Soya Lecithin, Sunflower Lecithin), Wheat Flour, Defatted Cocoa Powder, Corn Starch, Potato Starch, Wheat Fibre, Salt, Raising Agent (Sodium Bicarbonate), Sunflower Oil, Natural Vanilla Flavouring. Contains Cereals Containing Gluten, Nuts, Soybeans, Wheat.'
        },
        {
            'id': 'rXG8GcbtNcKTpRNdcRd8',
            'name': 'Organic Rye Sunflower Seed Bread',
            'brand': 'Biona',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Wholegrain Rye Meal, Water, Organic Sourdough (Organic Wholegrain Rye Meal, Water), Organic Sunflower Seeds (5%), Sea Salt.'
        },
        {
            'id': 'lDyEQ8ai1keq2v1COdL4',
            'name': 'Flora Natural Ingredients Lighter',
            'brand': 'Flora',
            'serving_size_g': 10.0,
            'ingredients': 'Water, Vegetable Oils (Rapeseed, Sunflower, Linseed), Coconut Fat, Salt (1.2%), Emulsifier (Mono- and Diglycerides of Fatty Acids), Vinegar, Natural Flavourings, Vitamin A.'
        },
        {
            'id': 'Sn0nAQuKNzaX6qZiuXER',
            'name': 'Strawberry Flavour High Protein Milkshake',
            'brand': 'Ufit',
            'serving_size_g': 500.0,
            'ingredients': 'Skimmed Milk, Water, Milk Protein, Inulin, Vitamin & Mineral Blend (Vitamin C, Vitamin E, Selenium, Vitamin D2), Stabilisers (Gellan Gum, Carrageenan), Natural Flavouring, Acidity Regulator (Sodium Citrate), Salt, Sweetener (Sucralose), Colours (Lycopene, Beta Carotene). Contains Milk.'
        },
        {
            'id': 'HH2y1MDNU5pyJV8fgW5G',
            'name': 'Simply Fruity Muesli',
            'brand': 'Dorset Cereals',
            'serving_size_g': 45.0,
            'ingredients': 'Dried Fruit, Sweetened Dried Papaya (9%) (Papaya, Sugar, Acidity Regulator (Citric Acid), Preservative (Sulphur Dioxide)), Sultanas (9%), Raisins (7%), Sweetened Dried Pineapple (3.5%) (Pineapple, Sugar, Acidity Regulator (Citric Acid), Preservative (Sulphur Dioxide)), Barley Flakes, Wholegrain Wheat Flakes, Wholegrain Oat Flakes, Wholegrain Toasted and Malted Wheat Flakes (Wheat, Barley Malt Extract). Contains Barley, Cereals Containing Gluten, Oats, Sulphites, Wheat.'
        },
        {
            'id': 'KVSwGXAyHcd09Gh943Am',
            'name': 'Orange Tangs',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 100.0,
            'ingredients': 'Orange Tangs (70%) (Sugar, Concentrated Orange Juice, Water, Glucose Syrup, Orange Peel, Acidity Regulators (Citric Acid, Sodium Citrate), Gelling Agent (Pectin), Flavouring), Chocolate (30%) (Cocoa Mass, Cocoa Butter, Sugar, Emulsifier (Soya Lecithin), Flavouring). Dark Chocolate Contains Minimum 70% Cocoa Solids. Contains Soybeans.'
        },
        {
            'id': 'T4rqCUv6hF2vp2yFGuIJ',
            'name': 'Pick Up! Choco & Milk',
            'brand': 'Bahlsen',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Sugar, Vegetable Fats (Palm, Coconut), Cocoa Butter, Cocoa Mass, Whole Milk Powder (4.6%), Glucose Syrup, Skimmed Milk Powder (1.1%), Whey Products (Milk), Clarified Butter, Ground Hazelnuts, Salt, Emulsifier (Lecithins (Soya)), Flavourings, Raising Agents (Sodium Carbonates, Diphosphates), Starch (Wheat), Acid (Citric Acid), Egg Yolk Powder. Contains Cereals Containing Gluten, Eggs, Milk, Nuts, Soybeans, Wheat.'
        },
        {
            'id': 'x2CAjkhR6DO7DoOiHDir',
            'name': 'Juiced Mango Loco Energy Drink',
            'brand': 'Monster',
            'serving_size_g': 500.0,
            'ingredients': 'Carbonated Water, Fruit Juice from Concentrates (9%) (White Grape, Mango, Guava, Apple, Pineapple, Passion Fruit, Apricot, Peach, Orange, Lemon), Sucrose, Glucose Syrup, Acids (Citric Acid, Malic Acid), Taurine (0.4%), Flavourings, Acidity Regulators (Potassium Citrates, Sodium Citrates), Preservatives (Potassium Sorbate, Sodium Benzoate), Caffeine (0.03%), Colour (Carotenes), Sweetener (Sucralose), Vitamins (Niacin, Vitamin B6, Riboflavin, Vitamin B12), Stabilisers (Xanthan Gum, Sodium Alginate, Gum Arabic), L-Carnitine L-Tartrate (0.004%), Inositol, Fruit and Vegetable Concentrates (Grape, Carrot, Sweet Potato). Contains Taurine, Caffeine.'
        },
        {
            'id': '0sVEvL82hDusXSOugVfi',
            'name': 'Rhubarb & Vanilla Dessert Sauce',
            'brand': 'Asda Extra Special',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Free Range Egg (18%), Rhubarb Juice (7%), Salted Butter (7%) (Butter (Milk), Salt), Water, Acidity Regulator (Citric Acid), Flavouring, Vanilla Extract, Gelling Agent (Agar), Carrot Concentrate. Contains Eggs, Milk.'
        },
        {
            'id': 'Te4RhnBi1NZmtzkVLLpc',
            'name': 'Bright And Bold Mix',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Dextrose, Starch (Wheat, Rice), Glucose Syrup, Rice Starch, Maize Starch, Vegetable Oils (Coconut, Rapeseed), Colouring Foods (Concentrates of Sweet Potato, Safflower, Lemon, Blackcurrants), Colours (Curcumin, Riboflavin, Patent Blue V), Glazing Agents (Shellac, Carnauba Wax, Beeswax White and Yellow), Maltodextrin, Thickener (Gum Arabic), Anti-Caking Agent (Talc). Contains Cereals Containing Gluten, Wheat. May Contain Peanuts, Milk, Almonds.'
        },
        {
            'id': 'kTfJYe23JoJmajMscWj5',
            'name': 'Greek Lemon Yogurt',
            'brand': 'Milbona',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (Milk), Sugar, Water, Lemon Juice from Concentrate (3%), Maize Starch, Flavouring, Stabiliser (Pectins), Colour (Curcumin). Contains Milk.'
        },
        {
            'id': 'hlSyOsYXuslm0hde7SrT',
            'name': 'Hot Cross Buns',
            'brand': "Sainsbury's",
            'serving_size_g': 65.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Moistened Mixed Fruit (22%) (Sultanas, Raisins, Water), Water, Yeast, Rapeseed Oil, Sugar, Wheat Gluten, Orange and Lemon Peel (2%), Dextrose, Maize Starch, Emulsifier (Mono- and Diglycerides of Fatty Acids), Salt, Palm Fat, Ground Mixed Spice (Cinnamon, Coriander, Clove, Nutmeg), Flavouring, Flour Treatment Agent (Ascorbic Acid), Palm Oil. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'HD17Ea0eZoCHIbs9u7d4',
            'name': 'Pork Sausage Slices',
            'brand': 'Paw Patrol',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (66%), Water, Potato Starch, Salt, Dextrose, Salt Replacers (Potassium Chloride, Sodium Gluconate), Spices, Antioxidant (Ascorbic Acid), Stabiliser (Diphosphates), Preservatives (Sodium Diacetate, Sodium Nitrite), Yeast Extract. Contains Pork.'
        },
        {
            'id': 'ZJFu1ko98XLLbheh6ZFq',
            'name': 'Hazelnut Truffles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Shell (75%) (Cocoa (32%) (Cocoa Butter, Cocoa Mass), Sugar, Chicory Root Extract, Rice Starch, Coconut Oil, Rice Flour, Emulsifier (Sunflower Lecithin)), Hazelnut Centre (25%) (Hazelnuts (50%), Sugar). Contains Nuts. May Contain Other Nuts, Dairy, Cereals Containing Gluten, Soybeans.'
        },
        {
            'id': 'sC83tV6Off8rLfuRjDK0',
            'name': 'Seabrook Cheese And Onion Crisps',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Sunflower Oil (30%), Onion Powder, Lactose (Milk), Salt, Cheese Powder (Milk), Yeast Extract, Sea Salt, Garlic Powder, Flavouring, Acid (Lactic Acid). Contains Milk.'
        },
        {
            'id': 'WjygtsMaO5C1jROD09CH',
            'name': 'Milkybar Cookies And Cream',
            'brand': 'Milkybar',
            'serving_size_g': 18.0,
            'ingredients': 'Milk Powders (Whole and Skimmed), Sugar, Cocoa Butter, Crumbled Cookie Pieces (13%) (Wheat Flour (Contains Calcium, Iron, Thiamin, Niacin), Sugar, Vegetable Fats (Palm, Rapeseed), Fat-Reduced Cocoa Powder, Raising Agent (Sodium Bicarbonate), Salt), Vegetable Fats (Mango Kernel, Palm, Sal, Shea), Emulsifier (Lecithins), Natural Flavouring. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'QGQ5cQ8TvuToOxtDOP4n',
            'name': 'KitKat',
            'brand': 'KitKat',
            'serving_size_g': 11.0,
            'ingredients': 'Sugar, Vegetable Fats (Palm, Rapeseed, Sunflower), Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Rice Flour, Lactose (from Milk), Fat-Reduced Cocoa Powder, Whey Powder (from Milk), Butterfat (Milk), Emulsifier (Lecithins), Potato Starch, Maize Starch, Raising Agent (Sodium Bicarbonate), Salt, Whey Protein Concentrate (Milk), Natural Flavourings, Vegetable Oil. Contains Cereals Containing Gluten, Milk. May Contain Tree Nuts.'
        },
        {
            'id': 'u9a9J2Bypf7dYMUWXQxE',
            'name': 'Gastro Greens',
            'brand': 'M&S Gastropub',
            'serving_size_g': 105.0,
            'ingredients': 'Peas (61%), Spinach (14%), Spring Greens (10%), Samphire (8%), Lemon, Mint and Garlic Dressing (7%) (Vegetable Oil (Sunflower/Rapeseed), Mint Infused Vegetable Oil (Sunflower/Rapeseed), Lemon Juice, Dried Mustard, Vinegar, Mint, Parsley, Salt, Garlic, Cracked Black Pepper, Mustard Husk, Ground Pimentos, Rapeseed Oil, Turmeric). Contains Mustard.'
        },
        {
            'id': 'ZEE5bxaQi3zPCRuOGsBt',
            'name': 'Smoked Back Bacon',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (87%), Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate). Contains Pork.'
        },
        {
            'id': 'GgV8GLZGEWoWiLTJyTWM',
            'name': 'Squeaky Bean Crispy Bacon',
            'brand': 'Squeaky Bean',
            'serving_size_g': 50.0,
            'ingredients': 'Water, Wheat Gluten (16%), Vegetable Oil (Rapeseed, Sunflower, Shea), Gelling Agents (Methylcellulose, Carrageenan, Gum Arabic), Salt, Tapioca Starch, Wheat Flour, Natural Flavouring, Yeast Extract, Maltodextrin, Smoked Water, Natural Concentrate (Radish, Blackcurrant, Apple), Sugar, Pea Fibre, Acidity Regulators (Disodium Diphosphate, Citric Acid), Coconut Oil, Emulsifier (Triacetin), Fat Reduced Cocoa Powder. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '6B5Mbeyb9N6SAUicUbr1',
            'name': 'New York Deli Dinky Dunkers',
            'brand': 'M&S',
            'serving_size_g': 26.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Garlic and Herb Dip (23%) (Rapeseed Oil, Water, Pasteurised Egg Yolk, Vinegar, Cornflour, Sugar, Garlic Purée, Salt, Lactic Acid, Dried Skimmed Milk, Concentrated Lemon Juice, Parsley), Extra Mature Cheddar Cheese (Milk) (20%), Palm Oil, Onions, Mozzarella Cheese (Milk) (4.5%), Full Fat Soft Cheese (Milk) (4%), Pasteurised Egg, Butter (Milk) (2.5%), Tomato Paste, Herbs (Basil, Parsley, Oregano), Potato Starch, Rapeseed Oil, Tomatoes, Cornflour, Red Onions, Salt, Sugar, Tomato Powder, Concentrated Lemon Juice, White Wine Vinegar, Garlic Purée, Stabiliser (E464), Roasted Garlic, Ground Black Pepper, Coarse Black Pepper, Green Jalapeño Peppers, Yeast, Ground White Pepper. Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': 'sKUe0HO3FX0KfLgTF15F',
            'name': "Nik Naks Nice 'N' Spicy",
            'brand': 'KP Snacks',
            'serving_size_g': 45.0,
            'ingredients': 'Maize, Sunflower Oil (36%), Nice N Spicy Flavour (Sugar, Yeast Extract, Natural Flavourings (Contains Barley Malt Vinegar, Barley Malt Extract, Soya Sauce, Wheat Flour), Salt, Dried Onion, Acid (Citric Acid), Curry Powder (Spices, Rice Flour, Salt), Acid (Malic Acid), Spice, Colour (Paprika Extract), Spice Extracts, Garlic Extract). Contains Barley, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'YJyguRls0WkJ18465ByR',
            'name': 'Drumstick Squashies',
            'brand': 'Swizzels',
            'serving_size_g': 3.333,
            'ingredients': 'Glucose Syrup, Sugar, Gelling Agent (Gelatine), Modified Starch, Acidity Regulators (Citric Acid, Trisodium Citrate), Flavourings, Apple Pulp, Glazing Agent (Carnauba Wax), Colour (Anthocyanin).'
        },
        {
            'id': 'ZD4QJkqJRK5rHYmYEaFs',
            'name': 'Burger Bites',
            'brand': 'Happy Shopper',
            'serving_size_g': 23.0,
            'ingredients': 'Maize (52%), High Oleic Sunflower Oil, Beef Flavouring (Rice Flour, Yeast Extract Powder, Salt, Paprika, Yeast Powder, Onion Powder, Acid (Citric Acid), Natural Flavouring), Dried Potato, Emulsifier (Mono- and Di-Glycerides of Fatty Acids).'
        },
        {
            'id': 'Aey8sBPNh3XbgYLUkRHY',
            'name': 'Prawn Cocktail Flavour Crisps',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (62%), Vegetable Oils (Rapeseed Oil, Sunflower Oil), Prawn Cocktail Flavour (Sugar, Acidity Regulator (Sodium Diacetate), Salt, Fructose, Dextrose Syrup Powder, Yeast Extract Powder, Acid (Citric Acid), Black Pepper Extract, Onion Powder, Tomato Powder, Garlic Powder, Flavouring, Colour (Paprika Extract)).'
        },
        {
            'id': 'MUjv74fk3slCAxhPtvNG',
            'name': 'Smoothie To The Rescue Defend',
            'brand': 'M&S',
            'serving_size_g': 350.0,
            'ingredients': 'Water, Banana Purée (17%), Orange Juice, Apple Purée, Apple Juice, Mango Purée (7%), Coconut Milk (5%) (Coconut Extract, Water), Oat Drink (5%) (Oats, Water), Acerola Purée, Chicory Fibre, Ginger Juice, Brown Linseed, Stabiliser (Pectin (from Fruit)), Concentrated Spirulina, Safflower Concentrate, Citrus Fibre, Matcha Green Tea, Vitamin C, Vitamin B12, Folic Acid, Vitamin D. Contains Cereals Containing Gluten, Oats. Not Suitable for Wheat Allergy or Coeliacs.'
        },
        {
            'id': 'lQKaj3fCegnZmYhlPiCW',
            'name': 'Wispa Gold',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Glucose Syrup, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Glucose-Fructose Syrup, Whey Powder (from Milk), Emulsifiers (E442, E471), Salt, Sodium Carbonates, Flavourings. Milk Chocolate Contains Milk Solids 14% Minimum. Contains Vegetable Fats in Addition to Cocoa Butter. Contains Milk. May Contain Nuts.'
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
            print(f"   Serving: {product['serving_size_g']}g\\n")
            updates_made += 1

    conn.commit()
    conn.close()

    total_cleaned = 356 + updates_made

    print(f"✨ BATCH 35 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    remaining_to_400 = 400 - total_cleaned
    if remaining_to_400 > 0:
        print(f"🎯 Next milestone: {remaining_to_400} products until 400!\\n")
    else:
        print(f"\\n🎉🎉🎉 400 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {450 - total_cleaned} products until 450!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch35(db_path)
