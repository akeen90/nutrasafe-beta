#!/usr/bin/env python3
"""
Clean ingredients batch 27 - Mixed Brands Batch
"""

import sqlite3
from datetime import datetime

def update_batch27(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 27 (Continuing Progress)\n")

    clean_data = [
        {
            'id': 'PUhw0oOL8tspPTbU4BNd',
            'name': 'Co-op Irresistible Hand Finished Mezze Salad',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Spicy Chick Peas and Cauliflower (41%) (Chick Peas, Rapeseed Oil, Ground Cumin, Ground Coriander, Ground Turmeric, Salt, Smoked Paprika, Black Pepper, Cayenne Pepper, Cauliflower, Dried Cranberries (Sugar, Cranberries, Sunflower Oil), Pumpkin Seeds, Coriander, Concentrated Lemon Juice), Olive Fritter (15%) (Sweet Potato, Red Onion, Chickpeas, Yellow Split Peas, Black Olives (Olives, Salt), Oregano, Parsley, Salt, Garlic Powder, White Pepper), Tahini Dressing (15%) (Water, Tahini Sesame Paste, Lemon Juice, Maple Syrup, Rapeseed Oil, Roasted Garlic Purée, Cornflour, Salt, Lemon Zest, Tapioca Starch), Beetroot Purée (13%) (Beetroot, Cannellini Beans, Oat & Coconut & Rice Dairy-Free Yogurt (Oat Flour, Rice Flour, Coconut Cream, Cornflour, Sugar, Coconut Oil, Tricalcium Phosphate, Pectin, Agar, Salt, Probiotic Cultures, Vitamins D2 and B12), Rapeseed Oil, Water, Sugar, Balsamic Vinegar, Cornflour, Concentrated Lemon Juice, Mint, Salt, Garlic Purée), Mixed Leaves (9%), Chargrilled Red Peppers (7%) (Red Peppers, Rapeseed Oil). Contains Oats, Sesame.'
        },
        {
            'id': 'LncHntp7RapHcFSPGVBh',
            'name': '12 Mini Pies',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Mincemeat (50%) (Sugar, Sultanas (28%), Bramley Apple Pulp, Currants (4%), Brandy (3.9%), Mixed Peel (Orange Peel, Glucose-Fructose Syrup, Lemon Peel, Sugar, Preservative (Potassium Sorbate), Acidity Regulator (Citric Acid)), Rapeseed Oil, Glucose Syrup, Modified Maize Starch, Glacé Cherries (Cherries, Glucose-Fructose Syrup, Sugar, Colour (Anthocyanins), Acidity Regulator (Citric Acid)), Humectant (Glycerol), Mixed Spices (Coriander, Cinnamon, Ginger, Caraway, Nutmeg, Clove), Ruby Port, Maize Starch, Preservative (Acetic Acid), Orange Oil), Pastry (50%) (Wheat Flour, Butter (Milk) (13%), Sugar, Whey Powder (Milk), Salt, Wheat Starch, Raising Agents (Diphosphates, Sodium Carbonates), Shea Oil, Colour (Carotenes)). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'CeeBLy5XqeVxZUTd96r6',
            'name': 'Baklava',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Filo Pastry (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Glucose Syrup, Rapeseed Oil, Salt, Clarified Butter (Milk), Maize Starch), Invert Sugar Syrup, Cashew Nuts (Ranging from 13% to 26% across varieties), Butter Blend (Rapeseed Oil, Clarified Butter (Milk)), Sugar, Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin, Sorbitan Tristearate), Natural Vanilla Flavouring), Milk Chocolate (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Whey Powder (Milk), Emulsifier (Soya Lecithin, Polyglycerol Polyricinoleate), Natural Vanilla Flavouring), Mixed Nuts (Walnut, Macadamia, Almond, Pistachio), Cocoa Powder, Flavouring. Assortment contains: Cashew Baklava (50%), Cashew Boukage with Dark Chocolate, Truffle Baklava with Milk Chocolate, Cashew Baklava with Dark Chocolate, Cashew Assabee. Contains Cereals Containing Gluten, Milk, Nuts, Soybeans, Wheat. May Contain Other Nuts, Sulphites.'
        },
        {
            'id': '7IdYHeIUASYWqwGCnysL',
            'name': 'Welsh Beef Steak Meatballs',
            'brand': 'Edwards The Welsh Butchers',
            'serving_size_g': 80.0,
            'ingredients': 'Welsh Beef (85%), Water, Gluten Free Breadcrumb (Rice Flour, Gram Flour, Maize Starch, Salt, Dextrose), Seasoning (Rice Flour, Salt, Dried Onion (Sulphite), Potassium Chloride, Dextrose, Preservative (Sodium Sulphite), Yeast Extract, Acidity Regulator (Citric Acid), Dried Garlic, Natural Flavourings, Colour (Carmine), Flavouring), Rice Flour. Contains Sulphites.'
        },
        {
            'id': 'U5WjtsMEktPZwBVvAu3S',
            'name': 'Slow Roasted Chicken Bites',
            'brand': 'Fridge Raiders',
            'serving_size_g': 22.5,
            'ingredients': 'Chicken Breast (91%), Vegetable Oils (Soya Bean, Sunflower, Rapeseed), Seasoning (Salt, Yeast Extract, Garlic, Onion, Sage, Stabiliser (Sodium Tripolyphosphate), Flavourings), Rusk (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Raising Agent (Ammonium Bicarbonate)), Tapioca Starch, Dextrose. Contains Cereals Containing Gluten, Soybeans, Wheat. May Contain Sulphites.'
        },
        {
            'id': 'Ira4JtXER3SkT9nHuOcx',
            'name': 'Dark Chocolate Orange',
            'brand': 'Elizabeth Shaw',
            'serving_size_g': 15.6,
            'ingredients': 'Dark Chocolate (35.5%) (Sugar, Cocoa Mass, Cocoa Butter, Anhydrous Milk Fat, Emulsifiers (Soya Lecithin, Polyglycerol Polyricinoleate), Vegetable Fats (Palm, Shea, Sal, Mango, in Varying Proportions), Flavouring), Wheat Flour, Sugar, Glucose Syrup, Invert Sugar Syrup, Palm Fat, Orange Pieces (5.5%) (Concentrated Apple Purée, Orange Juice Concentrate (9%), Humectant (Glycerol), Fructose-Glucose Syrup, Glucose Syrup, Wheat Fibre, Sugar, Starch, Palm Fat, Gelling Agent (Pectins), Acidity Regulator (Citric Acid), Flavouring, Antioxidant (Ascorbic Acid), Colour (Curcumin)), Grain Crisps (4.2%) (Rice Flour, Wheat Flour, Corn Flour, Sugar, Barley Malt Extract, Salt), Orange Juice Concentrate (2.7%), Whole Milk Powder, Humectant (Sorbitol Syrup), Starch, Barley Malt Extract, Whey Powder (Milk), Salt, Emulsifiers (Soya Lecithin, Mono- and Di-Glycerides of Fatty Acids), Raising Agents (Ammonium Carbonate, Sodium Carbonate, Diphosphates), Flavourings. Contains Barley, Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': '0YAFW3MsjsEwL7yt3McH',
            'name': 'Fibre One Salted Caramel Squares',
            'brand': 'Fibre',
            'serving_size_g': 100.0,
            'ingredients': 'Oligofructose, Vegetable Fats and Oils (Palm, Sunflower, Shea), Fructose, Sugar, Humectant (Glycerol), Molasses, Water, Raising Agents (Diphosphates, Sodium Bicarbonate), Flavourings, Salt, Thickeners (Locust Bean Gum, Xanthan Gum), Cocoa Mass, Colour (Paprika Extract), Antioxidant (Tocopherol-Rich Extract), Egg White Powder, Whole Milk Powder, Salted Caramel Flavour Pieces (Oligofructose, Vegetable Fats (Palm, Shea), Sugar, Whole Milk Powder, Caramel Powder (Sugar, Skimmed Milk Powder), Cocoa Mass, Salt, Emulsifier (Soy Lecithin), Flavouring, Colour (Paprika Extract)), Caramel Powder (Sugar, Skimmed Milk Powder), Wheat Flour, Wheat Fibre, Emulsifier (Soy Lecithin). Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
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

    print(f"✨ BATCH 27 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {214 + updates_made} / 681\n")
    print(f"🎯 Next milestone: {250 - (214 + updates_made)} products until 250!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch27(db_path)
