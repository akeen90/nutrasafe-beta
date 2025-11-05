#!/usr/bin/env python3
"""
Clean ingredients batch 42 - BREAKING 550 MILESTONE!
"""

import sqlite3
from datetime import datetime

def update_batch42(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 42 (BREAKING 550!)\n")

    clean_data = [
        {
            'id': 'AWsTrC8NB3brVm3f8EsR',
            'name': 'Ardennes & Wild Mushroom Pâté',
            'brand': 'Co-op',
            'serving_size_g': 42.0,
            'ingredients': 'Pork Liver (32%), Pork (28%), Pork Fat, Wild Mushrooms (7%) (Black Fungus, Wild Mushrooms, Mushrooms (5%)), Potato Starch, Pork Rind, Salt, Dextrose, Antioxidants (Potassium Lactate, Sodium Ascorbate, Ascorbic Acid), Preservatives (Potassium Acetates, Sodium Nitrite), Flavourings, Emulsifier (Citric Acid Esters of Mono- and Diglycerides of Fatty Acids), Shallots, Sunflower Oil, Garlic Powder, Shallot Powder, Spices (White Pepper, Mace, Cardamom, Nutmeg), Sugar, Spice Extracts (Coriander Extract, Ginger Extract, Mace Extract). Contains Pork.'
        },
        {
            'id': '7HxloPDRtGfkIrYFDPPL',
            'name': 'Seeded Brioche Burger Buns',
            'brand': 'Deluxe',
            'serving_size_g': 50.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Thiamin, Iron, Niacin), Free Range Egg (12%), Golden Linseed (5%), Sugar, Rapeseed Oil, Invert Sugar Syrup, Yeast, Concentrated Butter (Milk) (1.5%), Skimmed Milk Powder, Fermented Wheat Flour, Wheat Gluten, Salt, Water, Milk Protein, Emulsifier (Mono- and Diglycerides of Fatty Acids, Xanthan Gum, Soya Lecithin), Deactivated Yeast, Potato Dextrin, Colour (Carotene), Flour Treatment Agent (Ascorbic Acid), Flavouring. Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': '6LHKbtW2aj904KXYmGC4',
            'name': 'Creamy Mozzarella Cheese',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mozzarella Cheese (Cow\'s Milk), Anti-Caking Agent (Potato Starch). Contains Milk.'
        },
        {
            'id': '3Xb88Kce0U41FmqEKeyi',
            'name': 'Curry Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Reconstituted Tomato Purée, Turmeric, Rice Flour, Fenugreek, Cumin, Mustard Flour, Ginger, Salt, Onion (5%), Modified Maize Starch, Sugar, Curry Powder (Coriander, Black Pepper, Paprika, Nutmeg, Chilli, Fennel), Sultanas, Salt, Creamed Coconut, Onion Powder, Garlic Powder, Acidity Regulator (Lactic Acid), Ground Turmeric, Desiccated Coconut. Contains Mustard.'
        },
        {
            'id': 'wji4C65sU6YvJhgoPIJ0',
            'name': 'Scotch Broth',
            'brand': 'Baxters',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Cooked Pearl Barley (11%), Carrots, Marrowfat Peas, Potatoes (4%), Onions, Swede, Leeks, Beef (1.5%), Mutton (1.5%), Cornflour, Cabbage, Mutton Fat, Salt, Modified Cornflour, Yeast Extract, Parsley, Beef Extract, White Pepper. Contains Barley, Beef, Cereals Containing Gluten.'
        },
        {
            'id': '6nTFtjyVg3S456jiI55q',
            'name': 'Sparkling Blueberry & Raspberry Water',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Citric Acid, Malic Acid, Flavourings, Preservative (Potassium Sorbate), Sweeteners (Sucralose, Acesulfame K).'
        },
        {
            'id': '9Km3BOdWm62Yq315y8SZ',
            'name': 'Hot Cross Buns',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Mixed Fruits (33%) (Moistened Sultanas (Sultanas, Water), Vostizza Currants, Water), Yeast, Mixed Peel (3%) (Orange, Lemon), Sugar, Wheat Protein, Unsalted Butter (Milk) (2%), Invert Sugar Syrup, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Maize Starch, Mixed Spices, Salt, Soya Flour, Rapeseed Oil, Flavouring, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': '0oLYvZ8YtfpOO75pVHKh',
            'name': 'Walkers Squares Salt & Vinegar Flavour',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Sunflower Oil, Rapeseed Oil, Salt & Vinegar Seasoning (Lactose (Milk), Salt, Acidity Regulators (Sodium Diacetate, Citric Acid, Malic Acid), Flavouring (contains Barley Malt Vinegar)). Contains Barley, Cereals Containing Gluten, Milk.'
        },
        {
            'id': 'VWLjr9Zn9xv7IgM5SUoc',
            'name': 'Waitrose 2 Seeded Haddock Fillets',
            'brand': 'Waitrose',
            'serving_size_g': 130.0,
            'ingredients': 'Haddock (Melanogrammus Aeglefinus) (Fish) (60%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Water, Rice Flour, Wheat Starch, Linseed, Sunflower Seeds, Pumpkin Seeds, Wheat Gluten, Maize Flour, Poppy Seeds, Salt, Yeast, Dextrose, Sea Salt, Raising Agent (Ammonium Carbonates), Black Pepper Extract. Contains Cereals Containing Gluten, Fish, Wheat.'
        },
        {
            'id': '8rpurscPVEvn9tjmWbEX',
            'name': 'Cola Wands',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose-Fructose Syrup, Wheat Flour, Concentrated Apple Juice, Coconut Oil, Malic Acid, Humectant (Sorbitols), Acidity Regulator (Citric Acid), Colour (Plain Caramel), Corn Starch, Flavouring, Emulsifier (Mono- and Diglycerides of Fatty Acids), Plant Concentrates (Black Carrot, Hibiscus). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'AMGQmRczQshAF2aJISEm',
            'name': 'Protein Teriyaki Noodles',
            'brand': 'Inspired Cuisine',
            'serving_size_g': 350.0,
            'ingredients': 'Water, Cooked Egg Noodles (21%) (Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pasteurised Egg, Firming Agents (Potassium Carbonate, Sodium Carbonates), Salt, Paprika, Turmeric, Acidity Regulator (Citric Acid)), Cooked Chicken Breast (19%) (Chicken Breast, Salt), Cabbage, Carrot, Onion, Red Pepper, Spring Onions, Soy Sauce (Water, Salt, Soya Beans, Wheat Flour), Red Chilli Purée, Cornflour, Ginger Purée, Demerara Sugar, Garlic Purée, Honey, Caramelised Sugar Syrup, Tamarind. Contains Cereals Containing Gluten, Eggs, Soybeans, Wheat.'
        },
        {
            'id': 'rRYKa9iyPsLxzJJ5Rovm',
            'name': 'Apple & Pear Chutney',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Apple (22%), Barley Malt Vinegar, Apple Purée (11.5%), Pear Purée (11%), Dried Onions, Treacle, Sultanas, Salt, Ginger Purée, Ground Cinnamon, Ground Mixed Spice, Ground Nutmeg. Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': 'SBZja9jkuhATyIkp1Ufa',
            'name': 'Skittles Green',
            'brand': 'Skittles',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Fat, Acid (Malic Acid), Dextrin, Modified Starch, Maltodextrin, Acid (Citric Acid), Flavourings, Colours (E163, E162, E170, E100, E153, E160a, E133), Sweet Potato Concentrate, Acidity Regulator (Trisodium Citrate), Glazing Agent (Carnauba Wax), Radish Concentrate.'
        },
        {
            'id': 'IpkN3gGZondWAXSEYi8Q',
            'name': 'Clear Honey',
            'brand': 'Grandessa',
            'serving_size_g': 100.0,
            'ingredients': 'Clear Honey, a Blend of Non-EU Honeys.'
        },
        {
            'id': 'hEXPMYcs3Shc8WXq7baq',
            'name': 'Seeded Folded Flatbreads',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Mixed Seeds (6%) (Sunflower Seeds, Brown Linseed, Pumpkin Seeds), Rapeseed Oil, Yeast, Malted Barley Flour, Spirit Vinegar, Oat Flakes, Rye Flour, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate, Calcium Phosphate), Wheat Bran, Sugar, Salt, Preservative (Calcium Propionate), Dextrose, Wheat Starch. Contains Barley, Cereals Containing Gluten, Oats, Rye, Wheat.'
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

    total_cleaned = 536 + updates_made

    print(f"✨ BATCH 42 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 550:
        print(f"\n🎉🎉🎉 550 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Now shifting focus to 193 products with incomplete ingredients!\n")
    else:
        remaining_to_550 = 550 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_550} products until 550!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch42(db_path)
