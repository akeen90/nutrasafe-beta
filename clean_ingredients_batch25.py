#!/usr/bin/env python3
"""
Clean ingredients batch 25 - Mixed Brands (REACHING 200 MILESTONE!)
"""

import sqlite3
from datetime import datetime

def update_batch25(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 25 (200 MILESTONE!)\n")

    clean_data = [
        {
            'id': 'J4QP27qSQOZYySLTdKSy',
            'name': 'Smoky Tofu Burrito',
            'brand': 'Asda',
            'serving_size_g': 100.0,  # Per 100g
            'ingredients': 'Bar Marked Tortilla Wrap (23%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Folic Acid, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Sugar, Raising Agent (Sodium Carbonates), Acidity Regulator (Malic Acid), Salt), Cooked White Rice (15%) (Water, Rice), Marinated Tofu (9%) (Soya Beans, Water, Marinade (Water, Salt, Spices, Flavouring, Onion Powder, Garlic Powder, Herbs, Acidity Regulator (Citric Acid), Thickener (Guar Gum), Stabiliser (Xanthan Gum)), Sunflower Oil, Firming Agent (Calcium Sulphate)), Red Peppers (9%), Red Onions, Sweetcorn, Tomato Passata, Onions, Yellow Peppers (4%), Sweet Potato (3%), Non-Dairy alternative to Cheddar (Water, Coconut Oil, Modified Potato Starch, Maize Starch, Oat Fibre, Tricalcium Citrate, Modified Maize Starch, Thickeners (Carrageenan, Guar Gum), Fructose, Sea Salt, Flavourings, Acidity Regulators (Lactic Acid, Sodium Lactate, Citric Acid), Yeast Extract, Colour (Carotenes)), Spring Onions, Black Beans. Contains Oats, Soya, Wheat.'
        },
        {
            'id': 'eV1NRFZYs12TfawhPtYt',
            'name': 'Inspirations Fish',
            'brand': 'Birds Eye',
            'serving_size_g': 163.0,  # Per portion (half of 326g pack)
            'ingredients': 'Alaska Pollock (Fish) (82%), Water, Tomato Flakes, Paprika, Extra Virgin Olive Oil, Basil, Salt, Fish Gelatine, Natural Flavourings, Palm Fat, Vegetable Stock, Dextrose, Spices, Natural Emulsifier (Sunflower Lecithins), Oregano, Sunflower Oil. Contains Fish.'
        },
        {
            'id': 'rAZCGunMBYmHCgJCEIPu',
            'name': 'Chocolate Cake Doughnuts',
            'brand': 'Black Label Bakery',
            'serving_size_g': 73.0,
            'ingredients': 'Wheat Flour, Vegetable Fats (Palm, Coconut), Belgian Milk Chocolate (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Whey Powder, Emulsifier (Soya Lecithins), Natural Vanilla Flavouring), Sugar, Water, Vegetable Oils (Rapeseed, Sunflower, Palm), White Chocolate (Sugar, Cocoa Butter, Whole Milk Powder, Skimmed Milk Powder, Lactose, Whey Powder, Emulsifier (Soya Lecithins), Natural Vanilla Flavouring), Belgian Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Anhydrous Butterfat, Emulsifier (Soya Lecithins), Natural Vanilla Flavouring), Fat Reduced Cocoa Powder, Yeast, Rye Flour, Whole Milk Powder, Dextrose, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Lecithins, Sodium Stearoyl-2-Lactylate), Glucose Syrup, Salt, Raising Agents (Diphosphates, Sodium Carbonates), Cocoa Mass, Skimmed Milk Powder, Thickener (Xanthan Gum), Lecithins, Flour Treatment Agent (Ascorbic Acid), Natural Flavouring, Natural Vanilla Flavouring. Contains Gluten, Milk, Soya. May Contain Eggs, Nuts.'
        },
        {
            'id': 'khHRmywIMnWKDyjq26c0',
            'name': 'Ham Cheese & Pickle Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 204.0,
            'ingredients': 'Malted Bread (44%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes, Wheat Bran, Yeast, Malted Barley Flour, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Wheat Protein, Malted Wheat Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Oak Smoked Formed Ham (22%) (Pork, Water, Salt, Stabiliser (Pentasodium Triphosphate), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Mature Cheddar Cheese (Milk) (13%), Mayonnaise (7%) (Water, Rapeseed Oil, Cornflour, Spirit Vinegar, Pasteurised Egg Yolk, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Sugar, White Wine Vinegar, Concentrated Lemon Juice, Salt), Lettuce (5%), Pickle (4%) (Malt Vinegar (Barley), Sugar, Water, Carrot, Swede, Courgette, Onion, Molasses, Cornflour, Non Brewed Condiment (Water, Acidity Regulator (Acetic Acid)), Salt, Spices). Contains Barley, Eggs, Mustard, Wheat.'
        },
        {
            'id': 'sAo5to46xiOgGJ0ygewm',
            'name': 'Sweet Chili Crunch',
            'brand': 'Alesto',
            'serving_size_g': 100.0,
            'ingredients': '33% Sweet Chilli Flavoured Green Peas (Green Peas, Modified Corn Starch, Sunflower Oil, Wheat Flour, Sugar, Sweet Chilli Seasoning (Sugar, Dried Tomato, Yeast Extract, Dried Garlic, Dried Onion, Acidity Regulator (Citric Acid), Dried Chilli, Dried Cumin, Parsley Flakes, Dried Coriander, Dried Ginger, Dried Anise, Sunflower Oil, Colour (Paprika Extract), Lime Oil), Salt), 29% Sweet Chilli Flavour Fried Broad Beans (Broad Beans, Sunflower Oil, Sweet Chilli Flavour Seasoning (Salt, Sugar, Ground Spices (Black Pepper, Cayenne Pepper), Dried Tomato, Dried Onion, Maltodextrin, Dried Garlic, Dried Paprika, Dried Cumin, Dried Oregano, Yeast Extract, Acidity Regulator (Citric Acid), Colour (Paprika Extract))), 19% Fried Salted Corn (Corn, Sunflower Oil, Salt), 19% Sweet Chilli Flavour Fried Corn Snack (Corn, Sunflower Oil, Sweet Chilli Seasoning (Glucose Syrup, Fructose, Sugar, Ground Spices (Onion, Paprika, Cayenne Pepper), Dried Tomato, Salt, Natural Flavouring, Dried Lemon Juice, Dried Beetroot)). Contains Wheat.'
        },
        {
            'id': 'XBSIXcVDCzguEbYqnHnN',
            'name': 'Alpen Chocolate Caramel & Shortbread Imp',
            'brand': 'Alpen',
            'serving_size_g': 24.0,
            'ingredients': 'Cereals (40%) (Oats, Rice, Wheat), Oligofructose Syrup, Milk Chocolate (14%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Milk Powder, Milk Fat, Emulsifier (Soya Lecithin)), Cereal Flours (Rice, Wheat, Malted Barley), Caramel Pieces (4.5%) (Sugar, Glucose Syrup, Condensed Milk, Palm Oil, Shea Kernel Oil, Maize Starch, Humectant (Glycerol), Palm Stearin, Flavouring, Emulsifiers (Glycerol Monostearate, Sunflower Lecithin), Salt), Plain Chocolate (4.5%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithin), Flavouring), Glucose Syrup, Humectant (Glycerol), Shortbread Pieces (1.5%) (Fortified Wheat Flour (Wheat, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Shea Kernel, Rapeseed), Sugar, Invert Sugar Syrup, Tapioca Starch, Salt, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Emulsifier (Sunflower Lecithin)), Vegetable Oils (Sunflower, Rapeseed), Sugar, Flavouring, Salt, Emulsifier (Soya Lecithin). Contains Barley, Milk, Oats, Soya, Wheat. May Contain Nuts.'
        },
        {
            'id': 'YlsYK1IxwHeFpj2IPHI2',
            'name': 'Lamb Kebab',
            'brand': 'Birchwood',
            'serving_size_g': 48.0,  # Per kebab (from 320g pack)
            'ingredients': '83% Lamb, Mint, Honey, Onion, Crumb (Rice Flour, Gram Flour, Maize Starch, Salt, Dextrose), Seasoning (Sugar, Sea Salt, Black Pepper, Mint, Preservative (Sodium Metabisulphite), Antioxidant (Ascorbic Acid)), Lemon Zest, Concentrated Lemon Juice (Lemon Juice, Preservative (Sodium Metabisulphite)), Roast Garlic Purée, Parsley Fibre, Raising Agent (Sodium Carbonates). Contains Sulphites.'
        },
        {
            'id': 'DWEMov8oj9mFLzWCJ1ml',
            'name': 'Chicken Tikka Fillet',
            'brand': 'Asda',
            'serving_size_g': 100.0,  # Per 100g
            'ingredients': 'Chicken Breast (89%), Maltodextrin, Corn Starch, Spices, Sugar, Acidity Regulators (Potassium Acetate, Acetic Acid, Lactic Acid, Calcium Lactate, Citric Acid), Whey Powder, Salt, Coconut Milk Powder (Coconut Milk, Maltodextrin, Emulsifier (Sodium Caseinate)), Garlic, Onion, Modified Tapioca Starch, Yogurt Powder, Yeast Extract, Parsley, Colour (Paprika Extract), Flavourings. Contains Milk.'
        },
        {
            'id': 'rvYHRzU7yhJ98JNct1Wk',
            'name': 'Aptamil',
            'brand': 'Aptamil',
            'serving_size_g': 100.0,  # Per 100g powder
            'ingredients': 'Dairy-Based Blend (of which 29% is fermented) (Lactose (from Milk), Vegetable Oils (High Oleic Sunflower Oil, Coconut Oil, Rapeseed Oil, Sunflower Oil), Skimmed Milk, Demineralised Whey (from Milk), Whey Concentrate (from Milk), Fish Oil, Potassium Citrate, Calcium Carbonate, Magnesium Chloride, Choline Chloride, Calcium Phosphate, Sodium Citrate, Potassium Chloride, Vitamin C, Emulsifier (Soya Lecithin), Inositol, Antioxidant (Vitamin C), Pantothenic Acid, Nicotinamide, Vitamin E, Thiamin, Riboflavin, Vitamin B6, Potassium Iodide, Folic Acid, Vitamin K1, Biotin, Vitamin B12). Contains Fish, Milk, Soya.'
        },
        {
            'id': 'UH8TrseVP1bMED5z715J',
            'name': 'Unicorn Cake',
            'brand': 'Asda',
            'serving_size_g': 64.0,
            'ingredients': 'Sugar, Plum and Raspberry Jam (13%) (Glucose-Fructose Syrup, Plum Concentrate, Seedless Raspberry Concentrate, Gelling Agent (Pectins), Acidity Regulators (Citric Acid, Sodium Citrates), Colour (Anthocyanins), Flavouring), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Pasteurised Whole Egg, Palm Oil, Palm Kernel Oil, Water, Humectant (Glycerol), Dried Glucose Syrup, Skimmed Milk Powder, Raising Agents (Diphosphates, Sodium Carbonates), Maize Starch, Palm Stearin, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate, Soya Lecithins, Sunflower Lecithins, Acacia Gum, Sucrose Esters of Fatty Acids), Whey Solids (Milk), Preservative (Potassium Sorbate), Flavourings, Fruit, Plant and Vegetable Concentrates (Beetroot, Carrot, Spirulina, Pumpkin, Apple), Colours (Carotenes, Riboflavin, Iron Oxides and Hydroxides, Vegetable Carbon, Anthocyanins, Beetroot Red, Curcumin, Paprika Extract), Acidity Regulator (Citric Acid), Glucose Syrup, Coconut Oil, Spirulina Extract, Stabiliser (Xanthan Gum), Glazing Agent (Beeswax White and Yellow). Contains Eggs, Milk, Soya, Wheat. May Contain Nuts.'
        },
        {
            'id': 'RZll5F3FWXiE68py38ZI',
            'name': 'Memphis Beef Kebabs',
            'brand': 'Birchwood',
            'serving_size_g': 54.0,  # Per kebab (from 320g pack)
            'ingredients': '87% British Beef, 7% Sweet Chilli Sauce (Sugar, Water, Red Chilli Purée, Spirit Vinegar, Ginger Purée, Garlic Purée, Sunflower Oil, Tapioca Starch, Dried Red Peppers, Dried Chilli Flakes, Cornflour, Colour (Paprika Extract)), Crumb (Rice Flour, Gram Flour, Maize Starch, Salt, Dextrose), Seasoning (Sea Salt, Ground Black Pepper, Chilli Powder (Chilli, Cumin, Salt, Oregano), Preservative (Sodium Metabisulphite), Flour Treatment Agent (Ascorbic Acid), Chilli Extract), Chives. Contains Sulphites.'
        },
        {
            'id': 'WMUiWQIYquEiYPa0sKi2',
            'name': 'Chicken & Red Pepper Houmous Grain Salad',
            'brand': 'Asda',
            'serving_size_g': 100.0,  # Per 100g (315g pack)
            'ingredients': 'Cooked Giant Couscous (22%) (Wheat Flour, Water), Red Pepper Houmous (14%) (Chickpeas, Grilled Red Peppers, Tahini Paste (Sesame Seeds), Water, Rapeseed Oil, Concentrated Lemon Juice, Olive Oil, Garlic Purée, Salt, Colour (Paprika Extract)), Cooked Marinated Chicken (13%) (Chicken Breast (86%), Red Chilli Purée, Tomato Purée, Sugar, Rapeseed Oil, Red Wine Vinegar, Cornflour, Garlic Purée, Spices, Coriander, Salt, Onion Powder), Cooked Bulgur Wheat (12%) (Bulgur Wheat, Water), Carrots, Cooked Black Pearl Barley (6%) (Black Pearl Barley, Water), Pickled Red Cabbage and Carrots (Red Cabbage, Carrots, Sugar, Spirit Vinegar, Salt), Water, Pink Cabbage, Jumbo Raisins, Spinach, Sweetened Dried Cranberries (Sugar, Cranberries), Rapeseed Oil, White Wine Vinegar, Coriander, Pumpkin Seeds, Spices, Parsley, Tomato Paste, Red Chilli Purée, Concentrated Lemon Juice, Garlic Purée, Ginger Purée, Maple Syrup, Cornflour, Salt. Contains Gluten, Sesame, Wheat.'
        },
        {
            'id': 'a5IOLoDAZ8EYBf55qadu',
            'name': 'Sweet And Sour British Chicken Stir-fry Kit',
            'brand': 'Asda',
            'serving_size_g': 100.0,  # Per 100g
            'ingredients': 'Sun-dried Tomato Vinaigrette Dressed Wholewheat Pasta (38%), Vegetable Mix (22%) (Carrots, Cucumber, Sweetcorn), Piri Piri Style Marinated Chicken (14%) (Chicken Breast (85%), Red Chillies, Cayenne Pepper, Cumin, Coriander Powder), Iceberg Lettuce (13%), Sour Cream and Chive Dressing (13%) (Water, Rapeseed Oil, Cornflour, Soured Cream, White Wine Vinegar, Salted Egg Yolk, Spirit Vinegar, Sugar, Chives, Concentrated Lemon Juice, Salt). Wholewheat Pasta Component: Durum Wheat Semolina, Sun-dried Tomato Purée, Water, Coriander, Basil, White Wine Vinegar, Rapeseed Oil, Black Pepper, Dijon Mustard, Sugar, Stabilisers (Xanthan Gum, Guar Gum), Extra Virgin Olive Oil, Garlic Purée. Contains Eggs, Gluten, Milk, Mustard, Wheat.'
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

    print(f"✨ BATCH 25 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {187 + updates_made} / 681\n")
    print(f"🎉🎉🎉 200 PRODUCTS MILESTONE REACHED! 🎉🎉🎉\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch25(db_path)
