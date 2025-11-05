#!/usr/bin/env python3
"""
Clean ingredients batch 34 - BREAKING THE 350 MILESTONE!
"""

import sqlite3
from datetime import datetime

def update_batch34(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 34 (350 MILESTONE!)\\n")

    clean_data = [
        {
            'id': '6OEVDK6dPUlt0XVjhb9y',
            'name': 'Dairy Milk Snowy Fingers',
            'brand': 'Cadbury',
            'serving_size_g': 21.0,
            'ingredients': 'Wheat Flour, Sugar, Cocoa Butter, Palm Oil, Whole Milk Powder, Cocoa Mass, Skimmed Milk Powder, Whey Permeate, Lactose, Milk Proteins, Milk Fat, Partially Inverted Sugar Syrup, Emulsifiers (Soya Lecithin, E442, E476), Salt, Raising Agents (Ammonium Hydrogen Carbonate, Sodium Hydrogen Carbonate), Flavouring. Contains Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Nuts.'
        },
        {
            'id': 'nW2Nf5VmNlMspVEk19Qr',
            'name': 'Organic Dijon Mustard',
            'brand': 'Delouis',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Mustard Seeds, Organic Alcohol Vinegar, Water, Salt.'
        },
        {
            'id': 'LP39vadkqnzyOuVrfpCw',
            'name': 'Garlic Slices',
            'brand': "Sainsbury's",
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Unsalted Butter (Milk) (17%), Water, Garlic Purée (1%), Chopped Garlic (1%), Chopped Parsley (1%), Salt, Yeast, Concentrated Lemon Juice, Flour Treatment Agents (Ascorbic Acid, L-Cysteine). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'lFiCAdC4UlE39N7z8qca',
            'name': '6 Crumpets',
            'brand': 'Tesco',
            'serving_size_g': 55.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Spirit Vinegar, Sugar, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Yeast, Salt, Preservative (Potassium Sorbate). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'sbKy4cxIIVm9rZlGuJEl',
            'name': 'Smoky Chorizo Chicken',
            'brand': 'Birchwood',
            'serving_size_g': 74.0,
            'ingredients': 'British Diced Chicken Breast (86%), Chorizo Pork Sausage Slices (9%) (Pork (89%), Water, Salt, Smoked Paprika, Pork Collagen Casing, Dextrose, Garlic Paste, Antioxidant (Sodium Ascorbate), Nutmeg, Preservative (Sodium Nitrite), Oregano), Smoked Paprika Marinade (5%) (Sugar, Smoked Paprika, Ground Cumin, Ground Chilli, Salt, Cornflour, Dried Glucose Syrup, Garlic Powder, Tomato Powder, Ground Oregano, Chipotle Chilli, Thickener (Guar Gum), Green Pepper, Red Pepper, Parsley, Paprika Extract, Flavouring). Contains Pork.'
        },
        {
            'id': 'Hsw30CQRr1FMqNnICfGL',
            'name': 'Luxury Hot Cross Buns',
            'brand': 'Deluxe',
            'serving_size_g': 75.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Orange Juice Soaked Fruits (23%) (Sultanas, Raisins, Currants, Orange Juice from Concentrate), Water, Orange Soaked Flame Raisins (7%) (Flame Raisins, Orange Juice from Concentrate), Yeast, Mixed Peel (2.5%) (Orange, Lemon Peel), Wheat Gluten, Palm Oil, Dextrin, Butter, Salt, Sugar, Cane Molasses, Honey, Natural Flavouring, Rapeseed Oil, Vegetable Fibre (Potato, Psyllium), Palm Fat, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '6zucwyHem2iBzsepabuy',
            'name': '4 Brioche Burger Buns',
            'brand': 'Warburtons',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (with Calcium, Iron, Niacin, Thiamin), Water, Sugar, Vegetable Oils (Rapeseed Oil, Sustainable Palm Oil), Glaze (Water, Pea Protein, Glucose Syrup, Rice Flour), Yeast, Salt, Emulsifiers (E471, E481, E472e), Tapioca Starch, Wheat Gluten, Soya Flour, Preservative (Calcium Propionate), Colour (Beta Carotene), Flour Treatment Agent (Ascorbic Acid, E920), Natural Flavouring. Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'sJt9qzW1iiPJIy6WsZWz',
            'name': 'Cod Fishcakes',
            'brand': 'The Fishmonger',
            'serving_size_g': 100.0,
            'ingredients': 'Cod (Gadus Morhua and/or Gadus Macrocephalus) (Fish) (38%), Potato (22%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, White Sauce (Double Cream (Milk), Water, Salt, Lemon Juice Concentrate), Fish Stock (Water, Potato Flakes, Concentrated Fish Extract (Fish Extract, Salt), Salt, Cod Powder (Fish), Lemon Juice Concentrate, Onion Powder, Anchovy Purée (Anchovies (Fish), Salt, Sunflower Oil)), Cornflour, Onion Powder, Ground White Pepper, Rapeseed Oil, Potato Flake, Extra Virgin Olive Oil, Parsley, Maize Starch, Yeast, Paprika, Apple Cider Vinegar, Salt, Sugar, Wheat Gluten, Black Pepper. Contains Cereals Containing Gluten, Fish, Milk, Wheat.'
        },
        {
            'id': 'bkbUcLvlLKIv2Sf3uzZH',
            'name': 'Vegan Cocoa Dusted Truffles',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Vegetable Oils (Palm, Palm Kernel, Coconut, Sunflower, Rapeseed), Cocoa Mass, Fat Reduced Cocoa Powder, Cocoa Butter, Emulsifier (Lecithins (Soya)). Dark Chocolate Contains Cocoa Solids 56% Minimum. Contains Soybeans.'
        },
        {
            'id': 'zqeq4agTz4Fet8lBLXQo',
            'name': 'Mandarin Segments',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Mandarins, Mandarin Juice from Concentrate, Acidity Regulator (Citric Acid).'
        },
        {
            'id': 'bOjNYmm6qdFlAQkGs4AR',
            'name': 'Mozzarella',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mozzarella Medium Fat Soft Cheese (Milk), Acidity Regulator (Citric Acid). Contains Milk.'
        },
        {
            'id': '8tuE4EgfpFN4hhj9Nk5M',
            'name': 'Triple Chocolate Cookies',
            'brand': 'Generic',
            'serving_size_g': 23.86,
            'ingredients': 'Milk Chocolate Coating (40%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Margarine (Palm Oil, Rapeseed Oil, Water, Salt, Emulsifier (Mono and Diglycerides of Fatty Acids)), Sugar, Dark Chocolate Chips (9%) (Cocoa Mass, Sugar, Cocoa Butter, Fat Reduced Cocoa Powder, Emulsifier (Soya Lecithins)), Milk Chocolate Chips (8%) (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Whey Powder (Milk), Skimmed Milk Powder, Emulsifier (Soya Lecithin)). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': '4fnwFtcFafyuZKrgAAq8',
            'name': 'Tomato Ketchup',
            'brand': 'Robertshaws',
            'serving_size_g': 15.0,
            'ingredients': 'Tomato Purée (79%), Glucose Fructose Syrup, Modified Corn Starch, Sugar, Vinegar, Salt, Flavouring.'
        },
        {
            'id': '2tG6NdCZjxJWPW579wz4',
            'name': 'Toffee Apple Oat Bar',
            'brand': 'Bio&Me',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten-Free Wholegrain Oats (40%), Chicory Root Fibre, Dates, Coconut Oil, Almond Butter, Sultanas, Seeds (4%) (Pumpkin, Sunflower), Dried Apple (2%), Almonds, Dried Carrot, Seaweed (Providing Natural Calcium), Natural Flavourings. Contains Nuts, Oats.'
        },
        {
            'id': 'RrkDovAJT28j6Tz3CZ1j',
            'name': 'Bourbon Biscuits',
            'brand': 'M&S',
            'serving_size_g': 14.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Oil, Fat Reduced Cocoa Powder, Glucose Syrup, Dextrose, Wheat Starch, Raising Agent (Sodium Bicarbonate, E503), Salt, Flavouring. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'SKQc0o4eVu5nOI086IRr',
            'name': 'Swedish Style Meatballs & Buttery Mash',
            'brand': 'Asda',
            'serving_size_g': 400.0,
            'ingredients': 'Potatoes (36%), Water, Beef and Pork Meatballs (18%) (Beef (61%), Pork (36%), Onions, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Wheat Protein, Dextrose, Salt, Spices, Yeast), Peas (10%), Onions, Double Cream (Milk) (2%), Unsalted Butter (Milk), Whole Milk, Cornflour, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Garlic Purée, Yeast Extract, Chicken Fat, Chicken Stock, Black Mustard Seeds, White Pepper, Spirit Vinegar, Bay Leaf Powder, Colour (Plain Caramel). Contains Beef, Cereals Containing Gluten, Milk, Mustard, Pork, Wheat.'
        },
        {
            'id': 'BpXWSLSVTrvA2nAOALsc',
            'name': 'Sweet Chilli & Sour Cream',
            'brand': 'Kettle Chips',
            'serving_size_g': 25.0,
            'ingredients': 'Select Potatoes, Sunflower Oil, Sweet Chilli and Sour Cream Seasoning (Sugar, Dried Sour Cream (Milk), Dried Skimmed Milk, Dried Yoghurt (Milk), Sea Salt, Dried Onion, Yeast Extract, Dried Chilli, Dried Red Pepper, Ground Paprika, Citric Acid, Natural Flavouring, Dried Garlic, Dried Lemon). Contains Milk.'
        },
        {
            'id': '5nsiLuduzJK6ADIO0mdY',
            'name': "Patak's Korma Spice Paste",
            'brand': "Patak's",
            'serving_size_g': 100.0,
            'ingredients': 'Water, Desiccated Coconut (10%), Vegetable Oil, Sugar, Concentrated Tomato Purée (6%), Ginger, Coriander (4%), Cumin, Salt, Acetic Acid, Turmeric, Garlic, Paprika, Maize Flour, Spices (Contain Mustard), Lactic Acid, Dried Coriander Leaf. Contains Mustard.'
        },
        {
            'id': '2OfnEK92bmxeQsM9iKhv',
            'name': 'High Protein Bar',
            'brand': 'Myprotein',
            'serving_size_g': 80.0,
            'ingredients': 'Protein Blend (23%) (Milk Protein, Whey Protein Concentrate (Milk)), Humectants (Glycerol, Maltitol), Milk Chocolate Flavoured Coating (14%) (Sweeteners (Isomalt, Sucralose), Non-Hydrogenated Palm and Palm Kernel Oil, Whey Powder (Milk), Fat Reduced Cocoa Powder, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Emulsifiers (Soya Lecithin, E476), Natural Flavouring), Hydrolysed Collagen, Fructo-Oligosaccharides, Soya Protein Isolate, Bulking Agent (Polydextrose), Flavouring, Rapeseed Oil, Salt, Sweetener (Sucralose), Antioxidant (Natural Mixed Tocopherols). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': '7yst6F945cTBVfZMR9uU',
            'name': 'Snaktastic Potato Hoops BBQ Beef Flavour',
            'brand': 'Snaktastic',
            'serving_size_g': 25.0,
            'ingredients': 'Dried Potato, Potato Starch, High Oleic Sunflower Oil, Rice Flour, Barbecue Beef Flavour Seasoning (Rice Flour, Salt, Natural Flavouring, Sugar, Dried Onion, Acid (Citric Acid), Dried Garlic, Ground Black Pepper, Colour (Paprika Extract)), Salt. May Contain Cereals Containing Gluten.'
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
            print(f"   Serving: {product['serving_size_g']}g\\n")
            updates_made += 1

    conn.commit()
    conn.close()

    total_cleaned = 336 + updates_made

    print(f"✨ BATCH 34 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    if total_cleaned >= 350:
        print(f"\\n🎉🎉🎉 350 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {400 - total_cleaned} products until 400!\\n")
    else:
        remaining_to_350 = 350 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_350} products until 350!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch34(db_path)
