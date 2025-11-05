#!/usr/bin/env python3
"""
Clean ingredients batch 50 - Milestone batch! 🎉
Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch50(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 50 (MILESTONE!)\\n")

    clean_data = [
        {
            'id': '23vuSIDcMFhp0hKu4Mfr',
            'name': 'Iced Latte Black Edition Ready To Drink',
            'brand': 'Huel',
            'serving_size_g': 500.0,
            'ingredients': 'Water, Pea Protein, Faba Bean Protein, Tapioca Starch, Cold-Pressed Rapeseed Oil, Coconut Milk Powder, Ground Flaxseed, Coconut Sugar, Micronutrient Blend (Minerals (Potassium, Chloride, Calcium, Magnesium, Phosphorus, Copper, Zinc, Iodine, Chromium), Vitamins (C, K, E, A, Niacin, D, B12, Pantothenic Acid, Biotin, B6, B2, B1, Folate), Choline), Natural Flavourings, Soluble Vegetable Fibre (Chicory, Corn), Flaxseed Oil Powder, Instant Coffee Powder (0.46%), Medium-Chain Triglyceride Powder (from Coconut), Cocoa Powder, Green Tea Extract, Sweetener (Steviol Glycosides from Stevia), Thickener (Gellan Gum). May Contain Mustard.'
        },
        {
            'id': '23waGPhl75XDRfHCmxqn',
            'name': 'Wensleydale With Cranberries',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Wensleydale Cheese (Milk), Sweetened Dried Cranberries (13%) (Sugar, Cranberry, Sunflower Oil, Fructose, Preservative (Potassium Sorbate)). Contains Milk.'
        },
        {
            'id': '2415BGIkwdoTcf1P0Tu3',
            'name': 'Fusions Tuna',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack Tuna (Katsuwonus Pelamis) (Fish) (83%), Extra Virgin Olive Oil, Green Jalapeño (4%), Rice Vinegar, Salt, Sugar, Chilli Flakes, Water (5.5%), Onion Powder, Lemon Powder, Lime Juice Powder, Flavouring, Dried Green Jalapeño, Colour (Paprika Extract). Contains Fish.'
        },
        {
            'id': '246AXQIzsZUiwSD7whQy',
            'name': 'Melt In The Middle Belgian Chocolate Pudding',
            'brand': 'Asda Bistro',
            'serving_size_g': 100.0,
            'ingredients': 'Chocolate Sauce (19%) (Water, Belgian Milk Chocolate (24%) (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Emulsifier (Soya Lecithins), Vanilla Extract), Sugar, Belgian Dark Chocolate (8%) (Cocoa Mass, Sugar, Emulsifier (Soya Lecithins), Vanilla Extract), Partially Inverted Refiners Syrup, Tapioca Starch, Fat-Reduced Cocoa Powder (2%), Sea Salt, Cornflour, Emulsifier (Mono- and Diglycerides of Fatty Acids), Stabilisers (Xanthan Gum, Guar Gum), Madagascan Vanilla Extract), Salted Butter (Butter (Milk), Salt), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Water, Muscovado Sugar, Whipping Cream (Milk) (8%), Pasteurised Whole Egg, Fat-Reduced Cocoa Powder (4%), Sugar, Unsalted Butter (Milk), Emulsifier (Mono- and Diglycerides of Fatty Acids), Thickener (Xanthan Gum). Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat. May Contain Nuts.'
        },
        {
            'id': '24v2dod4gTyG4G5xq04E',
            'name': '4 Vegetable Samosas',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetables (58%) (Potato, Onion, Carrot, Peas), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Ginger Purée, Tomato Paste, Salt, Lemon Juice, Green Chilli Purée, Chopped Coriander, Ground Coriander, Cumin, Sugar, Cumin Seeds, Poppy Seeds, Kalonji Seeds, Turmeric, Dried Fenugreek Leaf, Chilli Powder, Cinnamon, Ground Ginger, White Pepper, Paprika, Clove, Nutmeg, Cardamom, Ground Bay Leaf. Contains Cereals Containing Gluten, Wheat. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': '27atyGxyl0VH0j2tp5ex',
            'name': 'Cadbury Chocolate Sandwich 260g',
            'brand': 'Cadbury',
            'serving_size_g': 20.0,
            'ingredients': 'Wheat Flour, Sugar, Palm Oil, Fat Reduced Cocoa Powder (3%), Whey Powder (from Milk), Glucose, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Whole Milk Powder, Raising Agents (Ammonium Hydrogen Carbonate, Sodium Hydrogen Carbonate), Milk Dextrose, Flavourings (contain Milk), Emulsifiers (Soya Lecithin). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Eggs.'
        },
        {
            'id': '291iWTn2Z4D1cNLOOINX',
            'name': 'Beldi Preserved Lemons',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Preserved Lemons (55%) (Lemons, Salt, Acidity Regulator (Citric Acid), Preservative (E224 Sulphites)), Water, Sea Salt, Acidity Regulator (Citric Acid). Contains Sulphites. Not Suitable for Those with a Nut, Peanut and Sesame Allergy. Not Suitable for Those with a Milk or Egg Allergy because these Allergens are Present in the Environment.'
        },
        {
            'id': '29OBKLcaXjnrQyVf84yu',
            'name': 'New Tesco Greek Style Chicken Crunchy RED Onion Ys',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Chicken Breast (30%) (Chicken Breast, Salt, Water), Greek Style Yogurt (Milk) (8%), Rapeseed Oil, Tomato (6%), Cucumber (4%), Red Onion, Cornflour, Sunblush Slow Roast Tomato with Herbs (Sunblush Tomato, Rapeseed Oil, Salt, Garlic, Oregano), Pasteurised Egg Yolk, Spirit Vinegar, Sugar, Lemon Juice from Concentrate, Garlic, Spearmint, Salt, Black Pepper, Dill. Contains Eggs, Milk.'
        },
        {
            'id': '2A5oOHsbvoZFf1prWyZK',
            'name': 'Cooked Lean Ham',
            'brand': 'Deli Co Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (80%), Water, Pork Rind, Salt, Acidity Regulators (Potassium Lactate, Sodium Acetate), Sugar, Stabilisers (Triphosphates, Diphosphates, Polyphosphates), Dextrose, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite), Flavourings, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Thiamin, Niacin), Pork Gelatine, Yeast, Glucose Syrup, Potato Fibre, Rice Flour, Maize Flour, Maize Starch, Rapeseed Oil, Turmeric, Honey. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '2AnLTUaqAiDUfgoWeHGa',
            'name': 'Cream Crackers',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oat Flour, Maize Flour, Rice Flour, Palm Oil, Gluten Free Oat Flakes, Tapioca Starch, Cornflour, Brown Rice Syrup, Sea Salt, Raising Agent (Ammonium Hydrogen Carbonate). Contains Oats.'
        },
        {
            'id': '2BAi1jNNY2InqucX11i4',
            'name': 'Mint Mini Reindeers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Palm Fat, Cocoa Mass, Barley Malt Extract, Whey Permeate (from Milk), Milk Fat, Full Cream Milk Powder, Glucose Syrup, Demineralised Whey Powder (from Milk), Shea Fat, Lactose, Emulsifier (Soya Lecithin), Wheat Flour, Raising Agents (E341, E500, E501), Salt, Wheat Gluten, Sweet Whey Powder (from Milk), Natural Peppermint Flavouring. Milk Chocolate Contains Milk Solids 14% Minimum. Milk Chocolate Contains Vegetable Fats in Addition to Cocoa Butter. Contains Barley, Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Eggs.'
        },
        {
            'id': '2Cnz7ihfE1Evs1P90Qxv',
            'name': 'Kling Rawberrie AM Tarts Mr Kipling Exceedingly GO',
            'brand': 'Mr Kipling',
            'serving_size_g': 43.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Caramel Sauce (Glucose Syrup, Sweetened Condensed Milk (Milk, Sugar), Water, Humectant (Vegetable Glycerine), Unsalted Butter (Milk), Sugar, Dextrose, Fructose, Gelling Agent (Pectin), Salt, Acidity Regulator (Sodium Citrates), Flavouring), Water, Icing Sugar, Gold and Bronze Sugar Pieces (Sugar, Water, Gelling Agent (Gum Arabic), Glucose Syrup, Colour (Iron Oxides and Hydroxides), Humectant (Vegetable Glycerine)), Skimmed Milk Powder, Whey Powder (Milk), Dried Egg White, Colour (Plain Caramel), Dextrose, Emulsifiers (Sorbitan Monostearate, Polysorbate 60, Mono- and Diglycerides of Fatty Acids), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Salt, Preservatives (Potassium Sorbate, Sulphur Dioxide), Flavouring. Contains Cereals Containing Gluten, Eggs, Milk, Sulphites, Wheat.'
        },
        {
            'id': '2D26MOgNwPjzMFdMw06A',
            'name': 'Gruyère',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Swiss Reserve Gruyère AOP Full Fat Hard Cheese Made with Unpasteurised Milk. Contains Milk.'
        },
        {
            'id': '2F7N7SrQabDynvMtL4Lx',
            'name': 'Waffles Chocolate & Hazelnut Flavour',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Egg, Sugar, Chocolate & Hazelnut Flavour Filling (26%) (Sugar, Palm Fat, Palm Kernel Oil, Whey Powder (Milk), Lactose (Milk), Coconut Oil, Cocoa Powder, Emulsifiers (Lecithins, Sorbitan Tristearate), Flavouring), Wheat Flour, Rapeseed Oil, Lupin Flour, Skimmed Milk Powder, Salt, Emulsifier (Lecithins), Flavouring. Contains Cereals Containing Gluten, Eggs, Lupin, Milk, Wheat. May Contain Nuts.'
        },
        {
            'id': '2G6BhANrqwMok4uCssut',
            'name': 'Griddle Waffles',
            'brand': 'Griddle',
            'serving_size_g': 40.0,
            'ingredients': 'Water, Wholegrain Wheat Flour, Sunflower Oil, Chocolate (7%) (Cocoa Mass, Sugar, Dextrose, Emulsifier (Lecithin (Soya))), Sugar, Soya Flour, Raising Agents (Monocalcium Phosphate, Sodium Bicarbonate), Salt. Contains Cereals Containing Gluten, Soybeans, Wheat. May Contain Eggs, Milk.'
        },
        {
            'id': '2KbgjAJhATns2G73irRg',
            'name': '8 Cranberry & Orange Oaty Cookies',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (28%), Margarine (Palm Oil, Rapeseed Oil, Water, Salt, Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Colour (Carotenes), Flavouring), Rice Flour, Sweetened Dried Cranberries (12%) (Sugar, Cranberries, Sunflower Oil), Sugar, Golden Syrup, Cornflour, Tapioca Flour, Raising Agents (Sodium Carbonates, Ammonium Carbonates), Orange Oil (0.2%), Salt. Contains Oats.'
        },
        {
            'id': '2LMbkRDTg4Ripl1tAMcV',
            'name': 'The Nice Slice',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Solids (Cocoa Mass, Cocoa Butter), Sugar, Hazelnut Paste (12%), Full Cream Milk Powder, Corn Flakes (7%) (Milled Corn, Sugar, Malt Flavouring (from Barley), Salt), Almond Nuts Paste (7%), Caramel Flakes (5%) (Sugar, Glucose Syrup), Vegetable Fats (Coconut, Shea, Sunflower), Rice Crispies (4%) (Rice, Sugar, Salt, Malt Flavouring (from Barley)), Skimmed Milk Powder, Butter Oil (from Milk), Lactose (from Milk), Caramelised Sugar, Sea Salt, Emulsifiers (Sunflower Lecithin, Soya Lecithin), Flavourings, Colour (Paprika Extract). Milk Chocolate Contains Minimum 50% Cocoa Solids, Minimum 20% Milk Solids. Caramel Milk Chocolate Contains Minimum 36% Cocoa Solids, Minimum 26% Milk Solids. Contains Barley, Cereals Containing Gluten, Milk, Nuts, Soybeans. May Contain Eggs, Peanuts, Sesame, Wheat.'
        },
        {
            'id': '2NrNOYDyXzvfSDhWq8e7',
            'name': 'Mozzarella Flavour Slices',
            'brand': 'Violife',
            'serving_size_g': 13.0,
            'ingredients': 'Water, Coconut Oil (26%), Modified Starch, Starch, Sea Salt, Calcium Phosphate, Lentil Protein, Mozzarella Flavour, Olive Extract, Colour (B-Carotene), Vitamin B12.'
        },
        {
            'id': '2NvXcOz4hZtvCinOHOBu',
            'name': 'Intergalactic Cones',
            'brand': 'Morrisons',
            'serving_size_g': 75.0,
            'ingredients': 'Reconstituted Skimmed Milk, Black Wafer Cone (15%) (Wheat Flour, Sugar, Fat Reduced Cocoa Powder, Emulsifier (Soya Lecithins), Coconut Oil, Colour (Vegetable Carbon), Salt), Sugar, Coconut Oil, Bubble Gum Flavour Sauce (6%) (Water, Sugar, Modified Maize Starch, Spirulina Extract, Thickener (Pectins), Acidity Regulator (Citric Acid), Flavouring), Glucose Syrup, Whey Powder (Milk), Fat Reduced Cocoa Powder, Dried Skimmed Milk, White Chocolate Stars (Sugar, Cocoa Butter, Dried Whole Milk, Emulsifier (Sunflower Lecithins)), Meringue Pieces (Sugar, Rehydrated Free Range Egg White, Wheat Starch), Blue Sugar Granules (Sugar, Glucose Syrup, Glazing Agent (Shellac), Flavouring, Spirulina Concentrate, Coconut Oil, Rapeseed Oil), Emulsifiers (Mono- and Diglycerides of Fatty Acids, Sunflower Lecithins), Colour (Vegetable Carbon), Stabilisers (Locust Bean Gum, Guar Gum), Concentrated Beetroot Juice, Flavourings, Spirulina Concentrate. Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': '2ODvISGgoo89KzTW7LWs',
            'name': 'Salt And Pepper Fries',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (89%), Sunflower Oil (4%), Modified Potato Starch, Rice Flour, Salt, Black Pepper, Potato Dextrin, Maltodextrin, Onion Powder, Parsley, Raising Agents (Disodium Diphosphate, Sodium Carbonates), Colours (Turmeric Extract, Paprika Extract), Thickener (Xanthan Gum).'
        },
        {
            'id': '2Ok28jQbQl2JPH6ZBTt0',
            'name': 'Low Fat Yogurts',
            'brand': 'M&S',
            'serving_size_g': 125.0,
            'ingredients': 'Strawberry: Low Fat Yogurt (Milk), Strawberries (13%), Water, Sugar, Rice Starch, Flavouring, Concentrated Lemon Juice, Gelling Agent (Pectin (from Fruit)), Colour (Anthocyanins (from Black Carrots)), Culture (Bifidobacterium). Black Cherry: Low Fat Yogurt (Milk), Black Cherries (8%), Sugar, Cherry Purée (4%), Rice Starch, Concentrated Lemon Juice, Gelling Agent (Pectin (from Fruit)), Colour (Anthocyanins (from Black Carrots)), Flavouring, Culture (Bifidobacterium). Peach and Apricot: Low Fat Yogurt (Milk), Peaches (7%), Sugar, Apricots (3%), Apricot Purée (2%), Rice Starch, Flavourings, Gelling Agent (Pectin (from Fruit)), Concentrated Lemon Juice, Antioxidant (Ascorbic Acid), Colour (Paprika Extract), Culture (Bifidobacterium). Fruits of the Forest: Low Fat Yogurt (Milk), Sugar, Strawberries (3%), Blackberries (3%), Blackcurrants (3%), Raspberries (3%), Rice Starch, Flavourings, Gelling Agent (Pectin (from Fruit)), Concentrated Lemon Juice, Colour (Anthocyanins (from Black Carrots)), Culture (Bifidobacterium). Contains Milk.'
        },
        {
            'id': '2Om4HIZoonX4cQWHQ0fg',
            'name': 'Monster Munch Roast Beef',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Rapeseed Oil, Roast Beef Seasoning (Wheat Flour (contains Calcium, Iron, Niacin, Thiamin), Hydrolysed Soya Protein, Whey Permeate (from Milk), Flavourings, Rusk (from Wheat), Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium 5-ribonucleotides), Onion Powder, Salt, Garlic Powder, Colour (Ammonia Caramel), Spices). Contains Barley, Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Celery, Mustard.'
        },
        {
            'id': '2Q2Q5NsmeAYQ55koDovd',
            'name': 'Stone Baked Margherita Pizza',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Pizza Base (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Durum Wheat Semolina, Rapeseed Oil, Salt, Yeast, Wheat Gluten, Enzymes (Wheat), Flour Treatment Agent (Ascorbic Acid), Potato Starch, Sunflower Oil), Tomato Sauce (22%) (Tomatoes, Water, Sugar, Salt, Dried Herbs, Sunflower Oil, Black Pepper, Acidity Regulator (Citric Acid), Dried Garlic), Mozzarella Full Fat Soft Cheese (21%) (Milk), Mild White Cheddar Cheese (5%) (Milk), Mature White Cheddar Cheese (5%) (Milk). Contains Cereals Containing Gluten, Milk, Wheat. May Contain Soybeans.'
        },
        {
            'id': '2Qhug0NY7bnXrkF9EmbZ',
            'name': 'Salt & Pepper Mix',
            'brand': 'Bramwells',
            'serving_size_g': 8.75,
            'ingredients': 'Maltodextrin, Sugar, Salt (10%), Maize Starch, Dried Garlic (6%), Dried Onion, Ginger Powder, Dried Green Bell Pepper (2%), Yeast Extract, Cracked Black Pepper (1.5%), Chilli Flakes (1.5%), Rapeseed Oil, Star Anise, Ground Fennel, Ground Cinnamon, Dried Parsley, Ground Cloves. May Contain Celery, Cereals Containing Gluten, Milk, Mustard, Soybeans, Sulphites.'
        },
        {
            'id': '2QuaPefyVZVlxbKTXY1F',
            'name': 'Freefrom Haddock Fishcakes',
            'brand': 'M&S',
            'serving_size_g': 50.0,
            'ingredients': 'Sugar, Butter (Milk), Wheat Flour (contains Gluten) (With Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rice Flour, Glucose Syrup, Sweetened Milk (Whole Milk, Sugar, Lactose (Milk)), Cocoa Butter, Golden Syrup (Invert Sugar Syrup), Palm Oil, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Salt, Lactose (Milk), Emulsifier (Soya Lecithin, Sunflower Lecithin, E491), Dried Whole Milk, Flavourings. Contains Cereals Containing Gluten, Milk, Soybeans, Wheat. Not Suitable for Nut Allergy Sufferers due to Manufacturing Methods.'
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

    total_cleaned = 636 + updates_made

    print(f"✨ BATCH 50 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Breaking 650 milestone check
    if total_cleaned >= 650:
        print(f"\\n🎉🎉🎉 650 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 10% progress through the messy ingredients!")

    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch50(db_path)
