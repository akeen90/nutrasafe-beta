#!/usr/bin/env python3
"""
Clean ingredients batch 51 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch51(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 51\n")

    clean_data = [
        {
            'id': '2iKVMqE1ID76bGwZUvgb',
            'name': 'Chicken In White Sauce',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (42%), Water, Cows\' Milk, Chicken Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Modified Maize Starch, Salt, Sugar, Skimmed Cows\' Milk, Pepper Extract, Onion Extract, Thyme Extract. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '2iKpfVslk0OVqN0yzRp7',
            'name': 'Thai Red Curry Paste',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Thai Red Curry Paste. May Contain Peanuts, Sesame, Soybeans.'
        },
        {
            'id': '2iP0Nh5Hf2q44hoRtI8o',
            'name': 'Greek Feta',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Feta Cheese (Sheep\'s Milk, Goats\' Milk). Contains Milk.'
        },
        {
            'id': '2kQlAu2HXiQF1Bj97FIU',
            'name': 'Curiously Cinnamon',
            'brand': 'Nestlé',
            'serving_size_g': 30.0,
            'ingredients': 'Whole Grain Wheat (37.3%), Rice Flour (28.1%), Sugar, Sunflower Oil, Glucose Syrup, Calcium Carbonate, Maize Starch, Salt, Cinnamon (0.3%), Emulsifier (Sunflower Lecithin), Antioxidant (Tocopherols), Roasted Barley Malt Extract, Natural Flavouring, Colour (Annatto Norbixin), Iron, Vitamin B3, B5, D, B6, B1, B2, B9. Contains Barley, Cereals Containing Gluten, Wheat. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': '2kusLPqWXU2D4UBfsSfP',
            'name': 'Sun-dried Tomato Pesto',
            'brand': 'Asda Extra Special',
            'serving_size_g': 25.0,
            'ingredients': 'Rehydrated Sun-Dried Tomatoes (29%) (Water, Tomatoes, Salt, Acidity Regulators (Lactic Acid, Citric Acid), Antioxidant (Ascorbic Acid)), Extra Virgin Olive Oil, Tomato Purée, Tomato Pulp, Basil (7%), Pecorino Romano Cheese PDO (Unpasteurised Ewe\'s Milk, using Lamb\'s Rennet) (4%), Parmigiano Reggiano Cheese PDO (Unpasteurised Milk, using Calves\'), Acidity Regulator (Lactic Acid), Antioxidant (Ascorbic Acid). Contains Milk. May Contain Nuts, Peanuts.'
        },
        {
            'id': '2lDvtyMjjVbT48NN0NBh',
            'name': 'Gravy Granules For Meat',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Palm Oil, Salt, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Colour (Ammonia Caramel), Hydrolysed Wheat Protein, Onion Powder, Flavouring (contains Wheat), Emulsifier (Soya Lecithins). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '2lKbU5DdGSi7BHMriOmd',
            'name': 'Rocky Road Pieces',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter (14%), Honeycomb (13%) (Sugar, Glucose Syrup, Raising Agent (Sodium Bicarbonate)), Raisins (12%), Cocoa Mass (8%), Dried Rice Syrup - Gluten-Free Cereal Balls (6%) (Rice Flour, Maize Flour, Sugar, Raising Agent (Sodium Bicarbonate), Salt), Rice Starch, Vegan Marshmallow (3%) (Glucose-Fructose Syrup, Sugar, Dextrose, Gelling Agent (Carrageenan), Cornflour, Hydrolyzed Rice Protein, Flavoring, Color (Calcium Carbonate, Beetroot Red), Stabilizer (E452)), Chicory Fiber, Rice Flour, Emulsifier (Lecithins), Tapioca Starch, Maize Protein, Glucose Syrup, Flavoring. Not Suitable for Those with a Nut and Peanut Allergy.'
        },
        {
            'id': '2m4xPeosRCl7ch466DsA',
            'name': 'St Clements Hot Cross Buns',
            'brand': 'Tesco',
            'serving_size_g': 70.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Moistened Sultanas (16%) (Sultanas, Water), Diced Candied Apple (10%) (Apple, Sugar, Glucose-Fructose Syrup), Water, Spiced Apple Compote (5%) (British Bramley Apple, Water, Sugar, Ginger, Cardamom, Cinnamon, Clove, Pimento, Black Pepper), Yeast, Invert Sugar Syrup, Palm Fat, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Emulsifier (Mono- and Diglycerides of Fatty Acids), Potato Starch, Wheat Gluten, Salt, Rye Flour, Rapeseed Oil, Cinnamon Powder, Flavouring, Cassia, Flour Treatment Agent (Ascorbic Acid), Palm Stearin, Coriander Powder. Contains Barley, Cereals Containing Gluten, Oats, Rye, Wheat. Not Suitable for Customers with an Allergy to Sesame, Egg, Milk, Soya, Spelt due to Manufacturing Methods.'
        },
        {
            'id': '2meBneL5s0IQE55JvPRi',
            'name': 'Peanut Butter Ice Cream',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Peanut Vegan Ice Cream (64%) (Water, Sugar, Coconut Oil, Peanut Paste, Oat Flour, Inulin, Maize Maltodextrin, Pea Protein, Caramelised Sugar Syrup, Stabilisers (Locust Bean Gum, Guar Gum), Flavouring, Emulsifier (Mono-and Diglycerides of Fatty Acids)), Chocolate Coating (28%) (Sugar, Cocoa Butter, Cocoa Mass, Coconut Oil, Emulsifier (Lecithins (Sunflower)), Flavouring), Peanut Sauce (4%) (Glucose Syrup, Water, Sugar, Peanut Paste, Caramelised Sugar, Gelling Agent (Pectins), Salt, Flavouring, Citrus Fibre), Roasted Peanut Pieces (4%). Contains Oats, Peanuts. May Contain Nuts, Sesame.'
        },
        {
            'id': '2moShhJkZlol6lxR5RB5',
            'name': 'Prawns',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Prawn (Pandalus Borealis) (Crustacean) (99%), Salt. Contains Crustaceans. Not Suitable for Customers with an Allergy to Molluscs or Fish due to Manufacturing Methods.'
        },
        {
            'id': '2nclvpm8xK7Xliqye8b7',
            'name': 'Creamed Cabbage & Spring Greens',
            'brand': 'Morrisons',
            'serving_size_g': 119.0,
            'ingredients': 'Savoy Cabbage (51%), Single Cream (Milk) (21%), Spring Greens (13%), Water, Semi-Skimmed Milk (4%), White Onion (2%), Salted Butter (Butter (Milk), Salt), Maize Starch, Salt, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Garlic Purée, Nutmeg, White Pepper. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '2o7RrVBsCcNE3zU5yBIU',
            'name': 'Oxtail Soup',
            'brand': 'Newgate Lydl',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomatoes (17%), Carrots (5%), Beef (4%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Modified Maize Starch, Yeast Extract, Oxtail Beef (1%), Red Wine (0.6%), Flavourings (contains Celery), Onion Powder, Beef Fat, Salt, Sugar, Yeast Extract, Barley Malt Extract, Colour (Paprika Extract), Rapeseed Oil. Contains Barley, Celery, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '2pyGO1EBN7P1CueIHCzy',
            'name': 'Cheese And Onion Oatcakes',
            'brand': 'Nairns',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oats (84%), Sustainable Palm Fruit Oil, Dietary Fibre (Oligofructose), Cheese (3%) (Milk), Dehydrated Onion (3%), Sea Salt, Natural Flavouring, Raising Agent (Sodium Carbonates). Contains Milk, Oats.'
        },
        {
            'id': '2ivazaTbp9Gjofl0xo0Y',
            'name': 'Cold Infuse',
            'brand': 'Twinings',
            'serving_size_g': 100.0,
            'ingredients': 'Rosemary (54%), Natural Mandarin Flavouring (25%), Stevia Leaves (10%), Natural Lemon Flavouring (5%), Vitamin C Granules (4.5%), Natural Rosemary Flavouring (2%).'
        },
        {
            'id': '2q4KqPDCmGAOnjx3B3Sm',
            'name': 'Mini Luxury Hot Cross Buns',
            'brand': 'M&S',
            'serving_size_g': 36.0,
            'ingredients': 'Wheat Flour (contains Gluten) (with Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Moistened Dried Vine Fruits (34%) (Sultanas, Vostizza Currants, Water), Water, Sugar, Pasteurised Egg (2.5%), Mixed Peel (Orange Peel, Lemon Peel) (2%), Unsalted Butter (Milk) (2%), Dried Wheat Gluten, Invert Sugar Syrup, Yeast, Rapeseed Oil, Malted Wheat (contains Gluten), Salt, Emulsifier (E471, E472e, E470a), Ground Sweet Cinnamon (Cassia), Dextrin, Palm Fat, Flavouring, Ground Coriander Seeds, Wheat Starch (contains Gluten). Contains Cereals Containing Gluten, Eggs, Milk, Wheat. Not Suitable for Those with a Sesame Allergy.'
        },
        {
            'id': '2ssHl0LgQFcfJm0uDtmk',
            'name': 'Brussels Pate',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Liver (31%), Pork (20%), Pork Fat (16%), Water, Caramelised Shallots (8%) (Shallots, Sugar, Sunflower Oil), Pork Rind, Salt, Potato Starch, Antioxidants (Sodium Ascorbate, Potassium Lactate), Emulsifier (Citric Acid Esters of Mono- and Diglycerides of Fatty Acids), Dried Onion, Ground Spices, Spice Extracts, Flavouring, Glucose Syrup, Dextrose, Tomatoes, Milk Protein, Bamboo Fibre, Pea Starch, Thickener (Guar Gum), Preservatives (Sodium Nitrite, Potassium Acetate). Contains Milk. May Contain Nuts.'
        },
        {
            'id': '2vWFdu7mzZBWdJwATSDz',
            'name': 'Choco Orange Soft Bar',
            'brand': 'Organix',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oats (48.5%), Raisins (contains Sunflower Oil) (17.9%), Sunflower Oil (11.2%), Apple Juice Concentrate (9.7%), Agave Fibre (Inulin) (7.9%), Dried Banana (4.8%). Contains Cereals Containing Gluten, Oats.'
        },
        {
            'id': '2vYAkALNs7uHnsM3iQG1',
            'name': 'Lemon And Lime Water',
            'brand': 'M&S',
            'serving_size_g': 250.0,
            'ingredients': 'Spring Water, Concentrated Apple Juice, Carbon Dioxide, Acid (Citric Acid, Malic Acid), Flavourings (Lime, Lemon), Flavouring, Acidity Regulator (E331), Preservative (E202), Antioxidant (Ascorbic Acid), Sweetener (Sucralose).'
        },
        {
            'id': '2vdAJUmb2FzP4iJqDvJc',
            'name': 'Cashew & Cranberry Mix',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sweetened Sliced Dried Cranberries (50%) (Cranberries, Sugar, Sunflower Oil), Cashew Nuts (50%). Contains Nuts. May Contain Other Nuts, Peanuts.'
        },
        {
            'id': '2wC29myAywAlZZEEhiu2',
            'name': 'Cheese \'a\' Peel',
            'brand': 'Emporium',
            'serving_size_g': 20.0,
            'ingredients': 'Pasteurised Milk, Acidity Regulator (Citric Acid), Colour (Paprika Extract). Contains Milk.'
        },
        {
            'id': '2wuLAxwfCA7Q17xxuKBK',
            'name': 'Protein Granola',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oat Flakes, Sugar, Soya Protein Isolate, Pumpkin Seeds, Rice Flour, Rapeseed Oil, Oat Bran, Almonds, Walnuts, Soya Flour, Desiccated Coconut, Honey, Sweetened Freeze-Dried Apricot Pieces (0.5%) (Dried Apricots, Sugar), Freeze Dried Cranberries (0.5%), Freeze Dried Raspberries (0.5%), Salt. Contains Nuts, Oats, Soybeans. May Contain Milk, Peanuts, Wheat.'
        },
        {
            'id': '2xWGRFbqMO2m1jsADL1s',
            'name': 'Granola Nutty',
            'brand': 'Mornflake',
            'serving_size_g': 100.0,
            'ingredients': 'Oatflakes (65%), Sugar, Mixed Nuts (15%) (Almonds, Cashew Nuts, Brazil Nuts, Hazelnuts), Rapeseed Oil, Honey (1%), Sunflower Seeds, Natural Flavouring. Contains Nuts, Oats. Not Suitable for Milk, Wheat or Barley Allergy Sufferers due to Manufacturing Methods. May Contain Other Tree Nuts.'
        },
        {
            'id': '2y3NRbOakhdN2qF5oeMz',
            'name': 'Rowntree Fruit Pastilles Lollies 4pk',
            'brand': 'Rowntree\'s',
            'serving_size_g': 67.0,
            'ingredients': 'Water, Fruit Juice from Concentrate (25%) (Pineapple, Orange, Lemon, Raspberry, Blackcurrant), Sugar, Glucose Syrup, Acid (Citric Acid), Stabilisers (Guar Gum, Sodium Alginate, Carrageenan), Flavourings, Colours (Beetroot Red, Annatto, Curcumin, Copper Complexes of Chlorophyllins), Dextrose. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': '2y6i94rdkZ1ZNNwNT5xr',
            'name': 'Lightly Seeded Loaf',
            'brand': 'Village Bakery',
            'serving_size_g': 44.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Mixed Seeds (6%) (Linseed, Sunflower Seeds, Millet, Poppy Seeds, Pumpkin Seeds), Yeast, Salt, Wheat Gluten, Barley Malt Flour, Spirit Vinegar, Preservative (Calcium Propionate), Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid). Contains Barley, Cereals Containing Gluten, Wheat. May Contain Soybeans.'
        },
        {
            'id': '2yHbCg2wqPQ34OuEOnBP',
            'name': '4 Wholemeal Sourdough Rolls',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal Wheat Flour (55%), Water, Wheat Bran (4%), Wheat Gluten, Rapeseed Oil, Wheat Fibre, Fermented Wheat Flour, Wheat Flour, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Salt, Yeast, Malted Barley Flour, Fermented Rye Flour, Palm Oil, Palm Fat, Flour Treatment Agent (Ascorbic Acid), Acidity Regulator (Acetic Acid), Wheat Flakes. Contains Barley, Cereals Containing Gluten, Rye, Wheat. May Contain Eggs, Milk, Oats, Spelt.'
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

    total_cleaned = 661 + updates_made

    print(f"✨ BATCH 51 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")
    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch51(db_path)
