#!/usr/bin/env python3
"""
Batch 58: Clean ingredients for 25 products
Progress: 836 -> 861 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch58(db_path: str):
    """Update batch 58 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '3cV1ajcDQ1P99tNgBumD',
            'name': 'Tesco Olive Oil And Sea Salt Croutons 100g',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Olive Oil (6%), Sugar, Yeast, Sea Salt.'
        },
        {
            'id': '3cwblSkx07oCYOHmd8nJ',
            'name': 'All Butter Shortbread',
            'brand': 'Lidl Deluxe',
            'serving_size_g': 17.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), 29% Salted Butter (Butter (Milk), Salt), Sugar, Cornflour, Raising Agents (Sodium Carbonates, Diphosphates), Natural Flavouring, Salt.'
        },
        {
            'id': '3d5HYZyDyPxkDl6pWKJs',
            'name': 'Diet Blue Charge Energy Drink',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Citric Acid, Taurine 0.4%, Flavourings, Acidity Regulator (Sodium Citrates), Sweeteners (Acesulfame K, Sucralose), Caffeine 0.03%, Preservative (Potassium Sorbate), Colour (Ammonia Caramel), Vitamins (Niacin B3, Pantothenic Acid B5, Vitamin B6, Vitamin B12), Inositol.'
        },
        {
            'id': '3dIlMWwA3XrSMg2KDPCx',
            'name': 'Original Steak Strips',
            'brand': 'New World Foods Europe Ltd Oakland Farms',
            'serving_size_g': 35.0,
            'ingredients': 'Beef (Made with 150g of Beef per 100g of Beef Jerky), Water, Demerara Sugar, Sea Salt, Apple Cider Vinegar, Pineapple Concentrate, Black Pepper, Dried Garlic, Dried Onion, Spices, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '3dYojcJNERHsrOSo2Jei',
            'name': 'Chicken Tikka',
            'brand': 'Everyday Essential Aldi',
            'serving_size_g': 80.0,
            'ingredients': 'Chicken Breast (95%), Stabiliser (Triphosphates), Salt, Tikka Seasoning (5%) (Sugar, Spices, Tomato, Tapioca Starch, Potato Starch, Salt, Garlic, Onion, Yeast Extract, Coconut Milk, Coriander, Colour (E150c)).'
        },
        {
            'id': '3dj2V2iVQxHa0ABbRMx9',
            'name': 'Veg Hoops',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes 42%, Veg Hoops 40% (Durum Wheat Semolina, Carrot Powder 4%, Cauliflower Powder 1%, Sweet Potato 12.7%), Water, Sugar, Modified Cornflour, Salt, Spice, Garlic Salt, Onion Extract, Acid (Citric Acid), Spice Extract.'
        },
        {
            'id': '3eNq8dTw53M2FH7l9THO',
            'name': 'Organic Original Milk Chocolate Alternative',
            'brand': 'Moo Free',
            'serving_size_g': 20.0,
            'ingredients': 'Sugar, Cocoa (Cocoa Mass, Cocoa Butter), Rice Powder (Rice Syrup, Rice Starch, Rice Flour), Shea Oil, Cinder Toffee Pieces (Sugar, Glucose Syrup, Raising Agent (Sodium Bicarbonate), Rice Flour), Inulin, Emulsifier (Sunflower Lecithin).'
        },
        {
            'id': '3erie90X3tWckMSrFvzD',
            'name': 'Morrisons Saver Yoghurts',
            'brand': 'Morrisons',
            'serving_size_g': 125.0,
            'ingredients': 'Yogurt (Milk), Sugar, Fruit Purée (Strawberry, Raspberry), Modified Maize Starch, Flavourings, Colour (Beetroot Red), Acidity Regulator (Citric Acid).'
        },
        {
            'id': '3erp9RHlGda9rvYdgCr8',
            'name': 'Dairy Milk Hazelnut',
            'brand': 'Cadbury',
            'serving_size_g': 23.8,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Chopped Hazelnuts, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings.'
        },
        {
            'id': '3fGP6EXvtDpGb3HEq5i0',
            'name': 'Southern Style Gravy Mix',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat, Calcium Carbonate, Iron, B1), Palm Oil, Sugar, Salt, Flavour Enhancer (E621), Dried Onions, Stock, Natural Flavours, Salt, Sunflower Oil, Colour (E150c), Black Pepper, Garlic.'
        },
        {
            'id': '3fMh75LfAQHcTs0rS8kV',
            'name': 'Pasta D\'aglio In Olio Di Girasole',
            'brand': 'Gia',
            'serving_size_g': 100.0,
            'ingredients': 'Garlic (60% - Origin Italy/Spain), Sunflower Oil, Salt, Preservative (Potassium Metabisulphite).'
        },
        {
            'id': '3fw6wm9ieelj6OtrAue3',
            'name': 'Oat So Simple Simply Apple',
            'brand': 'Quaker',
            'serving_size_g': 34.0,
            'ingredients': 'Quaker Wholegrain Rolled Oats (81%), Sweetener (Erythritol), Dried Apple Pieces (4%), Salt, Natural Flavourings.'
        },
        {
            'id': '3g54AcDR1rt7WktnURm6',
            'name': 'Caramel Shortbread',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Caramel 44% (Sweetened Condensed Milk (Milk, Sugar), Glucose Syrup, Invert Sugar Syrup, Palm Oil, Sugar, Water, Coconut Oil, Emulsifier (Lecithins (Soya)), Gelling Agent (Pectins)), Biscuit Base 41% (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Wholemeal Wheat Flour, Sugar, Inverted Sugar Syrup, Rapeseed Oil, Raising Agents (Sodium Carbonates, Ammonium Carbonates), Emulsifier (Lecithins (Rapeseed))), Milk Chocolate 15% (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Flavouring, Emulsifier (Lecithins (Soya))).'
        },
        {
            'id': '3gsqYCXLjSJ4q8yEeW6C',
            'name': 'Reese\'s Advent Calendar',
            'brand': 'Reese\'s',
            'serving_size_g': 9.0,
            'ingredients': 'Peanuts, Sugar, Vegetable Oils in Varying Proportions (Palm, Shea, Sunflower, Palm Kernel, Safflower), Dextrose, Skimmed Milk Powder, Corn Syrup, Lactose (Milk), Salt, Emulsifiers (Soy Lecithin, E476), Flavouring, Antioxidant (E319), Acidity Regulator (Citric Acid).'
        },
        {
            'id': '3j1lOaccs8YbIvkA4nH8',
            'name': 'Milk Chocolate Almond Honey Nougat',
            'brand': 'Tony\'s Chocolonely',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Dried Whole Milk, Cocoa Butter, Cocoa Mass, 10% Nougat (Cane Sugar, Glucose Syrup, 2% Almonds, Potato Starch, 0.1% Honey, Cocoa Butter, Egg White), Emulsifier (Soya Lecithin).'
        },
        {
            'id': '3jmZYVn18BPtqm65AmnE',
            'name': 'Bacon Rashers',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Rice Flour, Vegetable Oils (Rapeseed Oil, Sunflower Oil), Sugar, Yeast Extract, Stabiliser (Potassium Chloride), Flavouring, Salt, Maltodextrin, Onion Powder, Colours (Beetroot Red, Paprika Extract, Turmeric Extract).'
        },
        {
            'id': '3l4mxKONEdzai0z231or',
            'name': 'Cheddar Bar-b-que Snoop Dogg',
            'brand': 'Rap Snacks',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Vegetable Oil (May Contain One or More of the Following: Canola, Corn, Cottonseed, Soybean, Sunflower), BBQ Cheddar Seasoning (Sugar, Dextrose, Cheddar (Cultured Milk, Salt, Enzymes), Salt, Whey Powder, Monosodium Glutamate, Onion Powder, Paprika, Buttermilk Powder, Butter (Cream, Lactic Acid), Disodium Phosphate, Natural Flavour, Artificial Flavor, FD&C Yellow #5, FD&C Yellow #6, Malic Acid, Spice, Disodium Guanylate, Disodium Inosinate, Annatto for Color, Spice and Coloring (contains Turmeric)), Salt, Dextrose.'
        },
        {
            'id': '3neKqA9mVeBEthwmAHz1',
            'name': 'Chocolate Chip Brioche Rolls',
            'brand': 'Tesco',
            'serving_size_g': 32.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Dark Chocolate Chips (13%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithins)), Sugar, Water, Pasteurised Egg, Rapeseed Oil, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate), Dried Whole Milk, Yeast, Wheat Gluten, Salt, Thickener (Sodium Carboxy Methyl Cellulose), Milk Proteins, Flavouring, Antioxidant (Ascorbic Acid).'
        },
        {
            'id': '3nfJ9xIfV2W2khYsPb8B',
            'name': 'Fruit Pastilles',
            'brand': 'Aldi',
            'serving_size_g': 15.0,
            'ingredients': 'Sugar, Glucose Syrup, Maize Starch, Glucose-Fructose Syrup, Modified Potato Starch, Acids (Citric Acid, Malic Acid, Lactic Acid), Fruit and Plant Extracts (Black Carrot Concentrate, Turmeric Concentrate, Spirulina Concentrate, Safflower Concentrate, Radish Concentrate, Lemon Concentrate, Blueberry Concentrate, Apple Concentrate, Blackcurrant Concentrate), Flavourings.'
        },
        {
            'id': '3nybSFFh1jTmd7JWuuhm',
            'name': 'BBQ Chicken Breast Slices',
            'brand': 'The Deli Aldi UK',
            'serving_size_g': 30.0,
            'ingredients': 'Chicken Breast (98%), Iodized Salt (Salt, Potassium Iodate), Dextrose, Maize Starch, Modified Maize Starch, Rapeseed Oil, Stabiliser (Triphosphates), Antioxidant (Sodium Ascorbate), Sugar, Dried Onion, Dried Garlic, Dried Pepper, Dried Shallot, Smoked Salt, Dried Leek, Spice Extracts, Preservative (Sodium Nitrite).'
        },
        {
            'id': '3o5gR1nJXZPv9V9oFj9a',
            'name': 'Red Onion And Fontal Cheese Pantofola',
            'brand': 'M&S',
            'serving_size_g': 46.0,
            'ingredients': 'Wheat Flour (contains Gluten) (with Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Red Onions (12%), Regato Cheese (Milk) (8%), Durum Wheat Semolina (contains Gluten), Extra Virgin Olive Oil, Mozzarella Cheese (Milk) (2.5%), Yeast, Lemon Juice, Parsley, Salt, Dried Skimmed Milk, Cracked Black Pepper, Colour (Beetroot Red), Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '3oRtbn9HerQ4uEQ8hF3m',
            'name': 'Dry Roasted Peanuts',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts, Dry Roasted Flavour, Salt, Flavour Enhancer (Monosodium Glutamate), Yeast Extract, Rice Flour, Paprika, Spices & Herbs, Celery Seed Powder, Dried Onion, Dried Garlic, Colour (Paprika, Turmeric Extract), Smoke Flavouring, Stabiliser.'
        },
        {
            'id': '3phKH5I5worgBK3xLS0b',
            'name': 'Marmite Nuts',
            'brand': 'Graze',
            'serving_size_g': 100.0,
            'ingredients': 'Marmite Mini Broad Beans (43%) (Broad Beans (93%), Marmite Flavouring (Yeast Extract Powder, Rice Flour, Salt, Onion Powder, Natural Flavouring, Acid (Citric Acid)), Rapeseed Oil), Marmite Corn (37%) (Roasted Corn (90%), Vegetable Oil (Sunflower Oil, Rapeseed Oil), Yeast Extract Powder, Rice Flour, Natural Flavouring, Salt, Onion Powder, Citric Acid, Garlic Powder, Onion Juice Concentrate, Vitamin B Blend (Niacin, Maltodextrin, Thiamine, Vitamin B12, Riboflavin, Folic Acid)), Marmite Corn Hoops (20%) (Corn (67%), Sunflower Oil, Salt, Yeast Extract, Natural Flavouring, Molasses Powder, Acids (Citric Acid, Lactic Acid), Calcium Carbonate, Carob Powder, Spice, Herb Extract).'
        },
        {
            'id': '3q45NCcaX4v7aP9CcbI4',
            'name': 'Activated Chips',
            'brand': 'Boundless',
            'serving_size_g': 100.0,
            'ingredients': 'Sprouted Sorghum (43%), Yellow Pea Flour, Sea Salt and Cider Vinegar Flavour Seasoning (10%) (Rice Flour, Suffolk Cider Vinegar Powder, Natural Flavouring, Acid (Citric Acid), Salt, Sea Salt, Apple Powder), Sunflower Oil, Maize Flour, Calcium Carbonate.'
        },
        {
            'id': '3qHbIkJ6YaQqEB0LSldv',
            'name': 'Wholemeal Seeded Loaf',
            'brand': 'Aldi',
            'serving_size_g': 40.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Mixed Seeds (9%) (Linseed, Sunflower Seeds, Millet, Poppy Seeds), Mixed Grains (5%) (Malted Wheat Flakes, Kibbled Pearl Barley, Spelt (Wheat) Flakes), Wheat Gluten, Yeast, Salt, Emulsifiers (Mono-and Diglycerides of Fatty Acids, Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Spirit Vinegar, Preservative (Calcium Propionate), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 58\n")

    cleaned_count = update_batch58(db_path)

    # Calculate total progress
    previous_total = 836  # From batch 57
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 58 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 850 and previous_total < 850:
        print(f"\n🎉🎉🎉 850 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 13.2% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
