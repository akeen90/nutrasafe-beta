#!/usr/bin/env python3
"""
Batch 69: Clean ingredients for 25 products
Progress: 1111 -> 1136 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch69(db_path: str):
    """Update batch 69 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '6sfGT9N4BskMHIojE9ta',
            'name': 'Tropical Wonder',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Gelling Agent (Pectin), Acidulant (Citric Acid), Natural Flavouring of Grapefruit with Other Natural Flavourings, Natural Colours (Curcumin, Paprika Extract, Anthocyanins), Coconut and Rapeseed Oil, Glazing Agent (Carnauba Wax).'
        },
        {
            'id': '6suddoxQ5YlcnirCHX3p',
            'name': 'Houmous',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Chickpeas (49%) (Chickpeas, Water), Water, Rapeseed Oil, Sesame Seed Paste (6%), Concentrated Lemon Juice (4%), Cornflour, Garlic Purée, Salt, Preservative (Potassium Sorbate).'
        },
        {
            'id': '6tCtt0BuChOfKO7PeDxj',
            'name': 'Blue Charge Energy Drink',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Sugar, Glucose-Fructose Syrup, Citric Acid, Taurine 0.4%, Flavourings, Acidity Regulator (Sodium Citrates), Fruit and Vegetable Extracts (Apple, Safflower, Lemon, Carrot, Hibiscus), Caffeine 0.03%, Vitamins (Niacin B3, Pantothenic Acid B5, Vitamin B6, Vitamin B12), Preservative (Potassium Sorbate), Sweeteners (Acesulfame K, Sucralose), Inositol.'
        },
        {
            'id': '6tRFSVu2IkgvzTHSG0Lj',
            'name': 'Dark Chocolate',
            'brand': 'Everyday Essentials Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Mass, Fat Reduced Cocoa Powder, Cocoa Butter, Emulsifiers (Lecithins (Soya), Polyglycerol Polyricinoleate), Vanilla Extract.'
        },
        {
            'id': '6tsaui7zlcTLMGHHoGEw',
            'name': 'Beetroot Falafel',
            'brand': 'Gosh',
            'serving_size_g': 76.0,
            'ingredients': 'Beetroot (31%), Chickpeas (31%), Red Pepper, Potato Flake, Onion, Rapeseed Oil, Garlic Puree (Water, Garlic Granules), Ground Coriander, Ground Cumin, Lemon Juice from Concentrate (Concentrated Lemon Juice, Water), Paprika, Salt, Chilli Flakes.'
        },
        {
            'id': '6u0THjNZZIODEya0jRI7',
            'name': 'Honey BBQ BEEF Jerky',
            'brand': 'Biltong',
            'serving_size_g': 65.0,
            'ingredients': 'Beef, Demerara Sugar, Water, Tomato Puree, Honey (2%), Sea Salt, Apple Cider Vinegar, Pineapple Concentrate, Black Pepper, Apricot Puree, Dried Garlic, Apple Concentrate, Spices, Dried Onion, Herb, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '6vJzQ23SohUEOPDhnR47',
            'name': 'Kefir',
            'brand': 'Yeo Valley Organic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Milk Fermented with Live Kefir Cultures, Organic Sugar (5%), Organic Mango Purée (3.6%), Organic Passion Fruit Juice (1.5%), Organic Maize Starch, Organic Concentrated Lemon Juice, Natural Flavourings.'
        },
        {
            'id': '6xUGkRIav2qVYxJrIHvW',
            'name': 'You\'re Gold',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Lustred Milk Chocolate Coated Honeycomb Pieces (8%) (Sugar, Glucose Syrup, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Lactose (Milk), Dried Whey (Milk), Butter Oil (Milk), Glazing Agent (Shellac), Colour (Iron Oxide), Raising Agent (Sodium Bicarbonate), Emulsifier (Lecithins (Soya)), Stabiliser (Gum Arabic), Coconut Oil), Cornflour, Rice Flour, Emulsifier (Lecithins (Soya)), Flavourings, Salt.'
        },
        {
            'id': '6xhItdjrsXr7jzI530dM',
            'name': 'Tropical Crush',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Pineapple Juice from Concentrate (2%), Grapefruit Juice from Concentrate (1%), Citric Acid.'
        },
        {
            'id': '6y6KBOsKgkX4fml9Gkg4',
            'name': 'Rice Noodle Chilli Miso',
            'brand': 'Itsu',
            'serving_size_g': 63.0,
            'ingredients': 'Rice Noodles (62%) (Rice, Modified Tapioca Starch, Sugar, Salt, Stabiliser (Guar Gum)), Broth Paste (36%) (Soybean Paste (Water, Soya Beans, Rice, Salt), Water, Sesame Oil, Alcohol, Sugar, Yeast Extract Powder, Seasoned Kelp Extract (Kelp, Salt, Dextrin), Salt, Shiitake Mushroom Extract, Onion Powder, Chilli Pepper, Coriander, Ginger Powder, Black Pepper), Red Pepper, Leek (Sulphites).'
        },
        {
            'id': '6yO495q7z2cNdBjBp8Ak',
            'name': 'Scotch Pancakes',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Sugar, Pasteurized Egg, Whey Powder (Milk), Rapeseed Oil, Raising Agents (Diphosphates, Potassium Carbonates), Buttermilk, Preservatives (Calcium Propionate, Potassium Sorbate), Acidity Regulator (Citric Acid), Salt.'
        },
        {
            'id': '6z0FeuFn9R6zO3cqKmM8',
            'name': 'Creamy Greek Honey Yogurt',
            'brand': 'Milbona',
            'serving_size_g': 150.0,
            'ingredients': 'Greek Style Yogurt (Milk), Water, 6% Honey, Sugar, Maize Starch, Stabiliser (Pectins), Natural Flavouring, Concentrated Lemon Juice.'
        },
        {
            'id': '6zckbxfQ4PfaKWkNhZCR',
            'name': 'Fresh Fusilli',
            'brand': 'Dell Ugo',
            'serving_size_g': 100.0,
            'ingredients': 'Chickpea Flour, Water.'
        },
        {
            'id': '710kQsP3in0EHxNwBlnV',
            'name': 'Smoked Salmon Sushi',
            'brand': 'Tesco',
            'serving_size_g': 57.0,
            'ingredients': 'Cooked White Sushi Rice (Water, White Rice, Rice Vinegar, Sugar, Spirit Vinegar, Rapeseed Oil, Salt), Cucumber, Low Fat Soft Cheese (Milk), Smoked Salmon (Fish) 5%, Soy Sauce Bottle (Water, Soya Bean, Salt, Vinegar), Nori Seaweed, Black Sesame Seeds, Cornflour, Salt, Sugar.'
        },
        {
            'id': '712VkE623wlbrG1OiglJ',
            'name': 'Wensleydale With Cranberries',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Wensleydale Cheese (Milk), 13% Sweetened Dried Cranberries (Cranberries, Sugar, Sunflower Oil, Fructose).'
        },
        {
            'id': '714ekXKLWJATHUe4DZnO',
            'name': 'Farmhouse Loaf',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Leckford Estate Wheat Flour 47% (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rye Sourdough 6% (Water, Wholemeal Rye Flour, Rye Flour, Salt, Starters), Rye Flour, Wholemeal Wheat Flour, Sea Salt, Wheat Gluten, Coarse Wheat Malt, Caramelised Malted Wheat Flour, Malted Wheat Flour, Wheat Germ, Barley Malt Extract.'
        },
        {
            'id': '71Czp4TR6gwUGJRqy18r',
            'name': 'Sliced Bloomer',
            'brand': 'Morrisons',
            'serving_size_g': 57.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Yeast, Fermented Wheat Flour, Wheat Flour, Salt, Rice Flour, Dextrose, Acidity Regulators (Calcium Sulphate, Citric Acid), Raising Agents (Sodium Carbonates, Ammonium Carbonates), Flour Treatment Agents (L-Cysteine, Ascorbic Acid), Malted Barley, Sourdough Culture, Preservative (Calcium Propionate).'
        },
        {
            'id': '72QLHV36MK19l6XM4ZjN',
            'name': 'Fasolka Po Bretonsku',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Cooked White Beans 30%, Smoked, Parboiled Poultry and Pork Sausage 8% (Poultry Meat 60%, Pork Meat 18%, Salt, Native Starch, Spices (including Garlic), Aroma, Beetroot Juice Powder, Acerola Juice Concentrate, Maltodextrin, Starter Cultures), Tomato Concentrate 2.7%, Fried Onion 1.7% (Onion, No Fat), Modified Starch, Wheat Flour, Sugar, Salt, Spice Extracts, Spices, Flavor Enhancers (Monosodium Glutamate, Disodium Ribonucleotides), Maltodextrin, Marjoram, Fresh Garlic, Flavoring Preparations, Bay Leaf Extract, Allspice Extract.'
        },
        {
            'id': '72aym1uKut33jz7gjrDk',
            'name': 'Maryland Cookies',
            'brand': 'Maryland',
            'serving_size_g': 20.083,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Chocolate Chips (25%) (Sugar, Cocoa Mass, Vegetable Fats (Sustainable Palm, Shea, Sal), Emulsifiers (Soya Lecithin, E442, E476), Cocoa Butter, Flavourings), Sugar, Sustainable Palm Oil, Whey or Whey Derivatives (Milk), Partially Inverted Sugar Syrup, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Salt, Flavourings.'
        },
        {
            'id': '732IN8hK6dnc0SokR20i',
            'name': 'Tropical Fruits Granola',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes 65%, Sugar, Coconut 3.5%, Dried Banana Chips 3.5% (Banana, Coconut Oil, Sugar, Flavouring), Sweetened Dried Papaya 3.5% (Papaya, Sugar, Preservative (Sulphur Dioxide)), Sweetened Dried Pineapple 3.5% (Sugar, Pineapple, Acid (Citric Acid), Preservative (Sulphur Dioxide)), Palm Oil, Honey, Chopped Almonds, Sunflower Seeds, Flavouring.'
        },
        {
            'id': '6ya86opR85NtUvT31gXm',
            'name': 'Crispy Chicken Breast Strips',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast with Added Water (64%) (Chicken Breast 90%, Water, Tapioca Starch, Salt), Wheat Flour, Rapeseed Oil, Wheat Semolina, Maize Starch, Wheat Gluten, Modified Wheat Starch, Salt, Dextrose.'
        },
        {
            'id': '6ybkUuWnHPdyZr9tyOBt',
            'name': 'British Corned Beef',
            'brand': 'M&S',
            'serving_size_g': 27.0,
            'ingredients': 'British Beef, Curing Salt, Salt, Preservative (Sodium Nitrite), Sugar.'
        },
        {
            'id': '74gy6xv8jB0giKtV9bd0',
            'name': '2 Butternut Squash And Chickpea Pastry Parcels',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Butternut Squash (8%), Chickpeas (8%), Spinach, Chopped Tomatoes, Coconut Milk (Water, Coconut Milk), Diced Apricots (Apricots, Rice Flour, Preservative (Sulphur Dioxide)), Red Pepper, Chopped Dates (Dates, Rice Flour), Rapeseed Oil, Garlic Purée, Ginger Purée, Modified Maize Starch, Sugar, Spices, Salt, Potato Flake, Coriander, Stabiliser (Hydroxypropyl Methyl Cellulose), Tomato Powder, Emulsifier (Mono - and Diglycerides of Fatty Acids), Garlic Powder, Turmeric Extract, Wheat Protein, Parsley.'
        },
        {
            'id': '75rdhN7YiCkL97Hl79Dw',
            'name': 'Hummus',
            'brand': 'Jack\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Chickpeas 52% (Chickpeas, Water), Water, Sesame Seed Paste 13%, Rapeseed Oil, Concentrated Lemon Juice 4%, Garlic Purée 1%, Salt, Preservative (Potassium Sorbate).'
        },
        {
            'id': '75rxFO6UwV8P281AcCtG',
            'name': 'Tartare',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil, Water, Spirit Vinegar, Sugar, Diced Gherkins (8%) (Gherkin, Salt, Water, Acidity Regulator (Acetic Acid)), Glucose-Fructose Syrup, Capers (2%) (Capers, Acidity Regulator (Acetic Acid), Salt, White Wine Vinegar), Salt, Modified Maize Starch, Dried Free Range Egg Yolk, Mustard Flour, Parsley, Stabiliser (Xanthan Gum), Preservative (Potassium Sorbate), Dried Garlic.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 69\n")

    cleaned_count = update_batch69(db_path)

    # Calculate total progress
    previous_total = 1111  # From batch 68
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 69 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1125 and previous_total < 1125:
        print(f"\n🎉 1125 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 17.4% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
