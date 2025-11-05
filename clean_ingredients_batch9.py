#!/usr/bin/env python3
"""
Clean ingredients batch 9 - Mixed Brands
"""

import sqlite3
from datetime import datetime

def update_batch9(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 9 (Mixed Brands)\n")

    clean_data = [
        {
            'id': 'cpc7kOTPJn8OOOsBq8Gz',
            'name': 'Delight Raspberry Rocky Road Imp',
            'brand': 'Alpen',
            'serving_size_g': 24.0,  # Per bar (5 x 24g pack = 120g)
            'ingredients': 'Cereals (31%) (Oats, Rice, Wheat, Malted Barley), Oligofructose Syrup, Milk Chocolate (14%) (Sugar, Cocoa Butter (Rainforest Alliance Certified), Skimmed Milk Powder, Cocoa Mass (Rainforest Alliance Certified), Milk Powder, Milk Fat, Emulsifier: Soya Lecithin), Shortbread Biscuit Pieces (6%), Raspberry Fruity Pieces (5%), Glucose Syrup, Marshmallows (4%), Chocolate (4%), Cereal Flours (Rice, Wheat, Malted Barley), Vegetable Oils (contains Sunflower and/or Rapeseed), Humectant (Glycerol), Sugar, Flavouring, Salt, Emulsifier (Soya Lecithin). Soft marshmallow, sweet raspberry, dark chocolate and shortcake biscuit with creamy rolled oats, wholegrain wheat flakes and crispy rice, dipped in smooth milk chocolate. 92 kcal per bar. High fibre, low salt, suitable for vegetarians.'
        },
        {
            'id': 'gBDLlWgSDysBx3xpYZBz',
            'name': 'Alpro Plant Protein, Red Berries',
            'brand': 'Alpro',
            'serving_size_g': 200.0,  # Per pot
            'ingredients': 'Soya Base (85%) (Water, Hulled Soya Beans (9.8%)), Sugar, Soya Protein Isolate, Strawberry-Red Currant-Raspberry Mix (2%) (Strawberry (0.8%), Red Currant (0.8%), Raspberry (0.4%)), Faba Bean Protein, Calcium (Tri-Calciumcitrate), Stabiliser (Pectins), Natural Flavourings, Modified Starch, Black Carrot Concentrate, Acidity Regulators (Citric Acid, Sodium Citrates), Vitamins (B12, D2), Live Cultures (S. Thermophilus, L. Bulgaricus). 100% plant-based, 15g protein per pot, naturally lactose-free, low in saturated fat, gluten free, suitable for vegans. May contain traces of Nuts (no Peanuts).'
        },
        {
            'id': 'ba4UlFOyaQBfYWjygkYk',
            'name': 'Asda Assorted Jam Tarts',
            'brand': 'Asda',
            'serving_size_g': 100.0,  # Estimated per tart (6 pack contains 2 blackcurrant, 2 apricot, 2 strawberry)
            'ingredients': 'Blackcurrant and Apple Flavoured Jam (50%) (Glucose-Fructose Syrup, Blackcurrant Purée, Apple, Citric Acid, Colour (Anthocyanins), Gelling Agent (Pectins), Acidity Regulator (Sodium Citrates), Preservatives (Potassium Sorbate, Sodium Metabisulphite), Flavouring), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Palm Oil, Rapeseed Oil, Glucose Syrup, Dextrose, Raising Agents (Diphosphates, Sodium Carbonates), Whey Powder (from Milk), Preservative (Potassium Sorbate), Milk Proteins. Pack contains: 2 Blackcurrant and Apple, 2 Apricot, 2 Strawberry tarts. Suitable for vegetarians. Contains Sulphur Dioxide/Sulphites and Wheat. May contain nuts.'
        },
        {
            'id': 'KDCycNKu4AJqpH9Sb6LD',
            'name': 'Strawberry Yoghurt',
            'brand': 'Arla Jord',
            'serving_size_g': 100.0,  # Per serving (plant-based oat product)
            'ingredients': 'Water, Oats (9%), Strawberries (3%), Sugar (2.1%), Maize Starch, Rapeseed Oil, Fava Bean Protein, Rice Starch, Maize Fibre, Gelling Agent (Agar), Salt, Beetroot Concentrate, Natural Flavourings, Thickener (Pectin), Natural Strawberry Flavour, Lemon Juice Concentrate, Fermentation Cultures (Streptococcus Thermophilus, Lactobacillus Delbrueckii Subsp. Bulgaricus). Plant-based yoghurt alternative. Enriched with Vitamin D and Folic Acid.'
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

    print(f"✨ BATCH 9 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {29 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch9(db_path)
