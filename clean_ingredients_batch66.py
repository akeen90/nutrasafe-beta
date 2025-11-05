#!/usr/bin/env python3
"""
Batch 66: Clean ingredients for 25 products
Progress: 1036 -> 1061 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch66(db_path: str):
    """Update batch 66 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '4W2ESQoPuiZNBLxDD5sv',
            'name': 'Unsmoked Back Bacon',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (87%), Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': '4XAPBcJFk8jn3Qz6Ixon',
            'name': 'Arrabiata Ravioli',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Maize Flour, Vegetable Oils (Coconut, Sunflower), Red Pepper 9%, Corn Starch, Tomato Pulp 6%, Tomato, Tomato Juice, Acidity Regulator (Citric Acid), Modified Maize Starch, Onion, Tomato Purée 3%, Vegetable Fibres (Chicory, Pea, Psyllium), Dried Potato, Potato Starch, Chilli Pepper 1%, Basil, Salt, Sun Dried Tomato, Pea Protein, Rice Starch, Thickeners (Xanthan Gum, Guar Gum), Garlic, Flavouring, Acidity Regulators (Citric Acid, Sodium Hydrogen Carbonate), Oregano, Black Pepper, Calcium Carbonate, Stabiliser (Tara Gum), Colour (Carotenes), Vitamin B12.'
        },
        {
            'id': '4XO0uI7YEV2MHml9vk7P',
            'name': 'Mature English Cheddar',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mature Cheddar Cheese (Milk).'
        },
        {
            'id': '4XmXH2KQYxhoEuPypyRH',
            'name': 'Reduced Sugar Thick Cut Orange Marmalade',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Water, Oranges, Gelling Agent (Pectin), Acidity Regulators (Citric Acid, Sodium Citrate), Stabiliser (Guar Gum), Preservative (Potassium Sorbate), Colour (Plain Caramel), Orange Oil.'
        },
        {
            'id': '4Z2mG7FuYrPODsQb74K6',
            'name': 'Diet Cola',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Colour (Sulphite Ammonia Caramel), Acids (Phosphoric Acid, Citric Acid), Sweeteners (Aspartame, Acesulfame K), Preservative (Potassium Sorbate), Flavourings (contains Caffeine).'
        },
        {
            'id': '4ZUsqN0Vh2F5SqHzmPaM',
            'name': 'Cadbury Dairy Milk',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings.'
        },
        {
            'id': '4a5qzsfclJYq9YQkKDnV',
            'name': 'West Country Cheddar And Chive Sourdough',
            'brand': 'Coop Irresistible',
            'serving_size_g': 63.0,
            'ingredients': 'Wheat Flour, Water, Red Leicester (contains Colour (Annatto)) (Milk) (6%), West Country Cheddar (Milk) (4%), Rice Flour, Rye Flour, Yeast Extract, Fermented Wheat Flour, Chives (1%), Rapeseed Oil, Salt, Potato Starch.'
        },
        {
            'id': '4RvPSejhoOIUNTdq5tT1',
            'name': 'Oatcakes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Oatmeal 63%, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Rapeseed Oil, Brown Sugar, Salt, Raising Agents (Diphosphates E450, Bicarbonate of Soda E500).'
        },
        {
            'id': '4bQA1mNHZRDEZdR3Iaiv',
            'name': 'German Salami',
            'brand': 'Tesco',
            'serving_size_g': 31.0,
            'ingredients': 'Pork, Salt, Glucose Syrup, White Pepper, Garlic, Antioxidants (Ascorbic Acid, Sodium Erythorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '4bW0D7cM8zp1hHvLkNrg',
            'name': 'Crunchy And Piquant Pickled Cornichons And Onions',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cornichons, Water, Onions, Sugar, Salt, Spirit Vinegar, Mustard Seeds, Acidity Regulator (Acetic Acid), Spice Extracts, Firming Agent (Calcium Chloride), Preservative (Sulphur Dioxide).'
        },
        {
            'id': '4cwutxBZi0bX0devfpyg',
            'name': 'Raspberry Preserve',
            'brand': 'Fortnum & Mason',
            'serving_size_g': 100.0,
            'ingredients': 'Raspberries, Cane Sugar, Acidity Regulator (Citric Acid), Gelling Agent (Pectin).'
        },
        {
            'id': '4eWESNJFT8fSoBtlXG8R',
            'name': 'Mars Chocolate Bar',
            'brand': 'Mars',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Sunflower Oil, Milk Fat, Palm Fat, Lactose, Whey Permeate (from Milk), Fat Reduced Cocoa, Barley Malt Extract, Emulsifier (Soya Lecithin), Salt, Egg White Powder, Milk Protein, Vanilla Extract.'
        },
        {
            'id': '4yQb6IR0ZQ3zSSJRO46Z',
            'name': 'Quaker',
            'brand': 'Quaker',
            'serving_size_g': 57.0,
            'ingredients': 'Quaker Rolled Oats (67%), Skimmed Milk Powder, Sugar, Salt, Natural Flavourings, Anticaking Agent (Calcium Phosphate).'
        },
        {
            'id': '4yX6EZcqOBapMpZVqrWL',
            'name': 'Twirl Easter Egg',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings.'
        },
        {
            'id': '4ygwKz4neAwz1H0qCqnW',
            'name': 'Amaizin Organic Tortilla Chips Paprika',
            'brand': 'Amaizin',
            'serving_size_g': 100.0,
            'ingredients': 'Corn Flour (73%), Sunflower Oil, Paprika Mix (5%) (Sea Salt, Glucose Syrup, Spices (Paprika, Black Pepper, Garlic), Sugar, Onion, Tomato, Paprika Extract, Lovage).'
        },
        {
            'id': '4z33MWDJ5Fj1ltfOqv38',
            'name': 'Mini Rolls Raspberry',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (32%) (Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Milk Fat, Palm Oil, Shea Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Soya)), Flavouring), Vanilla Flavour Filling (19%) (Water, Dextrose, Humectant (Glycerol), Preservative (Potassium Sorbate), Emulsifiers (Mono - and Diglycerides of Fatty Acids, Polyglycerol Esters of Fatty Acids), Flavourings, Stabiliser (Sorbitol)), Jam (Plum and Raspberry Purée, Water, Acidity Regulators (Citric Acid, Sodium Citrates), Concentrated Raspberry Purée, Flavouring, Colour (Anthocyanins), Gelling Agent (Pectins), Preservative (Potassium Sorbate)), Wheat Flour, Sugar, Pasteurised Soya Flour, Whey Powder (Milk), Dextrose, Raising Agents (Diphosphates, Potassium Carbonates), Emulsifiers (Mono-and Diglycerides of Fatty Acids, Polyglycerol Esters of Fatty Acids), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Oil, Glucose Syrup, Rapeseed Oil, Humectant (Glycerol), Preservative (Potassium Sorbate), Thickener (Xanthan Gum), Acidity Regulator (Calcium Lactate), Stabiliser (Sorbitol), Flavouring.'
        },
        {
            'id': '4zJ88QNuE6dDvwtsDc5l',
            'name': 'Weetabix Oatiflakes',
            'brand': 'Weetabix',
            'serving_size_g': 30.0,
            'ingredients': 'Wholegrain Oats (93%), Sugar, Malted Barley Extract, Potassium Chloride, Salt, Niacin, Iron, Pantothenic Acid (B5), Thiamin (B1), Riboflavin (B2), Vitamin B6, Folic Acid, Vitamin B12.'
        },
        {
            'id': '4zMqjzOCoCa3ZkKw7d96',
            'name': 'Fibre Wholegrain OATS Harvest Morn NO Added Sugar',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oat Flakes 50%, Chicory Fibre, Rapeseed Oil, Raisins 8%, Rice Flour, Maize Starch, Flaked Almonds 2.5%, Cashew Nuts 2.5%, Almonds 2%, Sunflower Seeds, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Desiccated Coconut, Brazil Nuts 1%, Malted Barley Flour, Flavouring, Sunflower Oil.'
        },
        {
            'id': '51sPTzzvvk4IHokeSZbP',
            'name': 'Gourmet Sea Alt And Black Pepper Crackers',
            'brand': 'Specially Selected',
            'serving_size_g': 21.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, High Oleic Sunflower Oil, Sea Salt (1%), Autolysed Yeast, Dextrose, Black Pepper (0.5%), Sugar, Whey Powder (Milk), Partially Inverted Refiners Syrup, Dried Yeast, Flavourings, Yeast Extract.'
        },
        {
            'id': '51vn615FfHqcad3c4dMH',
            'name': 'Deluxe Festive Mini Pizzas',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Pizza Base (Fortified Wheat Flour, Water, Durum Wheat Semolina, Yeast, Rapeseed Oil, Salt, Dried Sourdough, Sugar), Tomato Sauce, Mozzarella Cheese, Regato Cheese, Cheddar Cheese, Chargrilled Turkey, Cranberry Sauce, Pork Sausage Wrapped in Bacon, Red Onions.'
        },
        {
            'id': '52qY3hGDd1b78P0pBNvW',
            'name': 'Peas And Carrots',
            'brand': 'Batchelors',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetables (Carrots 32%, Peas 31%), Water.'
        },
        {
            'id': '52rKcXdorUrvSKhWrv9L',
            'name': 'Plain Tortilla Wrap',
            'brand': 'Planet Deli',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Humectant (Glycerol), Palm Oil, Dextrose, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Emulsifier (Mono and Di-glycerides of Fatty Acids), Citric Acid, Preservatives (Potassium Sorbate, Calcium Propionate), Salt, Flour Treatment Agent (L-Cysteine Hydrochloride).'
        },
        {
            'id': '53D9aaauzRkORnFKR3qu',
            'name': 'Sliced Carrots In Water',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Carrots, Water.'
        },
        {
            'id': '546QhIBKKshf0avhoN2e',
            'name': '4 Battered Haddock',
            'brand': 'The Fishmonger',
            'serving_size_g': 100.0,
            'ingredients': 'Haddock 52%, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Rapeseed Oil, Sunflower Oil), Wheat Starch, Salt, Raising Agents (Diphosphates, Sodium Carbonates), Maize Flour, Yeast Extract, Palm Fat, Dextrose, Colour (Paprika Extract), Black Pepper Extract, Yeast.'
        },
        {
            'id': '54X92iTC5lTrvTKKTzIx',
            'name': 'BBQ Flavour Potato Snacks',
            'brand': 'Snackrite',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Flakes, High Oleic Sunflower Oil (26%), Wheat Starch, Potato Starch, Barbecue Flavour (Sugar, Salt, Rice Flour, Flavour Enhancers (Monosodium Glutamate, Disodium 5\'-Ribonucleotides), Tomato Powder, Flavouring, Smoke Flavouring, Onion Powder, Carob Flour, Garlic Powder, Acids (Citric Acid, Malic Acid), Yeast Extract Powder, Colour (Paprika Extract), Maltodextrin), Glucose Syrup, Emulsifier (Mono - and Diglycerides of Fatty Acids), Rapeseed Oil, Salt.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 66\n")

    cleaned_count = update_batch66(db_path)

    # Calculate total progress
    previous_total = 1036  # From batch 65
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 66 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1050 and previous_total < 1050:
        print(f"\n🎉 1050 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 16.3% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
