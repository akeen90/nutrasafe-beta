#!/usr/bin/env python3
"""
Batch 59: Clean ingredients for 25 products
Progress: 861 -> 886 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch59(db_path: str):
    """Update batch 59 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '48XLyI0QE83yHd8wGztS',
            'name': 'Seasoned Fries',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (86%), Sunflower Oil (5%), Rice Flour, Dextrin, Potato Starch, Garlic Powder, Black Pepper, Red Pepper Powder, Onion Powder, Flavouring, Chilli Powder, Salt.'
        },
        {
            'id': '49e71yI6D0PybXWR8Mas',
            'name': 'Oxo Stock Pots',
            'brand': 'Oxo',
            'serving_size_g': 100.0,
            'ingredients': 'Water, De-alcoholised Red Wine Extract (17%), Dried Glucose Syrup, Sugar, Red Wine Vinegar, Gelling Agent (Pectin), Iodised Salt, Acidity Regulator (Lactic Acid), Preservative (Potassium Sorbate), Salt, Natural Rosemary Flavouring.'
        },
        {
            'id': '49k1tNp0LPWaTQhWEO4K',
            'name': 'Hazel Nutter',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (with Calcium Carbonate, Iron, Niacin and Thiamin), Sugar, Sustainable Palm Oil, Chocolate Chips (12%) (Sugar, Cocoa Mass, Vegetable Fats (Sustainable Palm, Sal, Shea), Emulsifiers (Soya Lecithin, E442, E476), Cocoa Butter, Flavourings), Roasted Nibbed Hazelnuts (4%), Fat Reduced Cocoa Powder, Partially Inverted Sugar Syrup, Whey or Whey Derivatives (Milk), Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavourings.'
        },
        {
            'id': '4AO3OcWgZY4G1yHEUjSH',
            'name': 'Triple Chocolate Cookies',
            'brand': 'Belmont',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Dark Chocolate Chunks (16%) (Sugar, Cocoa Mass, Vegetable Fats (Mango Fat, Palm Fat, Shea Fat, Sal Fat), Cocoa Butter, Emulsifier (Lecithins (Soya))), Palm Oil, White Chocolate Chunks (11%) (Sugar, Cocoa Butter, Whole Milk Powder, Whey Powder (Milk), Lactose (Milk), Butter Oil (Milk), Flavouring, Emulsifier (Lecithins (Soya))), Oatmeal, Partially Inverted Sugar Syrup, Desiccated Coconut, Cocoa Powder, Glucose Syrup, Molasses, Raising Agents (Ammonium Carbonates, Sodium Carbonates, Diphosphates), Salt, Emulsifier (Lecithins (Soya)).'
        },
        {
            'id': '4APy8fZrOoVZjJhrmydS',
            'name': 'Pulled Pork With Apple Sauce',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Shoulder (74%) (Pork (91%), Water, Glucose Syrup, Salt, Modified Maize Starch, Stabilisers (Diphosphates, Triphosphates), Acidity Regulators (Sodium Citrates, Citric Acid), Yeast Extract), Apple Sauce (23%) (Apple Purée (31%), Water, Sugar, Apple Juice (9%), Candied Apple (Apple, Sugar, Glucose-Fructose Syrup), Dehydrated Diced Apple (5%) (Apple, Preservative (Sodium Metabisulphite)), Lemon Juice, Cornflour, Preservative (Potassium Sorbate)), Sage and Salt Glaze (3%) (Sage, Salt).'
        },
        {
            'id': '4BMog9QMkaJITiq0YCyT',
            'name': 'Apple And Raspberry Water',
            'brand': 'Spa',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Spring Water, Acid (Malic Acid), Natural Apple and Raspberry Flavourings with other Natural Flavourings, Acidity Regulator (Sodium Citrate), Preservative (Potassium Sorbate), Sweetener (Sucralose).'
        },
        {
            'id': '44f73sAPmpCqQGTwexPX',
            'name': 'Tesco Chunky Chicken And Vegetable Soup',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Mixed Vegetables (32%) (Potato, Carrot, Onion, Garden Peas), Chicken (12%), Modified Maize Starch, Tomato Purée, Salt, Yeast Extract, Onion Powder, Rapeseed Oil, Parsley, Garlic Powder, Sugar, Leek Powder, White Pepper, Sage Extract, Colour (Algal Carotenes), Lemon Juice, Glucose Syrup, Sage, Spinach Powder, Parsley Extract, Flavourings.'
        },
        {
            'id': '4EgBGo9HGLsegOz79p4D',
            'name': 'Houghton British Wiltshire Cured Honey Roast Ham',
            'brand': 'Houghton British Wiltshire',
            'serving_size_g': 43.0,
            'ingredients': 'British Pork Leg, Salt, Demerara Sugar, Honey (1%), Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Sodium Nitrite).'
        },
        {
            'id': '4FZulDaRsiIXYdQz1fi7',
            'name': 'Tangy & Juicy Sweet Pickle',
            'brand': 'Asda',
            'serving_size_g': 15.0,
            'ingredients': 'Sugar, Carrots 13%, Swede 13%, Onions 10%, Barley Malt Vinegar, Water, Tomato Purée, Cauliflower 4%, Salt, Cornflour, Apple Pulp, Date Paste (Chopped Dates, Rice Flour), Lemon Juice from Concentrate, Courgettes 1%, Acidity Regulator (Acetic Acid), Dried Vegetarian Onions, Gherkins 1%, Roast Barley Malt Extract, Spices, Garlic Extract.'
        },
        {
            'id': '4G1VkDaioTzJBWrri9xJ',
            'name': 'Energy Drink',
            'brand': 'Redbull',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sucrose, Glucose, Carbon Dioxide, Taurine 0.4%, Acidity Regulators (Sodium Carbonates, Magnesium Carbonates), Caffeine 0.03%, Vitamins (Niacin, Pantothenic Acid, B6, B12), Flavourings, Colours (Plain Caramel, Riboflavins).'
        },
        {
            'id': '4GneNNtLOgPY5nFvKAwu',
            'name': 'Hotel Chocolat Cherry Deluxe',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 29.7,
            'ingredients': 'Cocoa Solids (Cocoa Mass, Cocoa Butter), Sugar, Half Candied Cherries (9%) (Cherries, Liquor, Kirsch), Amaretto (7%), Full Cream Milk Powder, Butter Oil (from Milk), Glucose Syrup, Cream (from Milk), Stabiliser (Sorbitol), Concentrated Whey (from Milk), Skimmed Milk Powder, Neutral Alcohol, Emulsifier (Soya Lecithin), Natural Colours (Beetroot, Annatto), Flavourings, Milk Protein.'
        },
        {
            'id': '4GpZxTuMXBrWu4sdnkw1',
            'name': 'Mandarin In Orange Flavoured Jelly',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Mandarin (30%), Deionised Pear Juice from Concentrate, Concentrated Orange Juice (1%), Acidity Regulators (Citric Acid, Sodium Citrate), Gelling Agents (Xanthan Gum, Gellan Gum, Carob Gum), Antioxidant (Ascorbic Acid), Flavouring, Firming Agent (Calcium Chloride), Colour (Paprika Extract).'
        },
        {
            'id': '4HQjKPrNngPuJryy9FEq',
            'name': 'Peanut Butter Smooth',
            'brand': 'Grandessa',
            'serving_size_g': 15.0,
            'ingredients': 'Peanuts (94%), Dextrose, Fully Hydrogenated Rapeseed Fat, Salt, Sunflower Oil.'
        },
        {
            'id': '4HvOcAXIHnr4dmzn8ZID',
            'name': 'Rice Snaps',
            'brand': 'Lidl',
            'serving_size_g': 30.0,
            'ingredients': 'Rice, Sugar, Salt, Barley Malt Extract, Vitamin D, Riboflavin, Niacin, Vitamin B6, Vitamin B12, Iron.'
        },
        {
            'id': '4IPeGJRKqXJgelgQ9emJ',
            'name': 'Diet Whey Protein Shake',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'PHD Premium Protein Blend (Whey Protein Concentrate (Milk), Milk Protein Concentrate (of which 80% is Micellar Casein), Soya Protein Isolate), Reduced Fat Cocoa Powder, Waxy Barley Flour, Golden Brown Flaxseed Powder, Stabilisers (Acacia Gum, Guar Gum, Xanthan Gum), Flavouring, Conjugated Linoleic Acid Powder (Safflower Oil (Rich in Linoleic Acid), Milk Protein, Emulsifier (Soya Lecithin), Vitamin E), Acetyl-L-Carnitine, Green Tea Extract, Sweetener (Sucralose).'
        },
        {
            'id': '4J13cgLYNijwZ0XZ5ne5',
            'name': 'Sourdough Bread',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rye Flour, Wholemeal Rye Flour, Salt, Wholemeal Wheat Flour, Malted Barley.'
        },
        {
            'id': '4CljO5ZxBtpQ5yJ4inja',
            'name': 'Camarón Boreal',
            'brand': 'Ocean Sea',
            'serving_size_g': 100.0,
            'ingredients': '99% Prawns (Crustaceans), Salt.'
        },
        {
            'id': '4KNe7HxuY1GtBwiB1JsS',
            'name': 'Tuno Mayo',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Textured Soya Protein (50%), Water, Soya Oil, Rice Vinegar, Sugar, Rice Flour, Yeast Extract, Natural Onion Flavouring, Salt, Thickener (Xanthan Gum), Non-Dairy Creamer (Maltodextrin, Sunflower Oil, Flavouring, Dextrose), Black Pepper, DHA Algal Oil.'
        },
        {
            'id': '4L4ClqDheYq60EmX95zH',
            'name': 'Gingerbread Spiced Caramels',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (58%) (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Emulsifier (Soya Lecithin), Vanilla Extract), Sugar, Cream (Milk), Fat Reduced Cocoa Powder, Glucose Syrup, Butterfat (Milk), Salt, Cinnamon, Clove, Ginger, Nutmeg, Allspice, Coriander Seeds, Mace, Cardamom.'
        },
        {
            'id': '4LVlH6WXvHOxUfDPh0cC',
            'name': 'Sesame Breadsticks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Sesame Seeds (20%), Sunflower Oil 4.9%, Barley Malt Extract, Salt, Yeast.'
        },
        {
            'id': '4N0ZV7U1sxfVMl7m6Kbp',
            'name': 'Hazelnut & Milk Chocolate Nutty Clouds',
            'brand': 'M&S',
            'serving_size_g': 12.0,
            'ingredients': 'Hazelnuts (30%), Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Ground Hazelnuts, Emulsifier (Lecithins (Soya)), Natural Flavouring.'
        },
        {
            'id': '4Nto9i9nQj48sF5mO2cf',
            'name': 'Naked Burrito',
            'brand': 'Chef Select',
            'serving_size_g': 309.0,
            'ingredients': '51% Burrito Sauce (Water, Chopped Tomatoes (Tomatoes, Tomato Juice), Tomato, Onion, Haricot Beans, Borlotti Beans, Sweetcorn, Garlic, Tomato Purée, Sugar, Chicken Stock (Water, Natural Chicken Flavourings, Salt, Sugar, Cornflour, Rapeseed Oil), Smoked Paprika, Lime Juice, Vinegar Blend (Spirit Vinegar, Distilled Malt Barley Vinegar, Water), Modified Maize Starch, Salt, Caramelised Sugar Syrup, Oregano, Garlic Powder, Onion Powder, Parsley, Black Pepper), 24% Cooked Rice Mix (Water, Long Grain Rice, Red Peppers, Green Peppers, Garlic Purée, Smoked Paprika, Ground Turmeric, Chilli Powder), 20% Cooked Chicken Breast (99% Chicken Breast, Cornflour), 4% Mature Cheddar Cheese (Milk).'
        },
        {
            'id': '4OAU3jQfnBinqDl7MjbU',
            'name': 'Cream Cheese',
            'brand': 'Paysan Breton',
            'serving_size_g': 100.0,
            'ingredients': 'Cheese (Milk), Sea Salt (1.1%).'
        },
        {
            'id': '4ONwxsVDzV1PeUy832Dv',
            'name': 'Fresh Fusilli',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Durum Wheat Semolina, Water, Pasteurised Free Range Egg (5%).'
        },
        {
            'id': '4ORMIVZoczF1lAEDKZ5K',
            'name': 'Compliments - Spearmint (sugar Free)',
            'brand': 'Dominion',
            'serving_size_g': 0.5,
            'ingredients': 'Sweeteners (Sorbitol, Aspartame, Acesulfame K), Flavourings, Anti-caking Agent (Magnesium Salts of Fatty Acids), Colour (Copper Complexes of Chlorophylls and Chlorophyllins).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 59\n")

    cleaned_count = update_batch59(db_path)

    # Calculate total progress
    previous_total = 861  # From batch 58
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 59 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 875 and previous_total < 875:
        print(f"\n🎉 875 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 13.6% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
