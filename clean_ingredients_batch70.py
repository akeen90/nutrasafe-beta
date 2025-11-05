#!/usr/bin/env python3
"""
Batch 70: Clean ingredients for 25 products
Progress: 1136 -> 1161 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch70(db_path: str):
    """Update batch 70 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '7OTjsaFkHgFRNw8sjzDv',
            'name': 'Rambler Mix',
            'brand': 'Grape Tree',
            'serving_size_g': 100.0,
            'ingredients': 'Almonds (31%), Thompson Raisins (Raisins, Sunflower Oil) (27%), Whole Apricots (Apricots, Sulphur Dioxide) (17%), Diced Crystallised Pineapple (Pineapple, Sugar, Citric Acid, Sodium Metabisulphite) (14%), Banana Chips (Banana Chips, Coconut Oil, Sugar, Banana Flavour) (11%).'
        },
        {
            'id': '7P5a3B1QHn29J4rZzXg9',
            'name': 'Pizza Loaded Pepperoni',
            'brand': 'Asda',
            'serving_size_g': 157.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Mozzarella Cheese (Milk) 27%, Tomato Purée, Pepperoni 7% (Pork 74%, Durum Wheat Semolina, Salt, Dextrose, Paprika Extract, Cayenne Pepper, Antioxidants (Extracts of Rosemary, Sodium Ascorbate), Garlic Powder, Paprika, Pepper Extract, Preservative (Sodium Nitrite)), Wheat Semolina, Water, Tomatoes, Rapeseed Oil, Maize, Sugar, Cheddar Cheese (Milk) 1%, Potato Starch, Garlic Purée, Yeast, Salt, Herbs, Wheat Flour.'
        },
        {
            'id': '7PN3M7SQtFsr1qjUXFRO',
            'name': 'Belgian Chocolate Mousse',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Milk, Whipping Cream (Milk) 25%, Dark Chocolate 25% (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithins)), Sugar, Dried Skimmed Milk, Beef Gelatine, Tapioca Starch.'
        },
        {
            'id': '7PgZaYZToEJy7ZMZboj6',
            'name': 'David Still Borrowing Your Car To Get To The Party',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Vegetable Oils (Rapeseed, Sunflower) in varying proportions, Saucy BBQ Flavour (Sugar, Maltodextrin, Salt, Ground Paprika, Onion Powder, Yeast Extract, Flavour Enhancers (Monosodium Glutamate, Disodium 5\'-ribonucleotide), Flavourings, Garlic Powder, Potassium Chloride, Tomato Powder, Lactose (Milk), Acid (Citric Acid), Colour (Paprika Extract), Smoke Flavouring, Sweetener (Saccharin)), Dried Potato.'
        },
        {
            'id': '7QyOgYxXDzeGIWTFQx6g',
            'name': 'Raspberry Ripple Whey Complete',
            'brand': 'Smart Protein',
            'serving_size_g': 30.0,
            'ingredients': 'Whey Protein Concentrate (Milk), Raspberry Juice Powder (Maltodextrin, Gum Acacia), Natural Flavours, Natural Colour (Beetroot Red), Anticaking Agent (Silicon Dioxide), Sweetener (Sucralose), DigeZyme Enzyme Complex (Amylase, Protease, Cellulase, Lactase, Lipase).'
        },
        {
            'id': '7SENfxOBBgeelzftkG4m',
            'name': 'Tomato & Mascarpone Stir Through Sauce',
            'brand': 'Specially Selected',
            'serving_size_g': 95.0,
            'ingredients': 'Mascarpone Cheese (21%) (Milk), Tomato (19%), Tomato Purée (18%), Sunflower Oil, Water, Onion, Garlic Purée, Modified Maize Starch, Sugar, Basil, Vegetable Stock (Iodised Salt (Salt, Potassium Iodide), Sugar, Potato Starch, Onion, Sunflower Oil, Spices (contains Celery), Soy Sauce (Soya Bean, Wheat, Salt), Leek, Maltodextrin, Celery, Parsley, Spice Extracts, Flavouring (contains Milk)), Iodised Salt (Salt, Potassium Iodide), Acidity Regulator (Citric Acid), Spices, Thickener (Locust Bean Gum).'
        },
        {
            'id': '7TPXqrC3u8qtoGrvVyNl',
            'name': 'Southern Fried Chicken Fries',
            'brand': 'Tesco',
            'serving_size_g': 87.0,
            'ingredients': 'Chicken Thigh (96%), Rapeseed Oil, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Semolina (Wheat, Wheat Starch, Wheat Gluten, Maize Flour, Wheat Protein, Salt, Rice Flour), Onion Powder, Black Pepper, Garlic Powder, Dextrose, Fennel, Yeast Extract, Sunflower Oil, White Pepper, Yeast, Black Pepper Extract, Garlic Extract, Nutmeg Extract, Onion Oil.'
        },
        {
            'id': '7TjbmtkZ6Q11fpoDjSU7',
            'name': 'Nduja & Mascarpone Sauce',
            'brand': 'Specially Selected',
            'serving_size_g': 175.0,
            'ingredients': 'Tomatoes (36%), Water, Mascarpone Cheese (Milk) (10%), Double Cream (Milk), Nduja Sausage Paste (9%) (Pork, Pork Fat, Spices (Chilli, Coriander, Jalapeño Chilli, Paprika), Thickener (Guar Gum), Acidity Regulator (Gluconodelta Lactone), Antioxidants (Rosemary Extract), Rice Starch, Salt, Spice Extracts (Chilli, Garlic, Paprika, Pepper)), Tomato Purée, Onion, Red Peppers (4%), Cornflour, Garlic Purée, Pecorino Cheese (Ewes Milk), Sugar, Basil, Salt, Cracked Black Pepper.'
        },
        {
            'id': '7U1zGyKTRKWSCLFK541l',
            'name': 'British Butter',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Butter (Milk), Salt 1.5%.'
        },
        {
            'id': '7V9ARspEv0n0iXr2ui06',
            'name': 'Easter Break',
            'brand': 'Kitkat',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Whey Powder (from Milk), Butterfat (from Milk), Emulsifier (Lecithins), Potato Starch, Raising Agent (Sodium Bicarbonate), Natural Flavourings, Cocoa, Salt, Whey Protein Concentrate, Vegetable Fats.'
        },
        {
            'id': '7Vgt7jukdrOidRX9wpIl',
            'name': 'Thai Green Curry',
            'brand': 'The Spice Tailor',
            'serving_size_g': 137.5,
            'ingredients': 'Coconut Cream (44%), Water, Lemongrass (5%), Galangal (3%), Garlic, Green Chilli, Kaffir Lime Leaves, Sweet Basil (2%), Sunflower Oil, Coriander, Dry Spices, Sugar, Salt, Raw Sugar, Rice Flour, Soy Sauce (Water, Soybeans, Wheat, Salt), Shallot Powder.'
        },
        {
            'id': '7VskWFwFEZFEMeKct8Ei',
            'name': 'NEW Packs OF 3X 2slices O Uze MILK Chocolate Ryvit',
            'brand': 'Ryvita',
            'serving_size_g': 13.0,
            'ingredients': 'Milk Chocolate (60%) (Cocoa Solids: 38% Minimum) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Emulsifier (Soya Lecithin), Natural Flavour), Crackerbread (40%) (Rice Flour, Corn Flour, Sea Salt).'
        },
        {
            'id': '7Vt3gKtFU4u926KYdrSP',
            'name': 'Madagascan Vanilla Yogurt',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '65% Yogurt (Milk), 17% Cream (Milk), 10.3% Sugar, Water, Modified Maize Starch, Natural Flavouring, Bourbon Vanilla Extract, Concentrated Carrot Juice, Thickener (Pectins), Exhausted Vanilla Bean Powder, Acidity Regulator (Citric Acid).'
        },
        {
            'id': '7X1wCGBFUsEGiU3O27AH',
            'name': 'Mini Snow Balls Chocolate Imp',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Mass, Cocoa Butter, Vegetable Fats (Palm, Shea), Whole Milk Powder, Emulsifiers (Lecithins, E443, E476), Rice Starch, Thickener (Gum Arabic), Flavourings, Maize Protein.'
        },
        {
            'id': '7XGbOZmVhpbntGhqlhNK',
            'name': 'Grated Mozzarella',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetarian Mozzarella Cheese (Milk), Potato Starch.'
        },
        {
            'id': '7Z87NT5pYxrPhGqZjtdw',
            'name': 'Honey Glazed Roast Ham Crisps',
            'brand': 'Walkers Sensations',
            'serving_size_g': 30.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), Ham Flavour (Sugar, Salt, Potassium Chloride, Flavourings, Onion Powder, Mixed Spices, Acidity Regulators (Lactic Acid, Calcium Lactate, Calcium Phosphates), Garlic Powder, Colour (Paprika Extract), Firming Agent (Calcium Lactate), Antioxidants (Rosemary Extract, Ascorbic Acid, Tocopherol Rich Extract, Citric Acid)).'
        },
        {
            'id': '7RJambUiHTQKD1d2SoEq',
            'name': 'Salad Cream',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rapeseed Oil, Sugar, Spirit Vinegar, Egg Yolk, Modified Maize Starch, Salt, Mustard Powder, Thickeners (Xanthan Gum, Guar Gum), Caramelised Sugar Syrup, Spices, Colour (Riboflavins).'
        },
        {
            'id': '7ZrxYbwitOh4JLismit2',
            'name': 'Red Leicester Organic',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Red Leicester Cheese (Cows\' Milk), Salt, Colour (Annatto Norbixin).'
        },
        {
            'id': '7aAedUCjFIAUGq44hWt2',
            'name': 'Grande Nachos',
            'brand': 'El Sabor',
            'serving_size_g': 100.0,
            'ingredients': 'Corn Flour 68%, Vegetable Oil (Palm), Condiment (Cheese Flavoring (contains Milk), Salt, Sugar, Flavor Enhancer (Monosodium Glutamate), Anticaking Agent (Silicon Dioxide), Acidity Regulator (Citric Acid), Color (Paprika Extract), Acidity Regulator (Malic Acid), Flavor Enhancers (Disodium Inosinate, Disodium Guanylate)), Water.'
        },
        {
            'id': '7aHaXpINtDaZK0OWxFFG',
            'name': 'Bitsa Wispa',
            'brand': 'Cadbury',
            'serving_size_g': 24.5,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifier (E442), Flavourings.'
        },
        {
            'id': '7bDgIBzgnbZfnur2iczE',
            'name': 'Chorizo & Chilli Cheddar Rollitos',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Chilli Cheddar Cheese 64% (Cheddar Cheese (Milk), Red Chilli Peppers, Red Peppers), Chorizo Pork Sausage 36% (Pork, Curing Salt, Salt, Preservative (Potassium Nitrate, Sodium Nitrite), Ground Smoked Paprika, Garlic Purée, Dextrose, Antioxidant (E301), Ground Nutmeg, Dried Oregano).'
        },
        {
            'id': '7blk5FIm3csvPW34leFV',
            'name': 'Toffee Mousses',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cream Mousse 35% (Whipping Cream, Milk, Sugar, Skimmed Milk Powder, Beef Gelatine, Tapioca Starch), Caramel Flavour Sauce 35% (Water, Sugar, Whipping Cream, Milk, Skimmed Milk Powder, Modified Maize Starch, Stabilisers (Xanthan Gum, Carrageenan), Colour (Plain Caramel), Glucose, Flavouring), Toffee Mousse 30% (Whipping Cream, Milk, Sugar, Water, Skimmed Milk Powder, Sweetened Condensed Skimmed Milk (Skimmed Milk, Sugar), Salted Butter (Butter, Milk, Salt), Glucose Syrup, Beef Gelatine, Maize Starch, Tapioca Starch, Flavouring, Colour (Plain Caramel), Vanilla Extract, Salt).'
        },
        {
            'id': '7cDIuGgGsm0w5JSaLEf9',
            'name': 'Double Choc Mocha',
            'brand': 'Alcafe',
            'serving_size_g': 32.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Glucose Syrup, Coconut Oil, Fat Reduced Cocoa Powder (9%), Instant Coffee (6%), Lactose (Milk), Stabiliser (Potassium Phosphates), Flavourings, Salt.'
        },
        {
            'id': '7cVKXQfTvnJDSDfbDByd',
            'name': 'Campbell\'s Cream Of Chicken Condensed Soup',
            'brand': 'Campbell\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rapeseed Oil, Modified Maize Starch, Chicken (4%), Wheat Flour (Contains Calcium Carbonate, Iron, Thiamin, Niacin), Milk Proteins, Salt, Double Cream (Milk), Dried Chicken Stock, Flavourings, Autolysed Yeast, Yeast Extract, Potato Starch, Spices, Sage Extract, Garlic Extract, Onion Oil.'
        },
        {
            'id': '7cdMTEnVLOdzwKklpR6D',
            'name': 'Beef Lasagna By Sainsbury\'s',
            'brand': 'Italian Style',
            'serving_size_g': 375.0,
            'ingredients': 'British Beef (23%), Cooked Lasagne Pasta (Durum Wheat Semolina, Water, Egg), Whole Cows\' Milk, Water, Tomato Passata, Tomato, Red Wine (4.5%), Carrot, Onion, Mushroom, Tomato Purée, Mature Cheddar Cheese (2%) (Cows\' Milk), Cornflour, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Single Cream (Cows\' Milk), Garlic Purée, Rapeseed Oil, Salt, Balsamic Vinegar (Red Wine Vinegar, White Wine Vinegar, Grape Must Concentrate), Sugar, Rosemary, Oregano, Black Pepper, Nutmeg, White Pepper, Bay Leaf.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (
            product['ingredients'],
            product['serving_size_g'],
            current_timestamp,
            product['id']
        ))

        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Serving: {product['serving_size_g']}g\n")

    conn.commit()
    conn.close()

    return len(clean_data)

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🧹 CLEANING INGREDIENTS - BATCH 70\n")

    cleaned_count = update_batch70(db_path)

    # Calculate total progress
    previous_total = 1136  # From batch 69
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 70 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1150 and previous_total < 1150:
        print(f"\n🎉 1150 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 17.8% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
