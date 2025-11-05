#!/usr/bin/env python3
"""
Batch 72: Clean ingredients for 25 products
Progress: 1186 -> 1211 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch72(db_path: str):
    """Update batch 72 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '8AUPqmtA0EhIs9PT4psH',
            'name': 'White & Wheat Wraps',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Wholemeal Wheat Flour, Water, Palm Oil, Humectant (Glycerol), Sugar, Raising Agents (Diphosphates, Sodium Carbonates), Acidity Regulator (Citric Acid), Emulsifier (Mono - and Diglycerides of Fatty Acids), Preservatives (Potassium Sorbate, Calcium Propionate), Salt, Wheat Starch, Flour Treatment Agent (L-Cysteine).'
        },
        {
            'id': '8AUUApdD59xJf3zQ8MZl',
            'name': 'Tesco Crispy Coated Peanuts BBQ',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (44%), Rapeseed Oil, Potato Starch, Modified Maize Starch, Maize Starch, Sugar, Modified Tapioca Starch, Wheat Starch, Rice Flour, Salt, Maltodextrin, Yeast Extract Powder, Smoked Paprika, Onion Powder, Dextrose, Thickener (Acacia), Tomato Powder, Malt Vinegar Powder (Barley), Colours (Paprika Extract, Curcumin), Chilli Powder, Ginger Powder, Flavouring, Garlic Powder, Black Pepper, Cinnamon Powder, Citric Acid, Oregano, Fennel Extract, Allspice, Thyme Extract.'
        },
        {
            'id': '8B4i1xHmDG9cT8qyPGmu',
            'name': 'Gut Ball',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Almond Butter (24%), Date Paste, Chicory Fibre, Almonds (8%), Apple Purée (7%), Dried Apples, Ground Almonds, Calcium, Sweet Cinnamon (Cassia), Vitamin D.'
        },
        {
            'id': '8BMHzDfaSGPaca70Rw7m',
            'name': 'Middle Eastern Style Chicken & Tabbouleh Salad',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Orzo 22% (Durum Wheat Semolina, Water, Sunflower Oil), Cooked Bulgur Wheat 22% (Water, Bulgur Wheat), Marinated Chicken Breast 15% (Chicken Breast, Sugar, Spices (Coriander Seeds, Ginger, Cumin, Black Pepper, Cassia, Caraway, Fenugreek Leaf, Chilli, Sumac, Pimento, Star Anise), Maltodextrin, Tomato Paste, Concentrated Lemon Juice, Garlic, Cornflour, Salt, Extra Virgin Olive Oil, Garlic Powder, Onion Powder, Dried Red Bell Pepper, Colour (Anthocyanins), Dried Red Onion, Yeast Extract Powder, Acid (Citric Acid), Mint, Smoked Salt, Rapeseed Oil, Flavourings), Lettuce 8%, Yogurt and Mint Dressing 8% (Water, Greek Style Yogurt (Milk), Olive Oil, Lemon Juice, Spirit Vinegar, Sugar, Cornflour, Pasteurised Egg Yolk, Mint, Garlic Purée, Salt, Sunflower Oil, Black Pepper), Tomato 6%, Cider Vinaigrette 5% (Water, Cider Vinegar, Dijon Mustard (Water, Brown Mustard Seed, Spirit Vinegar, Salt), Sugar, Cornflour, Rapeseed Oil, Salt, Parsley, Tarragon, Ground White Pepper, Mustard Flour, Thyme), Cucumber 5%, Roasted Red Pepper 5% (Roasted Red Pepper, Water, Acidity Regulator (Citric Acid), Salt), Onion, Mint, Black Pepper.'
        },
        {
            'id': '8C1gceR4MCWI71rvsSRT',
            'name': 'Cinnamon Bun Balls',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Date Paste 45%, Cashew Nut Paste 18% (Cashew Nut Paste, Rapeseed Oil), Chicory Fibre (Inulin), Soya Flour, Soya Protein Crispies 5% (Soya Protein Isolate, Tapioca Starch, Salt), Ground Almond 5%, Cashew Nuts 4%, Pecan Nuts 4%, Gluten Free Oats, Ground Cinnamon 2%, Flavouring.'
        },
        {
            'id': '8CMZNEAJvOcct2O13Cgt',
            'name': 'Paneer Cheese',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pasteurised Cow\'s Milk.'
        },
        {
            'id': '87UhnMkqaFKnAtbNuLq6',
            'name': 'Wensleydale With Cranberry',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wensleydale Cheese 83% (Milk), Sweetened Dried Cranberries 13% (Sugar, Cranberries, Sunflower Oil), Fructose.'
        },
        {
            'id': '8D3us67J3i2WfHSmHMer',
            'name': 'Moo Milk Banana',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': '1% Fat Milk (95%), Sugar, Skimmed Milk Powder, Concentrated Banana Juice, Stabilisers (Carrageenan, Xanthan Gum, Calcium Sulfate), Colour (Algal Carotenes), Natural Flavourings.'
        },
        {
            'id': '8DANtDzy9Fv4tsX9QlJb',
            'name': 'Tesco Raita DIP A Taste OF India Made With Cucumber',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Yogurt (Milk) (30%), Rapeseed Oil, Cucumber (8%), White Wine Vinegar, Modified Maize Starch, Mint (2%), Sugar, Salt, Pasteurised Egg Yolk Powder, Stabiliser (Xanthan Gum), Preservative (Potassium Sorbate).'
        },
        {
            'id': '8EbBi6RDe8ukDeoUMpP5',
            'name': 'Mini Scotch Egg',
            'brand': 'Squeaky Bean',
            'serving_size_g': 100.0,
            'ingredients': 'Vegan Pork Style Pieces (40%) (Water, Vegetable Protein (Wheat, Pea), Textured Pea Protein, Wheat Gluten, Sunflower Oil, Seasoning (Sugar, Maize Starch, Black Pepper, White Pepper, Nutmeg, Cayenne Pepper, Salt, Chilli, Cumin, Garlic Powder, Oregano, Sage, Marjoram, Yeast Extract, Potato Maltodextrin, Sunflower Seed Oil, Onion Powder, Rice Flour, Parsley, Caramelised Sugar, Paprika Spice Extract, Rosemary), Potato Protein, Pea Protein Isolate, Preservatives (Potassium Lactate, Potassium Acetate), Stabilisers (Agar, Calcium Lactate), Salt, Dextrose, Citrus Fibre, Natural Flavouring, Maltodextrin, Acidity Regulator (Lactic Acid), Ground Nutmeg, Smoked Yeast, Mushroom Powder), Rapeseed Oil, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Onion, Crackd The No-Egg Egg (Water, Pea Protein, Thickener (Methyl Cellulose), Gelling Agent (Gellan Gum), Firming Agent (Calcium Lactate), Nutritional Yeast (Dried Inactive Yeast, Vitamin B12), Flavouring, Black Salt, Acid (Lactic Acid), Acidity Regulator (Potassium Bitartrate), Colour (Beta Carotene), Vitamin (D & B12)), Stabiliser (Methyl Cellulose), Cornflour, Cider Vinegar, Wheat Starch, Sage, Sugar, Wheat Gluten, Pea Protein, Thickener (Pectin), Salt, Yeast, Dextrose, Citrus Fibre, Concentrated Lemon Juice, Garlic Puree, Mustard Flour, Paprika, Turmeric.'
        },
        {
            'id': '8ErRWaO4X8XLeCz1STDY',
            'name': 'Dr Aloe Aloe Vera Drink Original',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Aloe Vera (25%), Sugar, Apple Juice from Concentrate, Acidity Regulators (Citric Acid, Sodium Citrate), Stabilizer (Calcium Lactate, Gellan Gum, Xanthan Gum), Sweetener (Acesulfame K), Preservative (Sodium Benzoate), Flavor.'
        },
        {
            'id': '8Fcf4DZFc0LQ84qo1dgY',
            'name': 'Gaviscon Double Action',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sodium Alginate, Sodium Bicarbonate, Calcium Carbonate, Mannitol, Aspartame (E951), Carmoisine Lake (E122), Mint Flavour.'
        },
        {
            'id': '8GOSH8RuXD2amIx9HV8d',
            'name': 'Dairy Milk Hot Cross Bun',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Dried Grapes, Cocoa Mass, Cocoa Butter, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Caramelised Sugar, Cinnamon, Glucose Syrup, Flavourings.'
        },
        {
            'id': '8Gio1CgoC7Hr23i3hSDg',
            'name': 'Honeyberry Jam',
            'brand': 'Scottish Honeyberries Ltd',
            'serving_size_g': 20.0,
            'ingredients': 'Honeyberries (50%), Sugar, Gelling Agent (Fruit Pectin).'
        },
        {
            'id': '8I9EwnHSL845U3f2MSuL',
            'name': 'Orange Juice',
            'brand': 'Everyday Essentials',
            'serving_size_g': 100.0,
            'ingredients': 'Orange Juice from Concentrate (100%).'
        },
        {
            'id': '8ITpuRAM9nvFW1HK9WMw',
            'name': 'Breaded Chicken Breast Fillets',
            'brand': 'Tesco',
            'serving_size_g': 163.0,
            'ingredients': 'Chicken Breast Fillet (64%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Wheat Gluten, Wheat Starch, Salt, Yeast Extract, Yeast, Sugar, Garlic Powder, Onion Powder, Paprika, Sourdough Culture (Wheat), White Pepper, Sunflower Oil, Sage, Cider Vinegar, Flavouring.'
        },
        {
            'id': '8JLm0PsIsc9khXLzNQRL',
            'name': 'Maple Crest',
            'brand': 'Pancake Syrup',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Syrup, Cane Sugar, Water, Maple Syrup (5%), Natural Flavouring, Caramelised Sugar Syrup (Sugar, Water).'
        },
        {
            'id': '8JcGctKdFMKLGwQsPj4o',
            'name': 'Pineapple And Grapefruit Soda',
            'brand': 'Fanta',
            'serving_size_g': 330.0,
            'ingredients': 'Carbonated Water, Fruit Juices from Concentrate 5% (Pineapple, Grapefruit), Sugar, Acid (Citric Acid), Antioxidant (Ascorbic Acid), Sweeteners (Acesulfame K, Aspartame, Saccharins), Preservative (Potassium Sorbate), Flavourings, Stabilisers (Acacia Gum, Guar Gum, Sucrose Acetate Isobutyrate, Glycerol Esters of Wood Rosins), Colour (Carotenes).'
        },
        {
            'id': '8JgE4kOi94LUmHeKIoF2',
            'name': 'Chocolate Gâteau',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (Milk) 55%, Water, Sugar, Wheat Flour, Egg, Invert Sugar Syrup, Fat-Reduced Cocoa Powder, Dark Chocolate 2% (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithins)), Maize Starch, Dark Chocolate Flakes (Sugar, Cocoa Mass, Fat-Reduced Cocoa Powder, Cocoa Butter, Emulsifier (Soya Lecithins)), Wheat Starch, Chocolate Powder (Cocoa Powder, Cocoa Mass, Sugar), Acidity Regulators (Calcium Sulphate, Sodium Citrates), Thickener (Sodium Alginate), Emulsifiers (Mono- and Diglycerides of Fatty Acids, Lactic Acid Esters of Mono- and Diglycerides of Fatty Acids), Flavouring, Palm Oil, Glucose Syrup, Coconut Oil, Lactose (Milk), Milk Protein, Salt, Raising Agent (Sodium Carbonates).'
        },
        {
            'id': '8K0fAYci9hPGeZEzBgu9',
            'name': 'Peach & Yogurt Lollies',
            'brand': 'Tesco',
            'serving_size_g': 29.0,
            'ingredients': 'Reconstituted Skimmed Milk Yogurt, Sugar, Glucose Syrup, Peach Purée from Concentrate, Inulin, Oil, Whey Powder, Fructose, Emulsifier (Mono - and Diglycerides of Fatty Acids), Stabilisers (Locust Bean Gum, Guar Gum), Acidity Regulator (Citric Acid), Flavourings, Colours (Annatto, Norbixin, Beta-Carotene).'
        },
        {
            'id': '8K1LxdvAjJLoYIKIctuf',
            'name': 'Sea Salt & Vinegar Potato Chips',
            'brand': 'Popchips',
            'serving_size_g': 100.0,
            'ingredients': '59% Dried Potatoes, Sunflower Oil, Seasoning (Potato Maltodextrin, Vinegar Powder, Sea Salt, Sugar, Acid (Citric Acid), Natural Flavourings, Yeast Extract, Antioxidant (Extracts of Rosemary)), Rice Flour, Potato Starch.'
        },
        {
            'id': '8DnaYhxElv9qmnAZNOyK',
            'name': 'Lemon Drizzle Flapjack',
            'brand': 'Graze',
            'serving_size_g': 50.0,
            'ingredients': 'Oats 44%, Chicory Root Fibre, Vegetable Oils (Rapeseed, Palm), Golden Syrup, Liquid Sugar, Humectant (Glycerine), Whole Milk Powder, Vegetable Fats (Palm, Palm Kernel, Shea), Modified Starch, Sugar, Demerara Sugar, Starch, Emulsifier (Lecithins (Soya)), Sea Salt, Natural Lemon Flavouring, Citrus Fibre, Yoghurt Powder (Milk) 0.2%, Sweet Whey Powder (Milk), Stabiliser (Xanthan Gum), Molasses, Natural Flavouring.'
        },
        {
            'id': '8LPc6yGAAMTbsi3jty86',
            'name': 'Light Spread',
            'brand': 'Kilkeel Aldi',
            'serving_size_g': 15.0,
            'ingredients': 'Water, Vegetable Oils (Rapeseed Oil, Palm Oil, Palm Kernel Oil), Cream (Milk), Salt (1.396%), Emulsifiers (Mono- and Diglycerides of Fatty Acids, Polyglycerol Polyricinoleate), Calcium Carbonate, Stabilizer (Sodium Alginate), Preservative (Potassium Sorbate), Carrier (Lactose (Milk)), Flavouring, Vitamin B6, Colour (Carotenes), Folic Acid, Vitamin A, Vitamin D, Vitamin B12.'
        },
        {
            'id': '8LwRpUka940y9tViJnUs',
            'name': 'Finest Apricot Conserve',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Apricot, Gelling Agent (Pectin), Citric Acid, Acidity Regulator (Sodium Citrate).'
        },
        {
            'id': '8MdVBwV2qgvdXtFd7EoV',
            'name': 'Banana Lunchbox Loaf',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Water, Sweetened Banana Flavoured Pieces (12%) (Fructose-Glucose Syrup, Concentrated Pear Purée, Concentrated Banana Purée, Humectant (Glycerol), Sugar, Wheat Fibre, Palm Fat, Gelling Agent (Pectin), Malic Acid, Natural Flavouring, Concentrated Lemon Juice), Banana Purée (9%), Sugar, Vegetable Fat (Rapeseed, Palm), Dextrose, Salt, Yeast, Flavourings, Preservative (Calcium Propionate), Colour (Lutein).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 72\n")

    cleaned_count = update_batch72(db_path)

    # Calculate total progress
    previous_total = 1186  # From batch 71
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 72 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1200 and previous_total < 1200:
        print(f"\n🎉🎉 1200 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 18.6% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
