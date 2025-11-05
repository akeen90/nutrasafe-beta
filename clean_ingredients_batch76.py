#!/usr/bin/env python3
"""
Batch 76: Clean ingredients for 25 products
Progress: 1286 -> 1311 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch76(db_path: str):
    """Update batch 76 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '9iuCqszgV2LGwjEPYedP',
            'name': 'Cheddar & Emmental Cheese Souffles',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Semi Skimmed Milk, Extra Mature Cheddar Cheese (Milk) (20%), Emmental Cheese (Milk) (20%), Pasteurised Free Range Egg White, Pasteurised Free Range Egg Yolk, Modified Maize Starch, Salt.'
        },
        {
            'id': '9jC6svpb5YijtgIKPKwV',
            'name': 'Doritos Stax Mexican Chilli Salsa',
            'brand': 'Doritos',
            'serving_size_g': 100.0,
            'ingredients': 'Corn Maize Flour, Sunflower Oil, Starch, Seasoning (Salt, Sugar, Onion Powder, Flavouring, Tomato Powder, Garlic Powder, Yeast Extract, Red Chilli Pepper Powder, Lactose from Milk, Cumin, Oregano, Colour (Paprika Extract), Dried Black Beans, Rapeseed Oil), Emulsifiers (E471, E322).'
        },
        {
            'id': '9jUp9AZubB9GMlfHtVJ5',
            'name': 'Bamwells Summer Vibes Buffalo HOT Sauce',
            'brand': 'Bramwells',
            'serving_size_g': 15.0,
            'ingredients': 'White Wine Vinegar (Sulphites), Red Jalapeño Chilli, Water, Rapeseed Oil, Salt, Garlic Purée, Sugar, Tomato Paste, Modified Maize Starch, Acidity Regulator (Acetic Acid), Soya Beans, Spirit Vinegar.'
        },
        {
            'id': '9kQPtbze5XxHjCGCQKEh',
            'name': 'Farmhouse Wholemeal',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Wheat Protein, Malted Barley Flour, Yeast, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Molasses Sugar, Salt, Spirit Vinegar, Soya Flour, Preservative (Calcium Propionate), Emulsifier (Mono and Diacetyl Tartaric Acid Esters of Mono and Diglycerides of Fatty Acids), Vegetable Oils and Fat (Rapeseed Oil, Palm Fat, Palm Oil), Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '9lDiHWYQsVhVw1pWLcS5',
            'name': 'Medium Egg Noodles',
            'brand': 'Asia Specialties',
            'serving_size_g': 83.0,
            'ingredients': 'Wheat Flour, Durum Wheat Flour, Pasteurised Free Range Egg (4%), Salt, Acidity Regulator (Potassium Carbonates).'
        },
        {
            'id': '9mFRXjifAVj6Tgp1eP8N',
            'name': 'Luxury French Sliced Brioche Burger Buns',
            'brand': 'Specially Selected',
            'serving_size_g': 50.0,
            'ingredients': 'Wheat Flour, Pasteurised Egg (12%), Sugar, Water, Rapeseed Oil, Invert Sugar Syrup, Wheat Gluten, Yeast, Skimmed Milk Powder (1.5%), Concentrated Butter (1.5%) (Milk), Salt, Flavouring, Emulsifier (Mono and Diglycerides of Fatty Acids), Milk Proteins, Malted Rye Flour, Deactivated Yeast, Colour (Carotenes).'
        },
        {
            'id': '9nYZqLRdOJM7I41nIm37',
            'name': 'Screen Malt Loaf',
            'brand': 'Samworth Brothers',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Raisins (13%), Partially Inverted Sugar Syrup (Partially Inverted Sugar Syrup, Colour (E150c)), Malted Barley Flour (5%), Barley Malt Extract (4%), Maize Starch, Rice Starch, Vegetable Fats (Rapeseed, Palm), Salt, Preservative (Calcium Propionate), Yeast.'
        },
        {
            'id': '9nsKMDrqXPMaQ2dZLgzz',
            'name': 'Heck Sausages Reduced Fat',
            'brand': 'Heck',
            'serving_size_g': 123.0,
            'ingredients': 'Pork (65%), Rice Flour (Rice Flour, Water, Dextrose Monohydrate, Vegetable Fibre), Water, Seasoning (Low Sodium Sea Salt, Spices, Sage, Parsley, Marjoram, Yeast Extract, Potato Starch, Preservative (Sodium Sulphite), Antioxidant (Ascorbic Acid)), Citrus Fibre, Calcium Alginate Casing.'
        },
        {
            'id': '9ikwAHBiM1fBNSPkEJi0',
            'name': 'No Steaks',
            'brand': 'No Meat',
            'serving_size_g': 110.0,
            'ingredients': 'Mushrooms (49%), Rehydrated Soya Protein (35%), Sunflower Oil, Oat Fibre, Tomato Paste, Coconut Fat, Gelling Agents (Methyl Cellulose, Carrageenan), Salt, Garlic Powder, White Pepper, Dried Parsley, Caramelised Sugar, Beetroot Powder.'
        },
        {
            'id': '9pQD06RC5PKsjWaTTKna',
            'name': 'Ben\'s Plant Powered Tikka Masala',
            'brand': 'Ben\'s',
            'serving_size_g': 142.0,
            'ingredients': 'Tomatoes, Chickpeas (17%), Sweet Potato (10%), Sweetcorn (8.6%), Onion (8.5%), Coconut Milk, Red Pepper (5.3%), Green Peas (3.4%), Green Pepper (2.6%), Garlic, Spices (Cumin Powder, Garam Masala, Green Chilli, Fenugreek, Turmeric, Red Chilli), Pea Protein, Yeast Extract, Sunflower Oil, Corn Starch, Salt, Lemon Juice, Sugar, Natural Flavouring, Colour (Paprika Oleoresin).'
        },
        {
            'id': '9q3AoWsmaZRvcVFN3Pph',
            'name': 'Roast Chicken Flavour Bites',
            'brand': 'Aldi',
            'serving_size_g': 23.0,
            'ingredients': 'Chicken Breast (91%), Rapeseed Oil, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Maltodextrin, Salt, Yeast Extract, Rice Flour, Maize Starch, Sugar, Garlic Powder, Onion Powder, Paprika Powder, Tapioca Starch, Flavouring, Dextrose, Chicken Powder (Chicken, Antioxidant (Rosemary Extract)).'
        },
        {
            'id': '9q48Pp3jgNrdaGRG8TZz',
            'name': 'Sliced Bread White',
            'brand': 'Almarai',
            'serving_size_g': 30.0,
            'ingredients': 'Wheat Flour, Water, Sugar, Wheat Gluten, Salt, Vegetable Oil (Palm), Yeast, Emulsifiers (E472e, E471), Full Fat Soya Flour, Preservative (E282), Flour Treatment Agent (E300).'
        },
        {
            'id': '9qQ0IumWNtByy0haX2hm',
            'name': 'Fruit Smiles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fruit Juices from Concentrates (Apple (53%), Strawberry (3%)), Sugar, Glucose Syrup, Gelling Agents (Tapioca Starch, Pectin), Acidity Regulator (Citric Acid), Natural Flavourings, Coconut Oil, Natural Colours (Radish, Blackcurrant, Black Carrot), Glazing Agent (Carnauba Wax).'
        },
        {
            'id': '9qTywaQ1JFrWpsnJTqgH',
            'name': 'Chocolate & Orange Mini Rolls',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (38%) (Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Milk Fat, Lactose (Milk), Emulsifier (Soya Lecithin)), Orange Buttercream (14%) (Butter (Milk), Sugar, Dried Glucose Syrup, Salt, Orange Oil), Orange Filling (14%) (Glucose-Fructose Syrup, Orange Purée, Sugar, Concentrated Orange Juice, Gelling Agent (Pectin), Acid (Citric Acid), Acidity Regulator (Trisodium Citrate), Orange Oil, Lemon Oil, Caramelised Sugar), Sugar, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pasteurised Free Range Egg, Fat Reduced Cocoa Powder, Pasteurised Free Range Egg White, Humectant (Vegetable Glycerine), Skimmed Milk Powder, Emulsifier (Mono and Diglycerides of Fatty Acids), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate).'
        },
        {
            'id': '9rSfWjLWwXrbc6X7tnnd',
            'name': 'Aldi Province\'s Bifdo Culture Super Berry Yoghurt',
            'brand': 'Mibona',
            'serving_size_g': 150.0,
            'ingredients': 'Yogurt (Milk), Water, Strawberries (4%), Sugar, Raspberries (3%), Modified Maize Starch, Carrot Concentrate, Pomegranate Juice Concentrate, Thickeners (Pectins), Flavouring, Acidity Regulator (Citric Acid), Riboflavin (Vitamin B2), Niacin (Vitamin B3), Vitamin B6, Bifidobacterium, Lactobacillus Acidophilus, Streptococcus Thermophilus, Lactobacillus Delbrueckii subsp. Bulgaricus.'
        },
        {
            'id': '9s3HaC9XH8cRPGFc8R10',
            'name': 'Sausages',
            'brand': 'Tarczyński',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast Fillet (90%), Chicken Fat, Starch, Salt, Spices, Spice Extracts, Flavourings (including Smoke Flavouring), Sugar, Chicken Protein, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '9t8ufj2ZgtczPQtEjOyQ',
            'name': 'Light &free',
            'brand': 'Light Free',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (Milk), Lemon Juice from Concentrate (0.8%), Potato and Tapioca Starch, Modified Maize Starch, Thickener (Xanthan Gum), Flavouring, Natural Flavouring, Acidity Regulators (Citric Acid, Sodium Citrate), Sweeteners (Acesulfame K, Sucralose), Vitamin D.'
        },
        {
            'id': '9u245WVToZiYbAShpt5W',
            'name': 'Smiths Frazzles Crispy Bacon Snacks 8 X',
            'brand': 'Generic',
            'serving_size_g': 18.0,
            'ingredients': 'Maize, Rapeseed Oil, Bacon Flavour Seasoning (Salt, Wheat Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Hydrolysed Vegetable Protein (Wheat, Soya), Dextrose, Flavour Enhancers (Monosodium Glutamate, Disodium 5\' Ribonucleotide), Potassium Chloride, Yeast Powder (from Barley), Flavourings (Soya, Wheat), Lactose (from Milk), Sugar, Yeast Extract (Barley), Rusk (from Wheat), Whey Powder (from Milk), Colours (Paprika Extract, Sulphite Ammonia Caramel), Barley Malt Flour (Wheat), Smoke Flavouring, Colour (Beetroot Red)).'
        },
        {
            'id': '9u98lEMJ5IrSp4SJWBzb',
            'name': 'Brioche Burger',
            'brand': 'Dulcesol',
            'serving_size_g': 85.0,
            'ingredients': 'Wheat Flour, Water, Sugar, Yeast, Dehydrated Potato Flakes, Sunflower Oil, Wheat Gluten, Salt, Oat Fibre, Emulsifiers (E471, E472e, E481), Bean Flour, Preservatives (E282, E200), Flavourings, Pulsing Protein, Dextrose, Colour (Carotenes), Stabiliser (Guar Gum).'
        },
        {
            'id': '9un2FPhKftrZjLXzlw52',
            'name': 'Spreadable',
            'brand': 'Bertolli',
            'serving_size_g': 100.0,
            'ingredients': 'Palm Oil, Olive Oil (17%), Water, Buttermilk (Milk), Rapeseed Oil, Butter (Milk) (10%), Salt (1%), Emulsifier (Sunflower Lecithin), Preservative (Potassium Sorbate), Acid (Lactic Acid), Natural Flavouring (Milk), Natural Butter Flavouring (Milk), Vitamins (A, D), Colour (Carotenes).'
        },
        {
            'id': '9p6wwlou5whZp5WgzwwJ',
            'name': 'Crunchy Veg Burgers',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour, Water, Potato Flakes (8%), Onion (8%), Red Pepper (8%), Sweetcorn (8%), Carrot (7%), Parsnip (7%), Peas (7%), Cauliflower (7%), Sunflower Oil, Green Beans (3%), Salt, Yeast, Rapeseed Oil, Yeast Extract, Sugar, Garlic Powder, Onion Powder, Tomato Powder, Red Pepper Powder, Parsley, Sage, White Pepper, Flavouring, Black Pepper Extract, Sage Extract.'
        },
        {
            'id': '9wC3WffrkB52I147pIvI',
            'name': 'Avour M Food- Spicy Buffalo WING Flavour Seanuts F',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (92%), Rapeseed Oil, Rice Flour, Sugar, Sea Salt, Dried Yeast Extract, Natural Flavouring, Dried Onions, Dried Vinegar, Chilli Powder, Acidity Regulator (Citric Acid), Dried Red Peppers, Natural Colour (Paprika Extract).'
        },
        {
            'id': '9wPVp25MA4CBGDi6ArFK',
            'name': 'Banoffee Pie',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British Cream (23%) (Milk), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Banana (15%), Glucose Syrup, British Whipping Cream (8%) (Milk), Palm Oil, Dark Brown Sugar, Sugar, Banana Purée (4%), Salted Butter (2%) (Butter (Milk), Salt), Milk Chocolate Shavings (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Whey Powder (Milk), Lactose (Milk), Emulsifier (Soya Lecithin), Flavouring), Maize Starch, Invert Sugar Syrup, Butter (Milk), Rapeseed Oil, Dextrose, Milk Protein Concentrate (Milk), Fat Reduced Cocoa Powder, Raising Agent (Sodium Bicarbonate), Stabiliser (Pectin).'
        },
        {
            'id': '9wfYNd1C9oCYdiukmbXM',
            'name': 'Crinkle Cut Sea Salt & Chardonnay Vinegar Hand Cooked Crisps',
            'brand': 'Tesco',
            'serving_size_g': 25.0,
            'ingredients': 'Potato, Rapeseed Oil, Flavouring, Rice Flour, Sugar, Citric Acid, Sea Salt, Yeast Extract Powder, Chardonnay Wine Vinegar Powder.'
        },
        {
            'id': '9wycXeLiDbKs8CfAYPRY',
            'name': 'Low Fat Mango And Passion Fruit Yogurt',
            'brand': 'Mary Ann\'s Dairy',
            'serving_size_g': 100.0,
            'ingredients': 'Low Fat Yogurt (Milk), Sugar, Mango Purée, Passion Fruit Juice, Potato Starch, Cornflour, Modified Maize Starch, Concentrated Lemon Juice, Flavourings, Gelling Agent (Pectin), Dextrose.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 76\n")

    cleaned_count = update_batch76(db_path)

    # Calculate total progress
    previous_total = 1286  # From batch 75
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 76 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1300 and previous_total < 1300:
        print(f"\n🎉🎉 1300 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 20.1% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
