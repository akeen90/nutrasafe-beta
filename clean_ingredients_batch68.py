#!/usr/bin/env python3
"""
Batch 68: Clean ingredients for 25 products
Progress: 1086 -> 1111 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch68(db_path: str):
    """Update batch 68 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '6Dq2xjnyDDlrApE0kOmG',
            'name': 'Cheese And Onion Bakes',
            'brand': 'Iceland',
            'serving_size_g': 141.4,
            'ingredients': 'Water, Fortified Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Onion (7%), Soft Cheese (4%) (Milk), Mature Cheddar Cheese (4%) (Milk), Potato, Coloured Mature Cheddar Cheese (3%) (Cheddar Cheese (Milk), Colour (Carotenes)), Rapeseed Oil, Modified Starch, Cheese Powder (Cheddar Cheese (Milk), Cheese (Milk), Milk Solids, Salt), Salt, Wheat Gluten, Cream Powder (Milk), Flavouring (contains Milk), Sunflower Oil, Stabiliser (Guar Gum, Carboxy Methyl Cellulose, Carrageenan, Cellulose), Mustard Powder, Milk Protein, White Pepper, Emulsifier (Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids, Mono - and Diglycerides of Fatty Acids), Skimmed Milk Powder, Acidity Regulator (Sodium Phosphates), Colour (Carotenes), Sugar, Cornflour, Pea Protein.'
        },
        {
            'id': '6E3iSmKo5J9lqh2qQqhl',
            'name': 'Classic Strawberry',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Strawberries, Acidity Regulator (Citric Acid), Gelling Agent (Pectins).'
        },
        {
            'id': '6E9TyAq5YZkKEFVSAYlX',
            'name': 'Plant Chef Meat Free Southern Fried Fillets',
            'brand': 'Tesco Plant Chef',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour, Soya Protein (7%), Wheat Protein (6%), Soya Protein Isolate (5%), Sunflower Oil, Yeast Extract, Thickener (Methyl Cellulose), Onion Powder, Spices, Garlic Purée, Wheat Starch, Flavouring, Lemon Juice, Sugar Cane Fibre, Garlic Powder, Salt, Dextrose, Yeast, Iron, Vitamin B12.'
        },
        {
            'id': '6EOUDZrlH2d9dKB171aQ',
            'name': 'Roasted Sweet Potato & Feta Pie',
            'brand': 'Higgidy',
            'serving_size_g': 100.0,
            'ingredients': 'Sweet Potato (21%), Water, Wheat Flour (contains Calcium Carbonate, Iron, Niacin, Thiamin), Sautéed Onion (Onions, Rapeseed Oil), Feta Cheese (Milk) (9%), Spinach (6%), Mature Cheddar Cheese (Milk), Vegetable Oils (Sustainable Palm Oil, Rapeseed Oil), Crème Fraîche (Milk), Wholemeal Spelt Flour (Wheat), Cannellini Beans, Dried Skimmed Milk, Butter (Milk), Butternut Squash Purée, Cornflour, Double Cream (Milk), Pumpkin Seeds, Garlic Purée, Salt, Brown Linseeds, Golden Linseeds, Poppy Seeds, Black Pepper, Cumin Seeds, Cumin, Salt, Nutmeg, Paprika, Cayenne Pepper, Dried Red Chilli (<1%), Mustard Powder, Yeast.'
        },
        {
            'id': '6FeK7LXCqrC8JwBvcB9M',
            'name': 'Soft White Farmhouse',
            'brand': 'Waitrose',
            'serving_size_g': 50.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Salt, Preservative (Calcium Propionate), Emulsifiers (Mono-and Diglycerides of Fatty Acids, Mono-and Diacetyl Tartaric Acid Esters of Mono-and Diglycerides of Fatty Acids), Spirit Vinegar, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '6FejXmDiBcpdejThLh8S',
            'name': 'Chicken And Chorizo Patatas Bravas Salad',
            'brand': 'Co-op',
            'serving_size_g': 260.0,
            'ingredients': 'Patatas Bravas Mix 55% (Potato, Roasted Mixed Vegetables (Red Pepper, Yellow Pepper, Red Onion), Rapeseed Oil, Sundried Tomato Paste (Water, Tomato Paste, Sundried Tomatoes, Rapeseed Oil, Tomato Purée, Salt, Sugar, Garlic Purée, Basil, Oregano), Concentrated Tomato Paste, Onion, Water, Sherry Vinegar, Rapeseed Oil, Tomatoes, Red Chilli Purée, Parsley, Sugar, Garlic Purée, Cornflour, Smoked Paprika, Concentrated Lemon Juice, White Wine Vinegar, Salt, Olive Oil, Colour (Paprika Extract), Extra Virgin Olive Oil), Cooked Marinated Chicken 13% (Chicken Breast, Red Chilli Purée, Tomato Purée, Rapeseed Oil, Sugar, Red Wine Vinegar, Cornflour, Garlic Purée, Spices (Chilli Powder, Coriander Seeds, Cumin, Black Pepper, Turmeric, Coriander), Salt, Onion Powder), Aioli Dressing 13% (Mayonnaise (Water, Rapeseed Oil, Cornflour, Pasteurised Egg Yolk, Salt, Spirit Vinegar, Sugar, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), White Wine Vinegar), Salt, Water, Concentrated Lemon Juice, Garlic Purée), Chorizo 5% (Pork, Salt, Lactose (Milk), Spices (Paprika, Smoked Paprika, Black Pepper), Dextrose, Sugar, Milk Protein, Garlic Powder, Colour (Paprika Extract), Antioxidants (Sodium Erythorbate, Rosemary Extract), Acidity Regulator (Sodium Citrate), Preservatives (Sodium Nitrate, Potassium Nitrate), Oregano), Piquillo Peppers 5% (Piquillo Pepper, Water, Sugar, Salt, Acidity Regulator (Citric Acid)), Apollo Lettuce 4%, Red Salanova 4%.'
        },
        {
            'id': '6FiRT7xEfHrDQ0CYQvsA',
            'name': 'Hula Hoops Salt & Vinegar',
            'brand': 'KP Snacks',
            'serving_size_g': 24.0,
            'ingredients': 'Potato (Potato Starch & Dried Potato), Sunflower Oil (24%), Rice Flour, Salt & Vinegar Flavour (Natural Flavourings, Salt, Acid (Citric Acid), Rice Flour, Dextrose, Sugar, Maltodextrin, Dried Yeast Extract), Maize Flour, Potassium Chloride, Salt.'
        },
        {
            'id': '6FxVMxZ2VRoJqjPQeP7B',
            'name': 'Sizzling Steak Ridge Cut Crisps',
            'brand': 'M&S',
            'serving_size_g': 30.0,
            'ingredients': 'Potatoes, Sunflower Oil, Rice Flour, Yeast Extract, Sugar, Salt, Dried Onions, Natural Flavouring, Acid (Citric Acid), Natural Colour (Paprika Extract), Black Pepper Extract.'
        },
        {
            'id': '6HdZwIgWbSydbLzn5meq',
            'name': 'For Chicken Gravy Granules',
            'brand': 'Tesco',
            'serving_size_g': 75.0,
            'ingredients': 'Potato Starch, Palm Oil, Wheat Flour (Wheat Flour, Carbonate, Iron, Niacin, Thiamin), Salt, Flavourings, Colour (Plain Caramel), Barley Malt Extract, Emulsifier (Soya Lecithins), Citric Acid.'
        },
        {
            'id': '6HnkhXx8Tv0Hg4tXULd6',
            'name': 'Red Hen Chicken Strips Hot & Spicy',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '58% Chicken Breast Fillet, Wheat Flour, Breadcrumbs (Wheat Flour, Yeast, Salt), Salt, Corn Starch, Raising Agents (Diphosphates, Sodium Carbonates), Rapeseed Oil, Water, Wheat Gluten, Paprika Extract, Flavourings, Spices, White Pepper, Dried Garlic.'
        },
        {
            'id': '6BAR9iivVYmEQxlVVkS0',
            'name': 'N BAR PACK 5 BAR Guiltless 76 Toffee Flavoured WHI',
            'brand': 'Guiltless',
            'serving_size_g': 20.0,
            'ingredients': 'Milk Chocolate Flavour Coating (27%) (Sugar, Vegetable Fat (Palm, Shea), Skimmed Milk Powder, Fat Reduced Cocoa Powder, Whey Milk Powder, Emulsifiers (Soya Lecithins, E476)), Glucose Syrup, Sugar, Bulking Agent (Polydextrose), Water, Crisped Rice (6%) (Rice Flour, Sugar, Salt), Bamboo Fibre, Skimmed Milk Powder, Oligofructose, Vegetable Fats (Palm, Palm Kernel), Dried Egg White, Salt, Emulsifier (Sunflower Lecithins), Flavouring.'
        },
        {
            'id': '6IlTN1CcWdbktYdpXCET',
            'name': 'Smoked No Salmon Slices',
            'brand': 'Plant Menu',
            'serving_size_g': 25.0,
            'ingredients': 'Water, Modified Corn Starch, Trehalose, Thickeners (Carrageenan, Konjac Gum, Locust Bean Gum), Salt, Flavouring, Rice Flour, Rice Protein, Vinegar Powder, Flax Seed Oil, Colour (Paprika Extract), Citrus Fibre, Plant Extracts (Beetroot Concentrate, Fenugreek Extract, Paprika Concentrate), Firming Agent (Potassium Chloride).'
        },
        {
            'id': '6Ilq7ALIZsXiGcyzV9JC',
            'name': 'Alsports',
            'brand': 'Dominion',
            'serving_size_g': 25.0,
            'ingredients': 'Sugar, Glucose Syrup, Modified Potato Starch, Glucose-Fructose Syrup, Acids (Citric Acid, Malic Acid, Lactic Acid), Fruit and Plant Concentrates (Carrot, Black Carrot, Apple, Safflower, Lemon, Turmeric, Radish, Blackcurrant), Flavourings, Sunflower Oil, Spirulina Concentrate, Glazing Agent (Carnauba Wax).'
        },
        {
            'id': '6KmrgbmrsKoUsPtjdxZH',
            'name': 'Frischei-waffeln',
            'brand': 'Confiserie Firenze',
            'serving_size_g': 21.0,
            'ingredients': '32% Egg, Sugar, Wheat Flour, Rapeseed Oil, Humectant (Glycerol), Rice Flour, Wheat Starch, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Sunflower Lecithins), Skimmed Milk Powder, Natural Flavouring, Salt.'
        },
        {
            'id': '6a9ClWEuIcWGxvViTUAr',
            'name': 'Wholemeal Tortilla Wraps',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Palm Oil, Humectant (Glycerol), Sugar, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Emulsifier (Mono - and Di-Glycerides of Fatty Acids), Acidity Regulator (Citric Acid), Preservatives (Potassium Sorbate, Calcium Propionate), Salt, Wheat Starch, Flour Treatment Agent (L-Cysteine).'
        },
        {
            'id': '6as4J77KZdCoc3lhbeg7',
            'name': 'Seafood Sticks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Surimi Fish Protein (35%) (Alaska Pollock (Fish), Hake (Fish), Sugar), Wheat Starch, Potato Starch, Sugar, Rapeseed Oil, Salt, Flavourings (contains Crustaceans), Free Range Egg White Powder, Colour (Lycopene), Free Range Dried Egg.'
        },
        {
            'id': '6UUpwaoZHcCy1DpXGnew',
            'name': 'Bacon Lettuce & Tomato With Mayonnaise On Malted Bread',
            'brand': 'Co-op',
            'serving_size_g': 173.0,
            'ingredients': 'Malted Bread, Bacon, Lettuce, Tomato, Mayonnaise.'
        },
        {
            'id': '6UHH99tAKfTTCHktz0ou',
            'name': 'Clear Whey Isolate - Peach Iced Tea',
            'brand': 'Bulk',
            'serving_size_g': 25.0,
            'ingredients': 'Whey Protein Hydrolysate (Milk), Flavouring, Anti-Foaming Agents (Dimethyl Polysiloxane, Silicon Dioxide), Sweetener (Sucralose), Acid (Citric Acid), Colour (Beetroot Red).'
        },
        {
            'id': '6bEf7kFZ5RDOt8i8tvRI',
            'name': 'Fruitfetti',
            'brand': 'Holland And Barrett',
            'serving_size_g': 30.0,
            'ingredients': '50% Freeze Dried Peach, 50% Freeze Dried Strawberry Slices.'
        },
        {
            'id': '6bWJCDGzhM1BY8ns54P5',
            'name': 'Bbq Beef Hoops',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Potato (31%) (Potato Flour, Potato Flake), Potato Starch, Vegetable Oil (Sunflower Oil, Rapeseed Oil, in varying proportions), Rice Flour, Salt, Flavouring, Maltodextrin, Sugar, Onion, Acids (Citric Acid, Sodium Citrate), Garlic, Black Pepper, Colour (Paprika Extract), Antioxidant (Ascorbic Acid).'
        },
        {
            'id': '6cXD6uojFxKIAYW9FYs6',
            'name': 'Squirty Topping',
            'brand': 'Dorlay',
            'serving_size_g': 10.0,
            'ingredients': 'Skimmed Milk (57%), Vegetable Oil (15%) (Palm Kernel, Coconut, Palm, Rapeseed), Water, Sugar (8%), Fully Hydrogenated Palm Kernel Oil (5%), Propellent Gas (Nitrous Oxide), Emulsifiers (E471, E435), Stabiliser (E407), Natural Flavouring, Colouring (E160a).'
        },
        {
            'id': '6cv6Z9wQULI5TE0VLpNI',
            'name': 'Sour Spiders',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Modified Potato Starch, Modified Tapioca Starch, Acid (Citric Acid, Malic Acid), Acidity Regulator (E331), Fruit, Vegetable and Plant Concentrates (Apple, Carrot, Hibiscus), Flavourings, Molasses.'
        },
        {
            'id': '6d7UU8rFLCCdT2uGpAm3',
            'name': 'ALDI Strawberries',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Frozen Strawberries.'
        },
        {
            'id': '6eCOU903ksVYJyyn6lct',
            'name': 'Mediterranean Tomato Chutney',
            'brand': 'Branston',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Tomato Purée (22%), Onion, Red Pepper, Carrot, Tomato (8%), Spirit Vinegar, Red Pepper, Carrot, Modified Maize Starch, Gherkin, Garlic Purée, Salt, Mustard Seed, Dried Herbs (Oregano, Rosemary, Tarragon, Basil, Mint), Ground Spices (Black Pepper, Basil, Cumin, Parsley), Colour (Paprika Extract), Tomato Powder.'
        },
        {
            'id': '6g0S2RjOcI9NkVXzN6Qx',
            'name': 'White Cooking Chocolate',
            'brand': 'Coles',
            'serving_size_g': 25.0,
            'ingredients': 'Sugar, Cocoa Butter, Whole Milk Powder, Whey Powder (Milk), Emulsifier (Lecithins (Soya)), Vanilla Extract.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 68\n")

    cleaned_count = update_batch68(db_path)

    # Calculate total progress
    previous_total = 1086  # From batch 67
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 68 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1100 and previous_total < 1100:
        print(f"\n🎉🎉 1100 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 17.1% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
