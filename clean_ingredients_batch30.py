#!/usr/bin/env python3
"""
Clean ingredients batch 30 - BREAKING THE 250 MILESTONE!
"""

import sqlite3
from datetime import datetime

def update_batch30(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 30 (250 MILESTONE!)\\n")

    clean_data = [
        {
            'id': 'lVk2s6nJaoOCkePenngE',
            'name': 'Green Goddess Slaw',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (22%), Mayonnaise (21%) (Yogurt (Milk), Water, Rapeseed Oil, Potato Starch, Honey, Vinegar, White Wine, Dried Mustard, Vinegar, Pasteurised Egg Yolk, Salt, Citrus Fibre, Dried Egg White, Allspice, Turmeric), Broccoli (12%), Celeriac (Celery) (9%), Apples, Spinach, Salad Onions, Avocado (3%), Olive Oil, Pumpkin Seeds, Lemon Juice, Chives, Concentrated Apple Juice, White Wine Vinegar, Dill, Parsley, Mint, Coriander, Salt, Rapeseed Oil, Roasted Garlic Purée, Cracked Black Pepper. Contains Celery, Eggs, Milk, Mustard.'
        },
        {
            'id': 'jbWF4Ki1f0SNcSmdzygI',
            'name': 'Classic Lasagne',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Meat Sauce (59%) (Water, Minced Beef (17%), Tomato, Onions, Tomato Purée, Modified Maize Starch, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Flavouring (Starch, Flavouring, Colour (Paprika Extract), Salt, White Sugar, Maltodextrin, Sunflower Oil, Modified Maize Starch), Salt, White Sugar, Garlic Purée, Yeast Extract, Basil, Thyme, Oregano, Onion Powder, Black Pepper), White Sauce (23%) (Water, Milk, Half Cream, Modified Maize Starch), Cooked Pasta (15%) (Durum Wheat Semolina, Water), Cheddar Cheese (Milk) (2.7%) (Contains Colour (Annatto)). Contains Beef, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'UNThxKjTOhDxXdP2se9P',
            'name': 'Worcestershire Sauce Flavour Potato Crisps',
            'brand': 'Walkers',
            'serving_size_g': 25.0,
            'ingredients': 'Potatoes, Sunflower Oil, Rapeseed Oil, Worcestershire Sauce Flavour (Barley Malt Vinegar, Sugar, Flavourings, Salt, Onion Powder, Garlic Powder, Citric Acid, Potassium Chloride, Yeast Extract, Molasses, Colour (Plain Caramel)). Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': 'eahUzvR9jxRFGYxT4WbD',
            'name': 'Complete Chocolate Flavour',
            'brand': 'Myprotein',
            'serving_size_g': 500.0,
            'ingredients': 'Water, Milk Protein Concentrate, Coconut Oil, Soya Protein Isolate, Chicory Root Fibre, Fat Reduced Cocoa Powder, Vitamins and Minerals (Potassium Phosphate, Calcium Carbonate, Magnesium Citrate, Sodium Chloride, Vitamin C, Ferric Pyrophosphate, Zinc Sulphate, Vitamin E, Niacin, Manganese Sulphate, Calcium Pantothenate, Vitamin A, Copper Sulphate, Vitamin D, Vitamin B6, Vitamin B2, Vitamin B1, Folic Acid, Chromium Chloride, Potassium Iodide, Sodium Selenite, Biotin, Vitamin K, Vitamin B12), Flavouring, Thickener (Cellulose Gum, Gellan Gum), Sweetener (Sucralose), Emulsifier (Soya Lecithin). Contains Milk, Soybeans.'
        },
        {
            'id': 'RPyW6OZWylO4gBLUNN84',
            'name': 'Almond Drink Organic UHT',
            'brand': 'Sante',
            'serving_size_g': 250.0,
            'ingredients': 'Water, Almond (3%), Emulsifier (Sunflower Lecithin), Sea Salt. Contains Nuts.'
        },
        {
            'id': 'FeqaqwJGiwH1T74RgdGj',
            'name': 'Aero Hot Chocolate',
            'brand': 'Nestlé',
            'serving_size_g': 24.0,
            'ingredients': 'Sugar, Barley Malt Extract (25%), Fat Reduced Cocoa Powder (25%), Skimmed Milk Powder, Glucose Syrup, Coconut Oil, Lactose, Natural Flavouring, Acidity Regulator (E340), Thickeners (E466, E415), Salt. Contains Barley, Cereals Containing Gluten, Milk.'
        },
        {
            'id': 'Tj8zZzhqH6A90fdbzD7b',
            'name': 'Chicken Bites',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (55%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Maize Flour, Rapeseed Oil, Durum Wheat Semolina, Maize Starch, Salt, Pea Starch, Pea Fibre, Soya Protein Concentrate, Spices, Raising Agents (Diphosphates, Sodium Carbonates), Garlic Powder, Onion Powder, Stabiliser (Sodium Citrates), Yeast Extract, Yeast, Spice Extracts (Paprika Extract, Black Pepper Extract), Dextrose, Acidity Regulator (Citric Acid), Herbs, Colour (Curcumin). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'OYv6r5FcvHLSRJufW9Ed',
            'name': 'Wow Water',
            'brand': 'Wow Hydrate',
            'serving_size_g': 500.0,
            'ingredients': 'Water (93%), Collagen Peptides (2.5%), Natural Flavourings, Acidity Regulators (Citric Acid, Malic Acid), Sweetener (Sucralose), Colour (Black Carrot Extract), Vitamin Blend (Vitamin C, Vitamin B6, Vitamin D), Preservative (Sodium Benzoate).'
        },
        {
            'id': 'vmUDgsUL2kz8lZ7DJDQs',
            'name': 'Chicken Mini Fillets',
            'brand': 'Co-op',
            'serving_size_g': 152.0,
            'ingredients': 'Chicken Breast (64%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Rapeseed, Sunflower), Water, Wheat Starch, Lentil Flour, Maize Flour, Rice Flour, Spices (Smoked Paprika, Paprika, Black Pepper, Chilli Powder, Cayenne Pepper, White Pepper), Garlic Powder, Wheat Protein, Onion Powder, Tomato Powder, Yeast Extract, Sugar, Salt, Smoked Sea Salt, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate), Parsley, Yeast, Cocoa Butter, Colour (Paprika Extract), Capsicum Extract, Spirit Vinegar Powder, Flavouring, Black Pepper Extract, Ginger Extract, Lemon Powder, Thyme Extract, Cumin Extract. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'uLZI0S3Jr3RzfNDzu7Gf',
            'name': 'Lentil & Pea Veggie Cakes - Caramelised Onion Chutney Flavour',
            'brand': 'Kallø',
            'serving_size_g': 9.4,
            'ingredients': 'Lentil & Pea Cake (82%) (Red Lentil (76%), Green Pea (6%)), Rapeseed Oil, Caramelised Onion & Balsamic Vinegar Seasoning (7%) (Onion Powder (40%), Tapioca Maltodextrin, Salt, Rice Flour, Flavouring, Natural Flavouring, Sunflower Oil, Maltodextrin (Potato), Acid (Citric Acid), Balsamic Vinegar). May Contain Milk, Soya, Sesame Seeds.'
        },
        {
            'id': 'wQW0suc6unAKU1Hg27dT',
            'name': 'Breakfast Biscuits Blueberry & Raspberry',
            'brand': "Nairn's",
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Whole Grain Oats, Sustainable Palm Oil, Brown Sugar, Infused Dried Blueberries (Blueberry, Sugar, Sunflower Oil), Tapioca Starch, Invert Sugar, Leavening (Sodium Bicarbonate, Ammonium Bicarbonate), Raspberry Pieces (Raspberry, Apple Juice Concentrate, Citrus Pectin, Apple Powder), Currants (Currants, Sunflower Oil), Sea Salt, Natural Flavour. Contains Oats.'
        },
        {
            'id': 'ANrgaTZlgPTNiNhWFqJN',
            'name': 'Chicken Satay Sticks',
            'brand': 'Lidl',
            'serving_size_g': 10.0,
            'ingredients': 'Chicken (83%), Water, Rusk (Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin)), Dextrose, Rapeseed Oil, Yeast Extract, Salt, Maltodextrin, Sunflower Oil, Soy Extract (Water, Salt, Soya Beans, Wheat), Mustard Powder, Ground Ginger, Garlic Powder, Cayenne Pepper, Preservatives (Sodium Lactate, Sodium Acetates), Emulsifier (Diphosphates). Contains Cereals Containing Gluten, Mustard, Soybeans, Wheat.'
        },
        {
            'id': 'yCZcAOtrWwcRokBw2EQm',
            'name': 'No Added Sugar Squash',
            'brand': 'Vimto',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Mixed Fruit Juices from Concentrate (10%) (Apple, Blackcurrant, Grape, Raspberry), Acid (Citric Acid), Flavourings, Acidity Regulator (Sodium Citrate), Preservatives (Potassium Sorbate, Sodium Benzoate), Sweeteners (Sucralose, Acesulfame K), Stabilisers (Acacia Gum), Colouring Food (Concentrates of Carrot and Blackcurrant), Vitamin D.'
        },
        {
            'id': 'Xucps1Cb188U6mGKrPRa',
            'name': 'Hot Chocolate',
            'brand': 'Maltesers',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Barley Malt Extract (25%), Fat Reduced Cocoa Powder (10%), Whey Permeate (Milk), Glucose Syrup, Coconut Oil, Skimmed Milk Powder, Stabilisers (E412, E466, E340, E339, E452i), Anti-Caking Agent (E551), Salt, Potassium Chloride, Magnesium Sulphate, Milk Proteins, Emulsifiers (E471), Flavouring. Contains Barley, Cereals Containing Gluten, Milk.'
        },
        {
            'id': 'vsIxNrC99IprlAhev5A3',
            'name': 'Almond And Pecan Crunch Oat Granola',
            'brand': 'Rollagranola',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats, Zusto (Bulking Agent (Polydextrose), Soluble Maize Fibres, Chicory Fibres, Sweeteners (Isomalt, Erythritol, Sucralose)), Pecan Nuts (10%), Sunflower Seeds, Almonds (5%), Brazil Nuts, Pumpkin Seeds, Rapeseed Oil, Chia Seeds, Coconut Flakes, Vanilla (0.6%), Himalayan Pink Salt. Contains Nuts, Oats. May Contain Cereals Containing Gluten.'
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

    total_cleaned = 238 + updates_made

    print(f"✨ BATCH 30 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    if total_cleaned >= 250:
        print(f"\\n🎉🎉🎉 250 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {300 - total_cleaned} products until 300!\\n")
    else:
        remaining_to_250 = 250 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_250} products until 250!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch30(db_path)
