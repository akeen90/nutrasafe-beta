#!/usr/bin/env python3
"""
Clean ingredients batch 40 - BREAKING 500 MILESTONE!
"""

import sqlite3
from datetime import datetime

def update_batch40(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 40 (BREAKING 500!)\n")

    clean_data = [
        {
            'id': 'z7nz4Eal4QlrMmZYJ317',
            'name': 'Free From Muesli',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (59%), Raisins (12%), Dates (12%), Sunflower Seed, Dried Sweetened Cranberries (5%) (Cranberries, Sugar), Pumpkin Seeds. Contains Oats.'
        },
        {
            'id': 'euLna5LdS6bgxsFXVESp',
            'name': 'Strawberry Fruity Bars',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Red Fruit Filling (37%) (Organic Apple Juice Concentrate, Organic Strawberries (25%), Organic Blackcurrants, Organic Cherries, Natural Raspberry Flavouring, Gelling Agent (Pectin)), Organic Whole Wheat Flour, Organic Apple Juice Concentrate, Organic Sunflower Oil, Organic Oat Flour, Raising Agent (Sodium Hydrogen Carbonate), Vitamin B1. Contains Cereals Containing Gluten, Oats, Wheat. May Contain Nuts, Eggs, Milk, Soybeans.'
        },
        {
            'id': 'FnCsaIClpSeQcWSANlwa',
            'name': 'Sea Salt & Lime',
            'brand': 'Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Maize Flour, Rapeseed Oil, Rice Flour, Golden Linseed (1%), Sunflower Seeds (0.5%), Brown Linseed (0.5%), Sugar, Yeast Powder, Yeast Extract Powder, Acid (Citric Acid), Sea Salt (0.5%), Lime Powder, Millet Seeds (0.5%), Salt, Key Lime Oil.'
        },
        {
            'id': 'XltdQhifTT7xa4yZyupa',
            'name': 'Black Bean Spaghetti',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Black Soya Beans (100%). Contains Soybeans.'
        },
        {
            'id': '0y2HhL4fpbHe6zMQOxuT',
            'name': 'Re-fried Beans',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Pinto Beans (63%), Water, Onions (13%), Red Peppers, Ground Spices (Cumin, Smoked Paprika, Chilli Powder, Black Pepper), Coriander Leaf, Salt, Roasted Garlic Purée, Cornflour, Concentrated Lime Juice.'
        },
        {
            'id': '7P9uWtEuWU2czDvUymyK',
            'name': 'Mccloskey\'s Cottage Brown',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Buttermilk (47%), Wholemeal Wheat Flour, Wheat Bran, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Salt, Sodium Bicarbonate, Vegetable Oil (Palm and Rapeseed). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'd3D52pBDOaoIN8NB4gHu',
            'name': '6 Duck Spring Rolls',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour, Shredded Duck (19%), Bean Sprouts, Water, Rapeseed Oil, Carrot, Water Chestnut, Spring Greens, Ginger Purée, Chopped Spring Onion, Sugar, Cornflour, Fermented Soya Bean, Salt, Star Anise, Rice Vinegar, Wheat Flour, Fennel, Black Pepper, Cinnamon, Garlic, Red Rice Koji, Spices, Toasted Sesame Seed Oil, Clove, Ground Ginger, Chilli Powder, Colour (Plain Caramel). Contains Cereals Containing Gluten, Sesame, Soybeans, Wheat.'
        },
        {
            'id': 'uigFiQctIfkoOFy4b9RU',
            'name': 'Traditional Real Dairy Ice Cream',
            'brand': 'MacKie\'s Of Scotland',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Milk (60%), Whipping Cream (21%), Sugar, Milk Solids, Glycerine, Emulsifier (Mono and Diglycerides of Fatty Acids), Pasteurised Free Range Eggs, Stabilisers (Sodium Alginate, Guar Gum). Contains Eggs, Milk.'
        },
        {
            'id': 'fjGC75HlRlZpqpZS2uF9',
            'name': 'Raw Vitamin Honey',
            'brand': 'Just Bee',
            'serving_size_g': 100.0,
            'ingredients': 'Pure Honey (96%), Ginger Purée (2.4%), Ginger Extract (0.4%), Lemon Extract (0.4%), Natural Flavour, Colour (Plain Caramel), Echinacea, Vitamin C, Vitamin D, Vitamin B6, Vitamin B12.'
        },
        {
            'id': 'PUH1yipeJ9uYQOzCVZeO',
            'name': 'Cottage Pie',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Mashed Potato (53%) (Water, Dried Potato (Potato, Turmeric), Yeast Extract, White Pepper), Minced Beef Gravy (47%) (Water, Minced Beef (14%), Onion, Modified Maize Starch, Celery, Flavouring, Modified Maize Starch, Flavourings, Colour (Ammonia Caramel), Salt, Sugar, Maltodextrin, Vegetable Oils (Sunflower, Palm), Tomato Purée, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Beef Stock (Water, Yeast Extract, Beef Stock, Sugar, Salt, Caramelised Sugar, Mushroom Concentrate, Red Wine Extract)). Contains Beef, Celery, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '4Exs5jUQFbkeAAVHAkWx',
            'name': 'Sweet Chilli Flatbread Thins',
            'brand': 'Lidl',
            'serving_size_g': 8.0,
            'ingredients': 'Wheat Flour (75%) (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Dark Rye Flour (8%), Extra Virgin Olive Oil, Clear Blossom Honey, Balsamic Vinegar (White Wine Vinegar (Sulphites), Concentrated Grape Must (Sulphites)), Ground Chilli Powder, Ground Paprika, Coriander, Sweet Chilli Seasoning, Salt, Garlic Powder, Dextrose, Onion Powder, Spices (Paprika, Cayenne, Black Pepper), Tomato Powder, Sugar, Maltodextrin, Natural Flavouring, Yeast Extract Powder, Barley Malt Vinegar Powder. Contains Barley, Cereals Containing Gluten, Sulphites, Wheat.'
        },
        {
            'id': 'xUL7elDvNI63sG9ULhgg',
            'name': 'Malted Milk Biscuits',
            'brand': 'Jack\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (contains Calcium Carbonate, Iron, Nicotinamide, Thiamin), Palm Oil, Sugar, Barley Malt Extract, Dried Whole Milk, Raising Agent (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavouring. Contains Barley, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'o1h3cgrigRQLa3663dxb',
            'name': 'Unsmoked Dry Cured Bacon',
            'brand': 'Edwards',
            'serving_size_g': 70.0,
            'ingredients': 'British Pork Loin (97%), Salt, Sugar, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate). Contains Pork.'
        },
        {
            'id': 'bTkaG55ZsC4HQK3Ipqk2',
            'name': 'Free From Gluten Fruit Loaf',
            'brand': 'Sainsbury\'s Taste The Difference',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sultanas (17%), Potato Starch, Rice Flour, Tapioca Starch, Rapeseed Oil, Maize Starch, Rice Starch, Orange Peel (3%), Psyllium Husk Powder, Invert Sugar Syrup, Yeast, Stabiliser (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Bamboo Fibre, Humectant (Glycerol), Dried Egg White, Raisin Juice Concentrate, Salt, Concentrated Orange Juice, Cinnamon, Ginger. Contains Eggs. May Contain Milk.'
        },
        {
            'id': 'PR71ezqzGW96U1WE8ygx',
            'name': 'Chilli Con Carne',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Red Kidney Beans (23%), Water, Tomato Purée, Minced Beef (15%), Chopped Tomatoes in Juice (14%) (Tomatoes, Tomato Juice), Dried Onions, Rapeseed Oil, Red Peppers, Green Peppers, Modified Maize Starch, Spices, Salt, Barley Malt Vinegar, Garlic Powder, Oregano. Contains Barley, Beef, Cereals Containing Gluten.'
        },
        {
            'id': 'lD1jWNGmaTZm5OCHlPYo',
            'name': 'Confiture De Gingembre',
            'brand': 'Harrods',
            'serving_size_g': 20.0,
            'ingredients': 'Sugar, Ginger, Lemon Juice from Concentrate, Gelling Agent (Citrus Pectin). Prepared with 64g of Fruit per 100g. Total Sugar Content 67g per 100g.'
        },
        {
            'id': 'La7a88V3bsMRgLmLKCHk',
            'name': 'Curry Powder Mild',
            'brand': 'Stonemill',
            'serving_size_g': 9.0,
            'ingredients': 'Ground Coriander Seeds (32%), Cumin (14%), Ground Fenugreek, Mustard Flour, Garlic Powder, Ginger, Salt, Turmeric (4.5%), Ground Bay Leaf, Cayenne Pepper, Black Pepper, Ground Cinnamon, Ground Nutmeg, Cloves. Contains Mustard.'
        },
        {
            'id': 'Ra9LVY0CaUCgiXyoypOU',
            'name': 'Asda Essential Self Raising Flour',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Raising Agents (Calcium Phosphate, Sodium Carbonates). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '2qgKwGJ4ojJS1bViASh0',
            'name': 'Golden Crispy Potatoes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (94%), Sunflower Oil (4%), Rice Flour, Potato Starch, Potato Dextrin, Salt, Dextrose, Turmeric.'
        },
        {
            'id': 'NHzv1FRoZE3evdeim59q',
            'name': 'Raspberry Sorbet',
            'brand': 'Tesco',
            'serving_size_g': 64.0,
            'ingredients': 'Water, Raspberry Purée (20%), Dextrose, Sugar, Lemon Juice, Glucose Syrup, Invert Sugar Syrup, Colour (Anthocyanins), Maltodextrin, Flavouring, Emulsifier (Mono- and Di-glycerides of Fatty Acids), Acidity Regulators (Citric Acid, Trisodium Citrate), Citrus Fibre, Stabiliser (Xanthan Gum), Glucose. May Contain Peanuts, Nuts, Milk.'
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

    total_cleaned = 486 + updates_made

    print(f"✨ BATCH 40 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 500:
        print(f"\n🎉🎉🎉 500 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {550 - total_cleaned} products until 550!\n")
        print(f"💪 We've cleaned over 10% of the ~4,846 identified messy products!")
    else:
        remaining_to_500 = 500 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_500} products until 500!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch40(db_path)
