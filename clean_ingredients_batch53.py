#!/usr/bin/env python3
"""
Clean ingredients batch 53 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch53(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 53\n")

    clean_data = [
        {
            'id': '3vvYYv1DDAY7DqS5WFl0',
            'name': 'Fruit Spiral Lollies',
            'brand': 'Asda',
            'serving_size_g': 70.0,
            'ingredients': 'Water, Fruit Juices from Concentrates (20%) (Orange, Blackcurrant, Raspberry, Apple, Lemon), Sugar, Glucose Syrup, Dextrose, Citric Acid, Flavourings, Stabiliser (Guar Gum), Beetroot Concentrate, Colour (Carotenes), Ascorbic Acid, Spirulina Extract, Safflower Extract.'
        },
        {
            'id': '3wstDeXXYOvbBGYK5twI',
            'name': 'Butter Roast Turkey',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Turkey (96%), Unsalted Butter (Milk) (1%), Salt, Dextrose, Stabiliser (Triphosphates), Water. Contains Milk.'
        },
        {
            'id': '3xdU8en49KUboIVbFbhh',
            'name': 'Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g of Ketchup), Sugar, Spirit Vinegar, Salt, Flavourings (contains Celery), Cayenne Pepper, Garlic Powder. Contains Celery.'
        },
        {
            'id': '3s9F7epdvrZwoWj8L0m6',
            'name': 'Free From Hot Cross Bun',
            'brand': 'Generic',
            'serving_size_g': 65.0,
            'ingredients': 'Water, Tapioca Starch, Rice Flour, Vegetable Oils (Rapeseed Oil, Sunflower Oil), Currants (6%), Raisins (6%), Sultanas (6%), Potato Flakes, Sugar, Psyllium Husk Powder, Yeast, Mixed Peel (2%) (Glucose-Fructose Syrup, Orange Peel, Lemon Peel, Salt, Acidity Regulator (Citric Acid)), Humectant (Glycerol), Stabiliser (Hydroxypropyl Methyl Cellulose), Spices, Salt, Potato Starch, Bamboo Fibre.'
        },
        {
            'id': '3yZ15VsjYvB5zUbkh6gV',
            'name': 'Tomato & Mascarpone Microwave Pasta',
            'brand': 'Morrisons',
            'serving_size_g': 200.0,
            'ingredients': 'Cooked Fusilli Pasta (57%) (Water, Durum Wheat Semolina, Dried Egg), Passata (9%), Mascarpone Cheese (Milk) (8%), Tomato Paste (6%), Onion, Single Cream (Milk), Tomato (3%), Sunflower Oil, Tomato Juice, Sugar, Yeast Extract Powder, Onion Powder, Basil, Garlic Purée, Colours (Paprika Extract, Curcumin), Salt, Yeast Extract, Stabiliser (Guar Gum), Garlic Powder, Dextrose, Potato Starch, Onion Extract, Herb Extracts (Marjoram, Thyme, Sage), Carrot Powder, Acidity Regulator (Citric Acid), Pepper Extract, Parsley. Contains Eggs, Milk, Wheat.'
        },
        {
            'id': '3ymSc6J2HbH5CP6aDX4d',
            'name': 'Korma',
            'brand': 'Deluxe',
            'serving_size_g': 180.0,
            'ingredients': 'Sauce (97%) (Water, Coconut Cream (7%) (Coconut Extract, Water), Sugar, Onion (12%), Rapeseed Oil, Tomato (4%), Single Cream (Milk) (3%), Yogurt (Milk), Modified Maize Starch, Desiccated Coconut (2%), Ginger Purée, Garlic Purée, Acidity Regulators (Lactic Acid, Citric Acid), Coriander Powder, Cumin Powder, Turmeric Powder, Fenugreek Powder, Salt, Cinnamon Powder, Green Cardamom Powder), Spice Cap (3%) (Salt, Onion Powder, Rice Flour, Potato Starch, Green Cardamom, Sugar, Natural Flavouring, Bay Leaf, Rapeseed Oil, Clove, White Pepper, Mace, Cayenne Pepper, Colour (Paprika Extract)). Contains Milk. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': '3zLkV2dLelBmWdPw3Blg',
            'name': 'Seeded Granola Protein',
            'brand': 'Brooklea',
            'serving_size_g': 197.0,
            'ingredients': 'Skimmed Milk Soft Cheese (45%), Fat Free Yogurt (36%) (Milk), Strawberry Preparation (Strawberries, Starch, Flavouring, Carrot Concentrate, Sweeteners (Acesulfame K, Sucralose), Thickener (Locust Bean Gum)), Granola (11%) (Wholegrain Oat Flakes, Pumpkin Seeds, Barley Flakes, Sunflower Seeds, Sweetener (Maltitols), Sunflower Oil, Corn Flakes, Dried Dates, Barley Flour, Maize Flour, Sea Salt, Flavouring, Cinnamon). Contains Barley, Cereals Containing Gluten, Milk, Oats. May Contain Nuts, Peanuts, Sesame, Soybeans.'
        },
        {
            'id': '3zX8jSl3ZO08cN8JjDHT',
            'name': 'Premium Lean Ham',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (82%), Water, Salt, Stabiliser (Triphosphates), Gelling Agent (Carrageenan), Antioxidant (Sodium Ascorbate), Pork Gelatine, Preservative (Sodium Nitrite).'
        },
        {
            'id': '40Yuo1EgGoJu89I6vitc',
            'name': 'Morrisons F F Syrup Sponge Pudding',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Golden Syrup (30%) (Invert Sugar Syrup), Water, Cornflour, Sugar, Vegetable Oils (Palm, Rapeseed), Egg, Rice Flour, Humectant (Glycerol), Water, Tapioca Starch, Potato Starch, Raising Agents (Diphosphates, Potassium Carbonates, Calcium Phosphates, Sodium Carbonates, Calcium Carbonates), Maize Flour, Flavouring, Thickener (Xanthan Gum), Preservative (Potassium Sorbate), Salt. Contains Eggs. May Contain Nuts.'
        },
        {
            'id': '41MdVWSEJXBEI5oqAMFO',
            'name': '5 Sunshine Veggies',
            'brand': 'Organix',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato (25%), Carrot (16%), Red Lentils (13%), Sweet Potato (10%), Whole Milk Yoghurt (9%), Potato (8.36%), Courgette (7%), Onion (6%), Red Pepper (3%), Extra Virgin Olive Oil (2.3%), Garlic (0.13%), Coriander (0.13%), Cumin (0.07%), White Pepper (0.01%). Contains Milk. May Contain Cereals Containing Gluten.'
        },
        {
            'id': '42J7YZWGGrWBzSpZNliT',
            'name': 'White Sourdough Baguette',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Sourdough (Wheat Flour, Water), Dehydrated Devitalized Wheat Sourdough (Water, Wheat Bran, Wheat Flour, Wheat Sourdough), Salt, Yeast, Wheat Protein, Malted Wheat Flour, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '42q4ZHRfnqLHFa0mGkui',
            'name': 'Vegetable Sushi',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Sushi Rice (Water, Rice, Sugar, Rice Vinegar, Salt), Vegetable Oil (Sunflower Oil and/or Rapeseed Oil), Rice Wine, Full Fat Soft Cheese (Milk) (5%), Red Peppers (4%), Sesame Seeds, Soy Sauce Bottle (3%) (Water, Soya Beans, Wheat, Salt, Alcohol), Edamame (Soya Beans) (3%), Green Peppers (3%), Red Cabbage (2%), Carrots, Nori Seaweed, Rapeseed Oil, Salt, Paprika Flakes, Sushi Vinegar (Sugar, Rice Vinegar, Salt, Water, Rice Wine), Ginger Purée (Sugar, Water, Rice Wine Vinegar, Spirit Vinegar, Horseradish, Ginger, Rice Vinegar, Mustard Powder, Red Chilli Purée, Cornflour, Garlic Purée, White Wine Vinegar, Wasabi Powder, Garlic Powder, Citrus Fibre, Red Pepper Granules). Contains Cereals Containing Gluten, Milk, Mustard, Sesame, Soybeans, Wheat.'
        },
        {
            'id': '44KE1ieLWwV7uMZGKlxq',
            'name': 'Salmon Fillets',
            'brand': 'Tesco',
            'serving_size_g': 94.0,
            'ingredients': 'Salmon (Fish). Contains Fish.'
        },
        {
            'id': '45IC4qh7CKELNJ4Tt8WV',
            'name': 'Chicken And Bacon Sandwich',
            'brand': 'Urbaneat',
            'serving_size_g': 100.0,
            'ingredients': 'Malted Bread (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes, Wheat Bran, Wheat Gluten, Malted Barley Flour, Yeast, Salt, Emulsifiers (Mono- and Di-Glycerides of Fatty Acids, Mono- and Di-Acetyl Tartaric Acid Esters of Mono- and Di-Glycerides of Fatty Acids), Rapeseed Oil, Spirit Vinegar, Malted Wheat Flour, Flour Treatment Agent (Ascorbic Acid), Palm Oil), Chicken Breast (25%) (Chicken Breast, Salt), Mayonnaise (Water, Rapeseed Oil, Free Range Pasteurised Egg, Cornflour, Spirit Vinegar, Salt, Yellow Mustard Flour), Sweetcure Smoke Flavoured Bacon (9%) (Pork Belly, Water, Sugar, Salt, Smoke Flavouring, Preservative (Sodium Nitrite)), Cornflour. Contains Barley, Cereals Containing Gluten, Eggs, Mustard, Wheat.'
        },
        {
            'id': '45lvZ6nuNBnIbSV1tX8X',
            'name': 'Raisins And Cranberries - Uvetta E Mirtilli',
            'brand': 'Alesto Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Flame Raisins (34%) (Raisins, Sunflower Oil), Golden Raisins (33%) (Raisins, Sunflower Oil, Preservative (Sulphur Dioxide)), Dried Sweetened Cranberries (33%) (Cranberries, Pineapple Juice from Concentrate, Sunflower Oil). Contains Sulphites. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': '45n026kjNSo87H3xr0ml',
            'name': 'Snack High Protein 121 Calories & Per Serving Use',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Free Range Hard Boiled Egg. Contains Eggs.'
        },
        {
            'id': '464Rn5CS06tUu0usYZ4O',
            'name': 'Cheese And Onion Potato Crisps',
            'brand': 'Tayto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato, Vegetable Oil (Sunflower, Rapeseed in Varying Proportions), Cheese & Onion Flavour (Onion Powder, Yeast Powder, Natural Flavourings, Salt, Dextrose, Starch, Cheese Powder (Contains Whey Powder) (Milk), Sugar, Yeast Extract, Colours (Paprika Extract, Curcumin), Antioxidant (Rosemary Extract)). Contains Milk. May Contain Barley, Soybeans, Wheat.'
        },
        {
            'id': '47LyTu6hgKn3lG9M1CBU',
            'name': 'Cinnamon Buns',
            'brand': 'The Bakery At Asda',
            'serving_size_g': 90.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Sugar, Cinnamon Filling (12%) (Water, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Soft Dark Brown Sugar, Soft Brown Sugar, Cane Molasses, Egg, Cinnamon (5%), Wheat Starch, Whole Milk Powder, Palm Oil, Rapeseed Oil, Cassia, Egg Albumen, Flavourings, Salt, Whey Powder (Milk)), Water, Margarine (Palm Oil, Rapeseed Oil, Water, Emulsifier (Mono- and Diglycerides of Fatty Acids), Salt, Acidity Regulator (Citric Acid), Flavourings, Vitamin A), Full Fat Soft Cheese (Milk) (3%), Salt, Yeast, Dried Glucose Syrup, Vegetable Oils and Fat (Palm Fat, Rapeseed Oil, Palm Oil), Invert Sugar Syrup, Tapioca Starch, Whole Milk Powder, Humectant (Glycerol), Emulsifiers (Mono- and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Cinnamon, Maize Starch, Salt, Lemon Juice, Gelling Agent (Agar), Wheat Flour, Flavourings, Acidity Regulator (Acetic Acid), Colours (Annatto Bixin, Curcumin), Antioxidant (Ascorbic Acid). Contains Barley, Cereals Containing Gluten, Eggs, Milk, Oats, Rye, Spelt, Wheat. May Contain Kamut.'
        },
        {
            'id': '47h92DqcJ6nua3EIYalk',
            'name': 'Super Nut, Fruit & Seed Flapjack',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Rolled Oats, Unsalted Butter (Milk) (15%), Golden Syrup (Invert Sugar Syrup), Sweetened Condensed Milk (Skimmed Milk, Sugar), Demerara Sugar, Chopped Pecan Nuts (5%), Chopped Almonds (5%), Sweetened Dried Cranberries (5%) (Sugar, Cranberries, Humectant (Glycerol), Sunflower Oil), Sweetened Dried Blueberries (3%) (Dried Blueberries, Sugar, Sunflower Oil), Brown Linseed, Sunflower Seeds, Wildflower Honey, Poppy Seeds, Potato Starch. Contains Milk, Nuts, Oats. Not Suitable for Those with a Nut, Peanut, and Wheat Allergy and Coeliacs.'
        },
        {
            'id': '47sSvtb8znxe1hFiXl7e',
            'name': 'Lemon Madeira Sponge Cake',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (Contains Calcium, Iron, Niacin, Thiamin), Egg, Rapeseed Oil, Emulsifier (Vegetable Glycerine (E422)), Modified Maize Starch, Whey Powder (Milk), Raising Agents (E500ii, E450 (Wheat)), Emulsifier Containing Glucose Syrup Solids, Emulsifiers (E472b, E471, E477), Skimmed Milk Powder, Stabiliser (E450), Salt, Preservative (Potassium Sorbate (E202)), Natural Lemon Flavouring, Natural Flavouring. Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': '49k1tNp0LPWaTQhWEO4K',
            'name': 'Hazel Nutter',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (with Calcium Carbonate, Iron, Niacin and Thiamin), Sugar, Sustainable Palm Oil, Chocolate Chips (12%) (Sugar, Cocoa Mass, Vegetable Fats (Sustainable Palm, Sal, Shea), Emulsifiers (Soya Lecithin, E442, E476), Cocoa Butter, Flavourings), Roasted Nibbed Hazelnuts (4%), Fat Reduced Cocoa Powder, Partially Inverted Sugar Syrup, Whey or Whey Derivatives (Milk), Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavourings. Contains Cereals Containing Gluten, Milk, Nuts, Soybeans, Wheat. May Contain Other Nuts.'
        },
        {
            'id': '4AO3OcWgZY4G1yHEUjSH',
            'name': 'Triple Chocolate Cookies',
            'brand': 'Belmont',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Dark Chocolate Chunks (16%) (Sugar, Cocoa Mass, Vegetable Fats (Mango Fat, Palm Fat, Shea Fat, Sal Fat), Cocoa Butter, Emulsifier (Lecithins (Soya))), Palm Oil, White Chocolate Chunks (11%) (Sugar, Cocoa Butter, Whole Milk Powder, Whey Powder (Milk), Lactose (Milk), Butter Oil (Milk), Flavouring, Emulsifier (Lecithins (Soya))), Oatmeal, Partially Inverted Sugar Syrup, Desiccated Coconut, Cocoa Powder, Glucose Syrup, Molasses, Raising Agents (Ammonium Carbonates, Sodium Carbonates, Diphosphates), Salt, Emulsifier (Lecithins (Soya)). Dark Chocolate Contains Cocoa Solids 36% Minimum. Contains Cereals Containing Gluten, Milk, Oats, Soybeans, Wheat. May Contain Nuts.'
        },
        {
            'id': '4APy8fZrOoVZjJhrmydS',
            'name': 'Pulled Pork With Apple Sauce',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Shoulder (74%) (Pork (91%), Water, Glucose Syrup, Salt, Modified Maize Starch, Stabilisers (Diphosphates, Triphosphates), Acidity Regulators (Sodium Citrates, Citric Acid), Yeast Extract), Apple Sauce (23%) (Apple Purée (31%), Water, Sugar, Apple Juice (9%), Candied Apple (Apple, Sugar, Glucose-Fructose Syrup), Dehydrated Diced Apple (5%) (Apple, Preservative (Sodium Metabisulphite)), Lemon Juice, Cornflour, Preservative (Potassium Sorbate)), Sage and Salt Glaze (3%) (Sage, Salt). Contains Sulphites. May Contain Nuts, Peanuts.'
        },
        {
            'id': '4AoOvVx9RS8yO3UJK5Lp',
            'name': 'Seriously Spreadable Light Cheese',
            'brand': 'Seriously',
            'serving_size_g': 100.0,
            'ingredients': 'Cheddar Cheese (Milk) (42%), Reduced Fat Cheese (Milk) (33%), Water, Skimmed Milk Powder, Emulsifying Salts (E331, E452, E450), Thickener (Pectin), Salt, Preservative (Potassium Sorbate). Contains Milk.'
        },
        {
            'id': '4BE6RMONXkK4RYR3X5ZS',
            'name': 'High Protein Noodles: Katsu Curry',
            'brand': 'Fuel10k',
            'serving_size_g': 278.0,
            'ingredients': 'Noodles (68%) (Wheat Flour, Palm Oil, Potato Starch, Acidity Regulators (Potassium Lactate, Citric Acid, Potassium Carbonate, Sodium Carbonate), Salt, Flavour Enhancer (Monosodium Glutamate), Colour (Carotenes), Antioxidant (Tocopherol-Rich Extract)), Textured Wheat Protein (15%) (Wheat Protein, Firming Agent (Calcium Sulphate), Preservative (Sodium Metabisulphite (Sulphites))), Yeast Protein Powder (6%), Maltodextrin, Dried Carrot (1.5%), Sugar, Salt, Coconut Milk Powder, Flavouring, Apple Juice Powder, Rapeseed Oil, Carrot Powder, Ground Coriander Seeds, Onion Powder, Ground Turmeric, Ground Cumin Seeds, Ground Ginger, Garlic Powder, Ground Cinnamon, Dried Yeast Extract, Chilli Powder, Ground Cloves, Milk Proteins. Contains Cereals Containing Gluten, Milk, Sulphites, Wheat.'
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

    total_cleaned = 711 + updates_made

    print(f"✨ BATCH 53 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch53(db_path)
