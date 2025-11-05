#!/usr/bin/env python3
"""
Clean ingredients batch 31 - Continuing Toward 300 Milestone
"""

import sqlite3
from datetime import datetime

def update_batch31(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 31 (Building to 300!)\\n")

    clean_data = [
        {
            'id': 'NAeuTbLhE8TWXPySlloX',
            'name': 'British Ham & Dijon Mustard Hand Cooked Potato Crisps',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (63%), High Oleic Sunflower Oil (30%), British Ham and Dijon Mustard Flavour Seasoning (7%) (Rice Flour, Sugar, Salt, Dried Onion, Dried Dijon Mustard, Dried Yeast, Dried Bay, Natural Flavouring, Acid (Citric Acid), Dried Clove, Rosemary Extract, British Cooked Ham Extract). Contains Mustard.'
        },
        {
            'id': 'BWTSnqbwCjWYLBRVoUdd',
            'name': 'Orange Squash',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Orange Juice from Concentrate (10%), Citric Acid, Stabilisers (Acacia Gum, Sucrose Acetate Isobutyrate, Glycerol Esters of Wood Rosins), Sweeteners (Aspartame, Sodium Saccharin), Preservatives (Potassium Sorbate, Sodium Benzoate), Acidity Regulator (Sodium Citrate), Antioxidant (Ascorbic Acid), Colour (Carotenes). Contains a Source of Phenylalanine.'
        },
        {
            'id': 'BJaP12O7PIlsFP8RfwVj',
            'name': 'Spinach & Ricotta Cannelloni',
            'brand': 'Chef Select',
            'serving_size_g': 381.0,
            'ingredients': 'Whole Milk, Cooked Egg Pasta Sheet (Durum Wheat Semolina, Water, Pasteurised Liquid Free Range Egg, Dried Free Range Egg White), Spinach, Water, Tomato, Ricotta Full Fat Whey Cheese (Milk), Cornflour, Rapeseed Oil, Single Cream (Milk), Tomato Paste, Mature Cheddar Cheese (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Medium Fat Hard Cheese (Milk), Onion, Carrot, Celery, Mozzarella Cheese (Milk), Salt, Sugar, Basil Infused Sunflower Oil (Sunflower Oil, Basil), Garlic Purée, Nutmeg, Thickener (Pectin), Oregano, White Pepper, Ground Bay Leaf, Rosemary, Black Pepper. Contains Celery, Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': 'z5ESOijepeOUpq25QyrD',
            'name': 'Mushroom Antipasti',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mixed Mushrooms (Shiitake, Nameko, Wine Cap, Straw), Sunflower Oil, Sea Salt, Sugar, Extra Virgin Olive Oil (1%), Garlic, Oregano, Acidity Regulator (Lactic Acid), Garlic Powder, White Wine Vinegar, Dried Parsley, Antioxidant (Ascorbic Acid), Garlic Extract, Parsley Extract, Laurel.'
        },
        {
            'id': '7rjDZ1OfS4RyNHNhaBnP',
            'name': 'Real Mayonnaise',
            'brand': 'Stokes',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil (75%), Free Range Pasteurised Whole Egg (12%), Water, Extra Virgin Olive Oil (5%), Unrefined Raw Cane Sugar, Acid (Acetic Acid), Sea Salt, Mustard. Contains Eggs, Mustard.'
        },
        {
            'id': 'UocUKRLUNwXr7DOspde1',
            'name': 'Organic Extra Virgin Olive Oil Spray',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Extra Virgin Olive Oil (53%), Water, Organic Alcohol, Emulsifier (Organic Sunflower Lecithin), Preservative (Citric Acid), Thickener (Xanthan Gum).'
        },
        {
            'id': 'j1hJwdLFlkmMR8A8LpFH',
            'name': 'Crunchy Vanilla Biscuits',
            'brand': 'Plants',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Coconut Oil, Beet Sugar, Rice Flour, Water, Rolled Oats, Oat Flour, Salt, Madagascan Vanilla Extract. Contains Cereals Containing Gluten, Oats, Wheat.'
        },
        {
            'id': 'OY10eRYNlInSXvQpK7TQ',
            'name': 'Chicken Liver Pâté',
            'brand': 'Castle MacLellan',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Liver (34%), Pork Fat, Water, Single Cream (Milk), Rice Starch, Heather Honey (2%), Potato Starch, Salt, Parsley, Thyme, Antioxidant (Ascorbic Acid), Black Pepper, Preservative (Sodium Nitrate). Contains Milk, Pork.'
        },
        {
            'id': 'dOdfEF1G3n09NjGmjJSi',
            'name': 'Cheese & Bacon Potato Skins',
            'brand': 'Bannisters Yorkshire Family Farm',
            'serving_size_g': 65.0,
            'ingredients': 'British Potato (70%), Water, White Mature Cheddar Cheese (8%) (Milk), Smoky Bacon (5%) (Pork, Water, Salt, Sugar, Smoke Flavouring, Preservative (Sodium Nitrite)), Sunflower Oil, Monterey Jack Cheese (3%) (Milk), Mustard Powder, White Pepper. Contains Milk, Mustard, Pork.'
        },
        {
            'id': 'TEuFz3WcNz4axe6bDc8w',
            'name': 'Chocolate Filled Wafer Biscuits',
            'brand': 'Sondey',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Palm Fat, Sugar, Fat Reduced Cocoa Powder (3.8%), Dextrose, Potato Starch, Salt, Flavouring, Raising Agent (Sodium Carbonates). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'fLKi61NQyJBYEZW3bDI9',
            'name': 'Big Halkidiki Pitted Olives',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Green Olives, Water, Sea Salt, Acidity Regulators (Lactic Acid, Citric Acid).'
        },
        {
            'id': 'Lk2QQSvPPUIvUyz73DKD',
            'name': 'Sliced Cooked Chicken Tikka Breast',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (80%), Water, Salt, Dextrose, Stabilisers (Carrageenan, Triphosphates, Diphosphates), Milk Powder, Potato Starch, Sugar, Maltodextrin, Modified Maize Starch, Modified Tapioca Starch, Maize Starch, Dried Garlic, Dried Onion, Dried Tomato, Ground Coriander, Cumin, Ginger, Cayenne, Yeast Extract, Coriander Leaves, Acid (Citric Acid), Colour (Paprika Extract), Black Pepper, Ground Fennel Seeds, Ground Fenugreek, Thickener (Guar Gum), Natural Flavouring, Natural Capsicum Flavouring, Acidity Regulator (Sodium Diacetate), Anti-Caking Agent (Silicon Dioxide). Contains Milk.'
        },
        {
            'id': 'HH8VBWGIJZ67AGCIiQCy',
            'name': 'Eatz Sweet Chilli Mix',
            'brand': 'Snackrite',
            'serving_size_g': 22.5,
            'ingredients': 'Corn (41%), Broad Beans (23%), Sunflower Oil, Green Peas (9%), Rapeseed Oil, Sugar, Corn Starch, Modified Corn Starch, Rice Flour, Salt, Chilli Powder, Garlic Powder, Onion Powder, Tomato Powder, Yeast Extract, Acidity Regulator (Citric Acid), Flavouring, Ground Ginger, Ground Basil, Fennel Seeds, Paprika Extract, Star Anise, White Pepper. May Contain Nuts, Peanuts, Celery, Crustaceans, Cereals Containing Gluten, Milk, Mustard, Sesame, Soya, Sulphites.'
        },
        {
            'id': 'xm997cPlWS0is7hLpZeH',
            'name': 'Lemon Curd Yogurt',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (Milk), Lemon Curd (24%) (Sugar, Water, Butter (Milk), Pasteurised Egg, Lemon Juice, Cornflour, Flavouring, Lemon Oil, Salt, Colour (Lutein)), Sugar. Contains Eggs, Milk.'
        },
        {
            'id': 'xe9I0deekfymgOGTn1S1',
            'name': 'Organic White Beans',
            'brand': 'Bold Bean Co',
            'serving_size_g': 100.0,
            'ingredients': 'Organic White Beans, Water, Salt.'
        },
        {
            'id': '5FqE05xtrr1kaF40jIAZ',
            'name': 'Meat Free Bisto Gravy',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Dried Glucose Syrup, Salt, Rapeseed Oil, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Mushroom Stock (2.5%) (Mushroom Concentrate, Rapeseed Oil, Glucose Syrup, Salt, Flavourings), Colour (Ammonia Caramel), Sugar, Onion Powder, Potassium Chloride, Emulsifier (Soya Lecithin), Black Pepper Extract, Onion Oil, Rosemary Extract. Contains Soybeans. May Contain Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'L607IoV8eKFCgA5TE9uA',
            'name': 'Hearty Dumplings',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Suet (Non Hydrogenated Palm Oil, Rapeseed Oil, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin)), Baking Powder (Raising Agents (Sodium Diphosphate, Sodium Bicarbonate), Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin)), Salt, Pepper. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'JopKYmhoMIEYkvWaLQBE',
            'name': 'Thick Sliced Corned Beef',
            'brand': 'Asda',
            'serving_size_g': 30.0,
            'ingredients': 'Beef, Salt, Sugar, Preservative (Sodium Nitrite). Made with 120g of Beef per 100g of Finished Product. Contains Beef.'
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

    total_cleaned = 253 + updates_made

    print(f"✨ BATCH 31 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    remaining_to_300 = 300 - total_cleaned
    if remaining_to_300 > 0:
        print(f"🎯 Next milestone: {remaining_to_300} products until 300!\\n")
    else:
        print(f"\\n🎉🎉🎉 300 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {350 - total_cleaned} products until 350!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch31(db_path)
