#!/usr/bin/env python3
"""
Clean ingredients batch 54 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch54(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 54\n")

    clean_data = [
        {
            'id': '4dIUCkvtLrXOi4SzBV82',
            'name': 'Gouda And Edam Crispies',
            'brand': 'Tesco',
            'serving_size_g': 5.0,
            'ingredients': 'Wheat Flour, Gouda Medium Fat Hard Cheese (23%) (Cheese (Milk), Colour (Mixed Carotenes)), Butter (Milk) (20%), Dried Whole Milk, Edam Medium Fat Hard Cheese (1%) (Cheese (Milk), Colour (Mixed Carotenes)), Sea Salt, Mustard Powder, White Pepper, Milk Proteins, Dextrose, Rapeseed Oil. Contains Cereals Containing Gluten, Milk, Mustard, Wheat.'
        },
        {
            'id': '4eWESNJFT8fSoBtlXG8R',
            'name': 'Mars Chocolate Bar',
            'brand': 'Mars',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Sunflower Oil, Milk Fat, Palm Fat, Lactose, Whey Permeate (from Milk), Fat Reduced Cocoa, Barley Malt Extract, Emulsifier (Soya Lecithin), Salt, Egg White Powder, Milk Protein, Vanilla Extract. Milk Chocolate Contains Milk Solids 14% Minimum. Milk Chocolate Contains Vegetable Fats in Addition to Cocoa Butter. Contains Barley, Cereals Containing Gluten, Eggs, Milk, Soybeans. May Contain Peanuts.'
        },
        {
            'id': '4fDrIXqKtj8kYdlE6SgE',
            'name': 'Vegan Coleslaw',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (45%), Vegan Mayonnaise (37%) (Rapeseed Oil, Water, Spirit Vinegar, Sugar, Broad Bean Protein, Salt, White Wine Vinegar, Cornflour, Stabilisers (Xanthan Gum, Guar Gum), Mustard Flour), Carrot (14%), Onion (2.5%), Water, Dijon Mustard (Water, Mustard Flour, Spirit Vinegar, Sea Salt, Mustard Husk, Ground Pimento, Ground Turmeric), Stabilisers (Guar Gum, Xanthan Gum), Preservative (Potassium Sorbate), Colour (Carotenes), Flavouring. Contains Mustard. May Contain Nuts, Peanuts.'
        },
        {
            'id': '4fKSxWKA9jjMQWW9wB5u',
            'name': 'Spinach And Ricotta Girasoli',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Ricotta and Spinach Filling (60%) (Ricotta Cheese (30%) (Milk), Spinach (10.8%), Sunflower Oil, Whey Powder (Milk), Breadcrumbs (Wheat Flour, Water, Salt), Dried Potato, Inulin, Cream Cheese (Cheese (Milk), Water, Salt), Salt, Wheat Flour, Garlic, Spinach Powder (0.2%), Natural Flavourings, Spices), Egg Pasta (40%) (Durum Wheat Semolina, Whole Egg (8%), Water). Contains Cereals Containing Gluten, Eggs, Milk, Wheat. May Contain Mustard, Soybeans.'
        },
        {
            'id': '4gaqTdJ0y9UEX3H0s7TZ',
            'name': 'Mint Cream',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Dark Chocolate (65%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Sunflower Lecithins), Vanilla Extract), Sugar, Glucose Syrup, Water, Invert Sugar Syrup, Peppermint Oil. Dark Chocolate Contains: Cocoa Solids 50% Minimum. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': '4goMoykUHGdPjq5yopAm',
            'name': 'Galaxy Chocolate Milk',
            'brand': 'Galaxy',
            'serving_size_g': 235.0,
            'ingredients': 'Milk (2.2% Fat) (64%), Recombined Whey (from Milk) (32%), Whey Powder (from Milk), Fat Reduced Cocoa Powder (0.9%), Barley Malt Extract, Modified Starch, Stabilisers (Carrageenan, Guar Gum), Emulsifier (Mono and Diglycerides of Fatty Acids), Salt, Natural Flavouring, Sweeteners (Acesulfame K, Sucralose). Contains Barley, Cereals Containing Gluten, Milk.'
        },
        {
            'id': '4hFUjOvC0aRY4Jn89hnM',
            'name': 'Roasted & Salted Jumbo Cashews',
            'brand': 'Co-op',
            'serving_size_g': 25.0,
            'ingredients': 'Cashew Nuts (96%), Sunflower Oil, Salt. Contains Nuts. May Contain Other Nuts, Peanuts.'
        },
        {
            'id': '4hPaaX6kuDwQD3ozGIlq',
            'name': 'G Almond',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Milk Chocolate (30%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Milk Fat, Cocoa Mass, Whey Powder (Milk), Emulsifiers (Lecithins (Sunflower), Polyglycerol Polyricinoleate), Flavouring), Whey Protein Concentrate (Milk), Glucose Syrup, Coconut Oil, Chopped Almonds (5%), Sugar, Skimmed Milk Powder, Emulsifier (Mono-and Diglycerides of Fatty Acids), Plant Extract (Carrot Concentrate), Stabilisers (Locust Bean Gum, Guar Gum), Natural Bourbon Vanilla Flavouring, Ground Extracted Vanilla Pod. Contains Milk, Nuts. May Contain Other Nuts.'
        },
        {
            'id': '4jYFpcnA5q0h9ob2s6vr',
            'name': 'Hazella Hazelnut Chocolate Spread',
            'brand': 'Hazella',
            'serving_size_g': 15.0,
            'ingredients': 'Sugar, Palm Oil, Hazelnuts (13%), Rapeseed Oil, Cocoa Powder (7.5%), Skimmed Milk Powder, Dried Glucose Syrup, Fat Reduced Sweet Whey Powder (Milk), Emulsifier (Lecithins). Contains Milk, Nuts.'
        },
        {
            'id': '4jqcUM3Y63RxH9lXz1iE',
            'name': 'German Style Salami',
            'brand': 'Deli Culture',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Glucose Syrup, Spices, Dextrose, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite). Prepared with 113g of Pork per 100g Salami. May Contain Celery, Cereals Containing Gluten, Mustard.'
        },
        {
            'id': '4kYEdhM5vVn3iU1Vw9Ds',
            'name': 'Instant Noodles',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Noodles (95%) (Wheat Flour, Palm Oil, Iodised Salt (Salt, Potassium Iodate), Sugar), Seasoning (Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Maltodextrin, Iodised Salt (Salt, Potassium Iodate), Onion Powder, Yeast Extract, Garlic Powder, Salt, Modified Maize Starch, Ground Turmeric, Acidity Regulator (Citric Acid), Dried Parsley, Xylose, Glucose, Flavouring, Black Pepper, Turmeric Extract, Colour (Plain Caramel)). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '4lKyZMFtlq5dumqYIYBm',
            'name': 'Tortellini Spinach And Ricotta',
            'brand': 'Tesco',
            'serving_size_g': 163.0,
            'ingredients': 'Fresh Egg Pasta (Wheat Flour, Durum Wheat Semolina, Pasteurised Egg, Water), Ricotta Full Fat Whey Cheese (Milk) (15%), Spinach (13%), Wheat Flour, Dried Potato, Medium Fat Hard Cheese (Milk), Dried Skimmed Milk, Butter (Milk), Salt, Wheat Fibre, Onion, Chicory Fibre, Olive Oil, Nutmeg, Black Pepper, Yeast, Garlic. Contains Cereals Containing Gluten, Eggs, Milk, Wheat. May Contain Soybeans.'
        },
        {
            'id': '4lcScb4zrKXbBi3nxFXy',
            'name': 'Golden Vegetable Savoury Rice',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Long Grain Rice (79%), Dried Mixed Vegetables (10%) (Peas, Carrot, Onion, Tomato, Green Pepper, Red Pepper), Maltodextrin, Flavourings (contain Celery), Lactose (Milk), Palm Oil, Onion Powder, Carrot Powder, Dried Garlic, Ground Turmeric, Salt, Colour (Paprika Extract). Contains Celery, Milk.'
        },
        {
            'id': '4lvpcichyo1okvNYXf93',
            'name': 'Blue Stilton Cheese',
            'brand': 'Farm Fresh',
            'serving_size_g': 100.0,
            'ingredients': 'Blue Stilton Cheese (Milk). Contains Milk.'
        },
        {
            'id': '4matUS9UQAaAyNYGkXfF',
            'name': 'Lindahls Pro+ Kvarg Banoffee Pie',
            'brand': 'Nestlé',
            'serving_size_g': 150.0,
            'ingredients': 'Quark (Skimmed Milk, Whey Proteins (from Milk), Lactic Cultures, Microbial Rennet), Banana Caramel Flavour Preparation (Water, Modified Maize Starch, Colour (Carotenes), Safflower Concentrate, Carrot Concentrate, Spirulina Concentrate, Natural Flavourings, Sweeteners (Aspartame, Acesulfame K)). Contains Milk. Contains a Source of Phenylalanine.'
        },
        {
            'id': '4nWJZGhfy2E0yC3IgOKS',
            'name': 'Tempura Chicken Nuggets',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (60%), Rice Flour, Water, Rapeseed Oil, Corn Starch, Potato Powder, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Pea Fibre, Salt, Dextrose, Anti-caking Agent (Silicon Dioxide), Stabiliser (Xanthan Gum), Concentrated Lemon Juice, Thyme Extract, Evaporated Cane Syrup, Cumin Extract, Black Pepper Extract.'
        },
        {
            'id': '4o7990ULyv81fEAsOYwM',
            'name': 'Red Berry Fibre Flakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cracked Wheat (85%), Sugar, Barley Malt Extract, Freeze Dried Fruits (2%) (Strawberry Pieces, Raspberries, Cranberry Slices), Salt, Iron, Vitamin E, Niacin (B3), Pantothenic Acid (B5), Vitamin B12, Vitamin D3, Thiamin (B1), Folic Acid (B9), Riboflavin (B2), Vitamin B6. Contains Barley, Cereals Containing Gluten, Wheat. May Contain Milk, Nuts, Oats, Rye, Spelt.'
        },
        {
            'id': '4oQhEmK7jCm8mga56NhD',
            'name': 'Genius Gluten Free Breakfast Bakes Honey, Raisin & Oat',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (33%), Margarine (Palm Oil, Rapeseed Oil, Water, Salt, Emulsifier (Polyglycerol Esters of Fatty Acids), Flavourings, Colours (Curcumin, Annatto)), Sugar, Raisins (9%), Soft Brown Sugar (Sugar, Cane Molasses, Invert Sugar Syrup, Colour (Plain Caramel)), Water, Honey (6%), Rice Flour, Potato Starch, Maize Flour, Raising Agents (Disodium Diphosphates, Sodium Bicarbonate, Sodium Hydrogen Carbonate), Stabiliser (Xanthan Gum), Sunflower Oil. Contains Oats. Not Suitable for Those with a Milk, Egg, Soya or Nut Allergy. Not Suitable for Those Who React to Avenin - A Protein in Oats.'
        },
        {
            'id': '4oSMROEGjg3pkea4W5DV',
            'name': 'Extra Mature Coloured Cheddar',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cheddar Cheese (Milk), Colour (Carotenes). Contains Milk.'
        },
        {
            'id': '4oUbB4Xd6qJEQKNdwp69',
            'name': 'Oat So Simple Classic Banana',
            'brand': 'Quaker',
            'serving_size_g': 100.0,
            'ingredients': 'Quaker Wholegrain Rolled Oats (80%), Sugar, Natural Flavourings, Salt. Contains Oats. May Contain Barley, Soybeans, Wheat.'
        },
        {
            'id': '4hfMjs60YIEAyYaSNL2c',
            'name': 'Cheesy Slices',
            'brand': 'Generic',
            'serving_size_g': 17.0,
            'ingredients': 'Cheese (60%) (Cheese (Milk), Acidity Regulator (Lactic Acid)), Water, Palm Oil, Emulsifying Salts (Polyphosphates, Calcium Phosphates, Sodium Phosphates), Modified Potato Starch, Flavouring (contains Milk), Milk Protein, Whey Powder (Milk), Colours (Carotenes, Paprika Extract). Contains Milk.'
        },
        {
            'id': '4qakmXFxU1RNEPE94EkD',
            'name': 'Cheddar Cheese Hash Brown Bites',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (78%), Sunflower Oil, Cheddar Cheese (Milk) (6%), Potato Flake, Potato Starch, Salt, Garlic Powder, Dextrose, Onion Powder, White Pepper. Contains Milk.'
        },
        {
            'id': '4rGyUXZSlZUdkyDWJgdU',
            'name': '4 White Ring Donuts',
            'brand': 'The Daily Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, White Sugar Frosting (9%) (Sugar, Vegetable Fats and Oils (Palm Kernel Fat, Palm Oil, Coconut Fat), Emulsifier (Lecithins)), Palm Oil, Sugar, Vegetable Fat and Oil (Palm Fat, Rapeseed Oil), Multi-Coloured Sugar Sprinkles (4%) (Sugar, Palm Kernel Fat, Potato Starch, Rice Flour, Corn Starch, Fruit & Vegetable & Plant Concentrates (Apple, Pumpkin, Lemon, Blackcurrant, Spirulina, Carrot, Hibiscus, Bell Pepper, Radish)), Yeast, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono-and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate), Gluten (Wheat), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Dextrose, Stabilizer (Guar Gum), Whey Powder (Milk), Lactose (Milk), Flour Treatment Agent (Ascorbic Acid), Concentrated Lemon Juice. Contains Cereals Containing Gluten, Milk, Wheat. May Contain Nuts, Soybeans.'
        },
        {
            'id': '4w8BBbR9dZKD6nBJqlSe',
            'name': 'Cypressa Hand Picked Whole Kalamata Olives',
            'brand': 'Cypressa',
            'serving_size_g': 100.0,
            'ingredients': 'Kalamata Olives, Water, Sea Salt, Red Wine Vinegar (Sulphites). Contains Sulphites.'
        },
        {
            'id': '4wzNP4zHa0Fybvf3h5Ud',
            'name': 'Chocolate Orange Cups',
            'brand': 'The Coconut Collab',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Coconut Cream (32%), Sugar, Dark Chocolate (9%) (Cocoa Mass, Sugar, Soy Lecithin, Natural Flavouring), Cocoa Powder, Modified Tapioca Starch, Diacetyl Tartaric Acid Esters Of Mono & Diglycerides Of Fatty Acids, Brazilian Orange Oil (0.3%), Carrageenan, Trisodium Phosphate, Guar Gum, Natural Flavouring, Salt. Contains Soybeans. Not Suitable for Peanut Allergy Sufferers. Packed in a Factory that Handles Dairy, Nuts and Peanuts.'
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

    total_cleaned = 736 + updates_made

    print(f"✨ BATCH 54 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Breaking 750 milestone check
    if total_cleaned >= 750:
        print(f"\n🎉🎉🎉 750 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 11.6% progress through the messy ingredients!")

    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch54(db_path)
