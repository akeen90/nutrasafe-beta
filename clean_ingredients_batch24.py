#!/usr/bin/env python3
"""
Clean ingredients batch 24 - Mixed Brands (Continuing Large Batches)
"""

import sqlite3
from datetime import datetime

def update_batch24(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 24 (Mixed Brands)\n")

    clean_data = [
        {
            'id': 'DG6Q1eyAwYkS72gnZUjV',
            'name': 'Shawarma Chicken Mezze Salad',
            'brand': 'Co-op',
            'serving_size_g': 255.0,
            'ingredients': 'Cooked Chicken Breast (22%) (Chicken Breast, Water, Salt, Brown Sugar, Dried Yeast), Red Cabbage (12%), Iceberg Lettuce, Falafel Balls (10%) (Rehydrated Chickpeas (Water, Dried Chickpeas), Onion, Rapeseed Oil, Red Pepper, Parsley, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Gram Flour, Ground Cumin, Ground Coriander, Garlic, Salt, Parsley, Coriander Leaf, Yeast Extract Powder, Stabiliser (Methyl Cellulose), Onion Powder, Rapeseed Oil, Cayenne Pepper, Raising Agent (Sodium Bicarbonate)), Tomato (10%), Cucumber (9%), Greek Style Yogurt Dressing (7%) (Greek Style Yogurt (Milk) (58%), Water, Rapeseed Oil, White Wine Vinegar, Pasteurised Egg Yolk, Cornflour, Sugar, Concentrated Lemon Juice, Garlic Purée, Salt, Ground Cumin, Dried Mint, Ground Coriander), Giant Cous Cous (6%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water), Pickled Red Onion (Red Onion, White Wine Vinegar, Sugar, Salt), Houmous (3%) (Cooked Chickpeas (Water, Dried Chickpeas), Water, Tahini (Sesame Seed Paste), Rapeseed Oil, Garlic Purée, Salt, Ground Cumin, Preservative (Potassium Sorbate), Acidity Regulator (Citric Acid)), Red Pepper (3%), Pomegranate Seeds (2%), Coriander. Contains Eggs, Milk, Sesame, Wheat.'
        },
        {
            'id': 'Uvnm5Mflr8Ple2H5slKY',
            'name': 'Southern Fried Chiken',
            'brand': 'Co-op',
            'serving_size_g': 211.0,
            'ingredients': 'White Sub Roll (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Rapeseed Oil, Sugar, Salt, Flour Treatment Agent (Ascorbic Acid)), Southern Fried Chicken (29%) (Chicken Breast, Batter (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Maize Flour, Salt, Raising Agent (Sodium Bicarbonate), Garlic Powder, Onion Powder, Paprika, Dried Yeast, Ground White Pepper), Coating (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Maize Flour, Water, Salt, Paprika, Onion Powder, Garlic Powder, Chilli Powder, Dried Yeast, Ground White Pepper, Cayenne Pepper), Rapeseed Oil), Iceberg Lettuce (10%), Hot Sauce Mayonnaise (9%) (Rapeseed Oil, Water, Spirit Vinegar, Tomato Purée, Pasteurised Egg Yolk, Sugar, Cornflour, Salt, Hot Pepper Sauce (Spirit Vinegar, Red Chilli Pepper, Salt), Concentrated Lemon Juice, Dried Garlic, Smoked Paprika, Dried Onion, Cayenne Pepper, Stabiliser (Xanthan Gum), Acidity Regulator (Citric Acid)), Tomato (4%). Contains Eggs, Wheat.'
        },
        {
            'id': 'WOt8dbRyLM9y4W98NxDD',
            'name': 'Steak & Balsamic Onion',
            'brand': 'Co-op',
            'serving_size_g': 199.0,
            'ingredients': 'Malted Bloomer (46%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes, Yeast, Wheat Bran, Salt, Malted Barley Flour, Rapeseed Oil, Wheat Gluten, Wheat Protein, Flour Treatment Agent (Ascorbic Acid)), Cooked British Beef (23%) (Beef Topside, Salt, Stabiliser (Triphosphates)), Spinach (11%), Balsamic Onion (10%) (Red Onion, Sugar, Balsamic Vinegar (Wine Vinegar, Grape Must), White Wine Vinegar, Water, Molasses, Cornflour, Salt, Garlic Purée, Ginger Purée, Black Pepper), Caramelised Onion Mayonnaise (7%) (Water, Rapeseed Oil, Caramelised Onion (Onion, Sugar, White Wine Vinegar, Water, Rapeseed Oil, Cornflour, Salt, Garlic Purée, Black Pepper), Spirit Vinegar, Pasteurised Egg Yolk, Cornflour, Mustard Flour, Sugar, Salt, Concentrated Lemon Juice), Rocket (3%). Contains Barley, Eggs, Mustard, Wheat.'
        },
        {
            'id': 'uBaiXQPeqiIPx9ruZNia',
            'name': 'Tikka Chicken Sizzlers',
            'brand': 'Co-op',
            'serving_size_g': 175.0,  # Half of 350g pack
            'ingredients': 'Cooked Marinated Chicken Breast (54%) (Chicken Breast, Water, Tomato Purée, Tikka Curry Paste (Tomato Purée, Paprika, Garlic Purée, Ginger Purée, Rapeseed Oil, Spices (Coriander, Cumin, Turmeric, Fenugreek, Cinnamon, Ginger, Chilli Powder, Cloves, Cardamom), Salt, Acidity Regulator (Citric Acid)), Rapeseed Oil, Cornflour, Garlic Purée, Ginger Purée, Ground Cumin, Ground Coriander, Paprika, Turmeric, Garam Masala (Spices (Coriander, Cumin, Black Pepper, Cassia), Salt, Paprika, Garlic Powder, Ground Ginger, Chilli Powder), Chilli Powder, Salt), Red Onion (15%), Red Pepper (15%), Green Pepper (15%), Tikka Sauce (Water, Tomato Purée, Single Cream (Milk), Sugar, Rapeseed Oil, Cornflour, Tomato Paste, Tikka Curry Paste (Tomato Purée, Paprika, Garlic Purée, Ginger Purée, Rapeseed Oil, Spices (Coriander, Cumin, Turmeric, Fenugreek, Cinnamon, Ginger, Chilli Powder, Cloves, Cardamom), Salt, Acidity Regulator (Citric Acid)), Garlic Purée, Ginger Purée, Ground Cumin, Ground Coriander, Paprika, Garam Masala (Spices (Coriander, Cumin, Black Pepper, Cassia), Salt, Paprika, Garlic Powder, Ground Ginger, Chilli Powder), Turmeric, Salt, Chilli Powder). Contains Milk.'
        },
        {
            'id': 'ZXyg4yn1V95NnRQRiJwU',
            'name': 'Triple Chocolate Sundae',
            'brand': 'Co-op',
            'serving_size_g': 83.0,
            'ingredients': 'Chocolate Flavour Ice Cream (58%) (Skimmed Milk, Sugar, Glucose Syrup, Vegetable Fat (Coconut), Whey Powder (Milk), Emulsifier (Mono- and Di-Glycerides of Fatty Acids), Stabilisers (Locust Bean Gum, Guar Gum), Fat Reduced Cocoa Powder, Flavouring), Chocolate Sauce (25%) (Glucose Syrup, Water, Sugar, Fat Reduced Cocoa Powder, Cornflour, Cocoa Mass, Flavouring), White Chocolate Curls (9%) (Sugar, Cocoa Butter, Dried Whole Milk, Emulsifier (Soya Lecithin), Flavouring), Milk Chocolate Curls (8%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Emulsifier (Soya Lecithin), Flavouring). Contains Milk, Soya.'
        },
        {
            'id': '5H9MiqJCItxSX5vRQ7yR',
            'name': 'Vegetable Antipasti Pizza',
            'brand': 'Co-op',
            'serving_size_g': 236.0,
            'ingredients': 'Pizza Base (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Rapeseed Oil, Sugar, Salt, Flour Treatment Agent (Ascorbic Acid)), Mozzarella Cheese (Milk) (17%), Tomato Sauce (15%) (Tomato, Water, Tomato Purée, Rapeseed Oil, Cornflour, Garlic Purée, Salt, Basil, Black Pepper, Acidity Regulator (Citric Acid)), Chargrilled Courgette (6%), Red Pepper (6%), Yellow Pepper (5%), Chargrilled Aubergine (3%). Contains Milk, Wheat.'
        },
        {
            'id': '6FDCG6RCYjSn4qtIaVyL',
            'name': 'Irresistible Chicken Tikka Masala',
            'brand': 'Coop Irresistible',
            'serving_size_g': 400.0,
            'ingredients': 'Tomato (25%), Cooked Chicken Breast (21%) (Chicken Breast, Water, Rapeseed Oil, Cornflour, Ginger Purée, Garlic Purée, Spices (Turmeric, Cumin, Coriander, Fenugreek), Salt, Tomato Paste, Acidity Regulator (Citric Acid)), Single Cream (Milk) (11%), Onion (10%), Water, Greek Style Yogurt (Milk) (7%), Pilau Rice (7%) (Water, Long Grain Rice, Rapeseed Oil, Onion, Turmeric, Salt, Cumin Seeds, Bay Leaf, Black Cardamom, Green Cardamom, Cloves, Cinnamon), Tomato Purée (5%), Butter (Milk), Garlic Purée, Ginger Purée, Cornflour, Ground Almonds, Sugar, Rapeseed Oil, Cumin, Ground Coriander, Paprika, Garam Masala (Spices (Coriander, Cumin, Black Pepper, Cassia), Salt, Paprika, Garlic Powder, Ground Ginger, Chilli Powder), Turmeric, Fenugreek Leaf, Salt, Chilli Powder, Black Cardamom Powder. Contains Almonds, Milk.'
        },
        {
            'id': 'e0Dxb2KVI1Ej2ksK2q7j',
            'name': 'Wild Mushroom & Aubergine Lasagne',
            'brand': 'Cook',
            'serving_size_g': 350.0,
            'ingredients': 'Béchamel Sauce (Milk, Wheat Flour, Butter (Milk), Vegetarian Italian Hard Cheese (Milk), Nutmeg, Salt, Black Pepper), Aubergine (18%), Pasta Sheets (Durum Wheat Semolina, Pasteurised Egg), Portobello Mushrooms (10%), Chestnut Mushrooms (8%), Tomato Sauce (Tomatoes, Onion, Garlic, Basil, Olive Oil, Salt, Black Pepper), Onion, Single Cream (Milk), Butter (Milk), Dried Porcini Mushrooms (2%), Garlic, Olive Oil, Vegetarian Italian Hard Cheese (Milk), Thyme, Basil, Salt, Black Pepper. Contains Eggs, Milk, Wheat.'
        },
        {
            'id': 'FfykdwqU1CoTGUrzW7sr',
            'name': 'Salted Caramel, Chocolate & Honeycomb Cheesecake',
            'brand': 'Cook',
            'serving_size_g': 100.0,  # Per portion
            'ingredients': 'Cream Cheese (Milk) (32%), Double Cream (Milk), Digestive Biscuits (Wheat Flour, Vegetable Oil (Palm), Wholemeal Wheat Flour, Sugar, Partially Inverted Sugar Syrup, Raising Agents (Sodium Bicarbonate, Tartaric Acid, Malic Acid), Salt), Sugar, Salted Caramel (Glucose Syrup, Sweetened Condensed Milk (Milk, Sugar), Salted Butter (Milk, Salt), Water, Gelling Agent (Pectin), Salt, Natural Flavouring, Acidity Regulator (Sodium Citrate)), Honeycomb (5%) (Sugar, Glucose Syrup, Raising Agent (Sodium Bicarbonate)), Dark Chocolate (Cocoa Mass, Sugar, Fat Reduced Cocoa Powder, Emulsifier (Soya Lecithin)), Butter (Milk), Pasteurised Egg, Cornflour, Vanilla Extract, Chocolate Sauce (Sugar, Cocoa Powder, Cornflour), Gelatine (Beef), Salt. Contains Eggs, Milk, Soya, Wheat.'
        },
        {
            'id': 'QHmJpHE4BXbyEX7yp6YK',
            'name': 'Crab & Crayfish Raviolo',
            'brand': "Dell'ugo",
            'serving_size_g': 100.0,  # Per portion
            'ingredients': 'Fresh Pasta (49%) (Durum Wheat Semolina, Pasteurised Egg (21%), Water), Crab Meat (11%), Ricotta Cheese (Milk, Whey (Milk), Salt, Acidity Regulator (Citric Acid)), Mascarpone Cheese (Milk, Cream (Milk), Acidity Regulator (Citric Acid)), Crayfish Tail (5%), Breadcrumbs (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Yeast), White Wine, Single Cream (Milk), Butter (Milk), Lemon Juice, Garlic, Chives, Salt, Parsley, White Pepper, Dill. Contains Crustaceans, Eggs, Fish, Milk, Wheat.'
        },
        {
            'id': 'VT1sfVIiRb6lyMFv4t19',
            'name': 'Bombay Mix',
            'brand': 'Cofresh',
            'serving_size_g': 100.0,
            'ingredients': 'Gram Flour, Vegetable Oil (Rapeseed, Palm), Peanuts (11%), Green Peas, Potato Starch, Chickpea Flour, Lentils, Sultanas (Sultanas, Sunflower Oil), Cashew Nuts, Sugar, Salt, Onion Powder, Cumin Powder, Coriander Powder, Fennel Powder, Black Pepper, Turmeric, Garlic Powder, Chilli Powder, Citric Acid, Sodium Bicarbonate. Contains Peanuts, Cashew Nuts. May Contain Mustard.'
        },
        {
            'id': 'cwGIBTpMGGQyMTTqV0gk',
            'name': 'Popping Candy Easter Egg',
            'brand': 'Dairyfine',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (95%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Emulsifier (Soya Lecithin), Flavouring), Popping Candy (5%) (Sugar, Glucose Syrup, Carbon Dioxide). Milk Chocolate contains Cocoa Solids 30% minimum, Milk Solids 18% minimum. Contains Milk, Soya. May Contain Nuts, Wheat.'
        },
        {
            'id': 'SssISy5DzsbpwgnR88Fa',
            'name': 'Chocolate Gateau',
            'brand': 'Conditorei Coppenrath Wiese',
            'serving_size_g': 100.0,  # Per portion estimate
            'ingredients': 'Sugar, Pasteurised Egg, Wheat Flour, Vegetable Oils (Rapeseed, Palm), Water, Fat Reduced Cocoa Powder (5%), Glucose Syrup, Humectant (Glycerol), Cocoa Mass, Cocoa Butter, Emulsifiers (Mono- and Di-Glycerides of Fatty Acids, Soya Lecithin, Polyglycerol Esters of Fatty Acids), Wheat Starch, Raising Agents (Diphosphates, Sodium Carbonates), Skimmed Milk Powder, Whey Powder (Milk), Modified Starch, Flavouring, Acidity Regulator (Citric Acid), Thickener (Xanthan Gum), Salt, Milk Protein. Contains Eggs, Milk, Soya, Wheat.'
        },
        {
            'id': '0ONknJLyT03DgnRHi3zB',
            'name': 'Aberdeen Angus Steak & Caramelised Onion',
            'brand': 'Co-op',
            'serving_size_g': 211.0,
            'ingredients': 'Onion Bread (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Toasted Kibbled Onion, Yeast, Salt, Wheat Protein, Emulsifiers (Mono-and Diglycerides of Fatty Acids - Vegetable, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids - Vegetable), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Cooked Aberdeen Angus (24%) (Beef Topside, Salt, Stabilisers (Diphosphates, Triphosphates)), Balsamic Onion Chutney (9%) (Red Onion, Sugar, Balsamic Vinegar (White Wine Vinegar, Grape Must), White Wine Vinegar, Water, Molasses, Cornflour, Salt, Garlic Purée, Ginger Purée, Black Pepper), Miso Caramelised White Onions (7%) (White Onion, Miso Paste (Water, Soya Beans, Rice), Muscovado Sugar, Sunflower Oil, Salt), Rocket (6%), French Style Mayonnaise (4%) (Rapeseed Oil, Water, Free Range Egg Yolk (Egg Yolk, Salt), Spirit Vinegar, Sugar, Mustard Flour, Salt), Mayonnaise (Water, Rapeseed Oil, Pasteurised Egg Yolk (Egg Yolk, Salt), Spirit Vinegar, Sugar, Cornflour, Salt, Concentrated Lemon Juice). Contains Eggs, Mustard, Soya, Wheat.'
        },
        {
            'id': '7aharDy3pqY7yzYrtkXD',
            'name': 'Beetroot Falafel & Giant Cous Cous Salad',
            'brand': 'Co-op',
            'serving_size_g': 230.0,
            'ingredients': 'Cous Cous (33%) (Wheat Flour, Water), Beetroot (17%), Beetroot Falafel (17%) (Beetroot, Chick Peas, Onion, Potato Flakes, Red Pepper, Garlic Purée, Rapeseed Oil, Ground Cumin, Chilli, Ground Coriander, Lemon Juice, Paprika, Salt, White Pepper), Spicy Coconut Dressing (11%) (Coconut Milk (Coconut Extract, Water), Water, Harissa Paste (Spirit Vinegar, Ground Coriander, Red Chilli Purée, Red Pepper Purée, Garlic Purée, Water, Rapeseed Oil, Cumin, Muscovado Sugar, Salt, Caraway Seeds, Concentrated Lemon Juice), White Miso Glaze (White Miso Paste (Water, Soya Beans, Rice, Salt, Alcohol), Rice Vinegar, Mirin (Glutinous Rice, Water, Alcohol, Rice), Sugar, Ginger Purée), Concentrated Lemon Juice, Orange Zest, Maple Syrup, Cornflour, Roasted Garlic Purée, Chipotle Chilli Flakes, Roasted Ground Cumin), Black Beluga Lentils (8%), Black Rice (7%) (Rice, Water), Spinach, Balsamic Dressing (1%) (Balsamic Vinegar (Red Wine Vinegar, Grape Must Concentrate), Salt), Sweetened Dried Cranberries (Sugar, Cranberries, Sunflower Oil), Pumpkin Seeds. Contains Soya, Wheat.'
        },
        {
            'id': 'Fk2LPL6ZXLUSRZ8eWNxw',
            'name': 'Chicken Katsu Rice Bowl - Co Op',
            'brand': 'Co-op',
            'serving_size_g': 260.0,
            'ingredients': 'Cooked White Rice (38%) (Long Grain Rice, Water), Katsu Dressing (17%) (Water, Coconut Milk (Coconut, Water), Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol, Distilled Vinegar), Rapeseed Oil, Brown Sugar, Rice Vinegar, Ginger Purée, Cornflour, Madras Curry Paste (Water, Spices (Cumin, Ground Coriander, Turmeric, Cayenne Pepper, Ground Ginger, Paprika, Fenugreek, Nutmeg, Cinnamon, Cloves), Salt, Rapeseed Oil, Yeast Extract (Yeast Extract, Salt), White Wine Vinegar, Garlic Powder, Tomato Powder), Spices (Turmeric, Black Pepper, Ground Cumin, Cassia, Fennel, Ginger, Star Anise, Cloves), Vegetable Bouillion (Salt, Yeast Extract Powder, Sugar, Onion Powder, Potato Starch, Celery Seeds, Dried Yeast, Flavouring), Yeast Extract Powder, Garlic Purée, Salt, Tapioca Starch), Cooked Marinated Chicken (13%) (Chicken Breast, Sugar, Cornflour, Brown Sugar, Tomato Powder, Salt, Ginger Purée, Garlic Purée, Garlic Powder, Yeast Extract Powder, Burnt Sugar, Spices (Star Anise, Cinnamon, Fennel Seed, Black Pepper)), Pickled Red Cabbage, Carrot, Lettuce. Contains Celery, Soya, Wheat.'
        },
        {
            'id': '0nXQBnAcctZ9zP9nyBYP',
            'name': 'Meat Feast Pizza',
            'brand': 'Co-op',
            'serving_size_g': 160.0,  # Half of 356g pizza
            'ingredients': 'Pizza Base (42%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Rapeseed Oil, Sugar, Malted Wheat Flour, Salt, Malted Barley Flour), Tomato Sauce (23%) (Passata, Water, Tomato Purée, Basil, Garlic Purée, Cornflour, Salt, Black Pepper, Acidity Regulator (Citric Acid)), Mozzarella Cheese (Milk) (15%), Chilli Beef (8%) (Beef, Onion, Dextrose, Water, Cornflour, Spirit Vinegar, Tomato Paste, Paprika, Cumin, Onion Powder, Garlic Powder, Tomato Powder, Salt, Garlic Purée, Red Pepper, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cayenne Chilli Powder, Natural Flavourings, Ground Coriander, Malt Extract (Barley), Black Pepper, Raising Agent (Ammonium Carbonates)), Smoked Ham (8%) (Pork, Salt, Stabiliser (Triphosphates), Water, Preservative (Sodium Nitrite), Antioxidant (Sodium Ascorbate)), Pepperoni (4%) (Pork, Sea Salt, Salt, Dextrose, Antioxidants (Sodium Ascorbate, Rosemary Extract), Paprika Extract, Anise, Garlic, Pepper Extract, Ginger). Contains Barley, Milk, Wheat.'
        },
        {
            'id': '8oWXXo8EHQCzauZQRSx6',
            'name': 'No Turkey Feast',
            'brand': 'Co-op',
            'serving_size_g': 198.0,
            'ingredients': 'Wheat & Oatmeal Bread (45%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Oatmeal, Wheat Bran, Yeast, Salt, Wheat Protein, Emulsifiers (Mono- and Diglycerides of Fatty Acids - Vegetable, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids - Vegetable), Malted Barley Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Soya Protein Pieces (18%) (Water, Soya Protein (Soya Protein Isolate, Wheat Protein, Wheat Starch), Rapeseed Oil, Soya Protein Concentrate, Wheat Protein, Stabiliser (Methyl Cellulose), Thickener (Carrageenan), Flavourings, Yeast Extract, Sea Salt), Roast Seasoned Carrot & Parsnip (10%) (Carrot, Parsnip, Brown Sugar, Maple Syrup, Rapeseed Oil, Salt, Black Pepper), Cranberry Chutney (9%) (Cranberries, Plums, Water, Sugar, Red Wine Vinegar, Cornflour, Concentrated Plum Juice, Sweetened Dried Cranberries (Sugar, Cranberries, Sunflower Oil)), Vegan Seasoned Mayo (7%) (Water, Rapeseed Oil, Cornflour, Mushroom Stock (Mushroom Juice Concentrate, Salt, Sugar, Rapeseed Oil, Mushroom Powder (Maltodextrin, Mushroom Juice Powder)), Spirit Vinegar, Sugar, Yeast Extract (Yeast Extract, Water, Salt, Sugar), Concentrated Lemon Juice, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Pea Protein, Garlic Powder, Onion Powder, Black Pepper, Salt, Ground Paprika), Spinach (5%), Sage and Onion Oat Stuffing. Contains Barley, Mustard, Oats, Soya, Wheat.'
        },
        {
            'id': 'T3IfCYQPdIRjmpwE4c7l',
            'name': 'Mexican Smoky Fajita Kit',
            'brand': 'Capsicana',
            'serving_size_g': 56.9,  # Per serving (kit serves 4-6)
            'ingredients': 'Soft Flour Tortillas (72%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Sugar, Humectant (Glycerol), Spirit Vinegar, Raising Agents (Diphosphates, Sodium Carbonates), Palm Oil, Extra Virgin Olive Oil, Rapeseed Oil, Acidity Regulators (Malic Acid, Citric Acid), Emulsifier (Mono-and Di-Glycerides of Fatty Acids), Preservatives (Potassium Sorbate, Calcium Propionate), Salt, Stabiliser (Cellulose Gum), Wheat Starch, Flour Treatment Agent (L-Cysteine)), Chipotle Sizzle Paste (18%) (Tomato, Water, Honey, Spirit Vinegar, Sugar, Tomato Paste, Dextrose, Chilli Purée, Onion Purée, Salt, Red Pepper, Cornflour, Garlic Purée, Spices (Smoked Paprika, Chipotle Chilli (0.5%), Black Pepper), Herbs (Coriander, Oregano), Colour (Paprika Extract)), Chipotle Chilli Salsa Mix (10%) (Water, Amarillo Chilli Mash (Amarillo Chillies, Salt, Acetic Acid), Onion, Tomato Paste (10%), Dextrose, Garlic Purée, White Wine Vinegar, Brown Sugar, Spices (Chipotle Chilli (1.5%), Cumin), Salt, Cornflour, Herbs (Coriander, Oregano), Natural Flavouring). Contains Wheat.'
        },
        {
            'id': 'HCx3ekrlrA8ZJGjH6RtM',
            'name': 'Vegan Sausage And Cranberry Wreath',
            'brand': 'Deluxe',
            'serving_size_g': 62.0,  # Per serving estimate from 550g
            'ingredients': 'Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Fat Spread (Vegetable Oil (Palm, Rapeseed), Water, Salt, Emulsifier (Mono- and Diglycerides of Fatty Acids)), Dried Sweetened Cranberries (6%) (Cranberries (60%), Cane Sugar, Sunflower Oil), Rapeseed Oil, Textured Soya Protein Concentrate (6%), Wheat Gluten, Sage and Onion Stuffing (Rusk, Breadcrumbs, Dried Onion, Dried Sage, Salt, Raising Agent, Dried Parsley, Barley Malt Extract), Salt, Modified Maize Starch, Stabiliser (Methyl Cellulose), Dried Onion, Yeast Extract, Natural Flavouring, Ground Nutmeg, Ground White Pepper, Ground Cayenne Pepper, Dried Sage, Wheat Protein, Parsley Flavoured Breadcrumbs. Contains Barley, Soya, Wheat.'
        },
        {
            'id': 'CeeBLy5XqeVxZUTd96r6',
            'name': 'Baklava',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,  # Per portion estimate
            'ingredients': 'Cashew Baklava: Filo Pastry (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Glucose Syrup, Rapeseed Oil, Salt, Clarified Butter (Milk), Maize Starch), Invert Sugar Syrup, 25% Cashew Nuts, Butter Blend (Rapeseed Oil, Clarified Butter (Milk)), Sugar, Flavourings. Cashew Baklava Drizzled with Dark Chocolate: Filo Pastry (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Glucose Syrup, Rapeseed Oil, Salt, Clarified Butter (Milk), Maize Starch), Invert Sugar Syrup, 25% Cashew Nuts, Butter Blend (Rapeseed Oil, Clarified Butter (Milk)), 0.8% Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Emulsifiers (Soya Lecithin, Sorbitan Tristearate), Natural Vanilla Flavouring), Sugar, Flavouring. Cashew Assabee: Filo Pastry (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Glucose Syrup, Rapeseed Oil, Salt, Clarified Butter (Milk), Maize Starch), 26% Cashew Nuts, Invert Sugar Syrup, Butter Blend (Rapeseed Oil, Clarified Butter (Milk)), Sugar, Flavouring. Contains Cashew Nuts, Milk, Soya, Wheat.'
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

    print(f"✨ BATCH 24 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {166 + updates_made} / 681\n")
    print(f"🎯 MILESTONE: {200 - (166 + updates_made)} products until 200!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch24(db_path)
