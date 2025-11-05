#!/usr/bin/env python3
"""
Batch 65: Clean ingredients for 25 products
Progress: 1011 -> 1036 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch65(db_path: str):
    """Update batch 65 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '3Yl2UiRKTgGKwjeADRnS',
            'name': 'Illegal Gianduja',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Solids (Cocoa Mass, Cocoa Butter), Hazelnut Paste (26%), Sugar, Full Cream Milk Powder, Butter Oil (from Milk), Emulsifier (Soya Lecithin), Flavouring. Milk Chocolate Contains Minimum 50% Cocoa Solids, Minimum 20% Milk Solids.'
        },
        {
            'id': '3ZQ6ITQRIgGhfMPNbbMV',
            'name': 'Italian Antipasto Selection',
            'brand': 'Aldi',
            'serving_size_g': 120.0,
            'ingredients': 'Prosciutto Crudo (33%) (Pork, Salt, Preservative (Potassium Nitrate)), Milano Salami (33%) (Pork, Salt, Flavouring, Dextrose, Sugar, Spices, Garlic, Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Sodium Nitrite)), Napoli Salami (33%) (Pork, Salt, Flavourings, Spices, Dextrose, Sugar, Garlic, Antioxidant (Sodium Ascorbate), Smoke Flavouring, Preservatives (Potassium Nitrate, Sodium Nitrite)).'
        },
        {
            'id': '3a3yNRw3hjQ7ZZoqfdi9',
            'name': 'Sliced Sweet & Smoky Chicken',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast, Sugar, Rice Bran Oil, Corn Starch, Tomato Paste, Salt, Smoked Paprika, Tapioca Starch, Dextrose, Stabiliser (Sodium Triphosphate), Onion Powder, Tomato Powder, Garlic Powder, Yeast Extract, Black Pepper, Paprika Extract, Flavouring, Chilli Powder, Paprika, Acidity Regulator (Citric Acid), Cocoa Powder.'
        },
        {
            'id': '3aMTvqXhw7WndatSJvB8',
            'name': 'Daily Milk Coconutty',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, Sugar, Cocoa Butter, Cocoa Mass, Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Vegetable Fats (Palm, Coconut, Shea), Desiccated Coconut (1.5%), Emulsifiers (E442, E476, Soya Lecithins), Whole Milk Powder, Whey Powder (from Milk), Raising Agents (E500, E503), Wheat Malt, Salt, Wheat Starch, Flavourings, Glucose Syrup, Glazing Agent (Gum Arabic), Modified Starch.'
        },
        {
            'id': '3astKNZvqanQFTp7i4z4',
            'name': 'Potato Salad',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '61.5% Cooked Potato, Water, 9.8% Yogurt Dressing (Whole Milk, Modified Maize Starch, Stabilizer (Pectins)), Rapeseed Oil, Sugar, Chives, Onion, Spirit Vinegar, Modified Starch (Maize, Potato), Salt, Egg Yolk, Spices (Mustard Seeds, Turmeric, Chilli Pepper), Preservative (Potassium Sorbate), Acids (Citric Acid, Lactic Acid), Thickeners (Guar Gum, Xanthan Gum), Acidity Regulator (Sodium Acetate).'
        },
        {
            'id': '3biv8jZraBma0i3MFlBC',
            'name': 'Unsmoked Bacon',
            'brand': 'Morrisons',
            'serving_size_g': 58.0,
            'ingredients': 'Pork (87%), Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': '3bxJ3veN4ZgCx0ZjdtPV',
            'name': 'Beef Chilli With Brown Rice & Sweetcorn Relish',
            'brand': 'Chef Select',
            'serving_size_g': 365.0,
            'ingredients': '35% Cooked Brown Rice and Peas (Cooked Brown Rice, Water, Brown Rice, 16% Peas, Coriander), 16% Minced Beef, 12% Sweetcorn, Water, 9% Chopped Tomato, 5% Black Turtle Beans, Onion, 2% Red Kidney Beans, 2% Red Lentils, Tomato Paste, Garlic, Green Chilli, Coriander, Salt, Red Chilli, Red Wine Vinegar, Beef Stock (Yeast Extracts, Glucose Syrup, Natural Flavouring, Salt, Onion Powder, Beef Stock Powder, Rapeseed Oil, Tomato Powder), Ground Cumin, Ground Smoked Paprika, Cornflour, Sugar, Dried Oregano, Barley Malt Extract, Cracked Black Pepper.'
        },
        {
            'id': '3bzxY17PkR1GtJ5ZGNNM',
            'name': 'Plum Hoisin Stir Fry Sauce',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Concentrated Plum Juice (8%), Tamari Soy Sauce (6%) (Water, Soya Beans, Salt, Spirit Vinegar, Alcohol), Cornflour, Rice Vinegar, Garlic Purée, Yellow Bean Paste (Soya Beans, Sugar, Water, Salt, Spirit Vinegar, Alcohol), Ginger Purée, Brown Sugar, Chinese Five Spice (Cassia, Fennel, Ginger, Star Anise, Clove Powder), Cinnamon, Star Anise Powder.'
        },
        {
            'id': '3c8bv2iKKT7uZBiPkA5i',
            'name': 'British Outdoor Bred Roast Ham',
            'brand': 'M&S',
            'serving_size_g': 150.0,
            'ingredients': 'British Pork, Curing Salt (Salt, Preservative (Sodium Nitrite)), Sugar, Stabiliser (E451(i), E451(ii)), Caramelised Sugar Syrup, Antioxidant (E301).'
        },
        {
            'id': '3cQ23pPW08FkCPek9kr6',
            'name': 'Costa Caramel Latte',
            'brand': 'Tassimo',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (from Milk) 29%, Sugar 28%, Roast and Ground Coffee 22%, Water, Milk Protein Concentrate, Milk Minerals, Salt, Thickener (E414), Flavourings, Acidity Regulator (E331).'
        },
        {
            'id': '3dIlMWwA3XrSMg2KDPCx',
            'name': 'Original Steak Strips',
            'brand': 'New World Foods Europe Ltd Oakland Farms',
            'serving_size_g': 35.0,
            'ingredients': 'Beef, Water, Demerara Sugar, Sea Salt, Apple Cider Vinegar, Pineapple Concentrate, Black Pepper, Dried Garlic, Dried Onion, Spices, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': '3l4mxKONEdzai0z231or',
            'name': 'Cheddar Bar-b-que Snoop Dogg',
            'brand': 'Rap Snacks',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Vegetable Oil (May Contain One or More of the Following: Canola, Corn, Cottonseed, Soybean, Sunflower), BBQ Cheddar Seasoning (Sugar, Dextrose, Cheddar (Cultured Milk, Salt, Enzymes), Salt, Whey Powder, Monosodium Glutamate, Onion Powder, Paprika, Buttermilk Powder, Butter (Cream, Lactic Acid), Disodium Phosphate, Natural Flavour, Artificial Flavor, FD&C Yellow #5, FD&C Yellow #6, Malic Acid, Spice, Disodium Guanylate, Disodium Inosinate, Annatto for Color, Spice and Coloring (contains Turmeric)), Salt, Dextrose.'
        },
        {
            'id': '3qHdh1gw4rGpQc1c1AWu',
            'name': 'Brunch Bar',
            'brand': 'Cadbury Bournville',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes (25%), Sugar, Glucose Syrup, Vegetable Fats (Palm, Shea, Mango, Sal in varying proportions), Cocoa Mass, Wheat Flour, Stabiliser (Sorbitol), Invert Sugar Syrup, Rice Flour, Honey (2%), Wheat Bran, Humectant (Glycerol), Cocoa Butter, Milk Fat, Emulsifiers (Soya Lecithins, E471, E476), Barley Malt Extract, Salt, Dextrose, Molasses.'
        },
        {
            'id': '3r97ZNLwlSQUiQgCVZid',
            'name': 'Wheat Biscuits',
            'brand': 'Tesco',
            'serving_size_g': 38.0,
            'ingredients': 'Wheat (95%), Malted Barley Extract, Sugar, Salt, Niacin, Iron, Riboflavin, Thiamin, Folic Acid.'
        },
        {
            'id': '3rIlUGtTJ4YlTFMbAhuV',
            'name': 'Beechwood Smoked Diced Pancetta',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Dextrose, Spices, Black Peppercorns, White Pepper, Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Potassium Nitrate), Garlic Powder.'
        },
        {
            'id': '3rfE3rYLO9aNBTgHzH2Z',
            'name': 'Squares',
            'brand': 'Kellogg\'s',
            'serving_size_g': 28.0,
            'ingredients': 'Kellogg\'s Toasted Rice Cereal (35%) (Rice, Sugar, Salt, Barley Malt Extract, Niacin, Iron, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin D, Vitamin B12), Marshmallow (33%) (Glucose Syrup, Sugar, Beef Gelatin, Flavouring), Fructose, Palm Oil, Invert Sugar Syrup, Glucose Syrup, Humectant (Glycerol), Salt, Flavouring (contains Milk), Emulsifiers (E472e, E472a), Antioxidant (E320).'
        },
        {
            'id': '3ssIIln0LoMdvpQLXEek',
            'name': 'Flatbread',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Yeast, Extra Virgin Olive Oil (2%), Wheat Gluten, Spirit Vinegar, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate, Calcium Phosphates), Stabiliser (Sodium Carboxy Methyl Cellulose), Preservative (Calcium Propionate), Acidity Regulator (Citric Acid), Salt, Wheat Starch.'
        },
        {
            'id': '3tJjWXYNlJIdV1C9ZzI8',
            'name': 'Christmas Pudding',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sultanas (36%), Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cider (8%), Vegetable Oils (Palm Oil, Sunflower Oil), Rum (4%), Humectant (Glycerol), Orange Peel, Raisins (2%), Candied Orange and Lemon Peel (Orange Peel, Glucose Syrup, Lemon Peel, Sugar, Acid (Citric Acid)), Brandy (1.5%), Cream (Milk), Glacé Cherries (1.5%) (Cherries, Glucose-Fructose Syrup, Colour (Anthocyanins), Acid (Citric Acid)), Orange Juice from Concentrate, Sherry (1%), Inulin, Treacle, Rice Flour, Lemon Peel, Molasses, Spices, Salt, Yeast, Orange Oil.'
        },
        {
            'id': '3thxpmn4gyP48wnb5m8Z',
            'name': 'Buttermilk Pancakes',
            'brand': 'Tesco Finest',
            'serving_size_g': 70.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Reconstituted Buttermilk (27%), Pasteurised Egg, Sugar, Rapeseed Oil, Humectant (Glycerol), Fermented Wheat Flour, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate, Calcium Chloride).'
        },
        {
            'id': '3tppTaoj4kSJLn4JRxpR',
            'name': 'Snap\'d Double Cheese Baked Snacks',
            'brand': 'Cheez It',
            'serving_size_g': 30.0,
            'ingredients': 'Wheat Flour, Sunflower Oil, Starch, Dehydrated Potatoes, Cheese Seasoning (Whey Permeate Powder (Milk), Maltodextrin, Salt, Cheese Powder (Milk) (0.5%), Buttermilk Powder (Milk), Onion Powder, Flavourings, Acidity Regulators (Citric Acid, Lactic Acid), Sugar, Yeast Extract, Garlic Powder, Rapeseed Oil, Colour (Paprika Extract)), Cheese (Milk) (4.2%), Oat Fibre, Sugar, Salt, Raising Agents (Ammonium Carbonates), Acids (Citric Acid, Lactic Acid), Emulsifiers (Lecithins), Colours (Curcumin, Annatto Norbixin, Paprika Extract).'
        },
        {
            'id': '3uAkYdk6vmGPg1SMe6LN',
            'name': 'Digestive',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Wholemeal Wheat Flour, Sugar, Palm Oil, Rapeseed Oil, Oats, Partially Inverted Refiners Syrup, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Salt.'
        },
        {
            'id': '3ursV99bCwWLc9d8PozC',
            'name': 'Refreshing Mint Choc Chip',
            'brand': 'Carte D\'Or',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted Skimmed Milk, Sugar, Coconut Fat, Glucose Syrup, Sugar, Cocoa Mass, Glucose-Fructose Syrup, Whey Solids (Milk), Skimmed Milk Powder or Concentrate, Cocoa Butter, Fructose, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Ammonium Phosphatides), Stabilisers (Guar Gum, Locust Bean Gum, Tara Gum), Glucose Syrup, Butter Oil (Milk), Colour (Copper Complexes of Chlorophyllins), Fat-Reduced Cocoa Powder, Flavouring.'
        },
        {
            'id': '3vhfFjqen3XHz8E2UEzd',
            'name': 'Tomato And Herb Pasta Sauce',
            'brand': 'Everyday Essentials Aldi',
            'serving_size_g': 110.0,
            'ingredients': 'Tomato Puree from Concentrate (42%), Tomatoes (29%), Water, Modified Maize Starch, Salt, Preservative (Citric Acid), Dried Onion, Garlic Powder, Sugar, Herbs, Spices, Sweetener (Sodium Saccharin).'
        },
        {
            'id': '3xdU8en49KUboIVbFbhh',
            'name': 'Ketchup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g of Ketchup), Sugar, Spirit Vinegar, Salt, Flavourings (contains Celery), Cayenne Pepper, Garlic Powder.'
        },
        {
            'id': '3rplEA1agCS6cnN9zTMG',
            'name': 'Pierogi Ruskie',
            'brand': 'Dawtona',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Boiled Potatoes 26.5%, Water, Cottage Cheese 10.5%, Fried Onion 5% (Onion, Rapeseed Oil), Rapeseed Oil, Salt, Spices.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 65\n")

    cleaned_count = update_batch65(db_path)

    # Calculate total progress
    previous_total = 1011  # From batch 64
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 65 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1025 and previous_total < 1025:
        print(f"\n🎉 1025 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 15.9% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
