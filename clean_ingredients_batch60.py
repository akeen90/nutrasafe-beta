#!/usr/bin/env python3
"""
Batch 60: Clean ingredients for 25 products
Progress: 886 -> 911 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch60(db_path: str):
    """Update batch 60 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '4fDrIXqKtj8kYdlE6SgE',
            'name': 'Vegan Coleslaw',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (45%), Vegan Mayonnaise (37%) (Rapeseed Oil, Water, Spirit Vinegar, Sugar, Broad Bean Protein, Salt, White Wine Vinegar, Cornflour, Stabilisers (Xanthan Gum, Guar Gum), Mustard Flour), Carrot (14%), Onion (2.5%), Water, Dijon Mustard (Water, Mustard Flour, Spirit Vinegar, Sea Salt, Mustard Husk, Ground Pimento, Ground Turmeric), Stabilisers (Guar Gum, Xanthan Gum), Preservative (Potassium Sorbate), Colour (Carotenes), Flavouring.'
        },
        {
            'id': '4fKSxWKA9jjMQWW9wB5u',
            'name': 'Spinach And Ricotta Girasoli',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Ricotta and Spinach Filling (60%) (Ricotta Cheese (30%) (Milk), Spinach (10.8%), Sunflower Oil, Whey Powder (Milk), Breadcrumbs (Wheat Flour, Water, Salt), Dried Potato, Inulin, Cream Cheese (Cheese (Milk), Water, Salt), Salt, Wheat Flour, Garlic, Spinach Powder (0.2%), Natural Flavourings, Spices), Egg Pasta (40%) (Durum Wheat Semolina, Whole Egg (8%), Water).'
        },
        {
            'id': '4gK7nYjJKHU3wZv1bIdR',
            'name': 'Sweets',
            'brand': 'Dairy Milk',
            'serving_size_g': 27.2,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings.'
        },
        {
            'id': '4gaqTdJ0y9UEX3H0s7TZ',
            'name': 'Mint Cream',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Dark Chocolate (65%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Sunflower Lecithins), Vanilla Extract), Sugar, Glucose Syrup, Water, Invert Sugar Syrup, Peppermint Oil.'
        },
        {
            'id': '4hFUjOvC0aRY4Jn89hnM',
            'name': 'Roasted & Salted Jumbo Cashews',
            'brand': 'Co-op',
            'serving_size_g': 25.0,
            'ingredients': 'Cashew Nuts (96%), Sunflower Oil, Salt.'
        },
        {
            'id': '4hPaaX6kuDwQD3ozGIlq',
            'name': 'G Almond',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Milk Chocolate (30%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Milk Fat, Cocoa Mass, Whey Powder (Milk), Emulsifiers (Lecithins (Sunflower), Polyglycerol Polyricinoleate), Flavouring), Whey Protein Concentrate (Milk), Glucose Syrup, Coconut Oil, Chopped Almonds (5%), Sugar, Skimmed Milk Powder, Emulsifier (Mono-and Diglycerides of Fatty Acids), Plant Extract (Carrot Concentrate), Stabilisers (Locust Bean Gum, Guar Gum), Natural Bourbon Vanilla Flavouring, Ground Extracted Vanilla Pod.'
        },
        {
            'id': '4jqcUM3Y63RxH9lXz1iE',
            'name': 'German Style Salami',
            'brand': 'Deli Culture',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Glucose Syrup, Spices, Dextrose, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '4jrE5DN2VssYyAdbfaIx',
            'name': 'Plant Butter',
            'brand': 'Flora',
            'serving_size_g': 100.0,
            'ingredients': 'Plant Oils (Sunflower, Coconut, Rapeseed), Filtered Water, Sea Salt (1.1%), Fava Bean Preparation, Plant-Based Emulsifier (Sunflower Lecithin), Natural Flavourings, Colourant (Beta-Carotene).'
        },
        {
            'id': '4lKyZMFtlq5dumqYIYBm',
            'name': 'Tortellini Spinach And Ricotta',
            'brand': 'Tesco',
            'serving_size_g': 163.0,
            'ingredients': 'Fresh Egg Pasta (Wheat Flour, Durum Wheat Semolina, Pasteurised Egg, Water), Ricotta Full Fat Whey Cheese (Milk) (15%), Spinach (13%), Wheat Flour, Dried Potato, Medium Fat Hard Cheese (Milk), Dried Skimmed Milk, Butter (Milk), Salt, Wheat Fibre, Onion, Chicory Fibre, Olive Oil, Nutmeg, Black Pepper, Yeast, Garlic.'
        },
        {
            'id': '4mLl64oStX6cuo0eehk1',
            'name': 'Extra Sugarfree Peppermint 14g',
            'brand': 'Freepost Mars Wrigley Confectionery UK Ltd',
            'serving_size_g': 1.4,
            'ingredients': 'Sweeteners (Xylitol, Sorbitol, Aspartame, Mannitol, Acesulfame K), Gum Base, Thickener (Gum Arabic), Flavourings, Humectant (Glycerol), Emulsifier (Soybean Lecithin), Colour (E171), Glazing Agent (Carnauba Wax), Antioxidant (BHA).'
        },
        {
            'id': '4nEsoy411835MKwkcJ7K',
            'name': 'Dairylea D. Jumbo',
            'brand': 'Dairylea',
            'serving_size_g': 100.0,
            'ingredients': 'Dairylea Cheese Dip: Skimmed Milk (Water, Skimmed Milk Powder), Cheese, Concentrated Whey (from Milk), Inulin, Milk Protein, Milk Fat, Emulsifying Salts (Polyphosphates), Modified Starch, Calcium Phosphate, Acidity Regulator (Lactic Acid). Corn and Potato Snack: Corn Flour, Potato Granules, Palm Oil, Flavourings, Sugar, Salt, Onion Powder, Emulsifier (Mono - and Diglycerides of Fatty Acids), Yeast Extract, Garlic Powder, Parsley, Acid (Citric Acid), Rosemary, Horseradish.'
        },
        {
            'id': '4o7990ULyv81fEAsOYwM',
            'name': 'Red Berry Fibre Flakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cracked Wheat (85%), Sugar, Barley Malt Extract, Freeze Dried Fruits (2%) (Strawberry Pieces, Raspberries, Cranberry Slices), Salt, Iron, Vitamin E, Niacin (B3), Pantothenic Acid (B5), Vitamin B12, Vitamin D3, Thiamin (B1), Folic Acid (B9), Riboflavin (B2), Vitamin B6.'
        },
        {
            'id': '4oQhEmK7jCm8mga56NhD',
            'name': 'Genius Gluten Free Breakfast Bakes Honey, Raisin & Oat',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (33%), Margarine (Palm Oil, Rapeseed Oil, Water, Salt, Emulsifier (Polyglycerol Esters of Fatty Acids), Flavourings, Colours (Curcumin, Annatto)), Sugar, Raisins (9%), Soft Brown Sugar (Sugar, Cane Molasses, Invert Sugar Syrup, Colour (Plain Caramel)), Water, Honey (6%), Rice Flour, Potato Starch, Maize Flour, Raising Agents (Disodium Diphosphates, Sodium Bicarbonate, Sodium Hydrogen Carbonate), Stabiliser (Xanthan Gum), Sunflower Oil.'
        },
        {
            'id': '4oUbB4Xd6qJEQKNdwp69',
            'name': 'Oat So Simple Classic Banana',
            'brand': 'Quaker',
            'serving_size_g': 100.0,
            'ingredients': 'Quaker Wholegrain Rolled Oats (80%), Sugar, Natural Flavourings, Salt.'
        },
        {
            'id': '4pW7eW40NnEBNbiLsUPB',
            'name': '2 Fish Fillets Lightly Dusted',
            'brand': 'Birds Eye',
            'serving_size_g': 140.0,
            'ingredients': 'Alaska Pollock (Fish) (70%), Breadcrumb Coating (Wheat Flour, Water, Potato Starch, Herbs, Yeast, Sea Salt, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Dextrose, Black Pepper, Mustard, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil.'
        },
        {
            'id': '4pp9YEZsWqnvBWuU0cmE',
            'name': 'Wiltshire Cured Thick Cut Oak Smoked Ham',
            'brand': 'Aldi',
            'serving_size_g': 43.0,
            'ingredients': 'Outdoor Bred Pork, Salt, Sugar, Preservatives (Sodium Nitrite, Sodium Nitrate).'
        },
        {
            'id': '4r0OH0djFdoSMfHL48Zb',
            'name': 'Alpine Milk',
            'brand': 'Milka',
            'serving_size_g': 30.0,
            'ingredients': 'Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Whey Powder (from Milk), Milk Fat, Emulsifier (Soya Lecithins), Hazelnut Paste, Flavouring.'
        },
        {
            'id': '4rGyUXZSlZUdkyDWJgdU',
            'name': '4 White Ring Donuts',
            'brand': 'The Daily Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, White Sugar Frosting (9%) (Sugar, Vegetable Fats and Oils (Palm Kernel Fat, Palm Oil, Coconut Fat), Emulsifier (Lecithins)), Palm Oil, Sugar, Vegetable Fat and Oil (Palm Fat, Rapeseed Oil), Multi-Coloured Sugar Sprinkles (4%) (Sugar, Palm Kernel Fat, Potato Starch, Rice Flour, Corn Starch, Fruit & Vegetable & Plant Concentrates (Apple, Pumpkin, Lemon, Blackcurrant, Spirulina, Carrot, Hibiscus, Bell Pepper, Radish)), Yeast, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono-and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate), Gluten (Wheat), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Dextrose, Stabilizer (Guar Gum), Whey Powder (Milk), Lactose (Milk), Flour Treatment Agent (Ascorbic Acid), Concentrated Lemon Juice.'
        },
        {
            'id': '4sP72gFQSzH82ZV4glBy',
            'name': 'Apple And Sultana Dino Fruit Bars',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Dried Dates, Dried Apple (33%), Sultanas (16%).'
        },
        {
            'id': '4vAEzIZWfK7x8aokg5gO',
            'name': 'Glaze',
            'brand': 'Mr Organic',
            'serving_size_g': 100.0,
            'ingredients': 'Concentrated Grape Must, 39% Balsamic Vinegar of Modena (Wine Vinegar, Concentrated Grape Must), Wine Vinegar, Maize Starch.'
        },
        {
            'id': '4vuCAdRccSamJWWKZXCw',
            'name': 'Ritz Cracker',
            'brand': 'Mondelez International',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Palm Oil, Sugar, Glucose-Fructose Syrup, Raising Agents (Calcium Phosphates, Ammonium Carbonates, Sodium Carbonates, Potassium Carbonates), Salt, Barley Malt Flour, Colour (E150c).'
        },
        {
            'id': '4wzNP4zHa0Fybvf3h5Ud',
            'name': 'Chocolate Orange Cups',
            'brand': 'The Coconut Collab',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Coconut Cream (32%), Sugar, Dark Chocolate (9%) (Cocoa Mass, Sugar, Soy Lecithin, Natural Flavouring), Cocoa Powder, Modified Tapioca Starch, Diacetyl Tartaric Acid Esters Of Mono & Diglycerides Of Fatty Acids, Brazilian Orange Oil (0.3%), Carrageenan, Trisodium Phosphate, Guar Gum, Natural Flavouring, Salt.'
        },
        {
            'id': '4xJXxfpI15dZPwj5E6dH',
            'name': 'Fusilli Bronze',
            'brand': 'Deluxe Lidl',
            'serving_size_g': 220.0,
            'ingredients': 'Dried Durum Wheat Semolina.'
        },
        {
            'id': '4xgIAb5sKHDRk0hkaqox',
            'name': 'Chunky Cod Fishfingers',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cod (Gadus morhua) Fish (63%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Maize Starch, Durum Wheat Semolina, Salt, Wheat Gluten, Yeast, Yeast Extract, Onion Powder, Dried Garlic, Black Pepper Extract, Colour (Paprika Extract).'
        },
        {
            'id': '4y1HObEnN0PRIbx6XDI8',
            'name': 'Milk Chocolate Peanuts',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (47%), Skimmed Cows\' Milk Powder, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Oil (Rapeseed Oil, Sunflower Oil), Glazing Agents (Acacia Gum, Shellac), Glucose Syrup, Flavouring.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 60\n")

    cleaned_count = update_batch60(db_path)

    # Calculate total progress
    previous_total = 886  # From batch 59
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 60 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 900 and previous_total < 900:
        print(f"\n🎉🎉🎉 900 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 14.0% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
