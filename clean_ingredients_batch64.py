#!/usr/bin/env python3
"""
Batch 64: Clean ingredients for 25 products
Progress: 986 -> 1011 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch64(db_path: str):
    """Update batch 64 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '6Kx92EwvpdMHZGngJ6tE',
            'name': 'No Bull Teriyaki Strips',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Minced Flavoured Rehydrated Textured Soya Protein 50% (Flavoured Rehydrated Textured Soya Protein (Water, Textured Soya Protein, Corn Starch, Flavouring), Sunflower Oil, Potato Protein, Soya Protein, Wheat Protein, Flavouring, Salt, Pepper), Water, Soya Sauce 9% (Water, Soya Bean, Wheat, Salt), Sunflower Oil, Sugar, Ginger Purée, Garlic Purée, Modified Tapioca Starch, Sesame Seed Oil, Rice Starch, Chili Pepper Purée (Chili Pepper, Vinegar, Salt), White Sesame Seed, Colour (Paprika Extract), Spices (Ground Coriander, Ground Fennel, Aniseed, Ground Cinnamon, Ground Black Pepper, Ground Cloves), Barley Malt Extract, Coriander Powder.'
        },
        {
            'id': '6LZx75cGIxzOMV34Z9Zj',
            'name': 'Beetroot Crackers',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Folic Acid, Iron, Niacin, Riboflavin, Thiamin), Sunflower Oil, Beetroot Powder (3.5%), Corn Starch, Sugar, Raising Agents (Ammonium Carbonates, Sodium Carbonates), Poppy Seeds (1.5%), Rolled Oats (1%), Sea Salt, Barley Malt Extract, Yeast Powder (contains Barley, Wheat), Beetroot Juice Powder, Onion Powder, Black Pepper, Flavouring.'
        },
        {
            'id': '6Lf5zALPQFkEXOLSdUZI',
            'name': 'Improved Recipe Meadow Fresh Zingy Onion & Garlic',
            'brand': 'Meadow Fresh',
            'serving_size_g': 100.0,
            'ingredients': '53% Mayonnaise (Water, Rapeseed Oil, Spirit Vinegar, Dried Egg, Maize Starch, Sugar, Salt, Citrus Fibre, Rice Starch, Dried Egg White, Sucrose, Potato Fibre), 34% Sour Cream (Milk), 8% Onion, 1% Garlic Purée, Cornflour, Spirit Vinegar, Chives, Salt, Preservative (Potassium Sorbate).'
        },
        {
            'id': '6LwWxgjOn5f7kaDM8NhQ',
            'name': 'Chilli Powder Mild',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mild Chilli Powder, Cumin Seeds, Salt, Garlic Powder, Oregano, Flavouring.'
        },
        {
            'id': '6M8BXbPLmwIRjuBQUW07',
            'name': 'Rustic Sourdough Rolls',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Sourdough Culture (Yeast, Alcohol), Salt, Wheat Gluten, Emulsifier (Acetic and Tartaric Acid Esters of Mono - and Di-Glycerides of Fatty Acids), Malted Wheat Flour, Malted Barley Flour, Barley Malt Extract, Antioxidant (Ascorbic Acid), Deactivated Yeast.'
        },
        {
            'id': '6NF2byb9oBJvo9MWdEa0',
            'name': 'Vegan Lemon & Almond Cookies',
            'brand': 'Easy Coast Bakehouse',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (Vitamin B3), Thiamin (Vitamin B1)), Sugar, Palm Oil, Oats, Almonds (6%), Lemon Peel (5%) (Lemon Peel, Sugar, Glucose-Fructose Syrup, Acidity Regulator (Citric Acid)), Desiccated Coconut, Glucose Syrup, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate, Disodium Diphosphate), Emulsifier (Soya Lecithin), Natural Flavourings, Salt.'
        },
        {
            'id': '6NnupXJZgwUmsShwKo4s',
            'name': 'Maltesers Teasers Egg',
            'brand': 'Maltesers',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Palm Fat, Milk Fat, Lactose, Whey Permeate from Milk, Emulsifier (Soya Lecithin), Vanilla Extract. Maltesers Teasers Milk Chocolate with Honeycombed Pieces 11%: Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Glucose Syrup, Palm Fat, Barley Malt Extract, Milk Fat, Lactose, Whey Permeate from Milk, Emulsifier (Soya Lecithin), Wheat Flour, Raising Agents (Calcium Phosphates, Sodium Carbonates, Potassium Carbonate).'
        },
        {
            'id': '6OEVDK6dPUlt0XVjhb9y',
            'name': 'Dairy Milk Snowy Fingers',
            'brand': 'Cadbury',
            'serving_size_g': 21.0,
            'ingredients': 'Wheat Flour, Sugar, Cocoa Butter, Palm Oil, Whole Milk Powder, Cocoa Mass, Skimmed Milk Powder, Whey Permeate, Lactose, Milk Proteins, Milk Fat, Partially Inverted Sugar Syrup, Emulsifiers (Soya Lecithin, E442, E476), Salt, Raising Agents (Ammonium Hydrogen Carbonate, Sodium Hydrogen Carbonate), Flavouring.'
        },
        {
            'id': '6OF7Zm2DS7MLGGkvjPML',
            'name': 'Deluxe Luxury Cracker',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Wholewheat Flour, Sunflower Oil, Sugar, Cracked Wheat, Corn Starch, Raising Agents (Ammonium Carbonates, Sodium Carbonates), Salt, Molasses, Beetroot Powder, Poppy Seeds, Palm Oil, Dried Carrot, Dried Onion, Brown Sugar, Barley Malt Extract, Yeast Powder, Oats, Pepper, Wheat Seasoning (Yeast Extract, Wheat Flour, Wheat Gluten, Sunflower Oil), Beetroot Juice Powder (Beetroot Juice from Concentrate, Maltodextrin, Acidity Regulator (Citric Acid)), Chives, Flavouring, Sea Salt, Honey, Dried Parsley, Yeast, Cane Sugar Syrup, Tomato Flakes, Red Bell Pepper, Green Bell Pepper, Yeast Extract.'
        },
        {
            'id': '6PMv7kaKjuiGT4cnbvob',
            'name': 'Edam Slices 250G',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Edam Medium Fat Hard Cheese (Milk).'
        },
        {
            'id': '6Pid94WVQtEgE09rPx7i',
            'name': 'British Medium Cheddar',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Medium White British Cheddar Cheese (Milk).'
        },
        {
            'id': '6R8hQchHHyIFgMpQg4Nf',
            'name': 'Unsmoked Back Bacon',
            'brand': 'Aldi',
            'serving_size_g': 35.0,
            'ingredients': 'Pork (87%), Water, Salt, Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Sodium Nitrite).'
        },
        {
            'id': '6RhNih4Tbe2DbHiPmazx',
            'name': 'Chinese Type Stir-fry Kit',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Diced Chicken Breast 50%, Red Peppers 25%, Soy and Rice Wine Sauce Sachet 13% (Water, Brown Sugar, Mirin Rice Wine, Soy Sauce (Water, Soya Beans, Wheat, Salt), Rice Vinegar, Molasses, Cornflour), Spring Onions 7%, Water Chestnuts, White Sugar, Spices, Cornflour, Salt, Tomato Powder, Dried Red Peppers, Garlic Granules, Dried Green Peppers, Dried Onion, Parsley, Spice Extracts, Oregano, Garlic Powder.'
        },
        {
            'id': '6RiVwhg6cOpeMfShBIIw',
            'name': 'Sourdough',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Wholemeal Wheat Flour, Wholemeal Rye Flour, Wholemeal Emmer Wheat Flour, Barley Flour, Rice Flour, Sea Salt, Wholemeal Spelt Flour, Wheat.'
        },
        {
            'id': '6RirKQxAfVqkchECrEg9',
            'name': 'Ginger Oat Biscuits',
            'brand': 'Dove\'s Farm',
            'serving_size_g': 100.0,
            'ingredients': 'Oats 26%, Wheat Flour (contains Ascorbic Acid and Statutory Nutrients (Calcium, Iron, Niacin, Thiamin)), Sugar, Palm Oil, Wholemeal Wheat Flour, Stem Ginger 6% (Stem Ginger 5.4%, Sugar 0.6%), Barley Malt Extract, Ginger Powder 2%, Raising Agents.'
        },
        {
            'id': '6StF0ckQL2i3dcAfJDPl',
            'name': 'Sweet & Sticky BBQ',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (73%), Water, Flour (Wheat, Rice), Rapeseed Oil, Starch (Maize, Wheat), Palm Oil, Demerara Sugar, Salt, Dried Onion, Molasses Powder (contains Wheat), Natural Flavourings (contains Barley), Dried Glucose Syrup, Garlic Powder, White Vinegar, Spices, Acidity Regulator (Citric Acid), Yeast Extract, Caramelised Sugar, Smoke Flavour, Emulsifier (Soya Lecithin), Colour (Paprika Extract), Calcium Carbonate, Iron, Niacin, Thiamin.'
        },
        {
            'id': '6TfsgMWiCS78BTVMWajD',
            'name': '26 Pepperoni Slices',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Maltodextrin, Glucose Syrup, Garlic, White Pepper, Paprika, Preservative (Sodium Nitrite), Chilli.'
        },
        {
            'id': '6TgT2R2j4pgY8MICULMY',
            'name': 'Dolly Mixtures',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Beef Gelatine, Maize Starch, Palm Oil, Flavourings, Citric Acid, Fat Reduced Cocoa Powder, Colours (Anthocyanins, Beetroot Red, Chlorophylls and Chlorophyllins, Plain Caramel, Lutein, Paprika Extract), Plant Concentrates (Safflower, Spirulina).'
        },
        {
            'id': '6NhJ14ZoWdjcPBjAEZ8i',
            'name': 'Beef Lasagna',
            'brand': 'Co-op',
            'serving_size_g': 375.0,
            'ingredients': 'Cooked Egg Pasta (Durum Wheat Semolina, Water, Pasteurised Egg), Beef (19%), Tomato, Milk, Water, Mushroom, Tomato Purée, Mature Cheddar Cheese (Milk), Onion, Cornflour, Medium Fat Hard Cheese (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Carrot, Sun-dried Tomato Purée (Water, Rapeseed Oil, Sun-dried Tomatoes, White Wine Vinegar, Salt, Garlic Purée, Sugar, Basil, Rosemary, Black Pepper), Soured Cream (Milk), Garlic Purée, Pasteurised Egg, Salt, Butter (Milk), Basil, Oregano, Black Pepper, Rosemary, Bay Leaf, Nutmeg, White Pepper.'
        },
        {
            'id': '6UzoxrqVYhY9o8oflB6K',
            'name': 'Greek Style Yoghurt With Honey',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Greek Style Yogurt (Milk), Honey (5%), Brown Sugar, Rice Starch, Concentrated Lemon Juice.'
        },
        {
            'id': '6WJaWwzJUbfC8uEvtHLr',
            'name': 'Chicken & Herb Flavour Super Low Fat Noodles',
            'brand': 'Batchelors',
            'serving_size_g': 148.0,
            'ingredients': 'Noodles (Water, Wheat Flour, Acidity Regulators (Pentasodium Triphosphate, Sodium Carbonate)), Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Salt, Flavourings, Onion, Maltodextrin, Garlic, Potassium Chloride, Yeast Extract, Ground Turmeric, Herbs, Acid (Malic Acid).'
        },
        {
            'id': '6WZxyHGQb1phwnVJOV7Q',
            'name': 'White Muffins',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Durum Wheat Semolina, Wheat Gluten, Butter (Milk) 2%, Sugar, Fermented Wheat Flour, Invert Sugar Syrup, Salt, Spirit Vinegar.'
        },
        {
            'id': '6WrUnCVQRS6t7YhKdcvH',
            'name': 'Mozzarella Sticks',
            'brand': 'Culinea',
            'serving_size_g': 100.0,
            'ingredients': '80% Mozzarella Cheese Sticks in Breadcrumbs (41% Mozzarella Cheese (Milk), Wheat Flour, Water, Rapeseed Oil, 5% Cream Cheese (Milk), Modified Potato Starch, Ground Spices, Potato Flakes, Potato Starch, Yeast, Salt, Thickener (Methyl Cellulose), Herbs, Spice Extract, Natural Flavouring), 20% Chilli Dip (Sugar, Water, Red Pepper, 2.5% Chillies, Modified Maize Starch, Brandy Vinegar, Apple Juice, Salt, Acid (Citric Acid)).'
        },
        {
            'id': '6Z1OsovspBarteKxpYde',
            'name': 'Raspberry & Cranberry Yogurt',
            'brand': 'Brooklea',
            'serving_size_g': 160.0,
            'ingredients': 'Yogurt 79% (Milk), Raspberry Purée 8%, Cranberry Juice from Concentrate 6%, Water, Modified Maize Starch, Acidity Regulators (Sodium Citrates, Citric Acid), Plant Extracts (Beetroot Juice from Concentrate, Black Carrot Juice Concentrate), Sweetener (Aspartame), Flavouring.'
        },
        {
            'id': '6ZxVucuSjNa6UlCHdkvH',
            'name': 'Sweet & Sour Sauce',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Pineapple (8%), Vinegar, Tomato Paste, Yellow Onion, Fructose Syrup, Modified Maize Starch, Salted Water, Salt, Red Pepper Strips (1.5%), Ginger, Acidity Regulator (Acetic Acid), Salt, Acidity Regulator (Citric Acid), Thickener (Xanthan Gum), Colour (Paprika Extract).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 64\n")

    cleaned_count = update_batch64(db_path)

    # Calculate total progress
    previous_total = 986  # From batch 63
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 64 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1000 and previous_total < 1000:
        print(f"\n🎉🎉🎉🎉🎉 1000 MILESTONE ACHIEVED! 🎉🎉🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 15.5% progress through the messy ingredients!")
        print(f"🚀 AMAZING PROGRESS - Over 1,000 products cleaned!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
