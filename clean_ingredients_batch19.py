#!/usr/bin/env python3
"""
Clean ingredients batch 19 - Cadbury, M&S & Tesco Products
"""

import sqlite3
from datetime import datetime

def update_batch19(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 19 (Cadbury, M&S & Tesco)\n")

    clean_data = [
        {
            'id': 'vJQjQRGa08W0oFD1O6N4',
            'name': 'Dairy Milk Caramel Layer Cake',
            'brand': 'Cadbury',
            'serving_size_g': 52.0,  # Per slice (approx 8 slices per cake)
            'ingredients': 'Caramel Flavour Filling (23%) (Sugar, Vegetable Margarine (Vegetable Oils (Palm, Rapeseed), Water, Emulsifier (E471)), Glucose Syrup, Water, Icing Sugar, Maize Starch, Humectant (Glycerol), Colour (Plain Caramel), Dried Egg White, Emulsifier (E471), Flavourings), Milk Chocolate (18%) (Sugar, Cocoa Mass, Cocoa Butter, Dried Skimmed Milk, Milk Fat, Vegetable Fat (Palm), Dried Whey (from Milk), Emulsifier (Soya Lecithin)), Caramel Sauce (13%) (Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar, Lactose (Milk)), Unsalted Butter, Sugar, Invert Sugar Syrup, Glucose Syrup, Water, Humectant (Glycerol), Flavourings, Salt, Gelling Agents (Pectin, E401), Preservative (Potassium Sorbate)), Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Glucose Syrup, Sugar, Mini Milk Chocolate Buttons (4.5%) (Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifier (E442), Flavourings), Humectant (Glycerol), Fat Reduced Cocoa, Soya Flour, Milk Chocolate Curls (1.5%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Dried Whey (from Milk), Lactose (Milk), Emulsifier (Soya Lecithin), Flavouring). Chocolate sponge layered with caramel filling and sauce, covered with milk chocolate. Contains Eggs, Milk, Soya, Wheat.'
        },
        {
            'id': 'Yp4TnL8uSaTREJoKf4Nd',
            'name': 'Colin The Caterpillar Cake',
            'brand': 'M&S',
            'serving_size_g': 62.5,  # Per slice (625g cake serves 10)
            'ingredients': 'Milk Chocolate (24%) (Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Lactose (Milk), Emulsifier: Soya Lecithin), Sugar, White Chocolate (12%) (Sugar, Dried Whole Milk, Cocoa Butter, Dried Skimmed Milk, Emulsifier: Soya Lecithin, Natural Vanilla Flavouring), Wheatflour (Fortified with Calcium, Iron, Niacin, Thiamin), Butter (Milk), Water, Dark Chocolate (3.5%) (Cocoa Mass, Sugar, Cocoa Butter, Fat Reduced Cocoa Powder, Emulsifier: Soya Lecithin), Pasteurised Egg, Sugar Coated Milk Chocolate Beans (3%), Fat Reduced Cocoa Powder, Dried Glucose Syrup, Rowan Extract, Pasteurised Egg White, Humectant: Glycerol, Dried Skimmed Milk, Dextrose. Chocolate Swiss roll filled with buttercream and chocolate chips. Contains Cereals Containing Gluten, Eggs, Milk, Soya, Wheat.'
        },
        {
            'id': 'mb9puFeD2rmbWlzsy9WC',
            'name': 'All Day Mexican Inspired Breakfast Wrap',
            'brand': 'Tesco',
            'serving_size_g': 300.0,  # Full wrap
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Black Turtle Beans, Water, Potato Rosti (11%) (Potato, Sunflower Oil, Potato Starch, Dehydrated Potato, Salt, Onion Powder, Dextrose, Flavouring, Starch, Maltodextrin, Rosemary Extract, Emulsifier (Mono- and Di-Glycerides of Fatty Acids), Stabiliser (Disodium Diphosphate), Antioxidants (Extracts of Rosemary, Citric Acid)), Tofu (Water, Soya Bean, Firming Agent (Magnesium Chloride)), Pinto Beans, Onion, Paprika Soya Chunks (Water, Soya Protein Concentrate). Wicked Kitchen vegan wrap with spicy beans, coconut oil cheese alternative, potato rosti, tofu and paprika soya protein chunks. Prepared to a vegan recipe. Contains Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'beW03V4ADBwirlMIMjoK',
            'name': 'Biscuit Tin',
            'brand': 'Tesco',
            'serving_size_g': 13.0,  # Per biscuit (400g tin approx 30 biscuits)
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Oil, Milk Chocolate (4.5%) (Sugar, Cocoa Mass, Cocoa Butter, Dried Skimmed Milk, Whey Powder (Milk), Butteroil (Milk), Palm Oil, Shea Fat, Sal Fat, Mango Kernel Fat, Emulsifier (Soya Lecithins)), Raspberry Jam (1.5%) (Glucose-Fructose Syrup, Invert Sugar Syrup, Sugar, Raspberry Purée, Gelling Agent (Pectin), Acidity Regulator (Sodium Citrate), Citric Acid), Glucose Syrup, Wholemeal Wheat Flour, Rolled Oats, Partially Inverted Refiners Syrup, Butter (Milk), Whey Powder (Milk), Fat Reduced Cocoa Powder, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate, Disodium Diphosphate), Whey Derivatives (Milk), Salt, Cocoa Powder, Flavourings, Emulsifier (Soya Lecithins). Teatime assortment of cream, chocolate and jam biscuits. Contains Cereals Containing Gluten, Milk, Oats, Soya, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': 'HzZuCfCMWARAaGOstKNO',
            'name': 'Chicken And Bacon Caesar Salad',
            'brand': 'Tesco',
            'serving_size_g': 265.0,  # Full pack
            'ingredients': 'Cooked Fusilli Pasta (Water, Durum Wheat Semolina), Romaine Lettuce, Chicken Breast (17%), Caesar Dressing (Water, Rapeseed Oil, Pasteurised Egg, Spirit Vinegar, Sugar, Parmigiano Reggiano Medium Fat Hard Cheese (Milk), Cornflour, Salt, Concentrated Lemon Juice, Garlic Purée, Malt Vinegar (Barley), Black Pepper, Black Treacle, Anchovy (Fish), Onion Powder, Sunflower Oil, Onion, Flavouring, Garlic Powder, Lemon Oil, Clove, Paprika, Red Chilli Powder), Parmigiano Reggiano Medium Fat Hard Cheese (Milk), Cooked Sweetcure Beechwood Smoked Bacon (3.5%) (Pork, Water, Sugar, Salt, Stabiliser (Sodium Triphosphate), Honey, Preservative (Sodium Nitrite)), Water, Sugar, Cider Vinegar, Salt, Rapeseed Oil, Potato Starch, Dextrose, Cornflour, Concentrated Lemon Juice, Garlic Purée, Sunflower Oil, Parsley, Chive, Black Pepper, Mustard Flour, Onion Powder, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Acidity Regulator (Citric Acid), Turmeric. Made using Thai chicken and British/EU pork. Contains Barley, Cereals Containing Gluten, Eggs, Fish, Milk, Mustard, Wheat.'
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

    print(f"✨ BATCH 19 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {75 + updates_made} / 681\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch19(db_path)
