#!/usr/bin/env python3
"""
Batch 67: Clean ingredients for 25 products
Progress: 1061 -> 1086 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch67(db_path: str):
    """Update batch 67 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '5PWNzn6XM4TN9mPDSHYx',
            'name': 'Seasoning',
            'brand': 'Aldi',
            'serving_size_g': 9.0,
            'ingredients': 'Mixed Spices.'
        },
        {
            'id': '5QuxYILWbWcm9vUNphoR',
            'name': 'Halal Spanish Selection',
            'brand': 'Najma',
            'serving_size_g': 100.0,
            'ingredients': 'Turkey Meat, Turkey Fat, Salt, Lactose (Milk), Milk Proteins, Dextrin, Dextrose, Spices, Antioxidants (E331, E301), Yeast Extract, Flavouring, Preservatives (E250, E252), Natural Colouring (Beetroot Red).'
        },
        {
            'id': '5RA0OZVm7xo06hMtmzzy',
            'name': 'Potato Pops',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes 82%, Sunflower Oil, Rice Flour, Dried Potatoes, Potato Starch, Salt, Stabilizer (Methyl Cellulose), Dextrose, White Pepper, Onion Powder.'
        },
        {
            'id': '5S4vDXUoD4kFXBucy1ZU',
            'name': 'Morrison',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Mozzarella Cheese (Milk), Water, Fior di Latte Cheese (Milk), Tomato, Semi-dried Tomatoes (Cherry Tomato, Canola Oil, Salt, Garlic, Oregano), Tomato Passata, Pesto Sauce (Rapeseed Oil, Basil, Sunflower Oil, Medium Fat Hard Cheese (Milk), Wheat Flour, Salt, Garlic Purée, Wheat Protein), Tomato Purée, Rapeseed Oil, Dried Whole Rye Sourdough, Extra Virgin Olive Oil, Yeast, Sugar, Salt, Cornflour, Basil, Garlic Purée, Barley Malt, Black Pepper, Acidity Regulator (Citric Acid).'
        },
        {
            'id': '5SDO59Es8wRxlNEfwtMZ',
            'name': 'Mackerel In Tomato Sauce',
            'brand': 'The Fishmonger',
            'serving_size_g': 125.0,
            'ingredients': 'Mackerel (64%) (Fish), Tomato Paste (16%), Water, Rapeseed Oil, Sugar, Salt.'
        },
        {
            'id': '5SkWk9vzzV6WHIOqu7x6',
            'name': 'Scampi Bites',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Thiamin, Niacin), Wheat Starch, Salt, Colour (E160c), Water, Scampi (Crustaceans) (7%), Rapeseed Oil, Stabilisers (E450, E451, E452).'
        },
        {
            'id': '5SnWsc2tRXaNqZgtuPJJ',
            'name': '6 Sausage Rolls',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), 29% British Pork, Water, Margarine (Palm Oil, Rapeseed Oil, Water, Salt), Rusk (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin, Water, Salt, Raising Agent (Ammonium Bicarbonate)), Seasoning (Salt, Sugar, Spice (Ground Nutmeg, Ground Mace, Coarse Black Pepper, Ground White Pepper), Yeast Extract, Rubbed Parsley, Onion Powder, Garlic Powder), Rapeseed Oil, Wheat Flour, Flour Treatment Agent (L-Cysteine), Glaze (Milk Proteins, Dextrose, Rapeseed Oil, Salt, Dextrose).'
        },
        {
            'id': '5T20hQaq6peh1gJIQXUL',
            'name': 'Squezzy Strawberry Jam',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Strawberries, Gelling Agent (Pectin), Citric Acid, Acidity Regulator (Sodium Citrate).'
        },
        {
            'id': '5V45in0W6127uCQP9fG2',
            'name': 'Mozzarella Burger Vegetarian',
            'brand': 'Linda Mccartney',
            'serving_size_g': 114.0,
            'ingredients': 'Rehydrated Textured Soya Protein (65%), Rapeseed Oil, Mozzarella Cheese (Milk) (9%), Onion, Chickpea Flour, Flavouring, Yeast Extract, Stabiliser (Methyl Cellulose), Garlic Purée, Malted Barley Extract, Onion Powder, Salt, Garlic Powder.'
        },
        {
            'id': '5W2G8Hpo0NYDrFI82WdK',
            'name': 'Strawberry, Apple And Orange Fruit Stars',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fruit Juices from Concentrate (30%) (Apple 28%, Strawberry 1%, Orange 1%), Sugar, Glucose Syrup, Dextrine, Humectant (Sorbitol), Tapioca Starch, Gelling Agent (Pectin), Acidity Regulator (Citric Acid), Natural Flavourings, Fruit and Vegetable Juice Concentrates (Black Carrot, Apple, Radish and Blackcurrant), Coconut Oil, Colours (Paprika Extract, Curcumin), Spirulina Concentrate, Glazing Agent (Carnauba Wax).'
        },
        {
            'id': '5YmC3rXVvVe3cwyKBMXk',
            'name': 'French Dressing',
            'brand': 'Morrisons',
            'serving_size_g': 15.0,
            'ingredients': 'Rapeseed Oil (21%), Water, Cold-Pressed Rapeseed Oil (14%), Cider Vinegar (12%), Sugar, Dijon Mustard (8%) (Water, Mustard Seed, Spirit Vinegar, Salt), White Wine Vinegar, Wholegrain Mustard (Water, Mustard Seed, Spirit Vinegar, Salt), Cornflour, Salt, Parsley, Mustard Seed, Concentrated Lemon Juice, Garlic Purée, Cracked Black Pepper, Preservative (Potassium Sorbate), Stabiliser (Xanthan Gum).'
        },
        {
            'id': '5YoJmTmXMKYR4Z7dI67v',
            'name': 'Walkers Max Extra Flaming Hot',
            'brand': 'Walkers',
            'serving_size_g': 30.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in varying proportions), Extra Flamin\' Hot Seasoning (Sugar, Flavouring, Acidity Regulators (Citric Acid, Malic Acid), Dried Garlic, Salt, Potassium Chloride, Flavour Enhancer (Monosodium Glutamate), Dried Onion, Smoked Paprika Powder, Vegetable Concentrate, Jalapeno Pepper Powder, Spices, Herbs, Smoked Sunflower Oil, Smoked Maltodextrin, Colour (Paprika Extract), Antioxidants (Rosemary Extract, Ascorbic Acid, Tocopherol Rich Extract, Citric Acid)).'
        },
        {
            'id': '5bVWZ4shXbJyKibMkNvk',
            'name': 'Tomato Ketchup',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g Tomato Ketchup), Spirit Vinegar, Sugar, Salt, Spice and Herb Extracts (contain Celery), Spice.'
        },
        {
            'id': '5gvRenzPc5ivTS9yy0ng',
            'name': 'Tomato Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g of Ketchup), Spirit Vinegar, Sugar, Modified Maize Starch, Salt, Flavouring.'
        },
        {
            'id': '5l8zaRu75IZLRwCbaRS6',
            'name': 'Loaded Rings',
            'brand': 'Seabrook',
            'serving_size_g': 100.0,
            'ingredients': 'Maize 66%, Rapeseed Oil, Sour Cream and Onion Seasoning (Whey Powder (Milk), Onion Powder, Dextrose, Sugar, Salt, Unmodified Potato Starch, Sour Cream Powder (Milk), Flavourings (Milk), Acid (Citric Acid, Malic Acid, Lactic Acid, Calcium Lactate), Yeast Extract, Parsley), Firming Agent (Calcium Carbonate).'
        },
        {
            'id': '5lRsM9Zex4RKvaHwZeDj',
            'name': 'Black Pepper & Sea Salt Crackers',
            'brand': 'Lidl Rivercote',
            'serving_size_g': 5.5,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Niacin, Iron, Thiamin, Riboflavin, Folic Acid), Sunflower Oil, Palm Oil, 1.5% Sea Salt, Yeast (contains Wheat and Barley), Sugar, 0.5% Black Pepper, White Rice Flour, Sugar Cane Syrup, Flavouring, Yeast, Emulsifier (Sorbitan Monostearate).'
        },
        {
            'id': '5lWAW2JeKrNSUzP78m3F',
            'name': 'Pan Perfect Sweet Teriyaki',
            'brand': 'Nestlé',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Corn Starch, Soya Sauce 9.2% (Water, Soyabeans, Wheat, Salt), Dried Spices 4.2% (Ginger 3.7%, Red Cayenne Pepper), Salt, Yeast Extract, Caramelised Sugar, Flavourings, Sunflower Oil, Garlic Powder, Onion Powder.'
        },
        {
            'id': '5losRLL1Pxp7g0JEmwzx',
            'name': 'Pine Nuts',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pine Nuts.'
        },
        {
            'id': '5m7h8IcZdQkOQ7ORoDZv',
            'name': 'Caramel, Shortbread & Chocolate Crispies',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Wheat Flour (contains Gluten), Glucose Syrup, Butter (Milk), Sweetened Condensed Milk (Whole Milk, Sugar), Wholemeal Wheat Flour (contains Gluten), Emulsifier (Lecithins (Soya)), Cocoa Powder, Sunflower Oil, Salt, Natural Flavouring, Stabilizer (Carrageenan), Sea Salt.'
        },
        {
            'id': '5m8K4cOUpWAi4cweIzIi',
            'name': 'Triple Chocolate Crisp',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': '32% Oat Flakes, Sugar, 15% Crisped Rice (Rice Flour, Sugar, Barley Malt Extract, Calcium Carbonate), Palm Oil, Wheat Flakes, 5% Milk Chocolate Chunks (Sugar, Dried Whole Milk, Cocoa Mass, Cocoa Butter, Dried Whey (Milk), Emulsifier (Soya Lecithins)), 5% Dark Chocolate Chunks (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithins)), 5% White Chocolate Chunks (Sugar, Cocoa Butter, Dried Whole Milk, Dried Whey (Milk), Emulsifier (Soya Lecithins)), Desiccated Coconut, Fat-Reduced Cocoa Powder, Chopped Hazelnuts.'
        },
        {
            'id': '5n37YrrmNtLoWTQRC9ZW',
            'name': 'Seed, Berry & Goji Mix',
            'brand': 'Waitrose',
            'serving_size_g': 30.0,
            'ingredients': 'Pumpkin Seeds, Sunflower Seeds, Goji Berries, Pine Kernels, Cranberries, Blueberries, Pineapple Juice from Concentrate, Apple Juice from Concentrate, Glazing Agent (Sunflower Oil).'
        },
        {
            'id': '5n6LiRePsaIAPWnQbunw',
            'name': 'Sugar Free Rhubarb And Custard',
            'brand': 'Dominion',
            'serving_size_g': 100.0,
            'ingredients': 'Sweeteners (Isomalt, Sucralose), Butter (Milk), Acid (Lactic Acid), Flavourings, Emulsifier (Lecithins (Soya)), Colours (Titanium Dioxide, Paprika Extract), Salt, Elderberry Concentrate, Acidity Regulator (Sodium Lactate), Rhubarb Juice Concentrate, Turmeric Extract.'
        },
        {
            'id': '5nsrcaG9cawPc2GcZLHY',
            'name': 'Sliced Brioche Loaf',
            'brand': 'Tesco',
            'serving_size_g': 33.0,
            'ingredients': 'Wheat Flour, Pasteurised Egg (14%), Sugar, Rapeseed Oil, Water, Emulsifiers (Mono - and Di-Glycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate), Flavourings, Salt, Yeast, Wheat Gluten, Thickener (Tara Gum), Deactivated Yeast, Antioxidant (Ascorbic Acid), Colour (Algal Carotenes).'
        },
        {
            'id': '5nuHJdtXHbZTXnPMqcbT',
            'name': 'Cheesy Curls',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sunflower Oil, Potato Starch, Wheat Flour, Maize Flour, Cheese Flavour (Whey Powder (Milk), Salt, Flavourings (contains Milk), Onion Powder, Mature Cheddar Cheese Powder, Cheddar Cheese Powder (Milk), Cheese Powder (Milk), Salt, Buttermilk Powder, Potassium Chloride, Yeast Extract, Lactic Acid, Calcium Lactate (Milk), Colour (Paprika Extract)), Salt, Paprika Powder, Turmeric, Onion Powder, White Pepper.'
        },
        {
            'id': '5nynkaT7o9UJNqU1Af9c',
            'name': 'Street Food - Thai Style Stir Fry',
            'brand': 'Ben\'s Original',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Noodles (56%) (Water, Durum Wheat Semolina), Carrot (8.1%), Peanuts (8.1%), Red Pepper (6.1%), Spring Onion (4.0%), Water Chestnuts, Sugar, Sunflower Oil, Mushroom Powder, Ginger, Lemon Juice Powder, Onion, Yeast Extract, Garlic, Salt, Natural Coriander Flavouring (Sunflower Oil, Coriander Extract, Natural Flavouring), Soya Sauce Powder (Soya Sauce (Soya Beans, Wheat), Salt, Maltodextrin), Chilli, Stabiliser (Soya Lecithin), Maize Starch, Thickener (Guar Gum), Paprika Oleoresin (Paprika, Sunflower Oil, Basil Oil, Lemongrass Oil).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 67\n")

    cleaned_count = update_batch67(db_path)

    # Calculate total progress
    previous_total = 1061  # From batch 66
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 67 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1075 and previous_total < 1075:
        print(f"\n🎉 1075 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 16.7% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
