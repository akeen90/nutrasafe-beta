#!/usr/bin/env python3
"""
Batch 79: Clean ingredients for 25 products
Progress: 1361 -> 1386 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch79(db_path: str):
    """Update batch 79 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {'id': 'BBBajvCs78aDxqfO7yYj', 'name': 'Newgate BBQ Beef Instant Noodles', 'brand': 'Lidl', 'serving_size_g': 140.0, 'ingredients': '95% Noodles (Wheat Flour, Palm Oil, Iodised Salt, Sugar, Garlic Powder, Stabiliser (Guar Gum)), Seasoning (Maltodextrin, Iodised Salt, Sugar, Flavouring (Milk, Soya), Yeast Extract, Onion Powder, Colour (Plain Caramel), Dried Whole Milk, Dried Coriander, Paprika Extract, Acidity Regulator (Citric Acid), Ground Black Pepper, Turmeric Extract, Ground Celery Seed, Thyme Powder).'},
        {'id': 'BCUi93h45aXKq0Z9026m', 'name': 'Blueberry Wheats', 'brand': 'Kellogg\'s', 'serving_size_g': 45.0, 'ingredients': 'Wholewheat (74%), Blueberry Flavoured Filling (Blueberry Purée (10%), Glucose Syrup, Sugar, Humectant (Glycerol), Acidity Regulator (Citric Acid), Gelling Agent (Pectin), Natural Flavouring).'},
        {'id': 'BD2bmy1BG5HkmT9wZJV4', 'name': 'Shortcake', 'brand': 'Happy Shopper', 'serving_size_g': 100.0, 'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Nicotinamide, Thiamin), Palm Oil, Sugar, Sunflower Oil, Partially Inverted Sugar Syrup, Salt, Raising Agent (Ammonium Bicarbonate).'},
        {'id': 'BD5b0UOp3uX455LCjePx', 'name': 'Sausage & Mash', 'brand': 'Generic', 'serving_size_g': 100.0, 'ingredients': 'Potato (46%), Cooked Pork Sausages (19%) (British Pork (79%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Salt, Dextrose, Potato Starch, Dried Sage, Spices, Stabiliser (Diphosphates), Raising Agent (Ammonium Carbonates), Flavouring, Rapeseed Oil, Pork Rind, Ground Bay Leaf), Water, Onion (11%), Butter (Milk), Whole Milk, Beef Stock (Water, Yeast Extract, Beef Extract, Beef Fat, Salt, Tomato Concentrate, Carrot Juice from Concentrate, Black Pepper, Carrot, Onion, Tomato Paste, Rapeseed Oil), Cornflour, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Brown Sugar (Sugar, Cane Molasses), Tomato Purée, Worcester Sauce (Water, Spirit Vinegar, Sugar, Tamarind Extract, Garlic Powder, Onion Powder, Chilli Powder, Ginger Powder, Ground Cloves, Lemon Juice Concentrate, Colour (Plain Caramel)), White Pepper, Beef Collagen Casings.'},
        {'id': 'BD6wEPEdU1mhx0ddSSb6', 'name': 'Korean Style Bbq Beef', 'brand': 'Naked', 'serving_size_g': 100.0, 'ingredients': 'Dried Egg Noodles (Soft Wheat, Durum Wheat Semolina, Egg, Salt, Acidity Regulator (Potassium Carbonate)), Maltodextrin, Natural Flavourings, Potato Starch, Soft Brown Sugar, Soy Sauce Powder (Maltodextrin, Salt, Soya Beans, Wheat), Salt, Onion Powder, Red Pepper Powder, Garlic Powder, Colour (Ammonia Caramel), Dried Red Pepper, Spring Onion, Chilli Powder, Ground Ginger, Ground Black Pepper, Barley Dried Malt Vinegar Extract.'},
        {'id': 'BDfgJcvr5O1ahMZLMEoH', 'name': 'Aldi Milk Chocolate Coins', 'brand': 'Dairy Fine', 'serving_size_g': 100.0, 'ingredients': 'Sugar, Whole Milk Powder, Cocoa Mass, Cocoa Butter, Whey Powder (Milk), Emulsifier (Lecithins (Soya)), Flavouring.'},
        {'id': 'BDhGeuC2lXOF3BjFnG9M', 'name': 'Mrbeast Deez Nutz', 'brand': 'Feastables', 'serving_size_g': 100.0, 'ingredients': 'Milk Chocolate (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Emulsifier (Soya Lecithin), Vanilla Extract), Peanut Butter (27%) (Peanuts, Sugar, Palm Oil, Salt).'},
        {'id': 'BDmgMEOsWT7izDZ36RXh', 'name': 'Spaghetti Hoops', 'brand': 'Tesco', 'serving_size_g': 100.0, 'ingredients': 'Pasta (42%) (Water, Durum Wheat Semolina), Tomato Purée (38%), Sugar, Glucose-Fructose Syrup, Modified Maize Starch, Salt, Paprika, Potato Starch, Acidity Regulator (Citric Acid), Onion Powder, Flavouring.'},
        {'id': 'BE5FwhAV1NrjGKmKx48d', 'name': 'Zesty Pesto Flavour Ridge Cut Crisps', 'brand': 'Morrisons', 'serving_size_g': 100.0, 'ingredients': 'Potato, Vegetable Oils (Rapeseed, Sunflower), Rice Flour, Salt, Sugar, Spinach Powder, Flavouring, Dried Garlic, Herbs (Parsley, Basil), Dried Onion, Acid (Citric Acid), Yeast Extract, Sunflower Oil, Antioxidant (Extracts of Rosemary), Colour (Curcumin).'},
        {'id': 'BEFktuLLf96VR0vtNRyb', 'name': 'Cheese & Egg Triple With Cheddar', 'brand': 'Asda', 'serving_size_g': 100.0, 'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vine Ripened Tomatoes (11%), Free Range Hard Boiled Egg (10%), West Country Mature Cheddar Cheese (8%) (Milk), Vegetable Oils (Rapeseed Oil, Palm Oil), Medium Mature Cheddar Cheese (4%) (Milk), Red Leicester Cheese (3%) (Cheese (Milk), Colour (E160b)), Cucumber, Lettuce, Malted Wheat Flake, Oatmeal, Sugar, Wheat Bran, Spirit Vinegar, Red Onions, Spring Onions, Cornflour, Yeast, Sundried Tomatoes, Salt, Sundried Tomato Powder, Wheat Gluten, Pasteurised Free Range Whole Egg, Emulsifiers (E471, E472e), Malted Barley Flour, Sea Salt, Pasteurised Egg Yolk, White Wine Vinegar, Black Pepper, Black Mustard Seeds, Malted Wheat Flour, Pasteurised Free Range Egg Yolk, Thickener (E440), Concentrated Lemon Juice, White Pepper, Flour Treatment Agent (E300), Palm Fat, Wheat Starch.'},
        {'id': 'BEkJaLME9AoJu93IH4lM', 'name': 'Smoky Garlic Mayonnaise', 'brand': 'Fortnum & Mason', 'serving_size_g': 100.0, 'ingredients': 'Cold Pressed Rapeseed Oil, Smoked Cold Pressed Rapeseed Oil (25%), Water, Garlic Oil (15%) (Cold Pressed Rapeseed Oil, Garlic Essence), White Wine Vinegar (White Wine Vinegar, Water), Free Range Pasteurised Egg, Sugar, Mustard Powder, Salt, Stabiliser (Xanthan Gum).'},
        {'id': 'BGBcp1KacIJ8yBQqe3Ld', 'name': 'Loaded Tandoori Spiced Chicken', 'brand': 'Co-op', 'serving_size_g': 208.0, 'ingredients': 'Marinated Chicken (40%) (Chicken Breast, Low Fat Yogurt (Milk), Spices, Cornflour, Rapeseed Oil, Green Chilli Purée, Lemon Juice, Garlic Purée, Ginger Purée, Salt, Colour (Paprika Extract), Bay Leaf, Lemon Oil), Tikka Sauce (28%) (Onion, Single Cream (Milk), Water, Tomato Paste, Tomato, Rapeseed Oil, Tomato Juice, Spices, Ginger Purée, Garlic Purée, Cashew Nuts, Honey, Coriander, Cornflour, Butter (Milk), Green Chilli Purée, Salt, Fenugreek, Colour (Paprika Extract), Red Chilli Powder, Bay Leaf, Lemon Oil), Vegetable Mix (14%) (Onion, Yellow Pepper, Red Pepper, Green Pepper, Rapeseed Oil, Red Chilli, Coriander Leaf, Lime Juice, Mint), Cheese Mix (9%) (Onion, Cheddar Cheese (Milk), Garlic, Coriander Leaf, Red Chilli, Cumin Seeds, Dried Red Pepper), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil.'},
        {'id': 'BGl0ts1m8ZZ4YhPJT1Ii', 'name': 'Morrisons Vegan Mince Pie', 'brand': 'Morrisons', 'serving_size_g': 100.0, 'ingredients': 'Dried Fruit (20%) (Raisins, Sultanas, Currants), Sugar, Brown Rice Flour, Tapioca Starch, Apple Purée, Vegetable Oils (Palm, Rapeseed, Sunflower), Glucose Syrup, Brown Sugar, Ground Almonds, Glucose-Fructose Syrup, Orange Peel, Spices, Dextrose, Rice Flour, Preservative (Acetic Acid), Lemon Peel, Salt, Thickener (Xanthan Gum), Treacle, Cornflour, Acidity Regulator (Citric Acid), Orange Oil, Emulsifier (Mono and Diglycerides of Fatty Acids).'},
        {'id': 'BGq8TbDCmyx1f8bpVAOo', 'name': 'The Best Raspberry Conserve', 'brand': 'Morrisons', 'serving_size_g': 15.0, 'ingredients': 'Sugar, Raspberries, Acid (Citric Acid), Gelling Agent (Pectins).'},
        {'id': 'BH6cUmOylgoUaPVXvQFt', 'name': 'Peanut M&m\'s', 'brand': 'M&M\'s', 'serving_size_g': 100.0, 'ingredients': 'Sugar, Peanuts, Cocoa Mass, Full Cream Milk Powder, Cocoa Butter, Starch, Palm Fat, Skimmed Milk Powder, Glucose Syrup, Stabiliser (Gum Arabic), Emulsifier (Soya Lecithin), Shea Fat, Whey Permeate (Milk), Milk Fat, Dextrin, Glazing Agent (Carnauba Wax), Palm Kernel Oil, Colours (Carmine, E133, E170, E100, E160a, E160e), Salt, Flavouring.'},
        {'id': 'BIUOOALVNTI1Hlk9lai4', 'name': 'Bakewell Slices', 'brand': 'Holly Lane Aldi', 'serving_size_g': 100.0, 'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin), Decorated Icing (24%) (Sugar, Icing Sugar, Water, Glucose Syrup, Palm Oil, Humectant (Glycerol), Rapeseed Oil, Vegetable Fats (Palm, Rapeseed, Shea, Sunflower), Skimmed Milk Powder, Fat Reduced Cocoa Powder, Whey Powder (Milk), Emulsifier (Lecithins (Soya)), Flavouring, Stabilizer (Sorbitan Tristearate)), Plum and Raspberry Jam (13%) (Glucose-Fructose Syrup, Plum Purée, Sugar, Raspberry Purée (3%), Acid (Citric Acid), Gelling Agent (Pectins), Acidity Regulator (Sodium Citrates), Colour (Anthocyanins), Preservative (Potassium Sorbate), Flavoring), Rapeseed Oil, Sugar, Water, Palm Oil, Humectant (Glycerol), Glucose Syrup, Dried Egg White, Whey Powder (Milk), Soya Flour, Ground Almonds, Raising Agents (Diphosphates, Sodium Carbonates), Emulsifiers (Mono and Diglycerides of Fatty Acids, Polyglycerol Esters of Fatty Acids), Flavoring, Preservative (Potassium Sorbate), Stabilizer (Xanthan Gum).'},
        {'id': 'BJvFdgqWDoYaX8ouih1C', 'name': 'Thick Sliced Oven Baked Ham', 'brand': 'Asda', 'serving_size_g': 100.0, 'ingredients': 'Pork (96%), Acidity Regulators (Sodium Lactate, Sodium Acetates), Salt, Brown Sugar, Dextrose, Stabilisers (Triphosphates, Polyphosphates, Potassium Phosphates, Diphosphates), Glucose Syrup, Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Sodium Nitrate), Flavourings.'},
        {'id': 'BKpa3xhgYOpfx0m34UE9', 'name': 'Apricot & Coconut Oat Bars 3 X', 'brand': 'Generic', 'serving_size_g': 100.0, 'ingredients': 'Gluten Free Oats (43%), Rice Syrup, Dried Apricots (12%), Desiccated Coconut (9%), Coconut Oil, Rapeseed Oil, Coconut Sugar.'},
        {'id': 'BL4AlYjdu9GzaznKvg7n', 'name': 'Rotterdam Sport E Te Fondente', 'brand': 'Ritter', 'serving_size_g': 10.0, 'ingredients': 'Cocoa Mass, Sugar, Cocoa Butter, Butterfat (from Milk).'},
        {'id': 'BLPd2Ymnn2YEnNdo5Qgf', 'name': 'Optimum Nutrition: Gold Standard Whey Protein, Double R', 'brand': 'Optimum Nutrition', 'serving_size_g': 28.0, 'ingredients': 'Whey Protein Blend (93%) (Whey Protein Isolate (Milk), Whey Protein Concentrate (Milk), Hydrolysed Whey Protein Isolate (Milk), Emulsifier (Soy Lecithin)), Fat-Reduced Cocoa Powder, Flavourings, Thickener (Xanthan Gum), Sweeteners (Sucralose, Acesulfame K).'},
        {'id': 'BMYlgMaHHm5OibdVvh2u', 'name': 'Sharwood\'s Sweet & Sour', 'brand': 'Sharwood', 'serving_size_g': 100.0, 'ingredients': 'Tomatoes (29%), Sugar, Water, Water Chestnut (8%), Pineapple (7%), Barley Malt Vinegar, Green Pepper (5%), Red Pepper (5%), Pineapple Juice Concentrate (4%), Modified Maize Starch, Garlic Purée, Ginger Purée, Salt, Toasted Sesame Oil, Colour (Paprika Extract).'},
        {'id': 'BMZsI3CSKY2JqNWqGAvW', 'name': 'Apple & Cinnamon Crunch', 'brand': 'M&S', 'serving_size_g': 45.0, 'ingredients': 'Oat Flakes (59%), Sugar, Vegetable Oil (Sunflower, Rapeseed), Cornflakes (Maize Flour, Salt), Crisped Rice (Rice Flour, Wheat Flour, Sugar, Malted Barley, Salt), Dried Red Apples (3%), Yogurt Coated Cornflakes (3%) (Sugar, Cocoa Butter, Lactose (Milk), Emulsifier, Glucose Syrup, Desiccated Maize, Dried Low Fat Yogurt (Milk), Lecithin, Salt, Barley Malt Extract), Coconut, Concentrated Apple Juice, Natural Flavourings, Honey, Sweet Cinnamon (Cassia), Salt, Caramelised Sugar, Antioxidant (Tocopherol-Rich Extract).'},
        {'id': 'BMbgDOJ6JGEpzcaAyQJs', 'name': 'Cypressa Stuffed Vine Leaves 280 G', 'brand': 'Cypressa', 'serving_size_g': 100.0, 'ingredients': 'Cooked Rice (Water, Rice) (45%), Water, Mint (15%), Onions, Soya Oil, Salt, Herbs (Spearmint, Dill) (0.4%), Black Pepper, Acidity Regulator (Citric Acid).'},
        {'id': 'BN84fx2gToYSONHRD5X0', 'name': 'Clover', 'brand': 'Clover', 'serving_size_g': 100.0, 'ingredients': 'Vegetable Oils (Sustainable Palm, Rapeseed), Buttermilk, Water, Salt, Natural Flavor, Colour (Carotenes).'},
        {'id': 'BNDNZNDdR1Ia6Pes6WCZ', 'name': 'Savers Morrison Lollies', 'brand': 'Morrisons', 'serving_size_g': 100.0, 'ingredients': 'Water, Sugar, Glucose Syrup, Acidity Regulator (Citric Acid), Flavourings, Stabiliser (Guar Gum), Colours (Beetroot Red, Curcumin).'}
    ]

    current_timestamp = int(datetime.now().timestamp())

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'], current_timestamp, product['id']))
        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Serving: {product['serving_size_g']}g\n")

    conn.commit()
    conn.close()
    return len(clean_data)

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    print("🧹 CLEANING INGREDIENTS - BATCH 79\n")
    cleaned_count = update_batch79(db_path)
    previous_total = 1361
    total_cleaned = previous_total + cleaned_count
    print(f"✨ BATCH 79 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    if total_cleaned >= 1375 and previous_total < 1375:
        print(f"\n🎉🎉 1375 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 21.3% progress through the messy ingredients!")
    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
