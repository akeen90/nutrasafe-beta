#!/usr/bin/env python3
"""
Batch 55: Clean ingredients for 25 products
Progress: 761 -> 786 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch55(db_path: str):
    """Update batch 55 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '2CVNBKR1E8Gkb4fqU3Wg',
            'name': 'Creamed Horseradish',
            'brand': 'Stokes',
            'serving_size_g': 100.0,
            'ingredients': 'Horseradish Root 29%, Rapeseed Oil, Spirit Vinegar, Sugar, Free Range Pasteurised Whole Egg, Single Cream 4% (Milk), Sea Salt, Mustard Flour, Stabilisers (Guar Gum, Xanthan Gum).'
        },
        {
            'id': '2F7N7SrQabDynvMtL4Lx',
            'name': 'Waffles Chocolate & Hazelnut Flavour',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Egg, Sugar, Chocolate & Hazelnut Flavour Filling (26%) (Sugar, Palm Fat, Palm Kernel Oil, Whey Powder (Milk), Lactose (Milk), Coconut Oil, Cocoa Powder, Emulsifiers (Lecithins, Sorbitan Tristearate), Flavouring), Wheat Flour, Rapeseed Oil, Lupin Flour, Skimmed Milk Powder, Salt, Emulsifier (Lecithins), Flavouring.'
        },
        {
            'id': '2G5VFaNGVIhcl9zTUXBC',
            'name': 'Manilife Deep Roast Smooth Peanut Butter',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts 99.7%, Sea Salt 0.3%.'
        },
        {
            'id': '2G6BhANrqwMok4uCssut',
            'name': 'Griddle Waffles',
            'brand': 'Griddle',
            'serving_size_g': 40.0,
            'ingredients': 'Water, Wholegrain Wheat Flour, Sunflower Oil, Chocolate (7%) (Cocoa Mass, Sugar, Dextrose, Emulsifier (Lecithin (Soya))), Sugar, Soya Flour, Raising Agents (Monocalcium Phosphate, Sodium Bicarbonate), Salt.'
        },
        {
            'id': '2HvWDpzU2OJIEbgTSZY5',
            'name': 'Performance Whey Protein',
            'brand': 'Precision Engineered Nutrition',
            'serving_size_g': 30.0,
            'ingredients': 'Milk Protein (Whey Protein Concentrate 71%, Whey Protein Isolate 20%, Whey Protein Hydrolysate 2%), Emulsifier (Sunflower Lecithin), Flavourings, Banana Powder (Dried Bananas) (1.66%), Thickeners (Guar Gum, Xanthan Gum), Sweetener (Sucralose).'
        },
        {
            'id': '2IxIzD6YC67XRUOS0rhY',
            'name': 'Light And Free',
            'brand': 'Light Free',
            'serving_size_g': 115.0,
            'ingredients': 'Yogurt (Milk), Strawberry (5%), Starches (Potato, Tapioca), Modified Maize Starch, Stabiliser (Pectin), Black Carrot Juice Concentrate, Flavourings, Acidity Regulators (Citric Acid, Sodium Citrate), Sweeteners (Acesulfame K, Sucralose).'
        },
        {
            'id': '2JIuAvBATZnNJESY8fl4',
            'name': 'Tomato And Oregano Bruschetta Snacks',
            'brand': 'Snacktural',
            'serving_size_g': 30.0,
            'ingredients': 'Wheat Flour, High Oleic Sunflower Oil (28%), Powdered Dehydrated Tomato (7%), Yeast, Salt, Oregano (0.4%), Sugar.'
        },
        {
            'id': '2JqO4DGRoQL2JPDosjRv',
            'name': 'Shin Ramyun Noodle Gourmet Spicy',
            'brand': 'Nongshim',
            'serving_size_g': 120.0,
            'ingredients': 'Noodles 89% (Wheat Flour, Potato Starch, Palm Oil, Salt, Acidity Regulators (E501, E500, E339), Antioxidant (E306), Emulsifier (E322 (contains Soy)), Seasoning (Yeast Extract, Soybean, Garlic, Wheat Starch), Green Tea Extract, Colour (E101)), Seasoning Powder 9% (Seasoning (Hydrolyzed Vegetable Protein (Soy), Maltodextrin, Yeast Extract, Salt, Wheat Flour), Salt, Spices (Maltodextrin, Black Pepper, Red Chili Pepper, Garlic, Corn Flour), Flavour Enhancers (E621, E627, E631), Sugar, Glucose, Shiitake), Vegetable Mushroom Flakes 2% (Pak-choi, Shiitake, Textured Vegetable Protein (Soy, Wheat Gluten), Carrot, Red Chili Pepper, Onion).'
        },
        {
            'id': '2KKsnHHSMTIHpEAv5ikY',
            'name': 'Selection Box',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Oil, Skimmed Milk Powder, Cocoa Butter, Milk, Cocoa Mass, Vegetable Fats (Palm, Shea), Whey Permeate Powder (from Milk), Milk Fat, Emulsifiers (E442, E476, E471, Sunflower Lecithins), Whey Powder (from Milk), Flavourings, Salt.'
        },
        {
            'id': '2LMbkRDTg4Ripl1tAMcV',
            'name': 'The Nice Slice',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Solids (Cocoa Mass, Cocoa Butter), Sugar, Hazelnut Paste (12%), Full Cream Milk Powder, Corn Flakes (7%) (Milled Corn, Sugar, Malt Flavouring (from Barley), Salt), Almond Nuts Paste (7%), Caramel Flakes (5%) (Sugar, Glucose Syrup), Vegetable Fats (Coconut, Shea, Sunflower), Rice Crispies (4%) (Rice, Sugar, Salt, Malt Flavouring (from Barley)), Skimmed Milk Powder, Butter Oil (from Milk), Lactose (from Milk), Caramelised Sugar, Sea Salt, Emulsifiers (Sunflower Lecithin, Soya Lecithin), Flavourings, Colour (Paprika Extract).'
        },
        {
            'id': '2MwCoMnDYYPDInF25UFZ',
            'name': 'Dried Mango',
            'brand': 'H B',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Mango, Preservative (Sodium Metabisulphite).'
        },
        {
            'id': '2NOo55AXPPbFugcCGt5K',
            'name': 'Chinese Chicken',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mixed Vegetables (Courgette, Red Pepper, Water Chestnut, Onion), White Rice (Water, Rice), Roasted Chicken (12%) (Chicken 98%, Water, Dextrose, Salt, Stabilizer (E451i)), Sauce (Water, Molasses, Black Garlic, Salt, White Wine Vinegar, Soybean, Wheat, Maltodextrin, Natural Aroma, Ginger, Vinegar, Citrus Fiber, Garlic, Potato Starch).'
        },
        {
            'id': '2Om4HIZoonX4cQWHQ0fg',
            'name': 'Monster Munch Roast Beef',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Rapeseed Oil, Roast Beef Seasoning (Wheat Flour (contains Calcium, Iron, Niacin, Thiamin), Hydrolysed Soya Protein, Whey Permeate (from Milk), Flavourings, Rusk (from Wheat), Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium 5-ribonucleotides), Onion Powder, Salt, Garlic Powder, Colour (Ammonia Caramel), Spices).'
        },
        {
            'id': '2KNZDIgWH3DjvhHz9Jq7',
            'name': 'Cadbury Dairy Milk',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings.'
        },
        {
            'id': '2Q2Q5NsmeAYQ55koDovd',
            'name': 'Stone Baked Margherita Pizza',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Pizza Base (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Durum Wheat Semolina, Rapeseed Oil, Salt, Yeast, Wheat Gluten, Enzymes (Wheat), Flour Treatment Agent (Ascorbic Acid), Potato Starch, Sunflower Oil), Tomato Sauce (22%) (Tomatoes, Water, Sugar, Salt, Dried Herbs, Sunflower Oil, Black Pepper, Acidity Regulator (Citric Acid), Dried Garlic), Mozzarella Full Fat Soft Cheese (21%) (Milk), Mild White Cheddar Cheese (5%) (Milk), Mature White Cheddar Cheese (5%) (Milk).'
        },
        {
            'id': '2Qhug0NY7bnXrkF9EmbZ',
            'name': 'Salt & Pepper Mix',
            'brand': 'Bramwells',
            'serving_size_g': 8.75,
            'ingredients': 'Maltodextrin, Sugar, Salt (10%), Maize Starch, Dried Garlic (6%), Dried Onion, Ginger Powder, Dried Green Bell Pepper (2%), Yeast Extract, Cracked Black Pepper (1.5%), Chilli Flakes (1.5%), Rapeseed Oil, Star Anise, Ground Fennel, Ground Cinnamon, Dried Parsley, Ground Cloves.'
        },
        {
            'id': '2QuaPefyVZVlxbKTXY1F',
            'name': 'Freefrom Haddock Fishcakes',
            'brand': 'M&S',
            'serving_size_g': 50.0,
            'ingredients': 'Sugar, Butter (Milk), Wheat Flour (contains Gluten) (With Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rice Flour, Glucose Syrup, Sweetened Milk (Whole Milk, Sugar, Lactose (Milk)), Cocoa Butter, Golden Syrup (Invert Sugar Syrup), Palm Oil, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Salt, Lactose (Milk), Emulsifiers (Soya Lecithin, Sunflower Lecithin, E491), Dried Whole Milk, Flavourings.'
        },
        {
            'id': '2RVsbleMVfqAZlDsBlEm',
            'name': 'Hazelnut Childcare Oats',
            'brand': 'Quaker',
            'serving_size_g': 36.5,
            'ingredients': 'Quaker Wholegrain Rolled Oats (76%), Sugar, Dark Chocolate Powder (5%) (Cocoa Powder, Cocoa Mass, Sugar), Natural Flavourings, Salt.'
        },
        {
            'id': '2Rr42CrNEsStiwggKlez',
            'name': 'Mini Cheese Bakes',
            'brand': 'Nairns',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Wholegrain Oats 41%, Cheese 15% (Milk), Rice Flour, Maize Flour, Sustainable Palm Fruit Oil, Tapioca Starch, Maize Starch, Potato Starch, Brown Rice Syrup, Sea Salt, Raising Agent (Ammonium Carbonates), Natural Flavouring.'
        },
        {
            'id': '2S7Bi66VREfeoew5c5OO',
            'name': 'Sliced Beetroot',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Beetroot, Water, Barley Malt Vinegar, Acid (Acetic Acid), Salt, Sugar, Preservative (Potassium Sorbate), Sweetener (Saccharins).'
        },
        {
            'id': '2SJ71VaYzgFo7EfrLB9f',
            'name': 'Mild Pepperoni',
            'brand': 'The Deli',
            'serving_size_g': 30.0,
            'ingredients': 'Pork, Sea Salt, Spices, Dextrose, Garlic Powder, Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Potassium Nitrate).'
        },
        {
            'id': '2SVi4BWkblPQQfCxwOA3',
            'name': 'Mini-egg-bites',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 20.0,
            'ingredients': 'British Pork (33%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Egg (16%), Water, Rapeseed Oil, Onion, Pork Fat, Salt, Potato Starch, Cornflour, Spirit Vinegar, Sugar, Pasteurised Free Range Egg Yolk, White Pepper, Black Pepper, Nutmeg, Yeast Extract, Pasteurised Free Range Egg, Concentrated Lemon Juice, Sage, Marjoram, Paprika Extract, Yeast.'
        },
        {
            'id': '2Tp5vatiP0lUbwIenJIu',
            'name': 'Serving Suggestion Crownfield Fibre UP Lemon Drizzle',
            'brand': 'Crownfield',
            'serving_size_g': 24.0,
            'ingredients': 'Wheat Flour, Fructo-Oligosaccharides, Sugar, 11% Lemon Flavour Pieces (Sugar, Vegetable Oil (Palm Kernel, Palm), Lactose (Milk), Whey Powder (Milk), Skimmed Milk Powder, Emulsifier (Sunflower Lecithins), Natural Lemon Flavouring), Humectant (Glycerol), Wheat Fibre, 7% Lemon Flavour Drizzle (Sugar, Vegetable Oils (Palm, Palm Kernel, Rapeseed), Whey Powder (Milk), Natural Flavourings, Emulsifier (Soya Lecithins), Colour (Carotenes)), Vegetable Oils (Palm, Rapeseed, Coconut), Whey Powder (Milk), Egg White Powder, Raising Agents (Diphosphates, Sodium Carbonates), Acids (Citric Acid, Malic Acid), Salt, Emulsifier (Rapeseed Lecithins), Thickeners (Xanthan Gum, Locust Bean Gum), Natural Flavouring, Colour (Carotenes).'
        },
        {
            'id': '2TybayvGfTBSNtNp3v7B',
            'name': 'Dirty Cow Plant Based Chocolate',
            'brand': 'Dirty Cow',
            'serving_size_g': 40.0,
            'ingredients': 'Dirty Cow Chocolate (Cocoa, Sugar, Cocoa Butter, Soy Lecithin, Natural Vanilla), Cookies (Fortified Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamine), Vegetable Oils (Palm (Certified Sustainable), Rapeseed), Sugar, Oats, Rice Powder, Sunflower Lecithin, Golden Syrup, Vanilla Extract, Salt, Raising Agent (Bicarbonate Of Soda)).'
        },
        {
            'id': '2U59g18sginD0QRLWf5P',
            'name': 'Fruit Oat Biscuit Breaks',
            'brand': 'Nairns',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Wholegrain Oats (66%), Sustainable Palm Fruit Oil, Currants (13%) (Currants, Sunflower Oil), Brown Sugar, Partially Inverted Refiners Syrup (Lyles Golden Syrup), Tapioca Starch, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Natural Flavouring, Sea Salt.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 55\n")

    cleaned_count = update_batch55(db_path)

    # Calculate total progress
    previous_total = 761  # From batch 54
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 55 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 775 and previous_total < 775:
        print(f"\n🎉 775 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 12.0% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
