#!/usr/bin/env python3
"""
Clean ingredients batch 36 - Breaking 400 Milestone!
Using new pattern-matching approach to find messy ingredients
"""

import sqlite3
from datetime import datetime

def update_batch36(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 36 (Breaking 400!)\n")

    clean_data = [
        {
            'id': 'gVD5KkXd4NKp0Sx2loW1',
            'name': 'Greek Feta',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Greek Feta PDO Cheese Made with Pasteurised Sheep\'s Milk. Contains Milk.'
        },
        {
            'id': 'Yz0rmPHqJFBC6gYO3CWS',
            'name': 'Frozen Kefir',
            'brand': 'Yeo Valley',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Milk Fermented with Live Kefir Cultures (41%), Organic Whole Milk, Organic Sugar, Organic Skimmed Milk Powder, Organic Blueberries (5%), Organic Maize Starch, Organic Lime Juice, Stabilisers (Organic Guar Gum, Organic Locust Bean Gum, Carrageenan), Natural Flavourings, Organic Concentrated Lemon Juice. Contains Milk. May Contain Nuts.'
        },
        {
            'id': '4ONwxsVDzV1PeUy832Dv',
            'name': 'Fresh Fusilli',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Durum Wheat Semolina, Water, Pasteurised Free Range Egg (5%). Contains Cereals Containing Gluten, Eggs. May Contain Soya, Mustard.'
        },
        {
            'id': 'FSvTZorA4PHp5p5npjsy',
            'name': 'Low Sugar Berry Granola',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 45.0,
            'ingredients': 'Oat Flakes, Maltodextrin Fibre, Wheat Flakes, Palm Oil, Sunflower Seeds, Pumpkin Seeds, Maple Syrup (2%), Freeze Dried Fruit (1.5%) (Raspberries, Strawberry Pieces). Contains Cereals Containing Gluten, Oats.'
        },
        {
            'id': '2XY41IQUzmKiqp6n7UpZ',
            'name': 'Pepperoni Slices',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Paprika, Spices, Glucose Syrup, Dextrose, Antioxidant (Sodium Ascorbate), Firming Agent (Potassium Chloride), Preservative (Sodium Nitrite). Prepared with 113g of Pork per 100g Salami. Contains Pork. May Contain Mustard, Celery.'
        },
        {
            'id': 'LC9RgqDVhED6BmZ5H3Gi',
            'name': 'Sea Salt And Chardonnay Vinegar',
            'brand': 'Tesco Finest',
            'serving_size_g': 25.0,
            'ingredients': 'Potato, Rapeseed Oil, Flavouring, Rice Flour, Sugar, Citric Acid, Salt, Yeast Extract Powder, Chardonnay Wine Vinegar Powder.'
        },
        {
            'id': 'icN0uNqpqiDfg0w1FPgZ',
            'name': '100% Wholegrain Organic Porridge Oats',
            'brand': 'Flahavan\'s',
            'serving_size_g': 100.0,
            'ingredients': '100% Organic Wholegrain Rolled Oats. Contains Oats.'
        },
        {
            'id': 'a1OhuvAMfLJBTdyqktiK',
            'name': 'Fabulously FREE FROM Chocolate & Vanilla Cheesecakes',
            'brand': 'Gu',
            'serving_size_g': 82.0,
            'ingredients': 'Coconut Cream (41%), Biscuit Crumb (17%) (Gluten Free Flour Blend (Brown Rice Flour, Potato Starch, Maize Flour), Sugar, Palm Oil, Dried Rice Syrup, Raising Agent (Sodium Bicarbonate)), Dark Chocolate (13%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Demerara Sugar, Dairy Free Vegan Alternative to Cream Cheese (Water, Coconut Oil, Soya Protein Concentrate, Salt, Acidity Regulator (Lactic Acid), Sugar, Thickener (Carrageenan), Natural Flavourings, Preservative (Potassium Sorbate)), Sugar, Coconut Oil (4%), Vegetable Oil (Palm Oil, Rapeseed Oil), Glucose Syrup, Cocoa Powder, Gelling Agent (Agar), Thickener (Modified Starch), Natural Vanilla Extract (0.1%), Acidity Regulator (Lactic Acid). Contains Soybeans. May Contain Milk, Eggs, Nuts.'
        },
        {
            'id': 'JoZywAQKKWLzkrxvOZIi',
            'name': 'Ricotta',
            'brand': 'Milbona',
            'serving_size_g': 100.0,
            'ingredients': 'Ricotta Cheese (Milk), Acidity Regulator (Citric Acid). Contains Milk.'
        },
        {
            'id': 'gnFPytSEQexRkKHDCTW2',
            'name': 'Salmon Poke',
            'brand': 'Taiko',
            'serving_size_g': 312.0,
            'ingredients': 'Cooked Rice (Water, Rice, Sugar, Spirit Vinegar, Rice Vinegar, Salt, Rapeseed Oil, Fructose-Glucose Syrup, Cane Molasses), Salmon (13%) (Salmo Salar) (Fish), Soy Sesame Dressing (9%) (Water, Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol), Sugar, Rice Vinegar, Sesame Seed Oil, Modified Maize Starch, Onion Purée, Spirit Vinegar, Apple Juice Concentrate, Ginger Purée, Lemon Juice Concentrate, Lime Juice Concentrate, Garlic Powder, White Pepper), Avocado (6%), Seasoned Seaweed (5%) (Seaweed, Apple Vinegar, Toasted Sesame Seed Oil, White Sesame Seeds, Thickener (Agar-Agar), Rice Wine, Salt, Fructo-Oligofructose, Red Chilli, Mushroom, Tapioca Starch, Spirulina, Colour (Curcumin)), Edamame Beans (4%) (Soya), Rocket (2%), Spring Onion (2%), White Sesame Seeds. Contains Cereals Containing Gluten, Fish, Sesame, Soybeans, Wheat.'
        },
        {
            'id': 'LUgoDJgZ9Gt3TFy50tXm',
            'name': 'Chip Shop Chips',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (94%), Sunflower Oil, Potato Starch, Rice Flour, Maize Starch, Rice Starch, Salt, Dextrose.'
        },
        {
            'id': 'YdeCCC8nVPQFJ6lXu3Fk',
            'name': 'American Style Pancake Mix',
            'brand': 'Dr. Oetker',
            'serving_size_g': 70.0,
            'ingredients': 'Wheat Flour, Whole Egg Powder, Sugar, Glucose Syrup, Egg White Powder, Raising Agents (Diphosphates, Sodium Carbonates), Flavouring, Acidity Regulator (Citric Acid). Contains Cereals Containing Gluten, Eggs, Wheat. May Contain Milk.'
        },
        {
            'id': 'KmWRhJYLgW6qwkndbOZ4',
            'name': 'Cranberry Juice Drink',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Cranberry Juice from Concentrate (19%), Cranberry Purée (2%), Acid (Citric Acid), Flavourings, Sweetener (Sucralose).'
        },
        {
            'id': 'hgpgTxIS6iVMacP1kDzM',
            'name': 'Strawberry & White Cereal Balls Protein Yogurt',
            'brand': 'Brooklea',
            'serving_size_g': 221.0,
            'ingredients': 'Low Fat Soft Cheese (Milk) (45%), Low Fat Yogurt (Milk), White Chocolate Coated Cereal Balls (10%) (Sugar, Milk Protein, Cocoa Butter, Whole Milk Powder, Rice Flour, Salt, Emulsifier (Lecithins (Soya)), Glucose Syrup, Glazing Agent (Gum Arabic), Vanilla Flavouring), Strawberry Preparation (Strawberries, Modified Maize Starch, Flavouring, Colour (Black Carrot Concentrate), Acidity Regulators (Citric Acid, Sodium Citrates), Sweeteners (Acesulfame K, Sucralose), Thickener (Locust Bean Gum)). Contains Milk, Soybeans. May Contain Nuts.'
        },
        {
            'id': 'CG8TZdMbVYW2A8HV54nU',
            'name': 'Midget Gems',
            'brand': 'Spar',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Modified Potato Starch, Maize Starch, Water, Acids (Lactic Acid, Acetic Acid), Beef Gelatine, Flavourings, Colours (Anthocyanins, Curcumin, Paprika Extract), Plant Concentrates (Safflower, Spirulina), Sunflower Oil, Glazing Agents (Carnauba Wax, Beeswax). May Contain Peanuts, Nuts.'
        },
        {
            'id': '5lM17CyqUSR4lYGFO8Ds',
            'name': 'Hummus Bites Sour Cream Flavour',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Chickpea Flour (29%), Potato Starch, Rice Flour, Rapeseed Oil, Sour Cream and Chives Flavour (6%) (Onion Powder, Rice Flour, Yeast Extract Powder, Sugar, Natural Flavourings, Acid (Citric Acid)), Modified Potato Starch, Maize Flour, Salt.'
        },
        {
            'id': 'sGJ4WfD2oPmT9l5WOJcw',
            'name': 'Chicken Sausages Garlic & Herb',
            'brand': 'Aldi',
            'serving_size_g': 97.0,
            'ingredients': 'Chicken (80%), Water, Parsley, Rice Flour, Chickpea Flour, Garlic, Potato Fibre, Sea Salt, Stabiliser (Diphosphates), Basil, Black Pepper, Lemon Zest, Cornflour, Flavouring, Preservative (Sodium Metabisulphite), Dextrose, Antioxidant (Ascorbic Acid). Filled into Vegetable Based Casings (Calcium Alginate). Contains Sulphites.'
        },
        {
            'id': 'kJ1R9EL00aX5W6gDZS0M',
            'name': 'Riverway Foods',
            'brand': 'Riverways Food',
            'serving_size_g': 115.0,
            'ingredients': 'British Pork (80%), Water, Gluten Free Rusk (Rice Flour, Water, Dextrose, Vegetable Fibre, Salt, Plain Caramel, Paprika), Salt, Rice Flour, Dextrose, Sodium Triphosphate, Rubbed Herbs, Preservative (Sodium Metabisulphite), Flavouring (Spice and Herb Extracts), Antioxidant (Ascorbic Acid). Filled into Natural Pork Casings. Contains Pork, Sulphites.'
        },
        {
            'id': 'Y8LkktfVhVGEOn4eVLD9',
            'name': 'Simply Seed Crackers',
            'brand': 'Olina\'s Bakehouse',
            'serving_size_g': 100.0,
            'ingredients': 'Linseeds, Sunflower Kernels, Pumpkin Seed Kernels, Black Sesame Seeds, White Sesame Seeds, Psyllium Husk, Dried Rosemary (2.5%), Salt, Thickener (Hydroxy Propyl Distarch Phosphate). Contains Sesame.'
        },
        {
            'id': '6CnacXTzPefFbQX1UDVc',
            'name': 'Walnut Pave',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 50.0,
            'ingredients': 'Fortified British Wheat Flour, Water, Walnut Halves (10%), Salt, Yeast, Malted Wheat Flakes, Roasted Barley Malt, Caramelized Malted Wheat Flour, Malted Wheat Flour, Wheatgerm, Barley Malt Extract, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat, Barley, Nuts.'
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

    total_cleaned = 386 + updates_made

    print(f"✨ BATCH 36 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 400:
        print(f"\n🎉🎉🎉 400 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {450 - total_cleaned} products until 450!\n")
    else:
        remaining_to_400 = 400 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_400} products until 400!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch36(db_path)
