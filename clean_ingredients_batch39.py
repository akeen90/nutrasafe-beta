#!/usr/bin/env python3
"""
Clean ingredients batch 39 - Pushing Toward 500!
"""

import sqlite3
from datetime import datetime

def update_batch39(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 39 (Toward 500!)\n")

    clean_data = [
        {
            'id': 'Hraa63nM4fzow1eONaBq',
            'name': 'Mcallister\'s Rough Oatcakes',
            'brand': 'Mcallister\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oats (90%), Sunflower Oil, Palm Oil, Sea Salt, Raising Agent (Sodium Carbonates). Contains Cereals Containing Gluten, Oats.'
        },
        {
            'id': 'KYHe0ycCtj0p1dRlJpzt',
            'name': 'Beef Stock',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Salt, Palm Oil, Corn Starch, Yeast Extract, Beef Extract (4%), Sugar, Natural Flavourings, Colour (Plain Caramel), Parsley, Onion Extract, Carrot Extract, Dried Carrot, Antioxidant (Extracts of Rosemary). Contains Beef. May Contain Celery, Eggs, Fish, Crustaceans, Soybeans.'
        },
        {
            'id': 'mF1h85aBStoTbNYqopSK',
            'name': 'Graze Cherry Bakewell Oat Boosts',
            'brand': 'Graze',
            'serving_size_g': 50.0,
            'ingredients': 'Oats (41%), Chicory Root Fibre, Vegetable Oils (Rapeseed, Palm), Golden Syrup, Liquid Sugar, Dried Cranberries (Sugar, Cranberries, Sunflower Oil), Humectant (Glycerine), Flaked Almonds (2.3%), Palm Fat, Soluble Corn Fibre, Apple Juice Infused Dried Sour Cherries (1%) (Sour Cherries (48%), Apple Juice Concentrate, Rice Flour, Lemon Juice Concentrate, Sunflower Oil), Soya Flour, Cherry Juice Powder, Demerara Sugar, Potato Starch, Sea Salt, Emulsifier (Soya Lecithin), Citrus Fibre, Natural Flavouring. Contains Nuts, Oats, Soybeans.'
        },
        {
            'id': '5g9vam8egkZ6rpgSKSzY',
            'name': 'TA Sweet Chilli Prawn Flavour Crackers',
            'brand': 'Tesco',
            'serving_size_g': 20.0,
            'ingredients': 'Tapioca Flour, Rapeseed Oil, Sugar, Rice Flour, Salt, Flavourings, Onion Powder, Garlic Powder, Cayenne Pepper, Yeast Extract Powder, Fennel Seeds, Tomato Powder, Ginger, Acidity Regulators (Citric Acid, Malic Acid), Parsley, Colour (Paprika Extract).'
        },
        {
            'id': 'LAJWQxFkJGONfR4SIx8I',
            'name': 'Vegan Melting Mature',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Coconut Oil, Potato Starch, Modified Maize Starch, Yeast Extract, Salt, Thickener (Carrageenan), Natural Flavouring, Tricalcium Phosphate, Calcium Chloride, Colour (Carotene), Vitamin B12.'
        },
        {
            'id': 'nGiMn3HSinohWWsszAgr',
            'name': 'Krisprolls Wholegrain',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Cracked Wheat (58%), Wheat Flour, Sugar, Vegetable Oils (Rapeseed Oil, Fully Hydrogenated Rapeseed Oil), Barley Malt, Yeast, Salt. Contains Barley, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'eFJVpqhsMb7GXHLj4CVf',
            'name': 'High Bran',
            'brand': 'Asda',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat Bran (70%), Wheat Flour, Sugar, Barley Malt Extract, Salt, Vitamin and Mineral Mix (Iron, Pantothenic Acid (B5), Vitamin B12, Niacin (B3), Thiamin (B1), Vitamin D, Folic Acid (B9), Vitamin B6, Riboflavin (B2)). Contains Barley, Cereals Containing Gluten, Wheat. May Contain Peanuts, Nuts, Milk, Oats.'
        },
        {
            'id': 'ae0U5bBlFvWLMEab4aSP',
            'name': 'Vegetarian Bacon',
            'brand': 'Quorn',
            'serving_size_g': 30.0,
            'ingredients': 'Mycoprotein (77%), Rehydrated Free Range Egg White, Flavourings (contains Milk, Smoke Flavourings, Colour (Iron Oxide)), Rapeseed Oil, Preservative (Potassium Sorbate). Contains Eggs, Milk.'
        },
        {
            'id': 'LOJ5FW7WEtoWHBaMXmdA',
            'name': 'Gravy Granules',
            'brand': 'Essential Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Palm Oil (Certified Sustainable), Salt, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Colour (Ammonia Caramel), Hydrolysed Wheat Protein, Onion Powder, Flavouring (contains Wheat), Emulsifier (Soya Lecithins). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'BKx7bWQTVmrNVk6VmSk6',
            'name': 'Spicy Red Kidney Beans',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Red Kidney Beans (46%), Tomatoes (43%), Water, Sugar, Modified Maize Starch, Chilli Pepper, Paprika, Ground Cumin, Dried Garlic, Ground Coriander, Ground Black Pepper, Garlic Powder, Ground Basil, Onion Powder, Ground Oregano, Ground Thyme, Flavouring.'
        },
        {
            'id': '5HjWAeOVS2w0Zl8oyq8H',
            'name': 'Coronation Chickpea Curry - Plant Menu',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Coriander Rice (25%) (Water, Long Grain Rice, Coriander Leaf), Chickpeas (18%), Water, Potato (11%), Onion, Spinach (8%), Coconut Cream, Apricots (3.5%) (Dried Apricot, Rice Flour, Preservative (Sulphur Dioxide)), Sultanas (1.5%) (Sultanas, Rapeseed Oil, Preservative (Sulphur Dioxide)), Spices, Garlic Purée, Ginger Purée, Mango Chutney (Sugar, Mango, Salt, Ginger Powder, Ground Cayenne Pepper, Garlic Powder, Acidity Regulator (Acetic Acid)), Tomato Purée, Rapeseed Oil, Cornflour. Contains Sulphites.'
        },
        {
            'id': 'GUxr3heQ77ee1IZewMuu',
            'name': 'Sweet Chilli And Garlic Sauce',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Water, Spirit Vinegar, Garlic Purée (4%), Modified Maize Starch, Salt, Dried Garlic, Birdseye Chilli (0.7%), Red Pepper, Chilli Flakes (0.4%), Preservative (Potassium Sorbate).'
        },
        {
            'id': 's6CwC8FzNnzWyr7heDYA',
            'name': 'Mild Curry Powder',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Coriander Seed, Salt, Turmeric, Cinnamon, Paprika, Sugar, Garlic Powder, Onion Powder, Cumin Seed, Ginger, Mustard Seed, Black Pepper, Cardamom, Chilli Powder, Clove, Nutmeg. Contains Mustard.'
        },
        {
            'id': 'o2YeXl4DNFh9CmTgbsTP',
            'name': 'Simply Delicious Chocolate Cake Mix',
            'brand': 'Dr. Oetker',
            'serving_size_g': 65.0,
            'ingredients': 'Wheat Flour, Sugar, Fat Reduced Cocoa Powder (8%), Rice Starch, Emulsifiers (Polyglycerol Esters of Fatty Acids, Mono- and Diglycerides of Fatty Acids, Polysorbate 80), Raising Agents (Diphosphates, Sodium Carbonates), Stabiliser (Xanthan Gum), Salt. Contains Cereals Containing Gluten, Wheat. May Contain Milk.'
        },
        {
            'id': 'kqVQbsXW6n667DfDMnc8',
            'name': 'Pea And Ham Soup',
            'brand': 'Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Peas (26%), Potato, Onions, Ham Hock (6%) (Pork Leg, Salt, Preservative (Sodium Nitrite)), Cornflour, Vegetable Stock (Sugar, Salt, Concentrated Onion Juice, Corn Starch, Carrot Juice Concentrate, Rapeseed Oil, Water, Leek Powder, Garlic Powder, Nutmeg Oil), Pork Stock (Water, Pork Bone, Pork Rind, Tomato Purée, Star Anise, Salt, Acidity Regulator (Sodium Carbonates), Spearmint, White Pepper). Contains Pork.'
        },
        {
            'id': 'aHsvrHOcbw1wNPyNCq0A',
            'name': 'Frozen Yogurt Lollies',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (Milk) (65%), Sugar, Glucose Syrup, Blueberry Juice from Concentrate (6%), Whey Powder (from Milk), Lemon Juice from Concentrate, Stabilisers (Locust Bean Gum, Guar Gum), Emulsifier (Mono- and Diglycerides of Fatty Acids), Flavouring, Colour (Anthocyanins), Raspberry Juice Concentrate, Strawberry Juice Concentrate. Contains Milk.'
        },
        {
            'id': 'vs9PYRIhijrP1Uv3n7oT',
            'name': 'Hoisin Duck Sushi',
            'brand': 'Tesco',
            'serving_size_g': 57.0,
            'ingredients': 'Cooked White Sushi Rice (Water, White Rice, Rice Vinegar, Sugar, Spirit Vinegar, Rapeseed Oil, Salt), Cucumber, Duck (7%), Soy Sauce (Water, Soya Bean, Salt, Vinegar), Nori Seaweed, White Sesame Seeds, Sugar, Cornflour, Rice Vinegar, Soya Bean, Salt, Concentrated Plum Juice, Plum, Garlic Purée, Cane Molasses, Spirit Vinegar, Cayenne Pepper, Cinnamon, Fennel, Ginger Powder, Ginger, Clove Powder, Star Anise, Aniseed, Cinnamon Powder. Contains Sesame, Soybeans.'
        },
        {
            'id': 'YSVZGI35ZS1UwTvpSdJG',
            'name': 'Greengage Extra Jam',
            'brand': 'The Wooden Spoon Preserving Company',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Greengage (50%), Gelling Agent (Pectin), Citric Acid. Prepared with 50g of Fruit per 100g. Total Sugar Content 60g per 100g. May Contain Nuts.'
        },
        {
            'id': 'qqiYkR3QYCkCRqiUQ9Jr',
            'name': 'Whey Protein Chocolate Flavour',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Whey Protein Concentrate (Milk), Emulsifier (Sunflower Lecithin), Soy Protein Isolate, Cocoa Powder, Flavouring, Sodium Chloride, Thickener (Xanthan Gum), Sweeteners (Acesulfame Potassium, Sucralose). Contains Milk, Soybeans. May Contain Eggs, Nuts, Fish, Crustaceans, Cereals Containing Gluten.'
        },
        {
            'id': 'j4uhvg9A3gfKUYNSx5uI',
            'name': 'Gray',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Lecithins. Contains Soybeans. May Contain Cereals Containing Gluten.'
        },
        {
            'id': 'QObqEujz9aWBWksDcqP9',
            'name': 'White Sauce Mix',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Maltodextrin, Palm Fat, Dried Glucose Syrup Powder, Emulsifiers (Soya Lecithin, Citric Acid Esters of Mono- and Diglycerides), Maize Starch, Vegetable Oils (Palm, Rapeseed), Salt, Sugar, Onion, Mono- and Diglycerides of Fatty Acids, Milk Proteins, Stabiliser (Dipotassium Phosphate, Sodium Polyphosphate), Dried Yeast Extract (contains Barley), Garlic Powder, Ground Black Pepper, Flavourings (contain Milk), Herbs (Bay Leaf, Lovage, Parsley), Acidity Regulator (Citric Acid), Colour (Carotenes). Contains Barley, Milk, Soybeans.'
        },
        {
            'id': 'kg5gpuHKwxIEE8PAXLw3',
            'name': 'Redefine Premium Burgers',
            'brand': 'Redefine Meat',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Plant Protein (Soy, Pea) (15%), Refined Coconut Fat, Refined Rapeseed Oil, Flavourings (contain Mustard), Thickener (Methyl Cellulose), Maltodextrin, Dehydrated Potato Flakes, Mushroom Extract, Concentrated Caramelised Pear Juice, Raising Agent (Sodium Bicarbonate), Salt, Raspberry Juice, Vitamin B3, Vitamin B6, Vitamin B12, Iron, Zinc, Colour (Beetroot Red). Contains Mustard, Soybeans. May Contain Cereals Containing Gluten, Lupin, Celery.'
        },
        {
            'id': 'siJ3ILCkP2Gj9C3dtP99',
            'name': 'Spam With Real Bacon',
            'brand': 'Hormel',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (74%), Smoked Bacon (15%) (Pork, Salt, Water, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Starch, Water, Ham (2%), Salt, Sugar, Stabiliser (Trisodium Diphosphate), Spice Extract, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite). Contains Pork. May Contain Milk.'
        },
        {
            'id': 'TQk2UiDhtrGMD3CiQYHE',
            'name': 'Smooth Bolognese Pasta Sauce',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (60%), Tomato Purée Concentrate (20%), Water, Lemon Juice from Concentrate, Modified Maize Starch, Salt, Herbs, Garlic Purée, Acidity Regulator (Citric Acid), Onion Powder, Ground Black Pepper.'
        },
        {
            'id': 'WW1K3RINYokYimtb0Ujr',
            'name': 'Raspberry Jelly',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Apple Juice from Concentrate (99%), Gelling Agents (Carrageenan, Carob Bean Gum), Acidity Regulators (Sodium Citrates, Calcium Lactate, Potassium Citrate, Citric Acid), Flavourings, Colour (Anthocyanins), Sweeteners (Sucralose, Acesulfame K).'
        },
        {
            'id': 'ibBsXtnXlw8Y4XQCgv6i',
            'name': 'Apple And Cinnamon Porridge',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes (81%), Sugar, Dried Apple Pieces, Cinnamon, Flavouring. Contains Cereals Containing Gluten, Oats. May Contain Nuts, Other Cereals Containing Gluten.'
        },
        {
            'id': 'EYP0SZixWyNAGBA7ayqV',
            'name': 'Both In One White And Wholemeal',
            'brand': 'Rowan Hill Bakery',
            'serving_size_g': 40.0,
            'ingredients': 'Wholemeal Wheat Flour (33%), Wheat Flour (33%) (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Salt, Vegetable Oil (Rapeseed Oil, Palm Oil), Soya Flour, Spirit Vinegar, Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Preservative (Calcium Propionate), Palm Fat, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'Ffmg3ZMmYCxRblLZfDhe',
            'name': 'Zesty Lemon Sorbet',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Lemon Juice from Concentrate (30%), Sugar, Glucose Syrup, Fructose, Lime Juice from Concentrate, Tapioca Starch, Stabiliser (Xanthan Gum), Flavouring. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': 'mFmxnR2kAAvF8C73Z2iV',
            'name': 'Tesco Finest Swiss Chocolate With Caramel Almond Pieces',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Dried Whole Milk, Cocoa Butter, Caramel Almond Pieces (9%) (Sugar, Almonds, Butter (Milk), Dried Whole Milk, Glucose Syrup, Salt), Cocoa Mass, Hazelnut (2.5%), Emulsifier (Soya Lecithins), Flavouring. Milk Chocolate Contains Cocoa Solids 31% Minimum, Milk Solids 26% Minimum. Contains Milk, Nuts, Soybeans. May Contain Other Nuts.'
        },
        {
            'id': '4FXKvvd3ZOiXZUrXqHIe',
            'name': 'Morrisons The Best Hand Rolled Chocolate Fudge Yule Log',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Butter (Milk), Milk Chocolate (11%) (Sugar, Cocoa Mass, Cocoa Butter, Milk Fat, Dried Skimmed Milk, Whey Powder (Milk), Vegetable Fats (Palm, Shea), Emulsifier (Soya Lecithins), Flavouring), Glucose Syrup, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Fat Reduced Cocoa Powder, Belgian Milk Chocolate (3%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Emulsifier (Soya Lecithins), Flavouring), Humectant (Glycerol), Dried Skimmed Milk, Dried Whole Egg, Cocoa Butter. Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
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

    total_cleaned = 456 + updates_made

    print(f"✨ BATCH 39 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 500:
        print(f"\n🎉🎉🎉 500 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {550 - total_cleaned} products until 550!\n")
    else:
        remaining_to_500 = 500 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_500} products until 500!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch39(db_path)
