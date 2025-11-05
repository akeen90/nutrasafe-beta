#!/usr/bin/env python3
"""
Clean ingredients batch 38 - Breaking 450 Milestone!
"""

import sqlite3
from datetime import datetime

def update_batch38(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 38 (Breaking 450!)\n")

    clean_data = [
        {
            'id': '8AymjAs9EbnEMVeg52kO',
            'name': 'Lemon & Black Pepper Mayonnaise',
            'brand': 'Bramwells',
            'serving_size_g': 15.0,
            'ingredients': 'Rapeseed Oil, Water, Pasteurised Free Range Egg Yolk (6%), Spirit Vinegar, Sugar, Salt, Cracked Black Pepper, Concentrated Lemon Juice, Flavourings, Modified Maize Starch, Stabiliser (Guar Gum). Contains Eggs.'
        },
        {
            'id': 'ZXFgxIDhJfjYE5lMi3Ct',
            'name': 'Wholenut Crunchy Peanut Butter',
            'brand': 'Grandessa',
            'serving_size_g': 100.0,
            'ingredients': 'Roasted Peanuts (97%), Palm Oil, Salt. Contains Peanuts. May Contain Almonds, Cashews, Hazelnuts, Pecan Nuts, Walnuts.'
        },
        {
            'id': 'ZtMuJqbDGCHwrWvvIBrY',
            'name': 'Mars Celebrations Carton 185g',
            'brand': 'Celebrations',
            'serving_size_g': 27.3,
            'ingredients': 'Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Milk Fat, Peanuts, Palm Fat, Desiccated Coconut, Wheat Flour, Lactose, Whey Permeate (from Milk), Sunflower Oil, Full Cream Milk Powder, Emulsifiers (Soya Lecithin, E471), Barley Malt Extract, Salt, Fat Reduced Cocoa, Humectant (Glycerol), Egg White Powder, Raising Agents (E341, E500, E501), Vanilla Extract, Starch, Wheat Gluten, Whey Powder (from Milk). Contains Barley, Cereals Containing Gluten, Eggs, Milk, Peanuts, Soybeans, Wheat.'
        },
        {
            'id': 'zw7udIvw4YNeOwIbDWtA',
            'name': 'Tomato & Mascarpone Stir Through Sauce',
            'brand': 'Aldi',
            'serving_size_g': 95.0,
            'ingredients': 'Water, Mascarpone Cheese (Milk) (21%), Tomato Pulp (19%), Tomato Purée (18%), Sunflower Oil, Sugar, Modified Maize Starch, Onion, Flavourings, Salt, Garlic Purée, Modified Potato Starch, Basil, Acidity Regulator (Citric Acid). Contains Milk.'
        },
        {
            'id': 'okyFfyWlZ0WD4hEVKj76',
            'name': 'Scotch White Rolls',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Water, Yeast, Wheat Semolina, Fermented Wheat Flour, Salt, Wheat Protein, Vegetable Oils and Fat (Rapeseed Oil, Palm Fat, Palm Oil), Sugar, Dried Wheat Sourdough, Emulsifiers (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Mono- and Diglycerides of Fatty Acids), Spirit Vinegar, Soya Flour, Flour Treatment Agents (Ascorbic Acid, L-Cysteine). Contains Cereals Containing Gluten, Soybeans, Wheat. May Contain Barley, Eggs, Milk, Oats, Spelt, Rye.'
        },
        {
            'id': 'pcQdjf8f3znhdlnJAEwg',
            'name': 'Tracker® Chocolate Chip',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Oat Flakes, Peanuts (10%), Sweetened Condensed Milk, Wholemeal Wheat Flour, Chocolate Chips (5%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin), Flavouring), Palm Oil, Sugar, Vegetable Oils (Palm Kernel Oil, Palm Stearin), Rice Flour, Humectant (Glycerol), Salt, Emulsifier (Soya Lecithin), Malted Barley Flour, Malted Whole Wheat Flour, Barley Malt Extract, Stabiliser (Calcium Carbonate). Contains Barley, Cereals Containing Gluten, Milk, Oats, Peanuts, Soybeans, Wheat.'
        },
        {
            'id': 'DigxgrZMOnf5pLK3iKsM',
            'name': '100% Pressed Apple And Mango Juice',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': '100% Pressed Apple and Mango Juice.'
        },
        {
            'id': 'YTdNe10Y6n9tt6M23ZUJ',
            'name': 'Curry Ketchup',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g Curry Ketchup), Spirit Vinegar, Sugar, Salt, Spices, Natural Flavour. Contains Celery.'
        },
        {
            'id': '2HpxGIjXGevXEK8KIXGH',
            'name': 'Quick Cook Fusilli',
            'brand': 'Tesco',
            'serving_size_g': 170.0,
            'ingredients': 'Durum Wheat Semolina. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'fTBe1RQF2oecnfNXtFE4',
            'name': 'Samosas',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (26%), Peas (22%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin) (22%), Carrot (15%), Rapeseed Oil, Onion (11%), Rice Flour, Lemon Juice from Concentrate, Ginger Purée, Salt, Coriander, Maize Flour, Sugar, Dried Cumin, Poppy Seeds (0.2%), Ground Coriander, Green Chillies, Asafoetida Powder, Yeast Extract, Dried Cinnamon, Ground Turmeric, Ground Fenugreek, Ajwain Powder, Dried Mint, Ground Bay Leaf, Chilli Powder, Ground Green Cardamom. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'ZVrQrY7dGLgxFdzy61pT',
            'name': 'Khao Soi Coconut Curry Kit',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Coconut Milk (76%) (Coconut Milk, Water), Khao Soi Curry Sauce (23%) (Water, Lemongrass, Red Chilli, Rice Bran Oil, Shallots, Sugar, Salt, Garlic, Soybeans, Galangal, Emulsifier (Modified Corn Starch), Coriander, Ground Coriander Seeds, Turmeric Powder, Makrut Lime Leaf, Black Pepper, Cumin Powder, Chilli Powder, Ground Star Anise, Clove Powder, Nutmeg Powder), Thai Dried Herbs and Spices (1%) (Dried Chilli, Dried Makrut Lime Leaf). Contains Soybeans.'
        },
        {
            'id': 'Qn9RXQhX9qkKGdjaI779',
            'name': 'Baby Potato & Free-range Egg Salad',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Iceberg Lettuce (29%), Baby Potatoes (22%), Cherry Tomatoes, Sliced Free Range Hard Boiled Egg (15%), Cucumber (10%), Salad Cream (9%) (Water, Rapeseed Oil, Sugar, Spirit Vinegar, Free Range Egg Yolk Powder, Cornflour, Mustard Powder, Salt, Stabiliser (Xanthan Gum), Colour (Carotenes)). Contains Eggs, Mustard.'
        },
        {
            'id': 'ilFZzzK5ZaRiIWfKDqTT',
            'name': 'Tesco Coleslaw Crunchy & Tangy',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Cabbage (47%), Carrot (16%), Rapeseed Oil, Water, Pasteurised Egg Yolk, Spirit Vinegar, Sugar, Onion, Salt, White Wine Vinegar, Citrus Fibre, Stabilisers (Guar Gum, Xanthan Gum), Concentrated Lemon Juice, Thickener (Pectin). Contains Eggs.'
        },
        {
            'id': 'fbb12rl5BKJGmFiiZQcH',
            'name': 'New York Deli Style Pickle Relish',
            'brand': 'Lidl',
            'serving_size_g': 15.0,
            'ingredients': 'Water, Gherkins (24%), Sugar, Onion (5%), Modified Maize Starch, Spirit Vinegar, Acidity Regulator (Acetic Acid), Salt, Red Pepper, Mustard Seeds, Ground Turmeric, Ground Cloves, Roasted Barley Malt Extract. Contains Barley, Cereals Containing Gluten, Mustard.'
        },
        {
            'id': 'zdcDRZcVH48VRRQHTpfo',
            'name': 'Moroccan Style Meatball Sauce',
            'brand': 'Al Fez',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomato (28%), Onion, Sugar, Concentrated Tomato Purée (5%), Rapeseed Oil, Spices (2.5%), Garlic Purée, Modified Maize Starch, Garlic Powder, Salt, Dried Coriander Leaf, Acid (Citric Acid). May Contain Peanuts, Nuts.'
        },
        {
            'id': 'aQ2DP8WlrFaTX1OzFkX3',
            'name': 'Luksusowa',
            'brand': 'E Wedel',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato Ketchup, Sugar, Vinegar, Salt, Flavouring.'
        },
        {
            'id': '8CaziCBgNXdzTM9tMA72',
            'name': 'Purple Powder',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Beetroot, Garcinia Cambogia, Bilberry, Flax Seed, Rosehip, Green Tea Extract, Apple Cider Vinegar Powder, Pomegranate, Cranberry Extract, Goji Berry, Green Coffee Bean Extract (50% CGA-Chlorogenic Acid), Acai Berry, Raspberry, Montmorency Cherry, Blueberry, Lingonberry Extract.'
        },
        {
            'id': 'y3iO2KWYF8J7zwF9s1QW',
            'name': 'Wholegrain Porridge',
            'brand': 'Costa',
            'serving_size_g': 80.0,
            'ingredients': 'Wholegrain Oatflakes (67%), Dried Skimmed Milk, Sugar. Contains Cereals Containing Gluten, Milk, Oats. May Contain Nuts, Wheat, Barley.'
        },
        {
            'id': 'UXBCfOJG9hAYTFMS1Zok',
            'name': 'Greek Style Yogurt With Coconut',
            'brand': 'Tesco',
            'serving_size_g': 113.0,
            'ingredients': 'Greek Style Yogurt (Milk), Water, Sugar, Coconut Milk (2%), Desiccated Coconut, Cornflour, Flavourings, Acidity Regulator (Lactic Acid). Contains Milk.'
        },
        {
            'id': 'lqJFZTlovBsRZRwaM8nR',
            'name': 'Wensley Dale With Cranberries',
            'brand': 'Valley Spire',
            'serving_size_g': 100.0,
            'ingredients': 'Wensleydale Cheese (Milk) (83%), Sweetened Dried Cranberries (13%) (Cranberries, Sugar, Sunflower Oil), Sugar, Salt. Contains Milk.'
        },
        {
            'id': 'iIxutIUfwv9EMvkLbMXP',
            'name': 'Morrisons Savers Orange Squash 750ml',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Comminuted Orange from Concentrate (10%), Acid (Citric Acid), Flavourings, Preservatives (Potassium Sorbate, Sodium Metabisulphite), Sweeteners (Sucralose, Acesulfame K), Acidity Regulator (Sodium Citrate), Stabiliser (Carboxy Methyl Cellulose), Colour (Carotenes). Contains Sulphites.'
        },
        {
            'id': 'rTpi6VIgEFeDqLztiIEm',
            'name': 'Chicken Poppers',
            'brand': 'Co-op',
            'serving_size_g': 70.0,
            'ingredients': 'Chicken (67%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Onion, Salt, Cayenne Pepper, Chilli Pepper, Cayenne Extract, Yeast, Garlic Purée, Raising Agents (Diphosphates, Sodium Hydrogen Carbonate), White Pepper, Colour (Paprika Extract), Cumin, Oregano, Garlic. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'ezJNhOJRa0jLnrCud9zE',
            'name': 'Katsu Chicken Bites',
            'brand': 'Fridge Raiders',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (91%), Vegetable Oils (Soya Bean, Sunflower, Rapeseed), Seasoning (Mixed Herbs and Spices, Sugar, Brown Sugar, Vegetable Powders (Garlic Powder, Onion Powder, Tomato Powder), Flavourings, Honey Powder, Stabiliser (Sodium Triphosphate), Salt, Yeast Extract, Soy Sauce Powder (Soya Bean, Wheat Flour, Salt, Maltodextrin), Turmeric Extract, Tapioca Starch, Curry Flavour, Bay Leaves), Rusk (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Raising Agent (Ammonium Bicarbonate)). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'Z2ptxQsGxtchiL3ZYw7N',
            'name': 'Ham And Mushroom Tagliatelle',
            'brand': 'Morrisons',
            'serving_size_g': 400.0,
            'ingredients': 'Cooked Tagliatelle Pasta (44%) (Water, Durum Wheat Semolina), Semi Skimmed Milk, Water, Roast Mushrooms (7%) (Mushroom, Rapeseed Oil, Garlic Purée), Beechwood Smoked Ham (5%) (Pork (91%), Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate)). Contains Cereals Containing Gluten, Milk, Pork, Wheat.'
        },
        {
            'id': 'MCDdPqmva4iUAxHNUdq2',
            'name': '4 Golden Savoury Rice Steam Bags',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Yellow Rice (56%) (Water, Rice, Ground Turmeric), Peas (15%), Sweetcorn (15%), Red Pepper (10%), Rapeseed Oil, Maltodextrin, Salt, Yeast Extract Powder, Onion Powder, Sugar, Garlic Powder, White Pepper, Ground Nutmeg, Tomato Powder, Celery Seed Powder. Contains Celery.'
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

    total_cleaned = 431 + updates_made

    print(f"✨ BATCH 38 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 450:
        print(f"\n🎉🎉🎉 450 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {500 - total_cleaned} products until 500!\n")
    else:
        remaining_to_450 = 450 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_450} products until 450!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch38(db_path)
