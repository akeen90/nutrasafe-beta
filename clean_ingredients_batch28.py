#!/usr/bin/env python3
"""
Clean ingredients batch 28 - Mixed Premium Brands
"""

import sqlite3
from datetime import datetime

def update_batch28(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 28 (Premium Brands Mix)\n")

    clean_data = [
        {
            'id': 'QgjZzkM7vlvVnVAocGyA',
            'name': 'New York Deli',
            'brand': 'Co-op',
            'serving_size_g': 211.0,
            'ingredients': 'Rye Bread (40%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rye Flour, Wheat Protein, Malted Barley Flour, Yeast, Salt, Spirit Vinegar, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Vegetable Oil (Rapeseed, Palm), Flour Treatment Agent (Ascorbic Acid), Palm Fat, Wheat Starch), Peppered Pastrami (22%) (Beef, Water, Salt, Dextrose, Pepper, Spice Extracts (Mace, Pimento, Ginger, Cayenne Pepper, Cardamom, Caraway), Brown Sugar, Stabilisers (Sodium Triphosphate, Sodium Polyphosphate), Cracked Black Pepper, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Monterey Jack Cheese (Milk) (8%), Vine Ripened Tomatoes (8%), Sauerkraut (6%) (White Cabbage, White Onion, White Wine Vinegar, White Sugar, Caraway Seeds), Mayonnaise (4%) (Water, Rapeseed Oil, Free Range Egg Yolk, Cornflour, Spirit Vinegar, Sugar, Dijon Mustard (Mustard Seeds, Spirit Vinegar, Salt), White Wine Vinegar, Salt), Gherkins (4%) (Gherkin, Water, Sugar, Spirit Vinegar, Salt, Acidity Regulator (Acetic Acid), Firming Agents (Calcium Chloride, Calcium Acetate), Flavouring), Apollo Lettuce (3%), Mustard (Spirit Vinegar, Mustard Flour, Mustard Bran, Cornflour, Salt, Ground Turmeric), Ground Black Pepper, Salt, Dried Onion, Onion Powder, Yeast Extract Powder, Rice Flour, Garlic Powder, Sunflower Oil. Contains Barley, Beef, Cereals Containing Gluten, Eggs, Milk, Mustard, Wheat. May Contain Sesame.'
        },
        {
            'id': '94DBjkYpvHAN7cAfkHeM',
            'name': 'Chicken Tikka Masala',
            'brand': 'Cook',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken (32%), Onions, Chopped Tomatoes (7%) (Tomato Juice), Coconut Milk (6%) (Coconut, Water), Double Cream (5%) (Milk), Tomato Purée (5%), Single Cream (Milk), Rapeseed Oil, Water, Creamed Coconut (3%), Sugar, Ground Almond (Nuts), Natural Yoghurt (Milk), Garlic, Ginger Purée, Coriander, Salt, Ground Garam Masala (Coriander, Cassia, Ginger, Cloves), Ground Coriander, Ground Cinnamon, Paprika, Lemon Juice Concentrate (Sulphites), Madras Powder (Coriander, Turmeric, Cumin, Black Pepper, Fenugreek, Garlic, Salt, Fennel, Mustard, Chilli), Chilli Powder, Ground Bay Leaf, Ground Cumin, Ground Cardamom. Contains Milk, Nuts, Sulphites, Mustard.'
        },
        {
            'id': 'nGoYDiLdH6xsrmxUcbbc',
            'name': 'Meatballs & Spaghetti',
            'brand': 'Cook',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Spaghetti (21%) (Durum Wheat Semolina, Water), Chopped Tomatoes (13%) (Tomato Juice, Acidity Regulator (Citric Acid)), Beef (10%), Pork (9%), Onion, Tomato Juice (3%) (Tomatoes, Salt, Acidity Regulator (Citric Acid)), Carrots, Wheat Flour (with added Calcium Carbonate, Iron, Niacin, Thiamin), White Bread (Wheat Flour (with added Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Soya Flour, Salt, Wheat Protein, Vegetable Fat (Palm, Rapeseed), Preservative (Calcium Propionate), Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyltartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate), Flour Treatment Agent (Ascorbic Acid)), Tomato Purée, Unsalted Butter (Milk), Mediterranean Vegetable Stock (Partially Reconstituted Vegetables (Onion, Red Bell Pepper, Artichoke, Celeriac, Potato), Tomato Purée, Salt, Sugar, Maltodextrin, Sun-Dried Tomato Paste (Sunflower Oil, Salt, Natural Flavouring, White Wine Vinegar, Black Pepper), Rapeseed Oil. Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': 'GiXxq6DHj34H3Mco0Ea5',
            'name': 'Luxury Vanilla Cheesecake With Lotus Biscoff',
            'brand': 'English Cheesecake Company',
            'serving_size_g': 80.0,
            'ingredients': 'Biscuit Base (29%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Thiamin, Niacin), Vegetable Oils (Palm, Rapeseed), Sugar, Invert Sugar Syrup, Raising Agents (Sodium Carbonates, Sodium Hydrogen Carbonates), Salt), Double Cream (Milk), Reduced Fat Soft Cheese (Milk) (14%) (Skimmed Milk, Cream (Milk), Permeate, Salt, Tapioca Starch, Thickener (Xanthan Gum, Locust Bean Gum), Bacterial Starter Culture), Lotus Original Caramelised Biscuit Spread (13%) (Original Caramelised Biscuits (Wheat Flour, Sugar, Vegetable Oils (Palm Oil, Rapeseed Oil), Candy Sugar Syrup, Raising Agent (Sodium Hydrogen Carbonate), Soya Flour, Salt, Cinnamon), Rapeseed Oil, Sugar, Emulsifier (Soya Lecithin), Acid (Citric Acid)), Sugar, Full Fat Soft Cheese (Milk) (6%), Caramelised Biscuit (5%) (Wheat Flour, Sugar, Vegetable Oils (Palm, Rapeseed), Candy Sugar Syrup, Raising Agent (Sodium Carbonates), Soya Flour, Salt, Cinnamon), Starch, Partially Inverted Sugar Syrup, Milk, Tapioca. Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': 'qm0aLsrpqDD4ue71teNu',
            'name': 'Ristorante Primo Salame Piccante Njuda',
            'brand': 'Dr. Oetker',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (with Calcium, Niacin (B3), Iron, Thiamin (B1)), Tomato Purée, Mozzarella Cheese (11%), Water, Calabrese Salami (7%) (Pork, Pork Fat, Salt, Dextrose, Spices, Flavouring, Glucose Syrup, Spice Extracts, Antioxidants (Extracts of Rosemary, Sodium Ascorbate), Stabiliser (Sodium Nitrite), Smoke), Hot Honey Sauce (6%) (Water, Honey (1.5%), Golden Syrup, Waxy Maize Starch, White Wine Vinegar, Spices, Ginger Purée, Spice Extracts, Red Pepper, Vegetable Oil (Rapeseed)), Nduja Sausage (6%) (Pork, Pork Fat, Spices (Paprika, Chipotle Peppers, Smoked Paprika Powder, Chilli Powder, Black Pepper, Cayenne Pepper, Ground Fennel), Dried Red Pepper, Dextrose, Salt, Stabilisers (Diphosphates, Triphosphates), Cayenne Pepper, Acid (Lactic Acid), Colour (Paprika Extract), Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Preservative (Sodium Nitrite)), Red Peppadew Piquante Pepper (6%), Vegetable Oil (Rapeseed), Yeast, Sugar, Salt, Garlic, Basil, Parsley, Onions, Chilli Powder, Cayenne Pepper. Contains Cereals Containing Gluten, Milk, Pork, Wheat.'
        },
        {
            'id': 'SaExEpgmBlCcm4gF9GP1',
            'name': 'Triple Chocolate Cake',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Pasteurised Whole Egg, Unsalted Butter (Milk), Glucose Syrup, Humectant (Vegetable Glycerol), Fat Reduced Cocoa Powder, Galaxy Milk Chocolate (3%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey (Milk), Palm Fat, Whey Powder (Milk), Milk Fat, Emulsifier (Soya Lecithin), Vanilla Extract), White Chocolate (2.5%) (Sugar, Whole Milk Powder, Cocoa Butter, Skimmed Milk Powder, Emulsifier (Soya Lecithin), Flavouring), Pasteurised Egg White, Milk, Cornflour, Whipping Cream (Milk), Wheat Starch, Mini Galaxy Ripple (0.7%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose (Milk), Palm Fat, Whey Powder (Milk), Milk Fat, Emulsifier (Soya Lecithin), Vanilla Extract), Invert Sugar Syrup, White Chocolate Curls (0.5%) (Sugar, Cocoa Butter, Whole Milk Powder, Lactose (Milk), Whey Powder (Milk), Emulsifier (Soya Lecithin), Vanilla Extract), Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate), Skimmed Milk Powder, Preservative (Potassium Sorbate), Emulsifiers (Mono and Diglycerides of Fatty Acids, Polyglycerol Esters of Fatty Acids), Salt, Flavouring. Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': 'EQhv8eR3u2fGNxCP2A3s',
            'name': 'Premium Mini Mix',
            'brand': 'Gelatelli',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Sugar, Liquid Whey Concentrated (Milk), Water, Glucose Syrup, Coconut Fat, Cocoa Mass, Cocoa Butter, Butter Oil (Milk), Skimmed Milk Powder, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Lecithins, Polyglycerol Polyricinoleate), Stabilisers (Locust Bean Gum, Guar Gum, Pectins, Sodium Citrates), Caramelised Sugar Syrup, Condensed Skimmed Milk, Natural Flavourings, Salt, Natural Vanilla Flavouring, Caramelised Glucose Syrup. Contains Milk. May Contain Nuts.'
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

    print(f"✨ BATCH 28 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {221 + updates_made} / 681\n")
    print(f"🎯 Next milestone: {250 - (221 + updates_made)} products until 250!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch28(db_path)
