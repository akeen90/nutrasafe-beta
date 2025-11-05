#!/usr/bin/env python3
"""
Batch 71: Clean ingredients for 25 products
Progress: 1161 -> 1186 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch71(db_path: str):
    """Update batch 71 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '7o38YiYmWQwCHMZzXDUG',
            'name': 'Comte',
            'brand': 'Comte Aop',
            'serving_size_g': 100.0,
            'ingredients': 'Comté Cheese, Unpasteurised Milk.'
        },
        {
            'id': '7pL2geHfufUmmDJTtDg3',
            'name': 'Crunchy Coleslaw',
            'brand': 'Sainos',
            'serving_size_g': 75.0,
            'ingredients': 'Cabbage 62%, Mayonnaise (Water, Rapeseed Oil, Pasteurised Egg, Salt, Spirit Vinegar, Stabilisers (Guar Gum, Xanthan Gum)), Carrot, Onion, Preservative (Potassium Sorbate).'
        },
        {
            'id': '7qBPJrOXssgXyJFoLY6w',
            'name': 'Sauce Mix',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Corn Wheat Flour, Cheddar Cheese Powder (16%) (Milk), Cheese Powder (16%) (Milk), Flavouring (contains Milk), Yeast Extract, Salt, Sugar, Mustard Powder, Ground White Pepper, Colour (Carotenes).'
        },
        {
            'id': '7qLVBWANI3OM2DRRWIdg',
            'name': 'Strawbery Rice Pudding',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Pudding (85%) (Skimmed Milk, Water, Rice (8%), Sugar, Skimmed Milk Concentrate, Cream (Milk), Stabilisers (Locust Bean Gum, Guar Gum), Flavourings, Salt), Strawberry Compote (15%) (Water, Strawberries (33%), Sugar, Modified Maize Starch, Flavouring, Acidity Regulators (Citric Acid, Calcium Citrates, Sodium Citrates), Stabiliser (Pectins), Black Carrot Concentrate, Concentrated Beetroot Juice).'
        },
        {
            'id': '7qTyLp8fQuuktG2ZU3MC',
            'name': 'Diet Cola',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Colour (Plain Caramel), Malted Barley Extract, Flavourings (including Caffeine), Acids (Phosphoric Acid, Citric Acid), Preservative (Potassium Sorbate), Acidity Regulator (Trisodium Citrate), Sweeteners (Acesulfame K, Sucralose).'
        },
        {
            'id': '7r4fPtkMcBMMDw8Rh3Ge',
            'name': 'Hot & Spicy Chicken Wings',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Wings, Sugar, Cornflour, Rice Flour, Tomato Powder, Red Chilli Powder, Potato Starch, Salt, Onion Powder, Garlic Powder, Cumin, Stabiliser (Sodium Triphosphate), Cayenne Pepper, Coriander, Oregano, Parsley, Dried Green Pepper, Dried Red Pepper, Sunflower Oil, Paprika Extract, Caramelised Sugar Syrup, Rapeseed Oil, Capsicum Extract, Maltodextrin.'
        },
        {
            'id': '7rLVL8OhUg1GImmRkcsO',
            'name': 'Deluxe Truffle Mayonnaise',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': '72% Rapeseed Oil, Water, 6.7% Pasteurised Free Range Egg Yolk, 3.4% Truffle Paste (Summer Truffles, Extra Virgin Olive Oil, Water, Flavouring), White Wine Vinegar, Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Concentrated Lemon Juice.'
        },
        {
            'id': '7rh5yOaBSNraBrYeHC3Y',
            'name': 'Tuna Chunks',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack Tuna (Fish), Sunflower Oil, Salt.'
        },
        {
            'id': '7sNgi2XjkTYnkDo5sgXB',
            'name': 'Wiltshire Cured Ham',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'British Pork, Curing Salt (Salt, Preservative (Sodium Nitrite, Potassium Nitrate)).'
        },
        {
            'id': '7se0EiLBd3BFQmcSFu8y',
            'name': 'Cheese And Onion Rolls',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin), Onion (14%), Potato (14%), Palm Oil, Cheddar Cheese (8%) (Milk), Full Fat Soft Cheese (4.5%) (Milk), Dried Potato, Mature Coloured Cheddar Cheese (3.5%) (Cheddar Cheese (Milk), Colour (Annatto Norbixin)), Milk, Rapeseed Oil, Salt, Cornflour, Stabilizers (Hydroxypropyl Methyl Cellulose, Methyl Cellulose), Balsamic Vinegar (Red Wine Vinegar, Grape Must Concentrate), Flavouring, White Pepper.'
        },
        {
            'id': '7tEQWuWFGRXM501rx4ej',
            'name': 'All Butter Pain Au Chocolate',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Wheat Gluten, Flour Treatment Agent (Ascorbic Acid)), Unsalted Butter (Milk) 19%, Water, Chocolate 12% (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithins)), Liquid Yeast, Sugar, Milk Glaze (Water, Skimmed Milk, Rapeseed Oil, Dextrose, Milk Proteins, Hydrolysed Vegetable Protein), Improver (Emulsifier (Mono - and Diacetyl Tartaric Acid Esters of Mono-and Diglycerides of Fatty Acids), Rapeseed Oil, Enzymes (Wheat), Antioxidant (Ascorbic Acid)), Sea Salt, Potassium Iodate.'
        },
        {
            'id': '7tPDwCGTMpvRi0JoUAbs',
            'name': 'Mango Chutney',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Mango (44%), Salt, Acid (Acetic Acid), Ground Spices, Colour (Paprika Extract).'
        },
        {
            'id': '7tgsOO6gz4ox8lHFx5E6',
            'name': 'Winter Spice',
            'brand': 'Ribena',
            'serving_size_g': 250.0,
            'ingredients': 'Water, Blackcurrant Juice from Concentrate (18%), Acids (Malic Acid, Citric Acid), Acidity Regulator (Sodium Gluconate), Extracts of Carrot and Hibiscus, Vitamin C, Natural Flavouring, Sweeteners (Aspartame, Acesulfame K), Preservatives (Potassium Sorbate, Sodium Bisulphite).'
        },
        {
            'id': '7o7PRsWF74RskH8PcUfP',
            'name': 'Reduced Fat Houmous',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Chickpeas, Water, Tahini (Sesame Seed Paste), Rapeseed Oil, Salt, Garlic Purée, Concentrated Lemon Juice, Preservative (Potassium Sorbate).'
        },
        {
            'id': '7vOXkptgJ61aJn1224dn',
            'name': 'Heroes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Glucose Syrup, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Whey Powder (from Milk), Glucose-Fructose Syrup, Skimmed Milk Powder, Rice Flour, Emulsifiers (E442, Soya Lecithins, E471, E476), Milk Fat, Whey Powder (from Milk), Stabiliser (Sorbitol), Whey Permeate Powder (from Milk), Humectant (Glycerol), Invert Sugar Syrup, Fat Reduced Cocoa Powder, Salt, Flavourings (contain Milk), Barley Malt Extract, Molasses, Dried Egg Whites, Sodium Carbonates, Colours (Carotenes, Paprika Extract, E150d).'
        },
        {
            'id': '7voYzOQEzHXG5k3Lvr7U',
            'name': 'Prosciutto Crudo',
            'brand': 'Principe',
            'serving_size_g': 10.0,
            'ingredients': 'Pork Leg, Salt.'
        },
        {
            'id': '7vtkEteKwcsP0WgGmoDU',
            'name': 'Prawn Cocktail',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Prawns (Crustaceans) (52%), Rapeseed Oil, Water, Pasteurised Free Range Salted Egg Yolk (Pasteurised Free Range Egg Yolk, Salt), Tomato Ketchup (Water, Sugar, Tomato Paste, Spirit Vinegar, Cornflour, Salt, Pepper), Worcester Sauce (Water, Sugar, Spirit Vinegar, Molasses, Onion Purée, Salt, Tamarind Paste, Clove Powder, Ginger Purée, Garlic Purée), Sugar, Spirit Vinegar, Lemon Juice from Concentrate, Cornflour, Salt, Mustard Flour.'
        },
        {
            'id': '7vwBKaJYjreOca8Y1XrY',
            'name': 'Apple Juice',
            'brand': 'The Juice Company',
            'serving_size_g': 150.0,
            'ingredients': 'Apple Juice from Concentrate (100%).'
        },
        {
            'id': '7wwKN59WccztvQ4Lxxdn',
            'name': 'Turtle Beach Ice Cream',
            'brand': 'Giannis',
            'serving_size_g': 61.0,
            'ingredients': 'Partially Reconstituted Buttermilk Powder, Whole Milk, Double Cream (Milk), Chocolate Flavour Caramel Filled Turtle Pieces (12%) (Sugar, Fat Reduced Cocoa Powder, Glucose Syrup, Butter (Milk), Condensed Skimmed Milk, Emulsifier (Lecithins (Soya)), Milk Fat, Flavouring, Salt), Sugar, Emulsifier (Mono - and Diglycerides of Fatty Acids), Flavourings, Plant Extract (Spirulina Extract), Stabilisers (Guar Gum, Sodium Alginate), Colours (Plain Caramel, Carotenes).'
        },
        {
            'id': '7x5zVIwOcfcmpcdca0Mw',
            'name': 'Blueberry Muffins',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Rapeseed Oil, Blueberries (12%), Water, Egg, Wheat Starch, Wheat Flour, Raising Agents (Potassium Hydrogen Carbonate, Disodium Diphosphate), Whey Protein Concentrate (Milk), Flavourings, Emulsifier (Polyglycerol Esters of Fatty Acids-Vegetable).'
        },
        {
            'id': '7xSFlb7NiUMccIxkUgmA',
            'name': 'Rapeseed Oil Cooking Spray',
            'brand': 'Asda',
            'serving_size_g': 1.0,
            'ingredients': 'Rapeseed Oil (53%), Water, Emulsifier (Lecithins), Acidity Regulator (Citric Acid), Thickener (Xanthan Gum), Preservative (Potassium Sorbate).'
        },
        {
            'id': '7yf4g9JdRQdda1hE3MnK',
            'name': 'Colour The Rainbow Cutie Cupcakes',
            'brand': 'M&S',
            'serving_size_g': 84.0,
            'ingredients': 'Sugar, Unsalted Butter (Milk), Wheat Flour (with Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pasteurised Egg, Rapeseed Oil, Butter, Butter Oil (Milk), Dried Whole Milk, Humectant (Glycerol), Modified Maize Starch, Dried Whey (Milk), Palm Fat, Emulsifier (E481, E477, E471, Soya Lecithin, E466, E464, E473), Raising Agent (E450, Sodium Bicarbonate, Calcium Phosphates), Vanilla Flavouring, Shea Oil, Coconut Oil, Wheat Gluten, Rice Flour, Dried Skimmed Milk, Salt, Colour (Beetroot Red, Paprika Extract, Lutein, Curcumin, Riboflavins, Anthocyanins (from Red Cabbage), Fruit, Plant and Vegetable Concentrates (Spirulina, Sweet Potato, Apple, Radish, Blackcurrant)), Vanilla Extract, Acidity Regulator (Citric Acid), Flavouring, Stabiliser (Gum Arabic), Cornflour, Spirulina Extract, Glazing Agent (Beeswax), Glucose Syrup.'
        },
        {
            'id': '7yst6F945cTBVfZMR9uU',
            'name': 'Snaktastic Potato Hoops BBQ Beef Flavour',
            'brand': 'Snaktastic',
            'serving_size_g': 25.0,
            'ingredients': 'Dried Potato, Potato Starch, High Oleic Sunflower Oil, Rice Flour, Barbecue Beef Flavour Seasoning (Rice Flour, Salt, Natural Flavouring, Sugar, Dried Onion, Acid (Citric Acid), Dried Garlic, Ground Black Pepper, Colour (Paprika Extract)), Salt.'
        },
        {
            'id': '7zIy2OOmqxs4qdcOBY3T',
            'name': 'Golden Breadcrumbs',
            'brand': 'Paxo',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour with Added Calcium, Iron, Niacin, Thiamin, Salt, Yeast, Turmeric Extract, Colour (Paprika Extract).'
        },
        {
            'id': '7uzcyaKjKs7IBq8Yu1Fy',
            'name': 'Fruit & Grain Blueberry',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Blueberry Filling 40% (Sugar, Water, Humectant (Glycerol), Modified Maize Starch, Blueberry Purée 3.5%, Gelling Agent (Pectin), Acidity Regulators (Citric Acid, Sodium Citrates), Plant Extracts (Carrot Concentrate, Blueberry Concentrate, Blackcurrant Concentrate), Flavouring, Firming Agent (Tricalcium Phosphate), Preservative (Potassium Sorbate)), Wheat Flour (Wheat Flour, Iron, Niacin, Thiamin, Riboflavin, Folic Acid), Sunflower Oil, Humectant (Glycerol), Oat Bran, Raisins (Raisins, Sunflower Oil, Cottonseed Oil), Oat Flakes, Molasses, Pasteurised Liquid Whole Egg, Brown Sugar, Oat Flour, Vitamins and Minerals (Calcium, Niacin, Iron, Zinc Oxide, Vitamin B6, Riboflavin, Thiamin, Vitamin A, Folic Acid), Invert Sugar Syrup, Raising Agents (Potassium Carbonates, Diphosphates, Sodium Carbonates, Calcium Phosphates), Stabiliser (Carboxymethyl Cellulose), Salt, Preservative (Sodium Propionate), Maize Starch.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (
            product['ingredients'],
            product['serving_size_g'],
            current_timestamp,
            product['id']
        ))

        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Serving: {product['serving_size_g']}g\n")

    conn.commit()
    conn.close()

    return len(clean_data)

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🧹 CLEANING INGREDIENTS - BATCH 71\n")

    cleaned_count = update_batch71(db_path)

    # Calculate total progress
    previous_total = 1161  # From batch 70
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 71 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1175 and previous_total < 1175:
        print(f"\n🎉 1175 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 18.2% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
