#!/usr/bin/env python3
"""
Batch 77: Clean ingredients for 25 products
Progress: 1311 -> 1336 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch77(db_path: str):
    """Update batch 77 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': 'A8ntPsUPFIlw12dzouG1',
            'name': 'Zero Sugar Oat Drink',
            'brand': 'Flahavan\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Oats (7%), Sunflower Oil, Stabiliser (Gellan Gum), Calcium Carbonate, Sea Salt, Vitamins (B2, B12, D2).'
        },
        {
            'id': 'AAM7Hygaim6Ee9a3yvbR',
            'name': 'Broccoli, Spinach & Ricotta Quiche',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Broccoli (16%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Extra Mature Cheddar Cheese (Milk), Pasteurised Free Range Egg, Ricotta Cheese (Milk) (8%), Spinach (5%), Palm Oil, Double Cream (Milk), Single Cream (Milk), Cornflour, Rapeseed Oil, Skimmed Milk Powder, Dried Free Range Egg, Salt, Black Pepper, Nutmeg, White Pepper.'
        },
        {
            'id': 'ABQLDBMl9M5ugmJmPKHR',
            'name': 'Strawberry & Lime',
            'brand': 'Kopperberg',
            'serving_size_g': 100.0,
            'ingredients': 'Premium Apple Cider Infused with Strawberry and Lime.'
        },
        {
            'id': 'ABdQDWxlUcGKe2NIvMv7',
            'name': 'Easter Mix',
            'brand': 'Bounty',
            'serving_size_g': 27.3,
            'ingredients': 'Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Palm Fat, Peanuts, Desiccated Coconut, Milk Fat, Wheat Flour, Lactose (Milk), Whey Permeate (Milk), Full Cream Milk Powder, Sunflower Oil, Barley Malt Extract, Emulsifiers (Soya Lecithin, E471), Fat-Reduced Cocoa Powder, Salt, Demineralised Whey Powder (Milk), Shea Fat, Humectant (Glycerol), Egg White Powder, Raising Agents (E341, E500, E501), Vanilla Extract, Wheat Gluten, Sweet Whey Powder (Milk).'
        },
        {
            'id': 'ACxOLqzTz8doRXgQ7MUx',
            'name': 'Bacon',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Pork, Salt, Sugar, Preservatives (Sodium Nitrite, Sodium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': 'ADQoac6vyD3uhgL89szc',
            'name': 'Duck And Orange Pate',
            'brand': 'Specially Selected',
            'serving_size_g': 34.0,
            'ingredients': 'Water, Duck Liver (20%), Pork Fat, Pork (14%), Pork Liver (9%), Tapioca Starch, Apricot Purée, Pork Rind, Sugar, Antioxidants (Potassium Lactate, Sodium Ascorbate, Citric Acid), Salt, Pork Gelatine, Glucose Syrup, Emulsifiers (Citric Acid Esters of Mono and Diglycerides of Fatty Acids, Glycerol), Bamboo Fibre, Orange Juice (0.5%), Dextrose, Roasted Onion, Tomato Purée, Milk Protein, Orange Liqueur, Spices, Preservatives (Potassium Acetates, Potassium Sorbate, Sodium Nitrite), Spice Extract, Thickeners (Xanthan Gum, Carrageenan), Flavourings, Orange Oil, Lemon Juice, Spirit Vinegar, Paprika Extract, Colour (Carotenes).'
        },
        {
            'id': 'ADa3PiOMHdpzQOEPAAW9',
            'name': 'Bistro Fish Pie',
            'brand': 'Asda',
            'serving_size_g': 350.0,
            'ingredients': 'Potatoes (48%), Whole Milk, Smoked Dyed Haddock (11%) (Haddock (Fish) (99%), Salt, Colours (Curcumin, Annatto Norbixin)), King Prawn (Crustacean) (9%), Salmon (Fish) (7%), Salted Butter (2%) (Butter (Milk), Salt), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Haddock Stock (Fish), Whipping Cream (Milk), Extra Mature Cheddar Cheese (Milk), Maize Starch, Mature Cheddar Cheese (Milk), Onions, White Wine, Salt, Sea Salt, Water, Cornflour, Lemon Juice, Waxy Maize Starch, Wheat Flour, Sunflower Oil, Rapeseed Oil, Preservative (Sodium Citrates), Parsley, Raising Agent (Sodium Carbonates), Olive Oil, White Pepper, Garlic Purée, Yeast, Spirit Vinegar, Mustard Flour, Bay Leaf Powder, Mustard Bran, Turmeric, Pimento, Black Pepper, Bay Leaves, Cinnamon Powder, Clove Powder.'
        },
        {
            'id': 'ADwJNczDy0iVmtmsxBk9',
            'name': 'Biscuits With A Sweet Caramel Crunch',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Butter (31%) (Milk, Salt), Soft Brown Sugar, Salted Caramel Pieces (5%) (Sugar, Glucose Syrup, Salted Butter (Milk, Salt), Palm Oil, Salt, Maize Starch, Natural Flavouring), Rice Flour, Sea Salt, Natural Flavouring, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate).'
        },
        {
            'id': 'AEWINzifVhrQpG8WdX64',
            'name': 'Chunky Veg Tomato',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (55%), Tomato Purée Concentrate (14%), Water, Courgettes (5%), Yellow Peppers (5%), Red Peppers (5%), Onions (2%), Sugar, Lemon Juice from Concentrate, Modified Maize Starch, Salt, Rapeseed Oil, Herbs, Garlic Purée, Acidity Regulator (Citric Acid), Ground Black Pepper.'
        },
        {
            'id': 'AEitjm1kyIxpbriCI5YZ',
            'name': 'Free From Onion & Herb Crackers',
            'brand': 'Tesco',
            'serving_size_g': 6.9,
            'ingredients': 'Gluten Free Oat Flour, Rice Flour, Maize Flour, Palm Oil, Tapioca Starch, Gluten Free Oat Flakes, Cornflour, Brown Rice Syrup, Sea Salt, Dried Onion, Raising Agent (Ammonium Hydrogen Carbonate), Herbs.'
        },
        {
            'id': 'AGVpTBzzfA1gx36Qtw2R',
            'name': 'Prawn Pasta Salad',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Short Penne Pasta (29%) (Durum Wheat Semolina, Water, Rapeseed Oil), Iceberg Lettuce (14%), Cooked Glazed Prawns (14%) (Prawn (Crustacean), Salt, Water), Cocktail Sauce (12%) (Water, Rapeseed Oil, Sugar, Cornflour, White Wine Vinegar, Tomato Purée, Pasteurised Egg Yolk, Spirit Vinegar, Concentrated Lemon Juice, Salt, Tomatoes, Mustard Flour, Distilled Barley Malt Vinegar, White Pepper, Sea Salt, Mustard Bran, Pimento, Ground Turmeric, Garlic Powder), Carrots (11%), Sweetcorn (9%), Cucumber, Water, White Wine Vinegar, Rapeseed Oil, Sugar, Paprika, Mustard Seed, Salt, Spirit Vinegar, Black Pepper, Extra Virgin Olive Oil, Stabiliser (Xanthan Gum), Garlic Purée.'
        },
        {
            'id': 'AI7lXncS3c94lveQknz5',
            'name': 'MADE TO Share Сабвичу Dairy MILK Creamy MILK Choco',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Milk Chocolate (18%) (Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifier (E442), Flavourings), Concentrated Buttermilk, Sugar, Palm Oil, Cream, Fat Reduced Cocoa Powder, Modified Maize Starch, Pork Gelatine, Emulsifiers (E471), Dried Whey (from Milk), Stabilisers (Pectin, E412), Salt.'
        },
        {
            'id': 'AIbIns4Cz96pkTW0NAZj',
            'name': 'Rice Crackles',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Rice (93%), Sugar, Salt, Iron, Niacin, Pantothenic Acid (B5), Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin D, Vitamin B12.'
        },
        {
            'id': 'AIfjwUQ0yNCKz3nbIFVs',
            'name': 'Fingers',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Wheat Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Sugar, Vegetable Fats (Palm, Shea, Sal), Cocoa Butter, Cocoa Mass, Partially Inverted Sugar Syrup, Emulsifiers (E442, Soya Lecithins, E476), Salt, Raising Agents (Ammonium Carbonates, Sodium Carbonates), Flavourings.'
        },
        {
            'id': 'AIi6PAikIxi1CEtzY1gg',
            'name': 'Just Essentials',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (67%), Water, Potato Starch, Salt, Sugar, Stabiliser (Phosphates), Spice (White Pepper, Coriander, Nutmeg, Mace), Antioxidant (Sodium Sorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': 'AJAH0qiCTKAARnK4Nkwv',
            'name': 'Squeaky Bean Nuggets',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Rehydrated Soya and Wheat Protein (56%), Cornflakes (Maize, Sugar, Salt, Barley Malt Extract), Sunflower Oil, Water, Wheat Starch, Vinegar, Thickener (Methylcellulose), Natural Flavourings, Wheat Flour, Sea Salt, Onion, Potato Fibres, Dried Glucose Syrup, Salt, Dextrose, Preservative (Sodium Diacetate), Maize Starch, Maltodextrin, Cumin Seed, Capsicum Extract, Rosemary Extract, Vitamins and Minerals (Iron, Vitamin B12).'
        },
        {
            'id': 'AJAQFJYfv2YtqkYAfnsF',
            'name': 'Anchovy Fillets',
            'brand': 'Nixe',
            'serving_size_g': 100.0,
            'ingredients': 'Anchovies (Fish), Olive Oil, Salt.'
        },
        {
            'id': 'AJHzq9grxTMxRH9UNBod',
            'name': 'Chinese Style Drumsticks And Thighs',
            'brand': 'Morrisons Global Grill',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Thigh (47%), Chicken Drumstick (47%), Sugar, Dried Glucose Syrup, Garlic Powder, Fennel Seed, Cornflour, Salt, Thickener (Guar Gum), Tomato Powder, Onion Powder, Yeast Extract Powder, Ginger, Flavouring, Cinnamon, Star Anise, Colour (Paprika Extract), Acid (Citric Acid), Clove.'
        },
        {
            'id': 'AKH5gawdviirzSmfy4uY',
            'name': 'Potato & Leek Soup',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Potato (23%), Leek (12%), Onion, Rapeseed Oil, Maize Starch, Skimmed Milk Powder, Double Cream (Milk), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sea Salt, Emulsifier (Polyphosphates), Sugar, Black Pepper.'
        },
        {
            'id': 'AKmvDTHcx84ImPDA18rH',
            'name': 'Balti 2 Step Cooking Sauce',
            'brand': 'Lidl',
            'serving_size_g': 180.0,
            'ingredients': '97% Sauce: Water, Tomato (22%), Onion (15%), Rapeseed Oil, Tomato Paste, Sugar, Modified Maize Starch, Ginger Purée, Garlic Purée, Garam Masala Powder (Coriander, Cumin, Cassia, Black Pepper, Star Anise, Ginger, Green Cardamom, Pimenta, Black Cardamom, Cloves, Bay Leaves), Coriander Leaf, Cumin Powder, Paprika Powder, Concentrated Lemon Juice, Chilli Powder, Green Cardamom Powder, Fenugreek Powder, Colour (Plain Caramel), Salt, Acidity Regulator (Citric Acid). 3% Spice Cap: Salt, Coriander, Sugar, Tomato Powder, Turmeric, Onion Powder, Dextrose, Flavouring, Rice Flour, Garlic Powder, Colour (Curcumin), Chilli Powder, Cumin, Ginger, Cayenne Powder, Cassia, Cloves, Black Pepper, Fennel, Fenugreek, Bay Leaf, Mango Powder, Cinnamon, Oregano, Cardamom, Nutmeg.'
        },
        {
            'id': 'ALD9l4kEbLZhArSC6pcm',
            'name': 'Mini Blueberry Muffins',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Rapeseed Oil, Egg, Blueberries (8%), Humectant (Glycerol), Water, Modified Maize Starch, Raising Agents (Diphosphates, Sodium Carbonates, Calcium Phosphates, Potassium Carbonates), Dextrose, Emulsifier (Polyglycerol Esters of Fatty Acids), Preservative (Potassium Sorbate), Stabiliser (Xanthan Gum), Salt, Acidity Regulator (Citric Acid), Whey Powder (Milk), Soya Flour, Flavouring.'
        },
        {
            'id': 'AM8YSzRJyVUOgGKgtvZE',
            'name': 'Costa Mini All Butter Shortbreads',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk) (29%), Sugar, Cornflour, Salt.'
        },
        {
            'id': 'AMrjc1rzxZE7lV5nsjrr',
            'name': 'Moutarde',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Cider Vinegar, Brown Mustard Seeds (15%), Yellow Mustard Seeds (13%), Honey (10%), Dijon Mustard (10%) (Water, Mustard Seeds, Spirit Vinegar, Salt), Sugar, Sea Salt, Lemon Juice, Black Peppercorns, Chillies.'
        },
        {
            'id': 'AMzyxLw7gUVZC6BFbXOC',
            'name': 'Butterkist Crunchy Toffee Popcorn',
            'brand': 'Butterkist',
            'serving_size_g': 78.0,
            'ingredients': 'Glucose Syrup, Sugar, Popped Maize, Salted Butter (Milk), Rapeseed Oil, Salt, Cane Molasses, Partially Inverted Sugar Syrup, Single Cream (Milk), Emulsifier (Lecithins).'
        },
        {
            'id': 'AO9lx0oCd5Yx2OVh2Pw7',
            'name': 'Midget Gems',
            'brand': 'Bassetts',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Starch, Gelatine, Acids (Citric Acid, Acetic Acid), Flavourings, Vegetable Oils (Palm Kernel, Sunflower, Coconut), Colours (Anthocyanins, Paprika Extract, Vegetable Carbon, Lutein, Curcumin), Glazing Agent (Carnauba Wax).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 77\n")

    cleaned_count = update_batch77(db_path)

    # Calculate total progress
    previous_total = 1311  # From batch 76
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 77 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1325 and previous_total < 1325:
        print(f"\n🎉🎉 1325 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 20.5% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
