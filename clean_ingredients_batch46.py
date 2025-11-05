#!/usr/bin/env python3
"""
Clean ingredients batch 46 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch46(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 46\\n")

    clean_data = [
        {
            'id': '00yRfvfTq8kW2ojsETqH',
            'name': 'Garlic Mushroom Escalopes',
            'brand': 'Quorn',
            'serving_size_g': 116.0,
            'ingredients': 'Mycoprotein (37%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamine), Medium Fat Soft Cheese (Milk) (13%), Water, Vegetable Oils (Sunflower, Rapeseed), Cheese (Milk) (6%), Mushrooms (3%), Rehydrated Free Range Egg White, Wheat Starch, Milk Proteins, Natural Flavouring, Garlic Purée (0.8%), Wheat Semolina, Salt, Yeast, Firming Agents (Calcium Chloride, Calcium Acetate), Gelling Agent (Pectin). Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': '00z7gmqrkPTzIEYCXLgT',
            'name': 'Tesco Finest Christmas Pudding',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Vine Fruits (30%) (Sultanas, Raisins, Currants), Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cider (8%), Glacé Cherries (6%) (Cherry, Glucose-Fructose Syrup, Sugar, Colour (Anthocyanins), Acidity Regulator (Citric Acid)), Palm Oil, Brandy (4.5%), Humectant (Glycerol), Almonds, Amontillado Sherry (3%), Cognac (2%), Molasses, Ruby Port, Pecan Nuts, Single Cream (Milk), Rice Flour, Colour (Plain Caramel), Mixed Spices, Salt, Yeast, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Wheat Protein, Spirit Vinegar, Sunflower Oil, Rapeseed Oil, Orange Oil, Lemon Oil, Flour Treatment Agent (Ascorbic Acid), Palm Fat. Contains Cereals Containing Gluten, Milk, Nuts, Wheat. May Contain Eggs, Peanuts.'
        },
        {
            'id': '017eFV4LSUXLGticEv9N',
            'name': 'Garlic And Herb Flatbread',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Yeast, Spirit Vinegar, Wheat Gluten, Raising Agents (Diphosphates, Sodium Carbonates, Calcium Phosphates), Preservatives (Calcium Propionate, Potassium Sorbate), Garlic Powder, Stabiliser (Cellulose Gum), Salt, Dried Oregano, Dried Basil, Dried Marjoram, Acidity Regulator (Citric Acid), Dried Thyme, Wheat Starch. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '01iU4WcHuzuXhHI097Ta',
            'name': 'Belgian Chocolate Éclairs',
            'brand': 'Tesco',
            'serving_size_g': 39.0,
            'ingredients': 'Cream (Milk) (38%), Pasteurised Egg, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Rapeseed Oil, Belgian Milk Chocolate (6%) (Sugar, Dried Whole Milk, Cocoa Butter, Cocoa Mass, Emulsifier (Soya Lecithins), Flavouring), Belgian Dark Chocolate (3%) (Cocoa Mass, Sugar, Emulsifier (Soya Lecithins), Flavouring), Dextrose, Palm Oil, Dried Glucose Syrup, Milk Proteins, Stabiliser (Pectin). Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': '01mMrZX33kWj9PLyz7iu',
            'name': 'Cappuccino',
            'brand': 'Nescafe',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Capsule (73%) (Whole Milk Powder, Sugar, Emulsifier (Lecithins (Sunflower))), Coffee Capsule (27%) (Roast and Ground Coffee). Contains Milk. Coffee Capsule May Contain Milk.'
        },
        {
            'id': '02RJrEPGyy5U1g2aq6gI',
            'name': 'Easy Garlic',
            'brand': 'Cook By Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Garlic Purée (65%), Spirit Vinegar, Rapeseed Oil, Dried Garlic (5%), Salt, Acidity Regulator (Citric Acid), Stabiliser (Xanthan Gum), Preservative (Potassium Sorbate).'
        },
        {
            'id': '037qjzK0FM3pt30cZaXF',
            'name': 'All Butter Fruit And Oat Cookies',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Salted Butter (17%) (Butter (Milk), Salt), Sultanas (14%), Oats (10%), Diced Apricots (9%) (Apricots, Preservative (Sulphur Dioxide)), Demerara Sugar, Sugar, Oatmeal (6%), Desiccated Coconut (5%) (Desiccated Coconut, Preservative (Sodium Metabisulphite)), Partially Inverted Refiners Syrup, Raising Agents (Sodium Carbonates, Diphosphates, Ammonium Carbonates), Molasses. Contains Cereals Containing Gluten, Milk, Oats, Sulphites, Wheat. May Contain Nuts.'
        },
        {
            'id': '03NewAyBVhqQE94Jiglj',
            'name': 'No Chick Strips Hot And Spicy',
            'brand': 'The No Meat Company',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour, Sunflower Oil, Breadcrumbs (Wheat Flour, Yeast Extract, Extra Virgin Olive Oil, Cider Vinegar, Salt, Sugar), Protein Blend (4%) (Wheat Gluten, Wheat Starch, Pea Protein, Soya Protein Isolate (3%), Wheat Gluten (3%)), Potato Starch, Bamboo Fibre, Thickener (Methyl Cellulose), Modified Starch, Yeast Extract, Maize Starch, Salt, Colour (Paprika Extract), Acid (Citric Acid), Chilli, Dextrose, Sugar, Garlic, Flavourings, Onion, Chilli Extract, Raising Agent (Diphosphates, Sodium Carbonates). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '05SEN8G0L7FWklmeztxr',
            'name': 'Sriracha Hot Chilli Sauce',
            'brand': 'Taste Of Thailand',
            'serving_size_g': 15.0,
            'ingredients': 'Pickled Red Chilli (64%) (Red Chilli, Water, Garlic, Salt), Modified Maize Starch, Sugar, Salt, Acidity Regulators (Acetic Acid, Citric Acid), Yeast Extract, Preservative (Potassium Sorbate), Thickener (Xanthan Gum), Colour (Paprika Extract).'
        },
        {
            'id': '05tCBeycOaXRV90lvhXa',
            'name': 'Wotsits Crunchy Flaming Hot',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Vegetable Oils (Sunflower, Rapeseed), Flaming Hot Seasoning (Whey Powder (Milk), Sugar, Flavourings (contains Soya), Salt, Colour (Paprika Extract), Yeast Extract Powder, Acid (Citric Acid), Potassium Chloride). Contains Milk, Soybeans. May Contain Barley, Cereals Containing Gluten.'
        },
        {
            'id': '06NjmS3fls0nM77wPDK3',
            'name': 'Crystal Noodles Sweet Soy Glaze',
            'brand': 'Itsu',
            'serving_size_g': 73.0,
            'ingredients': 'Crystal Noodles (55%) (Pea Starch, Water, Mung Bean Starch), Broth Paste (44%) (Soy Sauce (40%) (Water, Soya Beans, Wheat, Salt, Alcohol), Mirin (Fermented Rice, Water, Maltose, Alcohol), Water, Yeast Extract, Sugar, Dashi Stock Powder (Salt, Maltose, Dried Bonito Powder (Fish), Protein Hydrolysate (Wheat), Yeast Extract Powder, Kombu Powder), Reduced Sodium Salt (Potassium Chloride, Salt), Cayenne Pepper, Leek). Contains Cereals Containing Gluten, Fish, Soybeans, Wheat.'
        },
        {
            'id': '07Y7kca36JaXPvb8MK8s',
            'name': 'Organic Unsalted Crunchy Peanut Butter',
            'brand': 'Equal Exchange',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Roasted Peanuts (100%). Contains Peanuts. Not Suitable for Peanut, Nut and Sesame Allergy Sufferers.'
        },
        {
            'id': '07q3t0bbj4TF3IiQJu4N',
            'name': 'Breaded Mini Fillets',
            'brand': 'Teaco',
            'serving_size_g': 148.0,
            'ingredients': 'Chicken Breast (64%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Wheat Gluten, Wheat Starch, Salt, Yeast Extract, Sugar, Yeast, Garlic Powder, Onion Powder, Paprika, Sourdough Culture (Wheat), White Pepper, Sunflower Oil, Sage, Cider Vinegar, Flavouring. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '08RF4r4xsHmiuukjvSHc',
            'name': 'Beef Gravy Granules',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Palm Oil, Salt, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Caramelised Sugar, Flavourings (contains Wheat), Red Onion (3.0%), Beef (10%), Onion Powder, Hydrolysed Maize Protein, Emulsifier (Soya Lecithin), Thyme Leaves, Black Pepper, Colour (Paprika Extract). Contains Beef, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '09iuMgYLBmQVvcyTShdx',
            'name': 'Mug Shot Heart-warming Roast Chicken Pasta',
            'brand': 'Mug Shot',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Pasta (65%) (Durum Wheat Semolina), Dried Glucose Syrup, Potato Starch, Whey Powder (from Milk), Flavourings (contain Wheat, Barley, Celery), Palm Oil, Dried Chicken (1.3%), Onion Powder, Salt, Milk Protein, Dried Rosemary, Dried Parsley, Stabiliser (Dipotassium Phosphate), Emulsifier (Mono- and Di-glycerides of Fatty Acids), Fortified Wheatflour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin). Contains Barley, Celery, Cereals Containing Gluten, Milk, Wheat. May Contain Eggs.'
        },
        {
            'id': '09xVEJDLJFd5YQf9ugp7',
            'name': 'Jordans Country Crisp Chocolate',
            'brand': 'Jordans',
            'serving_size_g': 45.0,
            'ingredients': 'Wholegrain Cereals (50%) (Oat Flakes, Oat Flour), Sugar, Barley Flakes, Dark Chocolate Curls (10%) (Cocoa Solids: 70% Minimum (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin), Natural Flavouring)), Vegetable Oil (Rapeseed and Sunflower in Varying Proportions), Rice Flour, Desiccated Coconut, Natural Flavouring. Contains Barley, Cereals Containing Gluten, Oats, Soybeans. May Contain Milk, Nuts.'
        },
        {
            'id': '0A7YEpU6cpxhhrQRnOfI',
            'name': 'Soured Cream',
            'brand': 'Cowbelle',
            'serving_size_g': 100.0,
            'ingredients': 'Pasteurised Soured Cream (Milk). Contains Milk.'
        },
        {
            'id': '0AEI0xqtNbqERVAY3X9h',
            'name': 'Chicken Dinner',
            'brand': 'Tesco',
            'serving_size_g': 371.0,
            'ingredients': 'Water, Potato, Chicken (19%), Peas (11%), Baby Carrots (11%), Sage and Onion Stuffing Ball (Water, Wheat Flour, Onion, Oats, Salt, Rapeseed Oil, Sage, Parsley, Yeast), Cornflour, Sunflower Oil, Butter (Milk), Yeast Extract, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Salt, Flavouring, Chicken Fat, Caramelised Sugar, Chicken Extract, Sage, Thyme, White Pepper. Contains Cereals Containing Gluten, Milk, Oats, Wheat.'
        },
        {
            'id': '0BUnrBxaku5WuNHntt5e',
            'name': 'Family Farm Little Yeos Fruity Favourites Yogurt 4 X 360g',
            'brand': 'Yeo Valley',
            'serving_size_g': 90.0,
            'ingredients': 'Peach: Organic Yogurt (Milk), Organic Peach Purée (5%), Organic Sugar (3.9%), Organic Maize Starch, Natural Flavouring, Organic Concentrated Lemon Juice. Apricot: Organic Yogurt (Milk), Organic Apricot Purée (5%), Organic Sugar (3.9%), Organic Maize Starch, Natural Flavourings, Organic Concentrated Lemon Juice. Strawberry: Organic Yogurt (Milk), Organic Strawberry Purée (5%), Organic Sugar (3.9%), Organic Maize Starch, Natural Flavouring, Organic Concentrated Lemon Juice. Raspberry: Organic Yogurt (Milk), Organic Raspberry Purée (5%), Organic Sugar (3.9%), Organic Maize Starch, Natural Flavouring, Organic Concentrated Lemon Juice. Contains Milk. Contains Live Cultures: Bifidobacterium, Lactococcus Cremoris, Streptococcus Thermophilus.'
        },
        {
            'id': '0BtSWxD5RqxmbPgiWUnQ',
            'name': 'Korean Style Rice Bowl',
            'brand': 'Plant Menu',
            'serving_size_g': 300.0,
            'ingredients': 'Water, Mushrooms, Carrot, Brown Rice (10%), Garlic Purée, Textured Soya Protein, Gochujang Paste (3.5%) (Jalapeño Peppers, Rice Flour, Red Chillies, White Wine Vinegar, Sugar, Salt, Mirin Rice Wine (Rice, Water, Glucose Syrup, Alcohol), Water, Soya Beans, Yeast Extract, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sunflower Oil, Acidity Regulator (Citric Acid)), Spring Onions, Cornflour, Soy Sauce (Water, Soya Beans, Salt, Spirit Vinegar), Sugar, Rapeseed Oil, Smoked Paprika. Contains Cereals Containing Gluten, Soybeans, Wheat.'
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

    total_cleaned = 551 + updates_made

    print(f"✨ BATCH 46 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch46(db_path)
