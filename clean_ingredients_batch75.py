#!/usr/bin/env python3
"""
Batch 75: Clean ingredients for 25 products
Progress: 1261 -> 1286 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch75(db_path: str):
    """Update batch 75 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '9OLsoEBIErEii8yxhaiN',
            'name': 'Jingly Bells',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter, Skimmed Milk Powder, Whey Powder (from Milk), Milk Fat, Emulsifier (Soya Lecithins), Flavouring.'
        },
        {
            'id': '9Otvuo3ngITtp5HffoUU',
            'name': 'Free From White Sliced Bread',
            'brand': 'Aldi',
            'serving_size_g': 38.0,
            'ingredients': 'Water, Tapioca Starch, Maize Starch, Rice Flour, Bamboo Fibre, Potato Starch, Rapeseed Oil, Humectant (Glycerol), Psyllium Husk Powder, Potato Flakes, Thickeners (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Sugar, Dried Egg White, Salt, Yeast, Preservatives (Calcium Propionate, Sorbic Acid), Cornflour, Flavouring.'
        },
        {
            'id': '9PAJgrnugsD2ZUa0fqwB',
            'name': 'Scottish Cream Shortbread Selection',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Sugar, Double Cream (4%), Milk, Butter (Milk), Salt, Natural Flavouring.'
        },
        {
            'id': '9PL4bLkQDIIIk1mUZ7cv',
            'name': 'Instant Thickening Granules',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Maltodextrin, Palm Oil, Dried Glucose Syrup, Emulsifier (Soya Lecithin).'
        },
        {
            'id': '9Pc4nAs40XU4Kcsf9lHq',
            'name': 'Tesco Bombay Potatoes',
            'brand': 'Tesco',
            'serving_size_g': 150.0,
            'ingredients': 'Cooked Potato (36%), Tomato, Onion, Tomato Juice, Rapeseed Oil, Garlic Purée, Ginger Purée, Green Chilli Purée, Coriander Powder, Sugar, Cornflour, Salt, Coriander, Cumin Powder, Curry Leaf, Turmeric, Cumin Seed, Mustard Seeds.'
        },
        {
            'id': '9KF3MzAs9BrS2NrzDWPK',
            'name': 'Demae Ramen - Chicken',
            'brand': 'Nissin',
            'serving_size_g': 500.0,
            'ingredients': 'Noodles (91.5%) (Wheat Flour, Palm Oil, Stabilizer (Potassium Carbonate), Thickener (Guar Gum), Antioxidant (Tocopherol-Rich Extract)), Seasoning Powder (7.3%) (Salt, Flavour Enhancers (Disodium Guanylate, Disodium Inosinate), Sugar, Chicken Meat Powder (6.2%), Spices, Soy Sauce Powder (Soybeans, Wheat, Salt), Yeast Extract, Flavouring, Rapeseed Oil, Anti-Caking Agent (Silicon Dioxide), Smoke Flavouring), Seasoning in Oil (1.2%) (Toasted Sesame Seed Oil).'
        },
        {
            'id': '9QcE2ryPkeFnLRRUJL2T',
            'name': 'Wafer Rolls With Hazelnut Cream',
            'brand': 'Naty',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (Gluten), Palm Vegetable Fat, Whey Powder (Lactose, Milk Proteins), Maltodextrin, Low Fat Cocoa, Dextrose, Skimmed Milk Powder, Hazelnut Paste (0.8%), Emulsifier (Soy Lecithin), Colouring Agents (Ammonia Caramel, Carmine), Flavour, Salt, Vanillin, Antioxidant (Alpha-Tocopherol).'
        },
        {
            'id': '9QiMRVodpJliJDP8Ozzj',
            'name': 'Furrows Sea Salted Chips',
            'brand': 'Tyrrells',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Sunflower Oil, Sea Salt.'
        },
        {
            'id': '9Rl7GvdGLAceBWR7yfVO',
            'name': 'Thai Red Curry Paste',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rice Bran Oil, Lemongrass (8%), Shallots, Galangal (7%), Red Chillies (5%), Palm Sugar, Garlic, Shrimps (Crustacean) (1.5%), Salt, Modified Tapioca Starch, Coriander Root (1%), Acidity Regulator (Acetic Acid), Cumin, Lime Zest, Paprika Oil, Sea Salt.'
        },
        {
            'id': '9S28GNf6fxu3QMJkZbJH',
            'name': 'Slow Roasted Salt & Vinegar Nut Mix',
            'brand': 'Forest Feast',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (36%), Cashew Nuts (31%), Almonds (16%), Salt & Vinegar Seasoning (Cider Vinegar Powder, Natural Flavouring, Salt, Acidity Regulator (Citric Acid)), Jumbo Pumpkin Seeds (4%), Pecan Nuts (3.5%), Glazing Agent (Gum Arabic), Sunflower Oil, Sea Salt.'
        },
        {
            'id': '9S3zZonmWEcxcwLmfiYT',
            'name': 'Soda Twist',
            'brand': 'Haribo',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Gelatine, Acids (Citric Acid, Malic Acid), Acidity Regulators (Calcium Citrates, Sodium Hydrogen Malate), Fruit and Plant Concentrates (Apple, Aronia, Blackcurrant, Elderberry, Grape, Lemon, Mango, Orange, Passion Fruit, Radish, Safflower, Spirulina, Sweet Potato), Flavouring, Glazing Agents (Carnauba Wax, Caramelised Sugar Syrup), Elderberry Extract.'
        },
        {
            'id': '9S6nfAXCDGhFUP7YkLUR',
            'name': 'Stockwell & Co Apple & Blackcurrant Squash',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Apple Juice from Concentrate (5%), Citric Acid, Blackcurrant Juice from Concentrate (1.0%), Acidity Regulator (Sodium Citrate), Colour (Anthocyanins), Flavourings, Sweeteners (Sucralose, Acesulfame K), Preservatives (Potassium Sorbate, Sodium Metabisulphite).'
        },
        {
            'id': '9SI4OExMM0nIEdmbF7tR',
            'name': 'Metro Rolls Tiger',
            'brand': 'Village Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Sugar, Fermented Wheat Flour, Rapeseed Oil, Salt, Rice Flour, Yeast, Dextrose, Palm Oil, Flour Treatment Agents (L-Cysteine, Ascorbic Acid), Malted Barley Flour, Raising Agents (Sodium Carbonates, Ammonium Carbonates).'
        },
        {
            'id': '9TX0ACIhTlJxPZeXfNX7',
            'name': 'Tesco Spicy Chicken Pasta',
            'brand': 'Tesco',
            'serving_size_g': 275.0,
            'ingredients': 'Cooked Pasta (Water, Durum Wheat Semolina), Chicken Breast (9%), Water, Tomato Paste, Red Pepper, Onion, Sugar, Spirit Vinegar, Rapeseed Oil, Red Chilli Purée, Cornflour, Concentrated Lemon Juice, Basil, Garlic Purée, Salt, Oregano, Dried Chilli Flakes, Black Pepper, Mustard Seeds, Garlic Powder, Sunflower Oil.'
        },
        {
            'id': '9TZpUtBUZqdjDB6xjsMX',
            'name': '4 Ancient Grain Muffins',
            'brand': 'Irwins',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Ancient Cereal Mix (30%) (Wholemeal Wheat Flour, Wholemeal Rye Flour, Einkorn Wheat, Wheat Gluten, Emmer Wheat, Wholegrain Spelt Flour, Millet Seeds, Brown Linseeds, Sunflower Seeds), Palm Oil, Sugar, Sugar Beet Fibre, Sea Salt, Barley Malt Extract, Brown Sugar, Honey, Rapeseed Oil, Sourdough (Wholemeal Spelt Wheat), Flour Treatment Agent (Ascorbic Acid), Rice Flour, Yeast, Preservative (Calcium Propionate).'
        },
        {
            'id': '9Tgv2NyernrGKmO01uZ7',
            'name': 'Orange Flavoured Cookies',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk) (21%), Sugar, Belgian Dark Chocolate Chunks (13%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Lecithins (Soya)), Flavouring), Belgian Milk Chocolate Chunks (10%) (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Emulsifier (Lecithins (Soya)), Flavouring), Orange Peel (3%), Partially Inverted Sugar Syrup, Glucose Syrup, Raising Agents (Ammonium Carbonates, Disodium Phosphate, Sodium Bicarbonate), Salt, Orange Oil.'
        },
        {
            'id': '9UT0FUViw6gYytm91SHD',
            'name': 'Salted Caramel Drinking Chocolate',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Solids (Cocoa Butter, Cocoa Mass), Sugar, Full Cream Milk Powder, Caramel Sugar, Glucose Syrup, Skimmed Milk Powder, Caramelised Sugar, Sea Salt, Emulsifiers (Sunflower Lecithin, Soya Lecithin), Flavourings, Natural Paprika.'
        },
        {
            'id': '9UVQM3ovwksnkcCUb6Hk',
            'name': 'Korma Cooking Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Single Cream (Milk) (8%), Coconut (6%), Reconstituted Tomato Purée, Modified Maize Starch, Sugar, Dried Onion, Desiccated Coconut, Spices, Whey Powder (Milk), Rapeseed Oil, Acidity Regulator (Lactic Acid), Garlic Purée, Ginger Purée, Salt, Coriander.'
        },
        {
            'id': '9Prf1CHvnzMN3Y2M0bWt',
            'name': 'Mini Eggs Cadbury Bar',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Mass, Cocoa Butter, Vegetable Fats (Palm, Shea), Whole Milk Powder, Emulsifiers (E442, E476, Lecithins), Rice Starch, Thickener (Gum Arabic), Flavourings, Colours (Anthocyanins, Beetroot Red, Curcumin), Maize Protein.'
        },
        {
            'id': '9PudkvqcZpRTbXp4mFau',
            'name': 'Fajita Seasoning Sizzlin',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Spices (24%) (Paprika, Cumin, Garlic, Red Pepper Powder, Chilli Powder), Maize Starch, Flavouring, Yeast Extract, Salt, Onion Powder, Maltodextrin, Sugar, Hydrolysed Maize Protein, Anti-Caking Agent (Silicon Dioxide), Herbs (Basil, Parsley), Cocoa Powder, Rapeseed Oil, Lemon Powder, Black Pepper.'
        },
        {
            'id': '9V1HPS9Sxp7pC8yN47F7',
            'name': 'Light Greek Natural Yogurt',
            'brand': 'Milbona',
            'serving_size_g': 100.0,
            'ingredients': 'Fat Free Greek Style Natural Yogurt (Milk).'
        },
        {
            'id': '9WBEqvTPbEtni0Womev9',
            'name': 'Fruit Spiral Lollies',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Fruit Juice from Concentrate (19%) (Orange, Pineapple, Apple, Lemon), Glucose Syrup, Strawberry Purée (2%), Acids (Citric Acid, Ascorbic Acid), Dextrose, Flavourings, Stabiliser (Guar Gum), Colours (Carotenes, Riboflavin), Plant Extracts (Spirulina Concentrate, Safflower Extract, Concentrated Beetroot Juice).'
        },
        {
            'id': '9WHNOQekNerXFZcLYYFh',
            'name': 'Nesquik Choco Waves',
            'brand': 'Nestlé',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Grain Wheat (35.0%), Sugar, Wheat Flour (17.0%), Maize Semolina (15.2%), Cocoa Powder (7.2%), Glucose Syrup, Barley Malt Extract, Sunflower Oil and/or Palm Oil, Calcium Carbonate, Emulsifier (Lecithin), Salt, Natural Flavourings, Iron, Vitamins (B3, B5, D, B6, B1, B2, B9).'
        },
        {
            'id': '9WXncC8zrAVksy3bUfRO',
            'name': 'Organic Sauerkraut With Carrot',
            'brand': 'Morgiel',
            'serving_size_g': 100.0,
            'ingredients': 'White Cabbage (53%), Spring Water, Carrot (7%), Unrefined Rock Salt.'
        },
        {
            'id': '9WjRERCTMKIa1uCivPyT',
            'name': 'Kekse',
            'brand': 'Gold',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Vegetable Fat (Palm), Sugar, Whole Egg, Salt, Aroma (Vanillin).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 75\n")

    cleaned_count = update_batch75(db_path)

    # Calculate total progress
    previous_total = 1261  # From batch 74
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 75 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1275 and previous_total < 1275:
        print(f"\n🎉🎉 1275 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 19.9% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
