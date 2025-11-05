#!/usr/bin/env python3
"""
Batch 62: Clean ingredients for 25 products
Progress: 936 -> 961 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch62(db_path: str):
    """Update batch 62 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '5ZWAMfPvnbHBVq2pQBjJ',
            'name': 'Fruit-tella',
            'brand': 'Fruittella',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Fruit Juices from Concentrate (Orange, Strawberry, Lemon) (3%), Coconut Oil, Acids (Citric Acid, Malic Acid), Maltodextrin, Emulsifiers (Mono and Diglycerides of Fatty Acid, Sucrose Esters of Fatty Acids), Humectant (Glycerol), Gelling Agent (Gum Arabic), Cocoa Butter, Concentrates (Carrot, Blackcurrant, Elderberry), Natural Flavourings, Thickener (Gellan Gum).'
        },
        {
            'id': '5Zm9Sw6jjtLWrdDAWn08',
            'name': 'Dairy Milk Orange',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Orange Oil, Flavourings.'
        },
        {
            'id': '5Zpakd4UqencWN1p2KSm',
            'name': 'Smoky Bacon Flavour Chips',
            'brand': 'Boundless',
            'serving_size_g': 100.0,
            'ingredients': 'Sprouted Sorghum (46%), Pea Flour, Smoky Bacon Flavour Seasoning (14%) (Rice Flour, Sugar, Yeast Extract, Onion Powder, Natural Flavouring, Salt, Acid (Citric Acid), Garlic Powder, Smoked Salt, Colour (Paprika Extract)), Sunflower Oil, Maize Flour, Calcium Carbonate.'
        },
        {
            'id': '5a6SRDjK1cGgrvTcKAZr',
            'name': 'Cheddar & Spinach Mini Muffins',
            'brand': 'Higgidy',
            'serving_size_g': 17.0,
            'ingredients': 'Mature Cheddar Cheese, Wheat Flour (contains Calcium Carbonate, Iron, Niacin, Thiamin), Carrot, Spinach, Water, Free Range Whole Egg, Butternut Squash Purée, Rapeseed Oil, Cornflour, Whole Milk, Raising Agents (Sodium Hydrogen Carbonate, Disodium Diphosphate), Double Cream, Dried Skimmed Milk, Salt, Butter, Onion Purée, Turmeric, White Pepper, Cayenne Pepper, Cheese, Dijon Mustard, Mustard Powder, Nutmeg.'
        },
        {
            'id': '5aP2bqhY4d6EkVtWuhIg',
            'name': 'Gliten Free Tricolore Fusilli',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Yellow Cornflour, Rice Flour, White Cornflour, Tomato Powder, Spinach Powder, Emulsifier (Mono - and Diglycerides of Fatty Acids).'
        },
        {
            'id': '5bCq9oDZEDSqkURhtAXM',
            'name': 'Free From Lemon Drizzle',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Egg, Rice Flour, Rapeseed Oil, Tapioca Starch, Lemon Juice, Humectant (Glycerol-Vegetable), Invert Sugar Syrup, Glucose Syrup, Water, Rowanberry Extract, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate), Flavourings, Thickener (Xanthan Gum), Emulsifier (Sodium Stearoyl-2-Lactylate).'
        },
        {
            'id': '5bVWZ4shXbJyKibMkNvk',
            'name': 'Tomato Ketchup',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g Tomato Ketchup), Spirit Vinegar, Sugar, Salt, Spice and Herb Extracts (contain Celery), Spice.'
        },
        {
            'id': '5baeqQXYG4wxbhSFTila',
            'name': '898 Tesco Classic Veggie Meal Deal Main',
            'brand': 'Tesco',
            'serving_size_g': 126.0,
            'ingredients': 'Cooked White Sushi Rice (Water, White Rice, Sugar, Spirit Vinegar, Rice Vinegar, Salt, Rapeseed Oil, Fructose-Glucose Syrup, Cane Molasses, Pepper), Carrot, Cabbage, Edamame Soya Beans, Soy Sauce Bottle (Water, Soya Beans, Salt, Rice Vinegar, Rapeseed Oil), Avocado, Nori Seaweed, White Sesame Seeds, Black Sesame Seeds, Spinach, Red Pepper Flakes, Spirit Vinegar, White Wine Vinegar, Sugar, Cornflour, Coriander, Yeast Extract Powder, Salt, Onion, Turmeric, Caraway Seeds, Garlic, Modified Potato Starch, Soya Beans, Black Pepper, Stabilisers (Xanthan Gum, Guar Gum), Cumin, Concentrated Lemon Juice, Fenugreek, Cinnamon, Nutmeg, Star Anise, Acidity Regulator (Lactic Acid), Fennel, Cardamom, Clove, Chilli Powder, Bay Leaf, Allspice, Ginger, Paprika.'
        },
        {
            'id': '5c72CoPqYNjh5ngX1QRa',
            'name': 'Coconut Water',
            'brand': 'Fresh Express',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable (Romaine Lettuce), Dressing (Vegetable Oil (Canola and/or Soybean Oil), Water, Parmesan Cheese (Part Skim Milk, Culture, Salt, Enzymes), Egg Yolk, Dijon Mustard (Distilled Vinegar, Water, Mustard Seed, Salt, White Wine, Citric Acid, Turmeric, Tartaric Acid, Spices), Distilled Vinegar 2%, Dried Garlic, Lemon Juice Concentrate, Sugar, Anchovy Paste (Anchovies, Salt, Water), Salt, Molasses, Spice, Anchovy Powder (Maltodextrin, Anchovy Extract, Salt), Xanthan Gum, Ground Mustard), Bacon (Bacon Cured with Water, Salt, Sodium Phosphates (Preservative), Sodium Erythorbate (Preservative), Sodium Nitrite (Preservative)), Croutons (Enriched Wheat Flour (Enriched with Niacin, Reduced Iron, Thiamine Mononitrate, Riboflavin, Folic Acid), Canola Oil, Salt, Whey, Sugar, Yeast, Garlic Powder, Dehydrated Parsley, Spices, Natural Flavor, Maltodextrin), Cheese (Pasteurized Milk, Salt, Cheese Culture, Enzymes, Powdered Cellulose (Prevents Caking), Sorbic Acid (Preservative)).'
        },
        {
            'id': '5cUgOcYHzZBKirrvheNa',
            'name': 'Trek Original Oat',
            'brand': 'Trek',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (29%), Rice Syrup, Soya Protein Crispies (17%) (Soya Protein Isolate, Tapioca Starch, Salt), Vegetable Oils (Rapeseed, Palm), Soya Flour (8%), Sugar, Salt, Natural Flavouring.'
        },
        {
            'id': '5clAj1lQbik5e7BZymIv',
            'name': 'Cheese Alternatives',
            'brand': 'Plant Menu',
            'serving_size_g': 30.0,
            'ingredients': 'Water, Coconut Oil (24%), Maize Starch, Modified Potato Starch, Modified Tapioca Starch, Sea Salt, Modified Maize Starch, Flavouring, Olive Extract, Vitamin B12, Colour (Carotenes).'
        },
        {
            'id': '5dA9DEgJeSGQBqnxcxIb',
            'name': 'Milkybar Figure',
            'brand': 'Nestlé',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Powders (Whole and Skimmed) 37%, Sugar, Cocoa Butter, Vegetable Fat (Palm, Shea, Sal, Mango Kernel), Emulsifier (Lecithins), Natural Vanilla Flavouring.'
        },
        {
            'id': '5g3cJZOuystHZfqSPHt6',
            'name': 'Gluten Free Teacakes',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Flour, Cornflour, Water, Sunflower Oil, Yeast, Invert Sugar Syrup, Humectant (Glycerol), Dried Egg White, Stabiliser (E464), Xanthan Gum, Psyllium Husk Powder, Orange Peel, Salt, Ground Sweet Cinnamon (Cassia), Ground Coriander, Flavouring.'
        },
        {
            'id': '5g8U4GqytAnBleEVmkdZ',
            'name': 'Giant Skittles',
            'brand': 'Mars',
            'serving_size_g': 44.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Fat, Acid (Malic Acid), Dextrin, Modified Starch, Flavourings, Maltodextrin, Colours (E162, E163, E160a, E170, E100, E153, E133), Acid (Citric Acid), Acidity Regulator (Trisodium Citrate), Glazing Agent (Carnauba Wax), Emulsifier (Lecithin).'
        },
        {
            'id': '5gpGUs3C5RWC0sYORXQ7',
            'name': 'Wholegrain Bran Flakes',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Wheat (63%), Wheat Bran (20%), Sugar, Oat Flour, Barley Malt Extract, Glucose Syrup, Salt, Iron, Vitamin E, Antioxidants (Ascorbyl Palmitate, Alpha-Tocopherol), Niacin, Emulsifier (Mono - and Diglycerides of Fatty Acids), Pantothenic Acid, Vitamin B12, Vitamin D, Thiamin (B1), Folic Acid, Citric Acid, Riboflavin, Vitamin B6.'
        },
        {
            'id': '5gq4N0vmAtzpGo3fWMRx',
            'name': 'Cannellini Beans In Water',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cannellini Beans, Water, Firming Agent (Calcium Chloride), Antioxidant (Ascorbic Acid).'
        },
        {
            'id': '5gvRenzPc5ivTS9yy0ng',
            'name': 'Tomato Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g of Ketchup), Spirit Vinegar, Sugar, Modified Maize Starch, Salt, Flavouring.'
        },
        {
            'id': '5iJoObvPKOcVrHuUlVUl',
            'name': 'Clear Vegan Protein Raspberry Mojito',
            'brand': 'Myvegan',
            'serving_size_g': 16.0,
            'ingredients': 'Hydrolysed Pea Protein (77%), Raspberry Juice Powder (10%), Vitamin B Blend (Niacin, Pantothenic Acid, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Biotin, Vitamin B12), Acid (Citric Acid), Sweetener (Sucralose), Product Flavourings, Colour (Beetroot Red), Anti-Foaming Agents (Dimethyl Polysiloxane, Silicon Dioxide).'
        },
        {
            'id': '5iqY4J9eQma1FSIBUFeJ',
            'name': 'Egg Salad Cream',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Boiled Egg (75%), Salad Cream (Water, Rapeseed Oil, Spirit Vinegar, Sugar, Cornflour, Pasteurised Egg Yolk, Salt, Gelling Agent (Pectins), Mustard Flour), Cornflour, Black Pepper.'
        },
        {
            'id': '5jPduvc9arnYlrevfDon',
            'name': 'Half And Half Cake',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Buttercream 19% (Sugar, Butter (Milk), Invert Sugar Syrup, Glucose Syrup, Maize Starch, Acidity Regulator (Tartaric Acid)), Sugar, Chocolate Flavoured Buttercream 18% (Sugar, Butter (Milk), Invert Sugar Syrup, Glucose Syrup, Fat Reduced Cocoa Powder, Maize Starch, Acidity Regulator (Tartaric Acid)), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Pasteurised Egg, Cocoa Butter, Pasteurised Egg White, Dried Whole Milk, Humectant (Glycerol), Fat Reduced Cocoa Powder, Maize Starch, Cocoa Mass, Milk Sugar, Whey Powder (Milk), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate, Potassium Hydrogen Carbonate), Glucose Syrup, Emulsifiers (Soya Lecithins, Mono - and Diglycerides of Fatty Acids), Flavouring, Preservative (Potassium Sorbate), Rice Flour, Dried Skimmed Milk, Maize Flour, Barley Malt Extract, Milk Fat, Glazing Agent (Acacia Gum), Dextrose, Maltodextrin, Palm Oil, Dried Egg White, Salt, Milk Proteins, Honey.'
        },
        {
            'id': '5jVxdVhUNH3Rn3ipopuN',
            'name': 'Smarties Penguin',
            'brand': 'Smarties',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Butterfat (from Milk), Emulsifier (Lecithins), Wheat Flour, Lactose and Proteins from Whey (from Milk), Whey Powder (from Milk), Rice Starch, Flavourings, Colours (Beetroot Red, Carotenes, Curcumin), Spirulina Concentrate, Glazing Agents (Carnauba Wax, Beeswax White), Vegetable Concentrates (Safflower, Radish), Barley Malt Extract.'
        },
        {
            'id': '5kJLEKOE52wqHkrzb4t2',
            'name': 'Parmigiano Reggiano',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Parmigiano Reggiano P.D.O. Italian Hard Cheese Made from Raw Milk.'
        },
        {
            'id': '5kP9ORGn188ZfW0er8ej',
            'name': '4 Battered White Fish Fillets',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Alaska Pollock Fish 57%, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Wheat Starch, Maize Flour, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Salt, Dextrose, Yeast Extract, Sunflower Oil, Garlic Powder, Onion Powder, Black Pepper.'
        },
        {
            'id': '5eI8UpKXVb03by39qfzq',
            'name': 'BBQ Lentil Chips',
            'brand': 'Snacktastic',
            'serving_size_g': 15.0,
            'ingredients': '30% Lentil Flour, Potato Starch, Vegetable Oils in Varying Proportions (Rapeseed, Sunflower), Cornflour, 8% BBQ Seasoning (Sugar, Salt, Rice Flour, Onion Powder, Garlic Powder, Spices (Chipotle Chilli Powder, Cayenne Powder, Clove Powder), Flavouring, Potassium Chloride, Yeast Extract, Tomato Powder, Spirit Vinegar Powder, Colour (Paprika Extract)), Pregelatinised Potato Starch, Salt.'
        },
        {
            'id': '5kR20gAWvdXVJWPhIGna',
            'name': 'Chocolate Shortcake Ladybird Biscuit',
            'brand': 'Costa',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Invert Sugar Syrup, Sugar, Partially Inverted Sugar Syrup, Palm Oil, Glucose Syrup, Cocoa Powder, Pasteurised Free Range Egg, Rapeseed Oil, Palm Stearin, Raising Agent (Sodium Hydrogen Carbonate), Colours (Beetroot Red, Vegetable Carbon, Paprika Extract), Dried Free Range Egg White, Cornflour, Stabiliser (Disodium Diphosphate), Acidity Regulator (Acetic Acid), Concentrated Lemon Juice.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 62\n")

    cleaned_count = update_batch62(db_path)

    # Calculate total progress
    previous_total = 936  # From batch 61
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 62 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 950 and previous_total < 950:
        print(f"\n🎉🎉🎉 950 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 14.7% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
