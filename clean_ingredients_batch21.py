#!/usr/bin/env python3
"""
Clean ingredients batch 21 - Mixed Brands (Large Batch Continued)
"""

import sqlite3
from datetime import datetime

def update_batch21(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 21 (Mixed Brands - Large Batch)\n")

    clean_data = [
        {
            'id': 'NSTPJJlgAAoznhx0R180',
            'name': 'Yord Vanilla',
            'brand': 'Arla',
            'serving_size_g': 100.0,
            'ingredients': 'Skyr Yogurt (Skimmed Milk) (86%), Water, Sugar, Maize Starch, Natural Vanilla Flavouring, Lemon Juice from Concentrate, Vanilla Pods. Contains Milk.'
        },
        {
            'id': 'WLW6qmx404UnyPwfL07v',
            'name': 'Prawn Cocktail',
            'brand': 'Asda',
            'serving_size_g': 170.0,
            'ingredients': 'Prawns (Pandalus borealis) (Crustacean) (50%), Water, Rapeseed Oil, Salted Free Range Egg Yolk (2%) [Free Range Egg Yolk, Salt], Sugar, Cornflour, Salt, Tomato Paste, White Wine Vinegar, Vegetarian Worcester Sauce [Water, Sugar, Spirit Vinegar, Molasses, Onion Purée, Cloves, Garlic Purée, Ginger Purée, Tamarind Paste, Salt], Citrus Fibre, Concentrated Lemon Juice, Spirit Vinegar, Preservative (Potassium Sorbate), Mustard Flour, Allspice. Contains Crustaceans, Eggs, Mustard.'
        },
        {
            'id': 'UH8TrseVP1bMED5z715J',
            'name': 'Unicorn Cake',
            'brand': 'Asda',
            'serving_size_g': 64.0,
            'ingredients': 'Sugar, Plum and Raspberry Jam (13%) [Glucose-Fructose Syrup, Plum Concentrate, Seedless Raspberry Concentrate, Gelling Agent (Pectins), Acidity Regulators (Citric Acid, Sodium Citrates), Colour (Anthocyanins), Flavouring], Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Rapeseed Oil, Pasteurised Whole Egg, Palm Oil, Palm Kernel Oil, Water, Humectant (Glycerol), Dried Glucose Syrup, Skimmed Milk Powder, Raising Agents (Diphosphates, Sodium Carbonates), Maize Starch, Palm Stearin, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Sodium Stearoyl-2-Lactylate, Soya Lecithins, Sunflower Lecithins, Acacia Gum, Sucrose Esters of Fatty Acids), Whey Solids (Milk), Preservative (Potassium Sorbate), Flavourings, Fruit, Plant and Vegetable Concentrates [Beetroot, Carrot, Spirulina, Pumpkin, Apple], Colours (Carotenes, Riboflavin, Iron Oxides and Hydroxides, Vegetable Carbon, Anthocyanins, Beetroot Red, Curcumin, Paprika Extract). Contains Apple, Eggs, Gluten, Milk, Soybeans.'
        },
        {
            'id': 'gFA4N02Lz9Mh7uOvpGJ8',
            'name': 'Kimchi Sliced Kimchi',
            'brand': 'Bibigo',
            'serving_size_g': 50.0,
            'ingredients': 'Salted Napa Cabbage 69.4% (Napa Cabbage, Salt), Radish, Modified Tapioca Starch Mix (Tapioca Starch, Thickener (E412), Modified Starch (E1442)), Fermented Fish Sauce (Anchovy Extract, Shrimp Extract, Kelp Extract, Flavour Enhancer (E621), Sweetener (E420)), Red Pepper Powder 2.7%, Garlic, Leek, Green Onion, Onion, Ginger, Starter Culture (Hydrolysed Soy Protein). Contains Fish, Crustaceans, Soy.'
        },
        {
            'id': 'EA5BGJIJBj9Au36VkUAx',
            'name': 'Takis Fuego',
            'brand': 'Bimbo',
            'serving_size_g': 100.0,
            'ingredients': 'Pre-Cooked Cornflour, Palm Fat, Chilli and Lime Flavour Seasoning [Maltodextrin, Salt, Flavour Enhancers (Monosodium Glutamate, Potassium Chloride, Disodium Inosinate, Disodium Guanylate), Flavouring, Cornstarch, Acidity Regulator (Citric Acid), Sugar, Colours (Paprika Extract, Beetroot Red Concentrate), Stabiliser (Gum Arabic), Antioxidant (Tocopherol-Rich Extract)], Sunflower Oil. May Contain Milk, Soya.'
        },
        {
            'id': 'sbKy4cxIIVm9rZlGuJEl',
            'name': 'Birchwood Higher Welfare Smoky Chorizo 4 Chicken &',
            'brand': 'Birchwood',
            'serving_size_g': 74.0,
            'ingredients': '86% British Diced Chicken Breast, 9% Chorizo Pork Sausage Slices (89% Pork, Water, Salt, Smoked Paprika, Pork Collagen Casing, Dextrose, Garlic Paste, Antioxidant: Sodium Ascorbate, Nutmeg, Preservative: Sodium Nitrite, Oregano), 5% Smoked Paprika Marinade (Sugar, Smoked Paprika, Ground Cumin, Ground Chilli, Salt, Cornflour, Dried Glucose Syrup, Garlic Powder, Tomato Powder, Ground Oregano, Chipotle Chilli, Thickener: Guar Gum, Green Pepper, Red Pepper, Parsley, Paprika Extract, Flavouring).'
        },
        {
            'id': 'vLbOPGwWOkSVR0fM46QB',
            'name': '2 Garlic And Herb Chicken Kievs',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (42%), Water, Fortified Wheat Flour (Wheat, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Butter (Milk), Starch (Potato, Wheat), Flour (Maize, Rice), Garlic, Salt, Egg White Powder, Natural Emulsifier: Sunflower Lecithin, Concentrated Lemon Juice, Parsley, Natural Flavourings, Yeast, Garlic Powder, Onion Powder, Dextrose, Black Pepper. May Contain Mustard. Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': 'RIDwLBcW0sHx22vWFlSB',
            'name': 'Birds Eye 12 Chicken Nuggets With Golden Wholegrain',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (51%), Flour (Wheat, Wholegrain Wheat, Maize), Rapeseed Oil, Water, Starch (Wheat, Maize), Salt, Spices, Yeast, Natural Flavouring, Onion Powder, Garlic Powder, Calcium Carbonate, Iron, Niacin, Thiamin. May Contain Egg. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'jSsM0F4I8yJfOdG03LYH',
            'name': 'Peri Peri Chicken Chargrill',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (73%), Water, Rapeseed Oil, Flour (Wheat, Rice), Palm Oil, Starch (Maize, Wheat), Salt, Dried Onion, Spices, Natural Flavouring, Garlic Powder, Acidity Regulator (Citric Acid), Dried Red Pepper, Onion Powder, Yeast Extract, Tomato Powder, Emulsifier (Soya Lecithin), Natural Lemon and Cayenne Flavourings, Parsley, Caramelised Sugar, Smoke Flavouring, Cumin Extract, Colour (Paprika Extract), Skimmed Milk Powder, Calcium Carbonate, Iron, Niacin, Thiamin. May Contain Egg. Contains Cereals Containing Gluten, Milk, Soya, Wheat.'
        },
        {
            'id': '6StF0ckQL2i3dcAfJDPl',
            'name': 'Sweet & Sticky BBQ',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (73%), Water, Flour (Wheat, Rice), Rapeseed Oil, Starch (Maize, Wheat), Palm Oil, Demerara Sugar, Salt, Dried Onion, Molasses Powder (contains Wheat), Natural Flavourings (contains Barley), Dried Glucose Syrup, Garlic Powder, White Vinegar, Spices, Acidity Regulator (Citric Acid), Yeast Extract, Caramelised Sugar, Smoke Flavour, Emulsifier (Soya Lecithin), Colour (Paprika Extract), Calcium Carbonate, Iron, Niacin, Thiamin. May Contain Egg, Milk. Contains Barley, Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'eWat6JypBBO0ExHAuPzE',
            'name': 'Nutty Stir Fry',
            'brand': 'Blue Dragon',
            'serving_size_g': 60.0,
            'ingredients': 'Nutty Satay and Chilli Sauce (67%) (Water, Coconut Milk (Water, Desiccated Coconut, Emulsifier (E466)), Peanuts (6%), Red Curry Paste (Creamed Coconut, Lemongrass, Chilli, Garlic, Salt, Galangal, Shallot, Kaffir Lime, Coriander, Palm Sugar, Yeast Extract, Colouring(E160c)), Sugar, Soy Sauce (Water, Soybean, Wheat, Salt), Pickled Chilli Garlic (Red Chilli, Garlic, Salt, Acidity Regulator (Citric Acid, Acetic Acid)), Sunflower Oil, Creamed Coconut, Thickener (E1442), Chilli, Curry Powder (Mustard, Fenugreek, Coriander, Turmeric, Pepper, Paprika Powder, Cumin, Cinnamon), Turmeric Powder, Stabiliser (Xanthan Gum), Acidity Regulator (Citric Acid), Antioxidant (E306)), Garlic and Ginger Paste (25%) (Garlic (6%), Ginger (5%), Pickled Garlic (3%), Sugar, Water, Sunflower Oil, Distilled Vinegar, Acidity Regulator (Citric Acid, Lactic Acid, Ascorbic Acid), Stabilizers (Xanthan Gum)), Crushed Peanuts (8%). Contains Mustard, Peanuts, Soya, Wheat.'
        },
        {
            'id': 'leZuyXHOl1zRhQNzvIPD',
            'name': 'Protein Lower Soup Red Pepper, Tomato & Lentil',
            'brand': 'Bol',
            'serving_size_g': 300.0,
            'ingredients': 'Water, Red Lentils (11%), Tomatoes (7%), Red Peppers (7%), Red Pepper Purée, Tomato Paste, Onions, Garlic Purée, Sunflower Seeds, Basil, Salt, Smoked Paprika, Cornflour, Ground Black Pepper, Dried Red Chillies. May Contain Soya, Nuts, Peanuts.'
        },
        {
            'id': 'RbQ4BUDUZ1VJ6LXLOMI6',
            'name': 'Vegan No Duck & Hoisin',
            'brand': 'Boots',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Wrap [Fortified Wheat Flour, Water, Vegetable Oils (Palm, Rapeseed), Raising Agents, Sugar, Acidity Regulator, Salt], Seasoned Wheat Gluten and Soya Protein Pieces (21%) [Soya Protein, Wheat Gluten, Salt, Soya Bean Oil, Flavouring, Stock Powder (Yeast Extract, Chicory Extract, Salt, Sunflower Oil, Carrot Extract, Onion Powder, Tomato Powder), Yeast Extract, Black Pepper, Onion Powder], Vegan Hoisin Sauce (10%) [Water, Sugar, Brown Sugar, Dark Fermented Bean Paste (Fermented Soya Beans, Water, Salt, Fortified Wheat Flour), Concentrated Plum Juice, Cornflour, Rapeseed Oil, Soya Sauce], Cucumber, Lettuce, Spring Onion. Contains Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'tsEl5bnHhY0C5RznEMES',
            'name': 'Dark Chocolate Ginger Bars',
            'brand': 'Border',
            'serving_size_g': 24.0,
            'ingredients': 'Plain Chocolate (44%) (Sugar, Cocoa Mass, Cocoa Butter, Milk Fat, Emulsifier: Soya Lecithin, Vanilla Flavouring), Wheat Flour (Calcium, Iron, Niacin, Thiamin), Sugar, Vegetable Oil (Palm, Rapeseed), Invert Sugar Syrup, Butter, Ground Ginger (1.4%), Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt. May Contain Egg, Nuts. Contains Cereals Containing Gluten, Milk, Soya, Wheat.'
        },
        {
            'id': 'LZ8dQ5LbD230BBGHoCs3',
            'name': 'Chicken Casserole',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Cornflour, Potato Starch, Flavouring, Salt, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Onion Powder, Tomato Powder, Yeast Extract, Ground Paprika, Sugar, Lemon Juice Powder. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'ennwMcp9aissIAvmMByk',
            'name': 'Mature Cheddar And Branston Pickle',
            'brand': 'Branston',
            'serving_size_g': 100.0,
            'ingredients': 'Oatmeal Bread, Medium Mature Cheddar Cheese (30%), Branston Small Chunk Pickle (10%) [Vegetables in Variable Proportions (52%) (Carrot, Rutabaga, Onion, Cauliflower), Sugar, Barley Malt Vinegar, Water, Spirit Vinegar, Tomato Purée, Date Paste (Dates, Rice Flour), Apple Pulp, Modified Maize Starch, Salt, Colour: Sulphite Ammonia Caramel, Onion Powder, Concentrated Lemon Juice, Spices, Colouring Food: Roasted Barley Malt Extract], Butter. Contains Barley, Cereals Containing Gluten, Milk, Oats, Sulphites.'
        },
        {
            'id': 'eIje0OWZRN0VbnAcN9jJ',
            'name': 'Cheddar & Mozzarella Flavour Grated',
            'brand': 'Bute Island Sheese',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Coconut Oil (21%), Modified Potato Starch, Maize Starch, Gluten Free Oat Fibre, Modified Maize Starch, Thickeners (Carrageenan, Guar Gum), Salt, Natural Flavourings, Yeast Extract, Acidity Regulators (Lactic Acid, Sodium Lactate), Colour (Mixed Carotenes). Contains Oats.'
        },
        {
            'id': 'gewTAKFYYF92bhqBg5X3',
            'name': 'Mini Eggs Choc Cake',
            'brand': 'Cadbury',
            'serving_size_g': 62.0,
            'ingredients': 'Chocolate Flavour Filling (35%), Milk Chocolate (17%), Sugar, Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Mini Eggs (5%), Milk Chocolate Curls (5%), Glucose Syrup, Water, Humectant (Glycerol), Fat Reduced Cocoa, Soya Flour. Contains Eggs, Milk, Soya, Wheat.'
        },
        {
            'id': 'hsn0yOtzaQDiUDKKlysD',
            'name': 'Pumpkin Spice Oat Brew',
            'brand': 'Califia Farms',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Drink (Water, Oats (8%)), Pumpkin Puree (2%), Sunflower Oil, Sugar, Spices (0.4%) (Cinnamon, Ginger, Nutmeg), Flavourings, Acidity Regulator (Dipotassium Phosphate), Calcium Carbonate, Tricalcium Phosphate, Sea Salt, Stabiliser (Gellan Gum).'
        },
        {
            'id': 'T3IfCYQPdIRjmpwE4c7l',
            'name': 'Mexican Smoky Fajita Kit',
            'brand': 'Capsicana',
            'serving_size_g': 56.9,
            'ingredients': 'Soft Flour Tortillas (72%) [Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Sugar, Humectant (Glycerol), Spirit Vinegar, Raising Agents (Diphosphates, Sodium Carbonates), Palm Oil, Extra Virgin Olive Oil, Rapeseed Oil, Acidity Regulators (Malic Acid, Citric Acid), Emulsifier (Mono-and Di-Glycerides of Fatty Acids), Preservatives (Potassium Sorbate, Calcium Propionate), Salt, Stabiliser (Cellulose Gum), Wheat Starch, Flour Treatment Agent (L-Cysteine)], Chipotle Sizzle Paste (18%) [Tomato, Water, Honey, Spirit Vinegar, Sugar, Tomato Paste, Dextrose, Chilli Purée, Onion Purée, Salt, Red Pepper, Cornflour, Garlic Purée, Spices (Smoked Paprika, Chipotle Chilli (0.5%), Black Pepper), Herbs (Coriander, Oregano), Colour (Paprika Extract)], Chipotle Chilli Salsa Mix (10%) [Water, Amarillo Chilli Mash (Amarillo Chillies, Salt, Acetic Acid), Onion, Tomato Paste (10%), Dextrose, Garlic Purée, White Wine Vinegar, Brown Sugar, Spices (Chipotle Chilli (1.5%), Cumin), Salt, Cornflour, Herbs (Coriander, Oregano), Natural Flavouring]. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'v5pMfjw6uMJPBb6fAvfC',
            'name': 'Double Pepperoni Pizza',
            'brand': 'Carlos Stonebaked',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Tomato Sauce [Tomato Purée, Sugar, Dried Garlic, Dried Herbs, Pepper], Mozzarella Cheese (Milk), Water, Smoked Pepperoni (9%) [Pork, Pork Fat, Salt, Dextrose, Spices, Spice Extracts, Antioxidants: Extracts of Rosemary, Sodium Ascorbate, Preservative: Sodium Nitrite], Mini Smoked Pepperoni (5%) [Pork, Pork Fat, Salt, Dextrose, Spices, Spice Extracts, Sugar, Antioxidants: Sodium Erythorbate, Extracts of Rosemary, Preservative: Sodium Nitrite], Rapeseed Oil, Yeast, Salt, Dextrose, Dried Herbs, Dried Garlic, Pepper. May Contain Celery. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'bomQMu1EscIZrjERNrGZ',
            'name': 'Pumpkin And Caramelised Onion Veggie Bakes',
            'brand': 'Cauldron',
            'serving_size_g': 100.0,
            'ingredients': 'Pumpkin (28%), Carrot, Restructured Soy Flour, Sunflower Oil, Caramelised Onion (8%) (Onion, Rapeseed Oil, Sugar), Breadcrumb (Wheat Flour, Yeast, Salt), Wheat Gluten, Tapioca and Pea Starch, Potato Flake, Soy Protein Isolate, Onion, Pea Fibre, Parsley, Potassium Chloride, Vegetable Bouillon [Salt, Cornflour, Yeast Extract, Dried Vegetables (Onion, Celery, Carrot, Parsley), Olive Oil, Turmeric], Salt, Dried Garlic, Preservative: Potassium Sorbate, Spirit Vinegar, Natural Flavourings, Rosemary Powder. May Contain Mustard. Contains Celery, Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'vu5oOUIizXEfX38JdFfr',
            'name': 'Charlie Bigham Lasagne',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 345.0,
            'ingredients': 'Tomatoes, Milk, Egg Pasta (Durum Wheat Semolina, Water, Pasteurised Free-Range Egg), British Beef (10%), White Wine, Cream (Milk), Cheddar Cheese (Milk), Smoked Bacon (Pork, Water, Salt, Preservatives: Potassium Nitrate, Sodium Nitrite, Sodium Nitrate, Antioxidant: Sodium Ascorbate), British Pork (6%), Onions, Tomato Purée, Carrots, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Celery, Rapeseed Oil, Butter (Milk), Balsamic Vinegar of Modena (Wine Vinegar, Concentrated Grape Must, Sulphite Ammonia Caramel), Chicken, Cornflour, Beef Stock (British Beef, Yeast Extract, Water, Molasses, Tomato Purée, Salt, Sunflower Oil, Dried Onion, Black Pepper), Garlic Purée, Oregano, Salt, Sugar, Parsley, Black Pepper, Ground Nutmeg, Ground Star Anise, Ground White Pepper. Contains Celery, Cereals Containing Gluten, Eggs, Milk, Sulphites, Wheat.'
        },
        {
            'id': '39ZwbKNqwOMpfNAbezmH',
            'name': 'Thai Red Chicken Curry',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 416.5,
            'ingredients': 'Cooked Rice (Water, Rice), Chicken (18%), Coconut, Water, Onions, Rapeseed Oil, Bamboo Shoots, Edamame Beans (Soya), Lemon Juice, Ginger Purée, Demerara Sugar, Fish Sauce (Anchovy Extract (Fish), Salt, Sugar), Lime Leaves, Cornflour, Lime Juice, Lemongrass, Garlic Purée, Salt, Galangal, Red Chillies, Basil, Garlic, Coriander, Shallots, Dried Red Chillies, Paprika, Ground Cumin, Makrut Lime Peel, White Pepper, Ground Coriander, Ground Fennel Seeds, Sunflower Oil, Ground Cardamom, Shrimp (Crustaceans), Coriander Seed, Ground Star Anise, Colour: Paprika Extract, Ground Turmeric, Curry Powder (Coriander Seed, Turmeric, Cumin, Fennel Seed, Galangal), Cinnamon, Black Pepper, Nutmeg. May Contain Peanuts, Nuts, Sesame. Contains Crustaceans, Fish, Soya.'
        },
        {
            'id': 'hB97wRzlSV0Od4KzSyET',
            'name': 'Cheerios Multigrain',
            'brand': 'Cheerios Multigrain',
            'serving_size_g': 30.0,
            'ingredients': 'Whole Grain Oat Flour (31.9%), Whole Grain Wheat Flour (29.6%), Whole Grain Barley Flour (18.2%), Sugar, Wheat Flour (contains Calcium Carbonate, Vitamin B3, Iron, Vitamin B1), Invert Sugar Syrup, Calcium Carbonate, Sunflower Oil, Molasses, Salt, Caramelised Sugar Syrup, Colours: Carotene, Annatto Norbixin, Antioxidant: Tocopherols, Iron, Vitamins C, B3, B5, B9, D, B6, B2. Contains Barley, Cereals Containing Gluten, Oats, Wheat.'
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

    print(f"✨ BATCH 21 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {106 + updates_made} / 681\n")
    print(f"🎯 MILESTONE: {((106 + updates_made) / 681 * 100):.1f}% complete!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch21(db_path)
