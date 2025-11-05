#!/usr/bin/env python3
"""
Clean ingredients batch 12 - Asda Products
"""

import sqlite3
from datetime import datetime

def update_batch12(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 12 (Asda Products)\n")

    clean_data = [
        {
            'id': 'I26J4XUyJa32XVCyhwKr',
            'name': 'Mini Frieda Caterpillar Cakes',
            'brand': 'Asda',
            'serving_size_g': 51.0,  # Per cake (4 x 51g = 204g approx in 200g pack)
            'ingredients': 'Belgian Dark Chocolate 28% (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithins), Flavouring), Icing Sugar, White Chocolate Flavour Decorations 11% (Sugar, Cocoa Butter, Rice Syrup, Rice Starch, Rice Flour, Coconut Oil, Emulsifier (Lecithins), Flavouring), Water, Sugar, Palm Oil, Rapeseed Oil, Multi-Coloured Sugar Decorations 4% (Sugar, Rice Flour, Coconut Oil, Water, Shea Oil, Thickener (Cellulose Gum), Fruit and Vegetable Concentrates (Spirulina, Radish, Apple, Blackcurrant), Flavouring, Colours (Paprika Extract, Lutein, Curcumin)), Maize Starch, Fat-Reduced Cocoa Powder, Tapioca Starch, Rice Flour, Sunflower Oil, Soya Flour, Oat Flour, Raising Agents (Diphosphates, Sodium Carbonates), Brown Flax Seeds, Humectant (Glycerol), Flavourings, Emulsifiers (Soya Lecithins, Mono- and Diglycerides of Fatty Acids), Thickener (Xanthan Gum), Salt, Preservative (Potassium Sorbate), Psyllium. Free From: Eggs, Milk. Contains: Oats, Soya. Gluten free. Suitable for Vegans.'
        },
        {
            'id': 'psIO7o9BCGeaSrsg8BZQ',
            'name': 'Iced Mince Pies',
            'brand': 'Asda',
            'serving_size_g': 50.0,  # Estimated per pie (6-pack)
            'ingredients': 'Mincemeat Filling (39%) (Sugar, Bramley Apple Purée, Raisins (18%), Sultanas (8.9%), Glucose Syrup, Humectant (Glycerol), Dextrose, Apricot Filling, Mixed Peel, Currants (1.7%), Palm Oil, Rapeseed Oil, Ground Mixed Spices (Cinnamon, Coriander, Caraway, Fennel, Nutmeg, Cloves, Ginger, Turmeric), Acids, Barley Malt Extract, Flavouring), Icing (28%) (Sugar, Glucose Syrup, Sweetened Condensed Skimmed Milk, Vegetable Oils/Fats, Emulsifiers, Citric Acid, Egg White, Glycerol, Preservative), Wheat Flour (with Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Rapeseed Oil, Sugar, Salt, Dextrose, Preservative. Contains: Eggs, Gluten, Milk, Sulphur Dioxide/Sulphites, Wheat. Traditional mince pies with sweet mincemeat filling topped with icing.'
        },
        {
            'id': 'vjjtmQqhXsaFhzP5xuNr',
            'name': 'Plant Based Lentil Cottage Pie',
            'brand': 'Asda',
            'serving_size_g': 400.0,  # Full ready meal pack
            'ingredients': 'Potatoes (35%), Water, Sweet Potato (12%), Carrots, Red Wine, Tomatoes, Green Lentils (4%), Onions, Swede, Tomato Passata, Garlic Purée, Cornflour, Worcester Sauce (Water, Spirit Vinegar, Brown Sugar, Tamarind Extract, Spices, Onion Powder, Garlic, Concentrated Lemon Juice), Mushroom Concentrate, Salt, Yeast Extract, Red Wine Vinegar, Sugar, Rapeseed Oil, Malted Barley Extract, Herbs, Onion Concentrate, Spices. Lentils and vegetables in red wine and tomato sauce, topped with potato and sweet potato mash. Source of protein. Low in saturated fat. Suitable for vegans. Contains: Gluten. May Contain: Milk. NO ARTIFICIAL COLOURS, FLAVOURS OR HYDROGENATED FAT.'
        },
        {
            'id': 'xAmGo0tNp2kRWsukh0v2',
            'name': 'Cheese Bites',
            'brand': 'Asda',
            'serving_size_g': 12.0,  # Per bite (12 bites per 144g pack)
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Extra Mature Cheddar Cheese (Milk) (17%), Full Fat Soft Cheese (17%) (Full Fat Soft Cheese (Milk), Salt), Mashed Potato (Potatoes, Milk, Unsalted Butter (Milk), Salt, White Pepper), Rapeseed Oil, Caramelised Onion (6%) (Onions, Rapeseed Oil, Brown Sugar (Sugar, Molasses)), Red Leicester Cheese (3%) (Leicester Cheese (Milk), Colour (Carotenes)), Potato Starch, Wheat Starch, Yeast, Onion Powder, Salt, Stabiliser (Methyl Cellulose), Dextrose, Garlic Powder, Black Pepper Extract, White Pepper, Flour Treatment Agent (Ascorbic Acid). Extra mature Cheddar cheese, full fat soft cheese, caramelised onion and Red Leicester cheese in crispy breadcrumb coating. Ready to Eat Hot or Cold. No Artificial Colours, Flavours or Hydrogenated Fat. Suitable for vegetarians. Contains: Eggs, Milk, Sesame, Wheat.'
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

    print(f"✨ BATCH 12 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {41 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch12(db_path)
