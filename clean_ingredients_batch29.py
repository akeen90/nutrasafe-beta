#!/usr/bin/env python3
"""
Clean ingredients batch 29 - Continuing Toward 250 Milestone
"""

import sqlite3
from datetime import datetime

def update_batch29(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 29 (Pushing to 250!)\n")

    clean_data = [
        {
            'id': 'mgvh7KlEInsiMf1Ef9VR',
            'name': 'Flavoured Sparkling Beverage With Natural Mineral Water And Raspberry Juice',
            'brand': 'Aqua Carpatica',
            'serving_size_g': 100.0,
            'ingredients': 'Natural Mineral Water, Agave Syrup, Carbon Dioxide, Lemon Juice Concentrate (2.2%), Natural Flavouring, Raspberry Juice Concentrate (0.1%), Colouring Concentrate from Carrot.'
        },
        {
            'id': 'Q0B2RBZMUUSW1zdLszw8',
            'name': 'Blue Spark Original',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Sugar, Glucose-Fructose Syrup, Citric Acid, Taurine (0.4%), Acidity Regulator (Trisodium Citrate), Flavourings, Colour (Plain Caramel), Caffeine (0.03%), Preservative (Potassium Sorbate), B Vitamins (Niacin, Pantothenic Acid, Vitamin B6, Vitamin B12), Sweeteners (Acesulfame K, Sucralose), Inositol.'
        },
        {
            'id': 'B651uGj0XMXuHbWKEdka',
            'name': 'Pink & White Wafers',
            'brand': 'Caxton',
            'serving_size_g': 14.17,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Glucose Syrup, Invert Sugar, Gelatine, Soya Flour, Natural Colour (Beetroot), Sunflower Oil, Salt, Emulsifier (Soya Lecithin), Raising Agent (Sodium Bicarbonate), Skimmed Milk Powder, Natural Vanilla Flavour, Natural Colour (Annatto), Cornflour. Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': 'DEb1UiEvbaCf9azr9q8L',
            'name': 'Toffee Granola',
            'brand': 'Fuel',
            'serving_size_g': 173.0,
            'ingredients': 'Toffee Flavour Yogurt (84%) (Yogurt (Milk), Sugar, Glucose Syrup, Sweetened Condensed Milk (Milk, Sugar), Salted Butter (Milk), Tapioca Starch, Colour (Ammonia Caramel), Butter Oil (Milk), Modified Maize Starch, Sweetener (Sucralose), Salt, Preservative (Potassium Sorbate)), Granola with Dark Chocolate (16%) (Wholegrain Oat Flakes, Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Lecithins)), Cereal Crisps (Rice Flour, Wheat Protein, Sugar, Salt), Sugar, Glucose Syrup, Sunflower Oil, Wheat Protein, Wholegrain Wheat Flakes, Cocoa Powder, Fat Reduced Cocoa Powder, Caramelised Sugar Syrup, Dextrose, Vitamins (Vitamin E, Niacin, Pantothenic Acid, Vitamin B6, Thiamin, Riboflavin, Vitamin B12, Folic Acid), Flavourings, Salt, Antioxidant (Tocopherol-Rich Extract)). Contains Cereals Containing Gluten, Milk, Wheat. May Contain Nuts, Peanuts, Sesame, Soya.'
        },
        {
            'id': 'KDqLDsqT5yd3BvkbHgrz',
            'name': 'Jammie Dodgers Family Pack',
            'brand': 'Jammie Dodgers',
            'serving_size_g': 18.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Raspberry Flavour Apple Jam (27%) (Glucose-Fructose Syrup, Apples (Sulphites), Sugar, Humectant (Glycerol), Acid (Citric Acid), Acidity Regulator (Sodium Citrates), Flavourings, Colours (Anthocyanins, Annatto Norbixin), Gelling Agent (Pectin)), Vegetable Oils (Sustainable Palm, Rapeseed), Sugar, Partially Inverted Sugar Syrup, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavourings. Contains Cereals Containing Gluten, Sulphites, Wheat.'
        },
        {
            'id': 'QxUTqt7a6YwpbaJhgo8p',
            'name': 'Whip Bar',
            'brand': 'Bliss',
            'serving_size_g': 100.0,
            'ingredients': 'Chocolate (27%) (Sugar, Cocoa Mass, Cocoa Butter, Vegetable Fats (Palm, Shea), Milk Fat, Emulsifiers (Soya Lecithin, E476)), Sugar, Glucose Syrup, Bulking Agent (Polydextrose), Water, Fibres (Inulin, Bamboo), Crisped Cereal (6%) (Rice Flour, Sugar, Salt), Desiccated Coconut (4%), Vegetable Fats (Palm, Palm Kernel), Dried Egg White, Skimmed Milk Powder, Emulsifier (Sunflower Lecithin), Flavouring. Chocolate Contains Cocoa Solids 43% Minimum. Contains Eggs, Milk, Soybeans. May Contain Peanuts, Nuts.'
        },
        {
            'id': 'rVkoNgqte3pdbQ1DLeaf',
            'name': 'Rotisserie Chicken Flavour Seasoning',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Yeast Extract, Flavourings, Sugar, Maltodextrin, Roasted Onion Granules (4%), Garlic Powder, Anti-Caking Agent (Silicon Dioxide), Cracked Black Pepper, Sunflower Oil, Salt, Colour (Curcumin), Sage, Thyme.'
        },
        {
            'id': '5YBB0ncj40IP17fucjLY',
            'name': 'Penne',
            'brand': 'Asda',
            'serving_size_g': 180.0,
            'ingredients': 'Durum Wheat Semolina. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '9oCVhfKHJH9wcjh8GvFX',
            'name': 'The Skinny Tomato Ketchup',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomato Paste (20%), Thickeners (Citrus Fibre, Xanthan Gum), Salt, Acid (Citric Acid, Acetic Acid), Flavouring, Paprika, Sweetener (Sucralose), Preservatives (Potassium Sorbate, Sodium Benzoate), Colour (Caramel).'
        },
        {
            'id': 'oc3F5bESIvp97o86k14T',
            'name': 'Dark Chocolate Cranberries',
            'brand': 'Generic',
            'serving_size_g': 25.0,
            'ingredients': 'Dark Chocolate Coating (65%) (Sugar, Cocoa Mass, Palm Oil, Cocoa Butter, Whey Powder (Milk), Emulsifier (Sunflower Lecithin), Glazing Agents (Shellac, Gum Arabic)), Dried Sweetened Cranberries (35%) (Sugar, Cranberries, Sunflower Oil). Contains Milk.'
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

    print(f"✨ BATCH 29 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {228 + updates_made} / 681")

    remaining_to_250 = 250 - (228 + updates_made)
    if remaining_to_250 > 0:
        print(f"🎯 Next milestone: {remaining_to_250} products until 250!\n")
    else:
        print(f"🎉 250 MILESTONE ACHIEVED! {228 + updates_made} products cleaned!\n")
        print(f"🎯 Next milestone: {300 - (228 + updates_made)} products until 300!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch29(db_path)
