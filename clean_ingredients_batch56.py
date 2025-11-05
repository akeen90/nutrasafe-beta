#!/usr/bin/env python3
"""
Batch 56: Clean ingredients for 25 products
Progress: 786 -> 811 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch56(db_path: str):
    """Update batch 56 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '2iKpfVslk0OVqN0yzRp7',
            'name': 'Thai Red Curry Paste',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Lemongrass, Garlic, Red Chilli, Shallot, Salt, Galangal, Coriander Seeds, Cumin, Kaffir Lime Peel, Shrimp Paste (Shrimp, Salt).'
        },
        {
            'id': '2kQlAu2HXiQF1Bj97FIU',
            'name': 'Curiously Cinnamon',
            'brand': 'Nestlé',
            'serving_size_g': 30.0,
            'ingredients': 'Whole Grain Wheat (37.3%), Rice Flour (28.1%), Sugar, Sunflower Oil, Glucose Syrup, Calcium Carbonate, Maize Starch, Salt, Cinnamon (0.3%), Emulsifier (Sunflower Lecithin), Antioxidant (Tocopherols), Roasted Barley Malt Extract, Natural Flavouring, Colour (Annatto Norbixin), Iron, Vitamin B3, B5, D, B6, B1, B2, B9.'
        },
        {
            'id': '2kjCm3sq8BkR9yD5jaMO',
            'name': '75% Less Fat Ham',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (90%), Water, Salt, Brown Sugar, Preservatives (Potassium Nitrate, Sodium Nitrite), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': '2kusLPqWXU2D4UBfsSfP',
            'name': 'Sun-dried Tomato Pesto',
            'brand': 'Asda Extra Special',
            'serving_size_g': 25.0,
            'ingredients': 'Rehydrated Sun-Dried Tomatoes (29%) (Water, Tomatoes, Salt, Acidity Regulators (Lactic Acid, Citric Acid), Antioxidant (Ascorbic Acid)), Extra Virgin Olive Oil, Tomato Purée, Tomato Pulp, Basil (7%), Pecorino Romano Cheese PDO (Unpasteurised Ewe\'s Milk, using Lamb\'s Rennet) (4%), Parmigiano Reggiano Cheese PDO (Unpasteurised Milk, using Calves\' Rennet), Acidity Regulator (Lactic Acid), Antioxidant (Ascorbic Acid).'
        },
        {
            'id': '2lKbU5DdGSi7BHMriOmd',
            'name': 'Rocky Road Pieces',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter (14%), Honeycomb (13%) (Sugar, Glucose Syrup, Raising Agent (Sodium Bicarbonate)), Raisins (12%), Cocoa Mass (8%), Dried Rice Syrup - Gluten-Free Cereal Balls (6%) (Rice Flour, Maize Flour, Sugar, Raising Agent (Sodium Bicarbonate), Salt), Rice Starch, Vegan Marshmallow (3%) (Glucose-Fructose Syrup, Sugar, Dextrose, Gelling Agent (Carrageenan), Cornflour, Hydrolyzed Rice Protein, Flavoring, Color (Calcium Carbonate, Beetroot Red), Stabilizer (E452)), Chicory Fiber, Rice Flour, Emulsifier (Lecithins), Tapioca Starch, Maize Protein, Glucose Syrup, Flavoring.'
        },
        {
            'id': '2lugTNvPZ7AO4bj4UBPf',
            'name': 'Nik Naks Rib N Saucy Flavour',
            'brand': 'KP Snacks',
            'serving_size_g': 30.0,
            'ingredients': 'Maize, Sunflower Oil (36%), Rib \'N\' Saucy Flavour (Sugar, Yeast Extract, Salt, Spices, Natural Flavourings, Dried Onion, Dried Garlic, Acid (Citric Acid), Colour (Paprika Extract)).'
        },
        {
            'id': '2lz1bNo5X08IPICitbZS',
            'name': 'Organic 70% Dark Chocolate Bar',
            'brand': 'Green & Black\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Cane Sugar, Cocoa Butter, Vanilla Extract.'
        },
        {
            'id': '2m4xPeosRCl7ch466DsA',
            'name': 'St Clements Hot Cross Buns',
            'brand': 'Tesco',
            'serving_size_g': 70.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Moistened Sultanas (16%) (Sultanas, Water), Diced Candied Apple (10%) (Apple, Sugar, Glucose-Fructose Syrup), Water, Spiced Apple Compote (5%) (British Bramley Apple, Water, Sugar, Ginger, Cardamom, Cinnamon, Clove, Pimento, Black Pepper), Yeast, Invert Sugar Syrup, Palm Fat, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Emulsifier (Mono- and Diglycerides of Fatty Acids), Potato Starch, Wheat Gluten, Salt, Rye Flour, Rapeseed Oil, Cinnamon Powder, Flavouring, Cassia, Flour Treatment Agent (Ascorbic Acid), Palm Stearin, Coriander Powder.'
        },
        {
            'id': '2mRM9SZmTSUK5gj9azt6',
            'name': 'Zingy Dark Choc Ginger Oaties',
            'brand': 'Gullon',
            'serving_size_g': 100.0,
            'ingredients': 'Oats Flakes 26%, Wheat Flour, Dark Chocolate with Sweetener 18% (Cocoa Mass, Sweetener (Maltitol), Cocoa Butter, Anhydrous Milk Fat, Emulsifier (Sunflower Lecithin)), Sweetener (Maltitol), Vegetable Oil 13% (High Oleic Sunflower Oil), Vegetable Fibre, Ginger Powder 2%, Raising Agents (Potassium Hydrogen Carbonate, Ammonium Hydrogen Carbonate), Flavour Enhancer (Potassium Chloride), Emulsifier (Soya Lecithin), Salt, Natural Flavour, Antioxidant (Tocopherol-Rich Extract), Flavours.'
        },
        {
            'id': '2meBneL5s0IQE55JvPRi',
            'name': 'Peanut Butter Ice Cream',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Peanut Vegan Ice Cream (64%) (Water, Sugar, Coconut Oil, Peanut Paste, Oat Flour, Inulin, Maize Maltodextrin, Pea Protein, Caramelised Sugar Syrup, Stabilisers (Locust Bean Gum, Guar Gum), Flavouring, Emulsifier (Mono-and Diglycerides of Fatty Acids)), Chocolate Coating (28%) (Sugar, Cocoa Butter, Cocoa Mass, Coconut Oil, Emulsifier (Lecithins (Sunflower)), Flavouring), Peanut Sauce (4%) (Glucose Syrup, Water, Sugar, Peanut Paste, Caramelised Sugar, Gelling Agent (Pectins), Salt, Flavouring, Citrus Fibre), Roasted Peanut Pieces (4%).'
        },
        {
            'id': '2moShhJkZlol6lxR5RB5',
            'name': 'Prawns',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Prawn (Pandalus Borealis) (Crustacean) (99%), Salt.'
        },
        {
            'id': '2n7UlIlNqtENjrVx7Ayf',
            'name': 'Edamame Salad',
            'brand': 'Delphi',
            'serving_size_g': 100.0,
            'ingredients': 'Edamame Beans (Soya) 68%, Vegetable Mix 14% (Sliced Black Olives (Water, Salt, Acidity Regulator (Lactic Acid), Colour Stabilizer (Ferrous Gluconate)), Semi Dried Tomato Bits 5%, Red Onion), Lemon Concentrate, Water, Vegetable Oil (Sunflower), Citric Acid, Salt, Preservative (Potassium Sorbate), Black Pepper, Garlic Puree, Cheese (Milk) (Semi-Skimmed Cows Milk, Salt, Culture, Microbial Rennet).'
        },
        {
            'id': '2iv1wK84s8vPTLBGszMZ',
            'name': 'Almond & Coconut Milk',
            'brand': 'Generic',
            'serving_size_g': 250.0,
            'ingredients': 'Filtered Water, Organic Coconut Cream (5%), Organic Brown Rice, Activated Organic Almonds (4%), Sea Salt.'
        },
        {
            'id': '2q4KqPDCmGAOnjx3B3Sm',
            'name': 'Mini Luxury Hot Cross Buns',
            'brand': 'M&S',
            'serving_size_g': 36.0,
            'ingredients': 'Wheat Flour (contains Gluten) (with Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Moistened Dried Vine Fruits (34%) (Sultanas, Vostizza Currants, Water), Water, Sugar, Pasteurised Egg (2.5%), Mixed Peel (Orange Peel, Lemon Peel) (2%), Unsalted Butter (Milk) (2%), Dried Wheat Gluten, Invert Sugar Syrup, Yeast, Rapeseed Oil, Malted Wheat (contains Gluten), Salt, Emulsifiers (E471, E472e, E470a), Ground Sweet Cinnamon (Cassia), Dextrin, Palm Fat, Flavouring, Ground Coriander Seeds, Wheat Starch (contains Gluten).'
        },
        {
            'id': '2rN1AAeS7CybvsekuKUI',
            'name': '2 Kiln Roasted Salmon Fillets',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Hot Smoked Salmon (90%) (Farmed Salmon, Salt, Smoke), Sweet Chilli Sauce (10%) (Water, Sugar, Red Chilli, White Wine Vinegar, Garlic, Salt, Modified Maize Starch, Ginger, Acidity Regulator (Citric Acid), Stabiliser (Xanthan Gum)).'
        },
        {
            'id': '2rPl07Osq89iLsNueHLY',
            'name': 'Goikoa Chorizo De Navarra',
            'brand': 'Goikoa',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Paprika (2%), Smoked Paprika (1%), Garlic, Preservatives (Sodium Nitrate, Potassium Nitrate), Antioxidants (Rosemary Extract).'
        },
        {
            'id': '2ssHl0LgQFcfJm0uDtmk',
            'name': 'Brussels Pate',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Liver (31%), Pork (20%), Pork Fat (16%), Water, Caramelised Shallots (8%) (Shallots, Sugar, Sunflower Oil), Pork Rind, Salt, Potato Starch, Antioxidants (Sodium Ascorbate, Potassium Lactate), Emulsifier (Citric Acid Esters of Mono- and Diglycerides of Fatty Acids), Dried Onion, Ground Spices, Spice Extracts, Flavouring, Glucose Syrup, Dextrose, Tomatoes, Milk Protein, Bamboo Fibre, Pea Starch, Thickener (Guar Gum), Preservatives (Sodium Nitrite, Potassium Acetate).'
        },
        {
            'id': '2sshs6rwYadkR0WQrm8Z',
            'name': 'Wagyu - Marinated Air Dried Strips',
            'brand': 'Kings',
            'serving_size_g': 45.0,
            'ingredients': 'Beef (156g per 100g of Finished Product), Sugar, Cider Vinegar, Salt, Onion Extract, Paprika, Dried Red Bell Pepper, Dried Onion, Yeast Extract, Thyme, Flavouring, Potato Fibre, Preservative (Potassium Sorbate), Dried Chilli, Smoke Flavouring, Vegetable Oil.'
        },
        {
            'id': '2vdAJUmb2FzP4iJqDvJc',
            'name': 'Cashew & Cranberry Mix',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sweetened Sliced Dried Cranberries (50%) (Cranberries, Sugar, Sunflower Oil), Cashew Nuts (50%).'
        },
        {
            'id': '2wuLAxwfCA7Q17xxuKBK',
            'name': 'Protein Granola',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oat Flakes, Sugar, Soya Protein Isolate, Pumpkin Seeds, Rice Flour, Rapeseed Oil, Oat Bran, Almonds, Walnuts, Soya Flour, Desiccated Coconut, Honey, Sweetened Freeze-Dried Apricot Pieces (0.5%) (Dried Apricots, Sugar), Freeze Dried Cranberries (0.5%), Freeze Dried Raspberries (0.5%), Salt.'
        },
        {
            'id': '2xWGRFbqMO2m1jsADL1s',
            'name': 'Granola Nutty',
            'brand': 'Mornflake',
            'serving_size_g': 100.0,
            'ingredients': 'Oatflakes (65%), Sugar, Mixed Nuts (15%) (Almonds, Cashew Nuts, Brazil Nuts, Hazelnuts), Rapeseed Oil, Honey (1%), Sunflower Seeds, Natural Flavouring.'
        },
        {
            'id': '2y3NRbOakhdN2qF5oeMz',
            'name': 'Rowntree Fruit Pastilles Lollies 4pk',
            'brand': 'Rowntree\'s',
            'serving_size_g': 67.0,
            'ingredients': 'Water, Fruit Juice from Concentrate (25%) (Pineapple, Orange, Lemon, Raspberry, Blackcurrant), Sugar, Glucose Syrup, Acid (Citric Acid), Stabilisers (Guar Gum, Sodium Alginate, Carrageenan), Flavourings, Colours (Beetroot Red, Annatto, Curcumin, Copper Complexes of Chlorophyllins), Dextrose.'
        },
        {
            'id': '2y6i94rdkZ1ZNNwNT5xr',
            'name': 'Lightly Seeded Loaf',
            'brand': 'Village Bakery',
            'serving_size_g': 44.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Mixed Seeds (6%) (Linseed, Sunflower Seeds, Millet, Poppy Seeds, Pumpkin Seeds), Yeast, Salt, Wheat Gluten, Barley Malt Flour, Spirit Vinegar, Preservative (Calcium Propionate), Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '2yHbCg2wqPQ34OuEOnBP',
            'name': '4 Wholemeal Sourdough Rolls',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wholemeal Wheat Flour (55%), Water, Wheat Bran (4%), Wheat Gluten, Rapeseed Oil, Wheat Fibre, Fermented Wheat Flour, Wheat Flour, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Salt, Yeast, Malted Barley Flour, Fermented Rye Flour, Palm Oil, Palm Fat, Flour Treatment Agent (Ascorbic Acid), Acidity Regulator (Acetic Acid), Wheat Flakes.'
        },
        {
            'id': '2yISTlWjtu3xmUZgaVpe',
            'name': 'Classic Choc Coins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Butter, Sugar, Rice Flour, Cocoa Mass, Inulin, Cocoa Powder, Emulsifier (Soya Lecithins), Vanilla Extract, Salt.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 56\n")

    cleaned_count = update_batch56(db_path)

    # Calculate total progress
    previous_total = 786  # From batch 55
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 56 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 800 and previous_total < 800:
        print(f"\n🎉🎉🎉 800 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 12.4% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
