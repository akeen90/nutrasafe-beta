#!/usr/bin/env python3
"""
Clean ingredients and update serving sizes for scanned products
Batch 1: Verified products from online sources
"""

import sqlite3
from datetime import datetime

def update_clean_ingredients(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 1\n")
    print("=" * 80)

    # Verified clean ingredient data from official sources
    clean_data = [
        {
            'id': 'iyBCJY0WKbqxO0Xd9nPo',
            'name': 'Crispello',
            'brand': 'Cadbury',
            'serving_size_g': 36.0,  # UK version is 36g per bar
            'ingredients': 'Sugar, Full Cream Milk Powder, Cocoa Mass, Cocoa Butter, Non-hydrogenated Vegetable Oils (Palm Fruit, Shea Nut) (5% max), Emulsifiers (E476, E442), Natural And Artificial Flavours (Butter, Vanillin). May contain tree nuts, barley (gluten).'
        },
        {
            'id': 'nbFjKlGB8scUeTyvGMMQ',
            'name': 'Indulgent Chocolate Cake',
            'brand': 'Galaxy',
            'serving_size_g': 57.0,  # 12 portions per pack, approx 57g each
            'ingredients': 'Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Egg, Galaxy Ripple (4%) (Sugar, Cocoa Butter, Milk Powder, Cocoa Mass, Palm Fat, Milk Fat, Lactose, Whey Permeate, Emulsifiers (Soya Lecithin, E476), Vanilla Extract), Palm Oil, Galaxy Milk Chocolate Counters (3%), Fat Reduced Cocoa Powder, Glucose Syrup, Humectant (Vegetable Glycerine), Cream (Milk), Galaxy Milk Chocolate (2%), Marbled Chocolate Curls (2%), Maize Starch, Palm Kernel Oil, Cocoa Mass, Wheat Starch, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate), Whey Powder (Milk), Emulsifiers (Mono and Diglycerides of Fatty Acids, Soya Lecithin, E476), Cocoa Butter.'
        },
        {
            'id': 'vJQjQRGa08W0oFD1O6N4',
            'name': 'Dairy Milk Caramel Layer Cake',
            'brand': 'Cadbury',
            'serving_size_g': 52.0,  # Serves 8, approx 52g per serving
            'ingredients': 'Caramel Flavour Filling (23%) (Sugar, Vegetable Margarine (Vegetable Oils (Palm, Rapeseed), Water, Emulsifier (E471)), Glucose Syrup, Water, Icing Sugar, Maize Starch, Humectant (Glycerol), Colour (Plain Caramel), Dried Egg White, Emulsifier (E471), Flavourings), Milk Chocolate (18%) (Sugar, Cocoa Mass, Cocoa Butter, Dried Skimmed Milk, Milk Fat, Vegetable Fat (Palm), Dried Whey (from Milk), Emulsifier (Soya Lecithin)), Caramel Sauce (13%) (Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar, Lactose (Milk)), Unsalted Butter, Sugar, Invert Sugar Syrup, Glucose Syrup, Water, Humectant (Glycerol), Flavourings, Salt, Gelling Agents (Pectin, E401), Preservative (Potassium Sorbate)), Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Glucose Syrup, Sugar, Mini Milk Chocolate Buttons (4.5%) (Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifier (E442), Flavourings), Humectant (Glycerol), Fat Reduced Cocoa, Soya Flour, Milk Chocolate Curls (1.5%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Dried Whey (from Milk), Lactose (Milk), Emulsifier (Soya Lecithin), Flavouring). Contains: Eggs, Milk, Soya, Wheat. May contain nuts.'
        }
    ]

    updates_made = 0

    for product in clean_data:
        # Update the product with clean data
        cursor.execute("""
            UPDATE foods
            SET
                ingredients = ?,
                serving_size_g = ?,
                updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Old serving: 100g → New serving: {product['serving_size_g']}g")
            print(f"   Ingredients cleaned ✓\n")
            updates_made += 1

    conn.commit()
    conn.close()

    print("=" * 80)
    print(f"✨ BATCH 1 COMPLETE: {updates_made} products cleaned\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_clean_ingredients(db_path)
