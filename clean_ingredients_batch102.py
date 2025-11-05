#!/usr/bin/env python3
"""
Clean ingredients for batch 102 of messy products - MASSIVE BATCH (300 products!)
"""

import sqlite3
from datetime import datetime

def update_batch102(db_path: str):
    """Update batch 102 of products with cleaned ingredients (300 products!)"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 102: Products with cleaned ingredients (300 products - 6x previous batches!)
    clean_data = [
        {
            'id': 'H5PXdNzNVtLRxpd6F5Kt',
            'name': 'Piri Piri Chicken',
            'brand': 'The Gym Kitchen',
            'serving_size_g': 400.0,
            'ingredients': 'Cooked Brown Rice 25% (Water, Brown Rice), Cooked Marinated Chicken Breast 22% (Chicken Breast, Tomato Paste, Ginger Purée, Garlic Purée, Yogurt Powder (Milk), Cornflour, Green Chilli Purée, Salt, Chilli Powder, Fenugreek, Coriander Powder, Cumin Powder, Ginger Powder, Cinnamon Powder, Black Pepper, Mace, Star Anise, Turmeric, Basil Flakes, Paprika Extract), Broccoli 19%, Water, Carrots 8%, Tomatoes, Red Peppers, Onions, Garlic Purée, Red Quinoa 1%, Chilli Purée, Yellow Split Peas, Red Wine Vinegar, Sugar, Smoked Water, Cornflour, Tomato Paste, Rapeseed Oil, Salt, Pectin, Cumin Seeds, Smoked Paprika, Oregano, Coriander Powder, Chilli Powder, Black Pepper.'
        },
        {
            'id': 'H5sj0qqHBGoqdzlehwrf',
            'name': 'Smooth Chocolate Dessert',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Soya Beans (6%), Modified Maize Starch, Chocolate (2%) (Cocoa Powder, Cocoa Mass, Sugar), Cocoa Powder, Calcium Phosphates, Flavouring, Thickener (Pectins), Salt.'
        },
        {
            'id': 'H67IQM4xgeubWtflbuSl',
            'name': 'Crêpes Chocolate Hazelnut 6 X 180g',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Crêpe 56% (Wheat Flour, Whole Milk, Sugar, Whole Egg, Concentrated Butter from Milk, Stabilisers (Glycerol, Sorbitols), Dextrose, Salt), Chocolate and Hazelnut Filling 44% (Sugar, Vegetable Oil and Fat (Shea Fat, Sunflower Oil), Chocolate 11% (Fat Reduced Cocoa Powder, Sugar, Cocoa Paste), Dextrin, Fat Reduced Cocoa Powder, Lactose from Milk, Hazelnut Paste 3.4%, Skimmed Milk Powder, Emulsifier (Lecithins)).'
        },
        {
            'id': 'H6m6HUATyZ0couhrOv4I',
            'name': 'Duck Spring Rolls',
            'brand': 'Vitasia',
            'serving_size_g': 17.0,
            'ingredients': 'Spring Roll Pastry (Wheat Flour, Salt, Fully Refined Soya Bean Oil), 19% Duck Breast, Hoisin Sauce (Sugar, Honey, Rice Vinegar, Soybean Paste (Water, Soya Beans, Wheat, Salt), Modified Tapioca Starch, Salt, Apple Cider Vinegar, Ginger Powder, Five Spices (Fennel Powder, Coriander Powder, Star Anise, Cinnamon Powder, Clove Powder), Colour (Plain Caramel), Onion Powder, Maltose, Sesame Oil, Garlic Powder), Rice Flour, Carrots, Fully Refined Soya Bean Oil, Cabbage, Spring Onions, Corn Starch, Modified Tapioca Starch, Rice Vinegar, Potato Starch.'
        },
        {
            'id': 'H7Vow0AXD7WbzgP0f65h',
            'name': 'Easy Bake Spicy Cajun Chicken',
            'brand': 'Schwartz',
            'serving_size_g': 100.0,
            'ingredients': 'Spices (Paprika, Dried Garlic, Dried Chilli Pepper (7%), Cumin (6%), Allspice (5%), Cayenne Pepper, Thyme), Natural Flavourings, Salt, Sugar, Acid (Citric Acid), Rapeseed Oil, Anti-caking Agent (Silicon Dioxide), Colour (Paprika Extract).'
        },
        {
            'id': 'H84cudECFqG1y7iTgOWP',
            'name': 'Calorie Controlled Chicken, Broad Bean & Pea Risotto',
            'brand': 'Tesco',
            'serving_size_g': 385.0,
            'ingredients': 'Cooked Risotto Rice (Water, Risotto Rice, Salt), Chicken Breast 18%, Peas, Onion, Broad Beans 7%, Skimmed Milk, White Wine, Celery, Single Cream (Milk), Cornflour, Crème Fraîche (Milk), Grana Padano Cheese (Grana Padano Medium Fat Hard Cheese (Milk), Preservative (Egg Lysozyme)), Parsley, Garlic Purée, Salt, Potato Starch, Chicken Extract, Dextrose, Thyme, Mint, Sugar, Sunflower Oil, Ground White Pepper.'
        },
        {
            'id': 'H9HToXL1hkto7hbZJRC1',
            'name': 'T.sunblush Tomato Tomato And Garlic Flatbread',
            'brand': 'Tesco',
            'serving_size_g': 53.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Sunblush Tomato Relish (9%) (Water, Sugar, Sunblush Tomatoes (Tomato, Canola Oil, Salt, Garlic Powder, Oregano)), Tomato, Red Wine Vinegar, Cornflour, Apple, Dried Onion, Tomato Paste, Salt, Gherkin, Spirit Vinegar, Cayenne Pepper), Butter (Milk), Rapeseed Oil, Durum Wheat Semolina, Wheat Fibre, Sugar, Salt, Garlic, Yeast, Parsley, Buttermilk Powder (Milk), Concentrated Lemon Juice.'
        },
        {
            'id': 'H9oZElhU0ffDs40mXflM',
            'name': 'Deluxe French Onion & Red Wine Soup',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Water, 14% Onions, 4% Red Wine (contains Sulphites), Modified Maize Starch, Fried Onion Paste (Sugar, Water, Onions, Salt), Double Concentrated Tomato Purée, Sugar, Caramelised Sugar Syrup, Salt, Flavouring, Rapeseed Oil, Thickener (Guar Gum), Yeast Extract, Spices.'
        },
        {
            'id': 'HAA1rosCIyhtZdqNkQoV',
            'name': 'Sourdough',
            'brand': 'Warburtons',
            'serving_size_g': 60.0,
            'ingredients': 'Wheat Flour (Calcium, Iron, Niacin (B3), Thiamin (B1)), Water, Wheat Gluten, Salt.'
        },
        {
            'id': 'HBZ81Ru4V1OYwHQ6qhn9',
            'name': 'Southern Fried Chicken',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (71%), Southern Fried Style Breadcrumb Coating (26%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Rapeseed Oil, Sunflower Oil), Rice Flour, Salt, Wheat Starch, Fennel Powder, Black Pepper, Paprika Powder, White Pepper, Wheat Gluten, Yeast Extract, Onion Powder, Garlic Powder, Yeast, Black Pepper Extract, Thyme Extract, Dried Parsley, Dried Thyme), Water, Salt.'
        },
        {
            'id': 'HCRjcCqEcdnHdELrcaC5',
            'name': 'Seville Orange Marmalade',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Oranges, Lemon Juice from Concentrate, Gelling Agent (Pectins), Acidity Regulator (Sodium Citrates).'
        },
        {
            'id': 'HDCHJjIUh66DXZc0ryLm',
            'name': 'Food',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Vegetable Oils (Rapeseed, Palm), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Egg, Water, Glucose Syrup, Fat-Reduced Cocoa Powder, Humectant (Glycerol), Maize Starch, Cocoa Butter, Raising Agents (Diphosphates, Sodium Carbonates), Whole Milk Powder, Cocoa Mass, Preservative (Potassium Sorbate), Emulsifiers (Mono - and Diglycerides of Fatty Acids, Soya Lecithins), Whey Powder (Milk), Lactose (Milk), Flavouring, Caramelised Sugar Syrup, Skimmed Milk Powder, Dried Egg White.'
        },
        {
            'id': 'HDEUTI1hSqEE8ZlxJZFs',
            'name': 'Irish Latte',
            'brand': 'Nescafe',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Skimmed Milk Powder (20%), Coconut Oil, Coffee (7.5%) (Instant Coffee (7%), Roast and Ground Coffee), Lactose (from Milk), Natural Flavouring, Acidity Regulators (Sodium Bicarbonate, Citric Acid).'
        },
        {
            'id': 'HFeD7THEvvsttMo2Bij2',
            'name': 'Loaded Nacho Chips Chilli Beef',
            'brand': 'Seabrook',
            'serving_size_g': 100.0,
            'ingredients': 'Tortilla Chip (Corn, Pomegranate Extract, Rosemary Extract), Vegetable Oil (Rapeseed Oil, Sunflower Oil), Chilli Beef Seasoning 6% (Rice Flour, Sugar, Salt, Potassium Chloride, Yeast Extract, Spice (Cayenne Powder, Cumin Powder, Chilli Powder (Chilli, Cumin, Salt, Garlic Powder, Dried Oregano)), Flavourings, Onion Powder, Acid (Citric Acid), Garlic Powder, Spice Extract (Chilli, Cumin), Dried Parsley, Colour (Paprika Extract)).'
        },
        {
            'id': 'HFvWokX69sO4JUe3R00H',
            'name': 'French Vanilla Flavoured Coffee Capsules',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Arabica Coffee, French Vanilla Flavouring.'
        },
        {
            'id': 'HGG8LTC29DoqvjMsDPbt',
            'name': 'The Curators',
            'brand': 'Generic',
            'serving_size_g': 28.0,
            'ingredients': 'Beef (150g per 100g finished product), Salt, Dextrose, Coriander, Black Pepper, Nutmeg, Clove, Garlic, Chilli, Preservatives (Sodium Nitrite, Sodium Nitrate).'
        },
        {
            'id': 'HGGUW2kStrZhoStdEmh0',
            'name': 'Creamy Tomato Pasta Sauce',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomato Purée Concentrate (12%), Tomatoes (9%), Rapeseed Oil, Modified Maize Starch, Medium Fat Soft Cheese (Milk) (2%), Sugar, Chopped Onions, Single Cream (Milk), Salt, Stabiliser (Xanthan Gum), Acidity Regulator (Citric Acid), Egg Yolk Powder, Garlic Purée, Yeast Extract, Maltodextrin, Flavouring.'
        },
        {
            'id': 'HGvvQJe6i4wT1nNJS9va',
            'name': 'Squares',
            'brand': 'Walkers',
            'serving_size_g': 25.0,
            'ingredients': 'Potato Granules, Sunflower Oil, Potato Starch, Cheese & Onion Flavour (Whey Permeate from Milk, Salt, Sugar, Flavouring (contains Milk), Rice Flour, Onion Powder, Acidity Regulators (Citric Acid, Malic Acid), Whey Protein (contains Milk), Garlic Powder, Cheese Powder (from Milk), Whey Milk Powder, Colour (Annatto, Paprika Extract), Maltodextrin, Skimmed Milk Powder).'
        },
        {
            'id': 'HHcZCmo7e2mOzl5D8i3F',
            'name': 'Organic Pizza Bases Wheat',
            'brand': 'Biona Wind Mill Organic Ltd',
            'serving_size_g': 300.0,
            'ingredients': 'Whole Wheat Flour (30%), Wheat Flour (30%), Water, Yeast, Extra Virgin Olive Oil, Salt, Wheat Sourdough.'
        },
        {
            'id': 'HHnZCO6SXgOT8bJsuoqj',
            'name': 'Teeth & Lips',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Water, Pork Gelatine, Acidity Regulator (Citric Acid), Concentrated Grape Juice, Colour (Anthocyanins), Flavouring, Coconut Oil.'
        },
        {
            'id': 'HJAtDAU1NsC1re0BmHyL',
            'name': 'Tuna Chunks In Spring Water',
            'brand': 'The Fishmonger',
            'serving_size_g': 102.0,
            'ingredients': 'Skipjack Tuna (Fish), Spring Water, Salt.'
        },
        {
            'id': 'HJhGCEfsXomm72xLO6hv',
            'name': 'Katsu Curry Flavour Chickpea Chips',
            'brand': 'Proper Chips',
            'serving_size_g': 100.0,
            'ingredients': 'Chickpea Flour (24%), Rapeseed Oil, Potato Starch, Rice Flour, Katsu Curry Flavour (8%) (Rice Flour, Spices (Turmeric, Smoked Paprika, Cumin, Cayenne Pepper, Coriander Seed, Ginger, Clove), Sugar, Onion Powder, Salt, Garlic Powder, Yeast Extract Powder, Tomato Powder, Acidity Regulator (Citric Acid), Natural Flavouring, Fenugreek Leaf, Colour (Paprika Extract)), Potato Fibre, Corn Flour, Potassium Chloride, Salt.'
        },
        {
            'id': 'HKFPDoRsG0UTqe8Hkwm6',
            'name': 'Summer Pudding',
            'brand': 'Waitrose',
            'serving_size_g': 150.0,
            'ingredients': 'Blackberries (20%), Water, Raspberries (10%), Strawberries (10%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Blackcurrants, Apple Purée, Blackcurrant Purée, Blackberry Purée, Redcurrant Purée, Orange Concentrate, Raspberry Purée, Yeast, Salt, Preservative (Potassium Sorbate), Palm Oil (Certified Sustainable), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'HKi3OMPMOx1pyXEzIJ2O',
            'name': 'Pistachios With Milk Chocolate',
            'brand': 'Italiamo',
            'serving_size_g': 25.0,
            'ingredients': '70% Milk Chocolate Coating (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Whey Powder (Milk), Emulsifiers (Lecithins, Polyglycerol Polyricinoleate), Flavouring), 22% Pistachio Nuts, Sugar, Glucose Syrup, Glazing Agents (Gum Arabic, Shellac).'
        },
        {
            'id': 'HKlM9thYSMTIXsKCYO1U',
            'name': 'Tandoori Rice Chicken Bowl',
            'brand': 'Tesco',
            'serving_size_g': 240.0,
            'ingredients': 'Cooked Long Grain Rice (Water, Long Grain Rice), Chicken Breast (13%), Chickpeas, Green Lentils, Water, Onion, Spinach, Roasted Red Pepper, Red Cabbage, Coriander, Rapeseed Oil, Sugar, Low Fat Yogurt (Milk), Tomato Paste, Beetroot, Red Onion, Spices, Cider Vinegar, Cornflour, Mango, Red Wine Vinegar, Ginger Purée, Garlic Purée, Carrot, Petit Pois, Malt Vinegar (Barley), Salt, Ginger Paste, Apple, Apricot, Spirit Vinegar, Garlic Paste, Soya Oil, Concentrated Lemon Juice, Mint, Yogurt Powder (Milk), Pasteurised Egg, Pasteurised Egg Yolk, White Wine Vinegar, Red Chilli Purée, Dried Onion, Green Chilli Purée, Ginger, Colour (Paprika Extract), Nigella Seeds, Sunflower Oil, Gelling Agent (Pectin), Garlic Powder, Brown Mustard Seeds, Acidity Regulator (Citric Acid), Antioxidant (Ascorbic Acid), Basil.'
        },
        {
            'id': 'HMtYq8fwSUWpODcF0NfI',
            'name': 'Max Double Crunch Bold BBQ Ribs',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in varying proportions), Bold BBQ Ribs Seasoning (Flavourings, Sugar, Wheat Flour, Salt, Smoke, Glucose, Acid (Citric Acid), Spices, Garlic Powder, Onion Powder, Colour (Paprika Extract), Smoke Flavouring).'
        },
        {
            'id': 'HNkTi3QvEOfMKX4MHQmP',
            'name': 'Fruit Shortcake Biscuits',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Sugar, Currants (10%), Sunflower Oil, Oatmeal, Glucose Syrup, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate, Disodium Diphosphate), Partially Inverted Sugar Syrup, Salt, Flavouring, Colour (Curcumin).'
        },
        {
            'id': 'HNnTWl6aViqvuivW8kMH',
            'name': 'Mozzarella Sticks',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Mozzarella Stick Filling (Mozzarella Cheese (73%) (Milk), Water, Dried Potato, Potato Starch, Thickener (Methyl Cellulose)), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Sunflower Oil, Wheat Starch, Cornflour, Rice Flour, Yeast, Salt, Paprika, Pasteurised Dried Egg Powder. Tomato and Herb Dip: Tomato Paste, Water, Tomato, White Wine Vinegar, Sugar, Onion, Rapeseed Oil, Red Wine, Spirit Vinegar, Cornflour, Basil, Garlic Purée, Oregano, Salt, Lemon Juice from Concentrate, Black Pepper, Preservative (Sulphites).'
        },
        {
            'id': 'HPAR1M07HJqqvO8XTyhn',
            'name': 'Scottish Salmon En Croute',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Salmon, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Palm Oil (Certified Sustainable), Whole Milk, Whipping Cream, Watercress, Cheddar Cheese, Cornflour, Lemon Zest, Salt, Tarragon, Butter, Sea Salt, Emulsifier (Mono - and Diglycerides of Fatty Acids), White Pepper.'
        },
        {
            'id': 'HSgwhgQlwfKgFI3zPz7r',
            'name': 'Original Scratching Double Cooked',
            'brand': 'The Real Pork Crackling Co',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Rind, Seasoning (Salt, Flavour Enhancer (Monosodium Glutamate), Hydrolysed Soya Protein, Rusk (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin, Salt)), Sugar.'
        },
        {
            'id': 'HTMvFZnMO6tEgZchEcMa',
            'name': 'Dry Cured Ham',
            'brand': 'Tesco',
            'serving_size_g': 24.0,
            'ingredients': 'Pork, Salt, Brown Sugar, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': 'HV2fNZG1ANz6nXz1Nkky',
            'name': 'Le Justin',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (origin: EU), Salt, Lactose (Milk), Dextrose, Spices, Sugar, Preservatives (Potassium Nitrate, Sodium Nitrite), Starter Cultures.'
        },
        {
            'id': 'HWQMW2BsaNl6EpIsemYi',
            'name': 'Mini Eggs Ultimate Egg',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Milk, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Whey Permeate Powder from Milk, Vegetable Fats (Palm, Shea), Milk Fat, Modified Starches (Maize, Tapioca), Emulsifiers (E442, E476), Flavourings, Maltodextrin, Colours (Anthocyanins, Beetroot Red, Paprika Extract, Carotenes).'
        },
        {
            'id': 'HXOQVCu5r1U9G5CV9nAW',
            'name': 'Smooth Orange Chocolate',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Cocoa Butter, Cocoa Mass, Milk Fat, Palm Fat, Lactose, Whey Permeate (from Milk), Emulsifier (Soya Lecithin), Natural Orange Flavouring, Vanilla Extract.'
        },
        {
            'id': 'HXoGg07p8gkAKh6enX6T',
            'name': 'Whey Protein Strawberry',
            'brand': 'Muscle Moose',
            'serving_size_g': 45.0,
            'ingredients': 'Whey Protein Concentrate (Milk), Emulsifier (Sunflower Lecithin), Soy Protein Isolate, Flavouring, Colour (Beetroot Red), Sodium Chloride, Citric Acid, Thickener (Xanthan Gum), Sweeteners (Sucralose, Acesulfame Potassium).'
        },
        {
            'id': 'HZZUy021rxq6qxmLI8WZ',
            'name': 'Diet Lemonade',
            'brand': 'Lidl',
            'serving_size_g': 200.0,
            'ingredients': 'Water, Carbon Dioxide, Acid (Citric Acid), Natural Lemon Flavouring with other Natural Flavourings, Sweeteners (Cyclamates, Acesulfame K, Aspartame, Saccharins).'
        },
        {
            'id': 'HZs2QsqFdqi7Ow5Vh7Mi',
            'name': 'Wholemeal Large Baps',
            'brand': 'Asda Bakery',
            'serving_size_g': 95.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Palm Oil, Dextrose, Wheat Flour, Yeast, Salt, Spirit Vinegar, Fermented Wheat Flour, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Malted Barley Flour, Emulsifier (Mono - and Diacetyl Tartaric Acid Esters of Mono and Diglycerides of Fatty Acids), Deactivated Yeast, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'Hb65EiBRvliNABnFT8uY',
            'name': 'Mash',
            'brand': 'Tesco',
            'serving_size_g': 213.0,
            'ingredients': 'Potato (40%), Carrot (36%), Swede (13%), Butter (Milk), Whole Milk, Single Cream (Milk), Salt, White Pepper.'
        },
        {
            'id': 'Hc6A7sHI2obkjlm0m7f1',
            'name': 'Brioche',
            'brand': 'Aldi',
            'serving_size_g': 35.0,
            'ingredients': 'Wheat Flour, Water, Sugar, Palm Fat, Pasteurised Egg, Whole Milk Powder (1.5%), Yeast, Flavourings, Emulsifiers (Mono and Diglycerides of Fatty Acids), Salt, Thickener (Cellulose Gum), Wheat Gluten, Milk Proteins, Colour (Carotenes), Antioxidant (Ascorbic Acid).'
        },
        {
            'id': 'HcR41Yykh7xf20dat2C9',
            'name': 'Aldi Strawberry Pudding',
            'brand': 'Dreamy Delish',
            'serving_size_g': 92.0,
            'ingredients': 'Sugar, Modified Maize Starch, Glucose Syrup, Fully Hydrogenated Palm Kernel Oil, Palm Kernel Oil, Gelling Agents (Diphosphates, Sodium Phosphates), Maltodextrin, Emulsifiers (Acetic Acid Esters of Mono - and Diglycerides of Fatty Acids, Mono-and Diglycerides of Fatty Acids), Flavouring, Milk Protein, Red Beet Juice Concentrate, Strawberry Juice Concentrate, Stabiliser (Potassium Phosphates).'
        },
        {
            'id': 'HcvtW2yuwuiUWk1Iqemd',
            'name': 'Seeded Bread',
            'brand': 'The Health Menu',
            'serving_size_g': 40.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Mixed Seeds (9%) (Brown Linseeds, Sunflower Seeds, Pumpkin Seeds, Poppy Seeds, Golden Linseeds, Millet), Wheat Protein, Yeast, Pulse Blend (2%) (Green Split Peas, Chickpea Flour, Broad Bean Protein, Red Lentil Protein, Red Split Lentils, Kibbled Chickpeas), Fermented Wheat Flour, Salt, Vegetable Oils and Fat (Rapeseed Oil, Palm Fat, Palm Oil), Spirit Vinegar, Soya Flour, Emulsifier (Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Dextrose, Malted Barley Flour, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'HdqwGpnbzKshymLsI25E',
            'name': 'Raspberry Flavour Jelly',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Gelatine, Colour (Beetroot Red), Flavourings, Citric Acid, Acidity Regulator (Sodium Citrate), Sweetener (Sucralose), Malic Acid.'
        },
        {
            'id': 'HeNa2gQ3zmN5Zdu5vbO3',
            'name': 'Light Chocolate Fix Layers',
            'brand': 'Müller',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Skimmed Milk from Concentrate, Sugar, Modified Maize Starch, Belgian Milk Chocolate (3%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Cream (Milk), Fat Reduced Cocoa Powder, Stabilisers (Pectins, Carob Bean Gum), Flavourings, Caramel Syrup, Salt, Sweeteners (Aspartame, Acesulfame K).'
        },
        {
            'id': 'HekSoJezx6VJhNvJA3yP',
            'name': 'Frosted Flakes',
            'brand': 'Morrisons',
            'serving_size_g': 30.0,
            'ingredients': 'Maize, Sugar, Salt, Barley Malt Extract, Iron, Niacin, Pantothenic Acid (B5), Vitamin B6, Riboflavin (B2), Thiamin (B1), Folic Acid, Vitamin D, Vitamin B12.'
        },
        {
            'id': 'HhxXTj9nkTqCxnz3Cq6I',
            'name': '4 Carrot Cake Cupcakes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Yellow Coloured Vanilla Flavour Frosting (40%) (Sugar, Palm Oil, Rapeseed Oil, Dried Glucose Syrup, Humectant (Glycerol), Flavouring, Emulsifier (Mono-and Diglycerides of Fatty Acids), Colour (Lutein)), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Rapeseed Oil, Coconut Extract, Carrot Purée, Cider Vinegar, Humectant (Glycerol), Flavouring, Raising Agents (Sodium Bicarbonate, Potassium Hydrogen Carbonate, Disodium Diphosphate, Monocalcium Phosphate), Preservatives (Potassium Sorbate, Calcium Propionate), Colours (Plain Caramel, Riboflavin, Beetroot Red), Coriander, Dried Glucose Syrup, Lemon Juice from Concentrate, Palm Oil, Trehalose, Salt, Cinnamon, Stabiliser (Xanthan Gum), Maize Starch, Ginger, Cardamom, Clove, Fennel, Nutmeg, Emulsifier (Lecithins), Spirulina Concentrate.'
        },
        {
            'id': 'HihEQcnvb0ayuIljjV1d',
            'name': 'Sticky Toffee Loaf',
            'brand': 'Soreen',
            'serving_size_g': 52.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Water, Chopped Dates (5%) (Dates, Rice Flour), Toffee Flavoured Caramel Nuggets (5%) (Sugar, Caramel, Water, Lemon Juice from Concentrate, Pectin, Natural Flavour, Salt, Potassium Citrate), Maize Starch, Partially Inverted Sugar Syrup (Partially Inverted Sugar Syrup, Colour (E150c)), Sugar, Malted Barley Flour, Date Purée, Vegetable Fats (Rapeseed, Palm), Salt, Chicory Root Fibre, Natural Flavouring, Preservative (Calcium Propionate), Yeast.'
        },
        {
            'id': 'Hj9mzsQLa9eFoYxwPJJF',
            'name': 'Aromatic Half Crispy Duck With Pancakes And Sauce',
            'brand': 'Golden Lion',
            'serving_size_g': 40.0,
            'ingredients': 'Aromatic Duck 61% (Duck, Sugar, Rice Wine, Wheat, Salt, Spring Onion, Cinnamon, Fennel, Dried Szechwan Pepper, Ginger Powder, Star Aniseed, Dried Black Pepper, Cloves, Orange Peel, Cardamom), Pancakes (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Nicotinamide, Thiamine Hydrochloride), Water, Rapeseed Oil, Potato Starch, Salt), Hoisin Sauce (Water, Sugar, Rice Wine Vinegar, Soya Bean, Maize Starch, Salt, Glutinous Rice, Barley Malt Extract, Cayenne, Garlic Puree, Fennel, Alcohol, Glucose Syrup, Rice, Cinnamon, Black Pepper, Star Anise, Wheat Flour, Clove).'
        },
        {
            'id': 'HjTH2SZrmOeeo68q9lFL',
            'name': 'Crunchy Oats & Honey Granola Bars',
            'brand': 'Harvest Morn',
            'serving_size_g': 42.0,
            'ingredients': 'Wholegrain Oat Flakes (62%), Sugar, Sunflower Oil, Honey (2%), Salt, Molasses, Raising Agent (Sodium Carbonates), Emulsifier (Lecithins (Sunflower)).'
        },
        {
            'id': 'HkbvNKIqI37VwlDDldfB',
            'name': 'Welsh Breakfast Marmalade',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Oranges, Molasses, Acidity Regulator (Citric Acid), Gelling Agent (Fruit Pectin).'
        },
        {
            'id': 'Hl8rqTxLqgQBkfdAKIPi',
            'name': '6 Milk Chocolate Rice Cakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate 60% (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Anhydrous Milk Fat, Emulsifiers (Soya Lecithins, Polyglycerol Polyricinoleate), Flavouring), Brown Rice, White Rice.'
        },
        {
            'id': 'HlIcpWBTYlP0cKKRPVu0',
            'name': 'Galaxy Orange Brownie Mix',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (with added Calcium, Iron, Niacin, Thiamine), Milk Chocolate (8%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey (Milk), Palm Fat, Whey Powder (Milk), Milk Fat, Emulsifier (Soya Lecithin), Vanilla Extract), Cocoa Powder (7%), Whey Permeate (Milk), Maize Starch, Anti Caking Agent (E551), Raising Agents (E450, E500, E341), Natural Flavouring, Salt.'
        },
        {
            'id': 'HlScBza3oN4bz5wm2fOO',
            'name': 'Choc Orange Rocky Road',
            'brand': 'Gro',
            'serving_size_g': 100.0,
            'ingredients': 'Dark Chocolate (42% Cocoa) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Lecithins (Soya)), Flavouring), Biscuit Pieces 23% (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Rapeseed), Sugar, Wholemeal Wheat Flour, Invert Sugar Syrup, Raising Agents (Sodium Hydrogen Carbonate, Ammonium Carbonates), Salt), Vegetable Oils (Palm, Rapeseed, Sunflower), Pink Mallows 6% (Glucose-Fructose Syrup, Sugar, Water, Dextrose, Gelling Agent (Carrageenan), Maize Starch, Rice Protein, Flavouring, Stabiliser (Polyphosphates), Colour (Beetroot Red)), Sultanas 6%, Invert Sugar Syrup, Orange Pieces 2% (Fruit Concentrates (Apple, Orange), Humectant (Glycerol - Vegetable), Fructose-Glucose Syrup, Glucose Syrup, Wheat Fibre, Sugar, Palm Fat, Rice Starch, Acidity Regulators (Citric Acid, Ascorbic Acid), Gelling Agent (Pectin), Flavouring, Colour (Curcumin), Water, Emulsifier (Mono - and Diglycerides of Fatty Acids - Vegetable), Orange Oil).'
        },
        {
            'id': 'Hgltcj BfFiTXlbHzMYfO',
            'name': 'Kinder Country 23.5g',
            'brand': 'Kinder',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate, Cereals.'
        },
        {
            'id': 'Hmp7RXpXBiM51MZTxzBg',
            'name': 'Garlic & Herb Cheese Bites',
            'brand': 'Crestwood',
            'serving_size_g': 17.0,
            'ingredients': 'Cream Cheese (Milk) 45%, Wheat Flour, Water, Garlic 8%, Rapeseed Oil, Modified Potato Starch, Chives 1.5%, Rye Flour, Wheat Fibre, Salt, Potato Starch, Garlic Powder, Potato Flakes, Spice Extract, Yeast, Sugar, Rice Flour, Paprika Powder, Turmeric, White Pepper.'
        },
        {
            'id': 'HmzsxpQMPhgjKk6e8udL',
            'name': 'Gressini Breadsticks',
            'brand': 'Morrisons',
            'serving_size_g': 7.0,
            'ingredients': 'Wheat Flour, Olive Oil (7%), Yeast, Barley Malt Extract, Salt.'
        },
        {
            'id': 'HneWgmLNTfmmoXbAjIVp',
            'name': 'Cheese & Onion Gruffalo Claws',
            'brand': 'Organix',
            'serving_size_g': 100.0,
            'ingredients': 'Corn, Sunflower Oil, Cheese Powder (Milk) (Mature Cheddar Cheese (Milk) 50%, Skimmed Milk Powder 50%), Onion Powder (contains Rice Flour) 2.0%, Thiamin (Vitamin B1) <0.1%.'
        },
        {
            'id': 'Ho4PGHWkpHEgCXvlnMwV',
            'name': 'Tapas Selection',
            'brand': 'Dulano',
            'serving_size_g': 30.0,
            'ingredients': 'Jamón Serrano Air Dried Cured Ham (Pork, Salt, Sugar, Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Potassium Nitrate)), Chorizo Extra Air Dried Cured Pork Sausage (Pork, Pork Fat, Salt, Milk Protein, Paprika, Maltodextrin, Dextrose, Flavourings, Spices, Stabilisers (Diphosphates, Polyphosphates), Antioxidant (Sodium Ascorbate), Preservatives (Sodium Nitrite, Potassium Nitrate, Natamycin, Potassium Sorbate), Colours (Carmine, Paprika Extract)), Chorizo Pamplona Air Dried Cured Pork Sausage (Pork, Pork Fat, Salt, Maltodextrin, Spices, Skimmed Milk Powder, Dextrose, Milk Protein, Stabilisers (Diphosphates, Polyphosphates), Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Colour (Carmine), Preservatives (Sodium Nitrite, Potassium Nitrate, Natamycin, Potassium Sorbate)).'
        },
        {
            'id': 'HoEFCYuZKt1PaTkLn0ki',
            'name': 'Asda Madras Sauce',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato Purée from Concentrate (30%), Water, Tomatoes (22%), Onions (10%), Rapeseed Oil, Sugar, Modified Maize Starch, Coriander Leaf, Ground Cumin, Chili Powder, Garlic Purée, Ginger Purée, Dried Onion, Salt, Concentrated Lemon Juice, Cumin Seeds, Onion Purée, Acidity Regulators (Citric Acid, Acetic Acid), Ground Ginger, Mustard Seeds, Dried Chillies, Ground Cardamom, Ground Coriander, Paprika, Fenugreek, Ground Black Pepper, Black Onion Seeds, Allspice, Ground Nutmeg, Mate, Ground Cassia, Dried Herbs, Garlic Powder, Ground Fennel, Ground Cloves.'
        },
        {
            'id': 'HoavS5oa8gsfhd3BXhGA',
            'name': 'Luxury Mincemeat',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sultanas (23%), Glucose Syrup, Apple Purée, Currants (10%), Glacé Cherries (7%) (Cherries, Glucose Syrup, Sugar, Colour (Anthocyanins from Red Cabbage)), Brandy (4.5%), Port (2.5%), Raisins (2.5%), Sugar, Almonds (2.5%), Palm Oil, Orange Peel, Rice Flour, Acidity Regulator (Citric Acid, Acetic Acid), Sunflower Oil, Lemon Juice, Treacle, Ground Spices (Cinnamon, Nutmeg), Glucose-Fructose Syrup, Lemon Peel.'
        },
        {
            'id': 'HroGtwRPiEsgxyHi6LAI',
            'name': 'Milk Chocolate Digestive',
            'brand': 'Müller',
            'serving_size_g': 124.0,
            'ingredients': 'Yogurt (Milk), Sugar, Water, Wheat Flour (Gluten) (with added Calcium, Iron, Niacin, Thiamin), Cocoa Butter, Milk Powder, Coconut Oil, Wholemeal Wheat Flour, Barley Flour, Barley Malt Extract, Modified Starch, Cocoa Mass, Whey Powder (Milk), Lactose (Milk), Flavourings, Glazing Agents (Acacia Gum, Shellac), Glucose Syrup, Molasses, Emulsifier (Soya Lecithin), Skimmed Milk Powder, Salt, Treacle, Stabiliser (Pectins).'
        },
        {
            'id': 'HrqchVu8CjRncB6pOyNB',
            'name': '4 Blueberry Pancakes',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour, Water, Pasteurised Free Range Egg, Blueberries (10%), Sugar, Rapeseed Oil, Humectant, Dried Buttermilk (5%), Fermented Wheat Flour, Raising Agents, Flavouring, Salt, Preservative.'
        },
        {
            'id': 'HsbozMeU6qWfTFWWkTWD',
            'name': '01 1 Aug £3.30 Refrigerated SIC Veggie SU',
            'brand': 'Tesco',
            'serving_size_g': 135.0,
            'ingredients': 'Cooked White Sushi Rice (Water, White Rice, Sugar, Spirit Vinegar, Rice Vinegar, Salt, Rapeseed Oil, Fructose-Glucose Syrup, Cane Molasses), Chicken Breast 6%, Pepper, Carrot, Edamame Soya Beans, Wheat Flour, Soy Sauce (Water, Soya Bean, Salt, Rice Vinegar), Nori Seaweed, Rapeseed Oil, Sugar, White Sesame Seeds, Chive, Palm Oil, Black Sesame Seeds, Modified Tapioca Starch, Red Pepper Flakes, Cornflour, Salt, Corn Starch, Soya Beans, Wheat Gluten, Wheat, Spirit Vinegar, Yeast Extract, Onion, Yeast Extract Powder, Glucose Syrup, Acidity Regulators (Citric Acid, Acetic Acid, Lactic Acid), Garlic, Potato Starch, Colours (Plain Caramel, Paprika Extract, Curcumin), Caramelised Sugar Syrup, Turmeric, Rice Wine, Yeast, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Coriander, Cumin, Fenugreek, Concentrated Lemon Juice, Stabilisers (Xanthan Gum, Guar Gum), Fully Refined Soybean Oil, Fennel, Ginger, Rice Vinegar, Cinnamon, Nutmeg, Star Anise, Chilli Flakes, Black Pepper, Cardamom, Clove, Chilli Powder, Bay Leaf, Allspice, Black Treacle, Paprika.'
        },
        {
            'id': 'HwUohKow5WqZWTuTJnvt',
            'name': 'High Protein Tortilla',
            'brand': 'M&S',
            'serving_size_g': 61.0,
            'ingredients': 'Wheat Flour (contains Gluten) (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Pea Protein Isolate (7%), Wheat Protein (contains Gluten) (3.5%), Rapeseed Oil, Wheat Gluten, Humectant (Glycerol), Raising Agents (E450, Sodium Bicarbonate), Vinegar, Dried Fermented Wheat Flour (contains Gluten), Emulsifier (E471), Acidity Regulator (Citric Acid), Salt, Wheat Starch (contains Gluten), Yeast (Yeast, Vitamin D).'
        },
        {
            'id': 'HwamcA1kMYGgY5r72XE0',
            'name': 'Crumbed Wiltshire Cured Ham',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Gluten Free Breadcrumbs (Rice Flour, Gram Flour, Maize Starch, Salt, Colours (Paprika Extract, Curcumin)), Dextrose, Salt, Pork Gelatine, Preservatives (Sodium Nitrite, Potassium Nitrate).'
        },
        {
            'id': 'HwhouaEUgLgY85TNWZQ8',
            'name': 'Squirty Cream 30% Less Fat',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (Milk) (97%), Sugar (4%), Emulsifiers (Mono - and Diglycerides of Fatty Acids, Lactic Acid Esters of Mono - and Diglycerides of Fatty Acids), Stabiliser (Carrageenan), Propellant Gas (Nitrous Oxide).'
        },
        {
            'id': 'Hxqlmnhp5ssUXeb6i77H',
            'name': 'Malteasers Dark',
            'brand': 'Maltesers',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Sugar, Glucose Syrup, Barley Malt Extract, Skimmed Milk Powder, Fat-Reduced Cocoa Powder, Palm Fat, Cocoa Butter, Wheat Flour, Glazing Agents (Gum Arabic, Zein), Palm Kernel Fat, Raising Agents (E341, E500, E501), Palm Kernel Oil, Wheat Gluten, Emulsifier (Soya Lecithin), Whey Powder (from Milk), Natural Vanilla Flavouring, Salt, Humectant (Glycerol).'
        },
        {
            'id': 'HyR0h4oddmU0bZedEKw4',
            'name': 'Cola Bottles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Modified Potato Starch, Acids (Citric Acid, Malic Acid, Lactic Acid), Modified Pea Starch, Modified Tapioca Starch, Caramelised Sugar Syrup, Flavouring, Sunflower Oil, Glazing Agent (Carnauba Wax).'
        },
        {
            'id': 'HzFgLguyVwX0ja8s6r3z',
            'name': 'Sweet Potato & Bean Chilli With Mexican Rice',
            'brand': 'Charlie Bigham\'s',
            'serving_size_g': 420.0,
            'ingredients': 'Cooked Rice (Water, Rice), Tomatoes, Sweet Potatoes 7%, Cheddar Cheese (Milk), Black-Eye Beans 4%, Red Kidney Beans 4%, Onions, Rapeseed Oil, Carrots, Sweetcorn, Black Turtle Beans 2%, Celery, Lemon Juice, Cornflour, Salt, Honey, Sunflower Oil, Red Pepper Flakes, Mushroom Stock (Mushroom Concentrate, Dried Mushrooms, Cornflour, Salt), Cocoa Powder, Garlic Purée, Chipotle Peppers, Parsley, Ground Cumin, Lime Zest, Spirit Vinegar, Sugar, Paprika, Ground Coriander, Ground Chillies, Spices, Dried Oregano, Tomato Paste, Ground Cinnamon.'
        },
        {
            'id': 'HziZQbXuePrQPecw896Y',
            'name': 'Rowse',
            'brand': 'Rowse',
            'serving_size_g': 100.0,
            'ingredients': 'Honey.'
        },
        {
            'id': 'HznuFz6Dm0kA4LFs2T4j',
            'name': 'Oats Your Way. Blueberry',
            'brand': 'Nairn\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Wholegrain Oats (91%), Sugar, Freeze Dried Blueberries (1%), Natural Flavourings.'
        },
        {
            'id': 'Hzrs2mnUuFrlXzhdgNrE',
            'name': 'Yorkshire Puddings',
            'brand': 'Aunt Bessie\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Whole Egg, Egg White, Rapeseed Oil, Water, Skimmed Milk Powder, Salt.'
        },
        {
            'id': 'HzxDboaSnY5Zb7CLEcFU',
            'name': 'Chicken Satay Skewers',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken 72%, Peanut Dip 20% (Water, Coconut Cream, Peanut Paste, Onion, Garlic, Spices, Sugar, Sunflower Oil, Lime Leaves, Salt, Modified Maize Starch, Palm Sugar, Concentrated Lemon Juice, Molasses, Emulsifier (Sucrose Esters of Fatty Acids), Anchovy Extract (Fish), Flavouring, Soybean, Acid (Lactic Acid), Paprika, Stabiliser (Xanthan Gum)), Wheat Flour, Vegetable Oils (Rapeseed, Sunflower), Sugar, Mustard Flour, Salt, Stabilisers (Diphosphates, Polyphosphates), Yeast Extract, Garlic Powder, Cayenne Pepper, Soybean, Wheat, Ginger Powder, Yeast, Ginger Extract.'
        },
        {
            'id': 'I0ikCV7Mj8isG92Q9f8M',
            'name': '26659v10/120797 HER 5 063089 485835"&gt; Gluten Free',
            'brand': 'Exceptional By Asda',
            'serving_size_g': 63.0,
            'ingredients': 'Pork (90%), Water, Rice Flour, Salt, Chickpea Flour, Spices, Stabiliser (Diphosphates), Preservative (Sodium Metabisulphite), Flavouring, Cornflour (contains Sulphites), Antioxidant (Ascorbic Acid), Dextrose (contains Sulphites), Sausage Casing (Calcium Alginate).'
        },
        {
            'id': 'I0zpetRh3jfcLQaAkJ0I',
            'name': 'Bliss Corner',
            'brand': 'Müller',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (Milk), Whipping Cream (Milk) 13%, Sugar, Water, Raspberries 8%, Raspberry Puree 4.5%, Modified Maize Starch, Emulsifier (E472b), Inulin, Gelatine, Stabilisers (Pectins), Flavourings, Acidity Regulators (Citric Acid, Sodium Citrates).'
        },
        {
            'id': 'I1GCylJ0eeHWoZBdFija',
            'name': 'Pitted Black Olives',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Black Olive, Water, Salt, Stabiliser (Ferrous Gluconate).'
        },
        {
            'id': 'I1bDT5MokgrKiRnbVWsJ',
            'name': 'Plum Tart',
            'brand': 'Confiserie Firenze',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, 23% Plums, Sugar, Vegetable Margarine (Palm Fat, Rapeseed Oil, Water, Emulsifier (Mono - and Diglycerides of Fatty Acids)), Egg, Rapeseed Oil, Water, Wheat Starch, Glucose-Fructose Syrup, Persipan (Apricot Kernels, Sugar, Water, Invert Sugar Syrup, Potato Starch), Invert Sugar Syrup, Fructose, Whey Powder (Milk), Dextrose, Raising Agent (Sodium Carbonates), Modified Potato Starch, Salt, Gelling Agent (Pectins), Emulsifier (Mono - and Diglycerides of Fatty Acids), Natural Flavouring, Cinnamon, Lactose (Milk), Thickener (Xanthan Gum), Acid (Citric Acid), Acidity Regulators (Diphosphates, Calcium Phosphates, Sodium Citrates).'
        },
        {
            'id': 'I26J4XUyJa32XVCyhwKr',
            'name': 'Mini Frieda Caterpillar Cakes',
            'brand': 'Asda',
            'serving_size_g': 51.0,
            'ingredients': 'Belgian Dark Chocolate 28% (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithins), Flavouring), Icing Sugar, White Chocolate Flavour Decorations 11% (Sugar, Cocoa Butter, Rice Syrup, Rice Starch, Rice Flour, Coconut Oil, Emulsifier (Lecithins), Flavouring), Water, Sugar, Palm Oil, Rapeseed Oil, Multi-Coloured Sugar Decorations 4% (Sugar, Rice Flour, Coconut Oil, Water, Shea Oil, Thickener (Cellulose Gum), Fruit and Vegetable Concentrates (Spirulina, Radish, Apple, Blackcurrant), Flavouring, Colours (Paprika Extract, Lutein, Curcumin)), Maize Starch, Fat-Reduced Cocoa Powder, Tapioca Starch, Rice Flour, Sunflower Oil, Soya Flour, Oat Flour, Raising Agents (Diphosphates, Sodium Carbonates), Brown Flax Seeds, Humectant (Glycerol), Flavourings, Emulsifiers (Soya Lecithins, Mono- and Diglycerides of Fatty Acids), Thickener (Xanthan Gum), Salt, Preservative (Potassium Sorbate), Psyllium.'
        },
        {
            'id': 'I2h8jfZRcx0jauciCdq3',
            'name': 'Beefy Drink',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Beef Extract (31%), Yeast Extract, Water, Salt, Hydrolysed Soya Protein, Colour (Plain Caramel), Pepper Extract.'
        },
        {
            'id': 'I340P14emHp0mbHwiTkd',
            'name': 'Spaghetti Bolognese',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Spaghetti (Water, Durum Wheat Semolina), Water, Beef 12%, Tomatoes, Tomato Purée, Onion, Mushroom, Carrot, Celery, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast Extract, Basil, Garlic Purée, Sugar, Cornflour, Caramelised Sugar, Salt, Onion Powder, Whey Powder (Cows\' Milk), Black Pepper, Whey Protein Concentrate (Cows\' Milk), Wheat Gluten, Casein (Cows\' Milk).'
        },
        {
            'id': 'I3qi6MXCfZNZEMAor4Lq',
            'name': 'Katsu Curry Cooking Sauce',
            'brand': 'Fiesta',
            'serving_size_g': 125.0,
            'ingredients': 'Water, Sugar, Tomato Paste, Spices, Onion Powder, Salt, Garlic Powder, Vegetable Oil.'
        },
        {
            'id': 'I5oIg1jVh5KXSm9IcNRy',
            'name': 'Fig & Honey Chutney',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Partially Rehydrated Figs (32%) (Figs, Water), Bramley Apple, Sugar, Distilled Barley Malt Vinegar, Onion, Honey (5%), Spices.'
        },
        {
            'id': 'I5vqURvD6kk2tokvbINg',
            'name': 'Custard Creams',
            'brand': 'Happy Shopper',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Sugar, Palm Oil, Whey Powder (Milk), Glucose Syrup, Wheat Starch, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavouring, Colour (Carotenes).'
        },
        {
            'id': 'I6B5e5m4knlktDVK6cWn',
            'name': 'Salted Caramel Popcorn',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Belgian Milk Chocolate (18%) (Sugar, Dried Whole Milk, Cocoa Butter, Cocoa Mass, Emulsifier (Soya Lecithin), Vanilla Flavouring), Popcorn (17%), Dark Brown Sugar, Unsalted Butter (Milk), Rapeseed Oil, Salt, Emulsifier (Soya Lecithin), Flavouring.'
        },
        {
            'id': 'I7JTHJP8lxoIxcGp136p',
            'name': 'Organic Strawberry Jam',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Sugar, Organic Strawberries, Acid (Citric Acid), Gelling Agent (Pectin).'
        },
        {
            'id': 'I7cBVr5yNPvJU8gGjOpO',
            'name': 'Tomato Ketchup',
            'brand': 'Tiptree',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (180g per 100g of ketchup), Sugar, Wine Vinegar, Lemon Juice, Salt, Spices.'
        },
        {
            'id': 'I8h5sKJ1kYtvXSIBXErB',
            'name': 'Cheese & Onion Crisps',
            'brand': 'Walkers',
            'serving_size_g': 32.5,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in varying proportions), Cheese & Onion Seasoning (Dried Onion, Salt, Dried Milk Whey, Lactose from Milk, Sugar, Flavouring (contains Milk), Cheese Powder from Milk, Dried Yeast, Dried Garlic, Acids (Citric Acid, Malic Acid), Colours (Annatto Bixin, Paprika Extract)).'
        },
        {
            'id': 'I96p6Vv7AQlefhdYK7KX',
            'name': 'Milk Chocolate Ice Cream',
            'brand': 'Aldi',
            'serving_size_g': 75.0,
            'ingredients': 'Skimmed Milk, Milk Chocolate (29%) (Sugar, Cocoa Butter, Cocoa Mass, Whey Powder (Milk), Anhydrous Milk Fat, Skimmed Milk Powder, Emulsifiers (Lecithins, Polyglycerol Polyricinoleate), Natural Vanilla Flavouring), Whey Protein Concentrate (Milk), Glucose Syrup, Coconut Oil, Sugar, Skimmed Milk Powder, Emulsifier (Mono-and Diglycerides of Fatty Acids), Plant Extract (Carrot Concentrate), Stabilisers (Guar Gum, Locust Bean Gum), Natural Bourbon Vanilla Flavouring, Ground Extracted Vanilla Pod.'
        },
        {
            'id': 'I9Ng0XDoaXCAzWJHlCri',
            'name': 'Lemon & Herb Chicken',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken (99%), Salt, Stabiliser (Triphosphates), Garlic Powder, Sugar, Maize Starch, Black Pepper, Oregano, Lemon Extract, Maltodextrin, Onion Powder, Paprika, Parsley, Acid (Citric Acid), Cumin, Rosemary, Yeast Extract, Lemon Oil, Dried Pimento, Coriander, Sicilian Lemon Oil.'
        },
        {
            'id': 'IADXTKzPIZKJuFz4mkwi',
            'name': 'Aldi Garlic Bread',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Gluten, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Garlic Purée (3%), Palm Oil, Yeast, Salt, Parsley (19%), Emulsifiers (Mono-and Diglycerides of Fatty Acids, Polyglycerol Polyricinoleate), Colour (Carotenes), Preservative (Potassium Sorbate), Stabiliser (Sodium Alginate), Lemon Juice from Concentrate, Vitamin A, Vitamin D, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'IAEJFuLRk8Iyk4MmL6wG',
            'name': 'Cookies And Cream Mini Eggs',
            'brand': 'Hershey\'s',
            'serving_size_g': 100.0,
            'ingredients': 'White Chocolate 95.6% (Sugar, Cocoa Butter, Whole Milk Powder, Emulsifier (Soya Lecithin), Natural Vanilla Flavour), Cocoa Biscuit Pieces 4.4% (Wheat Flour (Gluten), Sugar, Vegetable Fat (Palm), Fat Reduced Cocoa Powder 9%, Glucose-Fructose Syrup, Skimmed Milk Powder, Salt, Natural Bourbon Vanilla Flavouring, Ground Bourbon Vanilla, Raising Agents (Ammonium Hydrogen Carbonate, Sodium Hydrogen Carbonate)).'
        },
        {
            'id': 'IAcRVwZ8H8G7krhpovwX',
            'name': 'Pork Luncheon Meat',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (67%), Water, Potato Starch, Salt, Sugar, Stabiliser (Sodium Phosphates), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite), Spice Extracts.'
        },
        {
            'id': 'IBQ7G5zlrjS2zraax20z',
            'name': 'Salt And Vinegar Multipack Bag',
            'brand': 'Walkers',
            'serving_size_g': 25.0,
            'ingredients': 'Potatoes, Vegetable Oil (Sunflower, Rapeseed, in varying proportions), Salt and Vinegar Seasoning (Flavouring, Corn (Maize) Starch, Salt, Acids (Citric Acid, Malic Acid), Yeast Extract, Potassium Chloride, Antioxidant (Rosemary Extract)).'
        },
        {
            'id': 'IBwwJIBKHRQHBA2aUjcI',
            'name': 'Spanish Style',
            'brand': 'Chicken Tonight',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomato Puree (60%), Tomatoes (16%), Red and Green Bell Peppers (11%), Onions, Modified Maize Starch, Lemon Juice, Sugar, Olive Oil (0.7%), Salt, Garlic, Thyme, Black Pepper, Extra Virgin Olive Oil.'
        },
        {
            'id': 'ICeMyZPnHqpOJdx35Eb7',
            'name': 'Honey Hoops',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Flour 59% (Oat Flour, Wholegrain Wheat Flour), Sugar, Wheat Starch, Maltodextrin, Oat Bran, Blended Honey 4%, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Raising Agents (Potassium Carbonates, Sodium Carbonates), Salt, Flavouring, Colour (Paprika Extract), Vitamin and Mineral Mix (Niacin (B3), Iron, Riboflavin (B2), Thiamin (B1), Vitamin D).'
        },
        {
            'id': 'ICksEiJfcqA4rXKlIcrX',
            'name': 'Abe Ultimate Pre Workout',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Citrulline Malate (2:1), Creatine Monohydrate, Beta-Alanine, Acid (Citric Acid), Flavouring, Acidity Regulator (Sodium Bicarbonate), Taurine, Choline Bitartrate (as Vitacholine), Caffeine Anhydrous, Anti-Caking Agents (Silicon Dioxide, Calcium Silicate), Colour (Beetroot Red), Sweetener (Sucralose), Niacin (Niacinamide), Vitamin B12 (Cyanocobalamin).'
        },
        {
            'id': 'IDAuHQIAbOzVkzhHNnVg',
            'name': 'Turkey Breast Chunks',
            'brand': 'Bernard Matthews',
            'serving_size_g': 160.0,
            'ingredients': 'Turkey Breast (90%), Milk Protein, Starch, Dextrose, Natural Flavourings, Stabilisers (Carrageenan, Diphosphates), Salt, Rosemary Extract, Oregano, Nutmeg.'
        },
        {
            'id': 'IEdjmNRS2TItV9RwlOWT',
            'name': 'Bunny',
            'brand': 'Maltesers',
            'serving_size_g': 29.0,
            'ingredients': 'Sugar, Skimmed Milk Powder, Palm Fat, Cocoa Butter, Barley Malt Extract, Cocoa Mass, Lactose and Protein from Whey (from Milk), Whey Powder (from Milk), Milk Fat, Full Cream Milk Powder, Glucose Syrup, Demineralised Whey Powder (from Milk), Shea Fat, Lactose, Emulsifier (Soya Lecithin), Wheat Flour, Raising Agents (E341, E500, E501), Salt, Wheat Gluten, Natural Vanilla Extract.'
        },
        {
            'id': 'IF7MRie022AYyIiOjNSk',
            'name': 'Lemon Drizzle Cake Kit',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Flour, Sugar, Icing Sugar, Haricot Bean Flour, Potato Starch, Inulin, Maltodextrin, Flavourings, Raising Agents (Disodium Diphosphate, Sodium Bicarbonate, Calcium Sulphate), Tapioca Starch, Pea Fibre, Stabiliser (Xanthan Gum).'
        },
        {
            'id': 'IFCfSzUwsfN2Q31UQ7fe',
            'name': 'Hot Honey Pork Sausage',
            'brand': 'Aldi',
            'serving_size_g': 57.0,
            'ingredients': 'British Pork (75%), Water, Red Peppers, Honey (3%), Rice Flour, Chickpea Flour, Brown Sugar, Tapioca Starch, Salt, Coriander, Garlic, Stabiliser (Diphosphates), Cornflour, Red Jalapeño Chilli, Red Chilli Purée, Crushed Chilli, Ground Cayenne Pepper, Sugar, Ground Black Pepper, Smoked Salt, Cider Vinegar (Apple Juice, Sugar, Yeast), Sea Salt, Smoked Paprika, Preservative (Sodium Metabisulphite), Tomato Powder, Dried Green Bell Pepper, Garlic Powder, Onion Powder, Chipotle Chilli Powder, Colour (Paprika Extract), Dextrose, Antioxidant (Sodium Ascorbate), Dried Oregano.'
        },
        {
            'id': 'IFoyHMCDr0ABgcSwMgje',
            'name': 'Chicken Breast 100% Fillet BIG Value PACK',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast Fillet (58%), Wheat Flour, Fully Refined Soya Bean Oil, Water, Modified Tapioca Starch, Salt, Black Pepper, Dextrose, Wheat Starch, Acidity Regulators (Sodium Carbonates, Citric Acid), Onion Powder, Fennel Powder, Garlic Powder, Yeast Extract, Ground Nutmeg, Paprika Powder, Sugar, Paprika Extract, White Pepper, Sunflower Oil, Flavouring, Maltodextrin, Nutmeg Extract, Yeast.'
        },
        {
            'id': 'IGjtr6NnyWl5eRMAeB7S',
            'name': 'Sweet Potato Wraps',
            'brand': 'Bfree',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sweet Potato Flour (21%), Mixed Wholegrain Flours (16%) (Sorghum Flour, Brown Rice Flour, Millet Flour, Buckwheat Flour, Teff Flour, Quinoa Flour, Amaranth Flour), Potato Starch, Thickening Agents (Cellulose, Xanthan Gum, Guar Gum, Sodium Carboxymethyl Cellulose), Corn Starch, Tapioca Starch, Pea Protein, Inulin, Sourdough (Fermented Corn Starch), Cultured Dextrose, Salt, Acidifiers (Citric Acid, Malic Acid, Tartaric Acid, Glucono Delta Lactone), Canola Oil, Psyllium Husk, Carrot Powder, Yeast, Tomato Powder, Preservative (Sorbic Acid).'
        },
        {
            'id': 'IHHH287iq5nZjTkh8auv',
            'name': 'Corned Beef',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Beef, Salt, Brown Sugar, Mineral Sea Salt, Stabilisers (Potassium Triphosphate, Sodium Triphosphate), Preservative (Sodium Nitrite).'
        },
        {
            'id': 'IHJXcTznUJ3hCOI8bPX8',
            'name': 'Extra Hot Curry Sauce Mix',
            'brand': 'Mayflower',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Rapeseed), Curry Powder (Coriander, Turmeric, Mustard, Bengal Gram Farina, Cumin, Chillies, Fenugreek, Black Pepper, Garlic, Fennel, Poppy Seeds), Sugar, Salt, Flavour Enhancer (E621), Tomato Purée, Spices.'
        },
        {
            'id': 'II3mu8u1BTwv2tp6E37X',
            'name': 'Snowballs',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (30%) (Sugar, Cocoa Butter, Dried Whole Milk, Cocoa Mass, Dried Whey (Milk), Emulsifier (Soya Lecithin)), Glucose Syrup (contains Sulphites), Sugar, Desiccated Coconut (16%), Reconstituted Egg White, Rice Flour, Stabiliser (E405).'
        },
        {
            'id': 'IByqJps1XGKSUq3agNhY',
            'name': 'Chicken',
            'brand': 'Oxo',
            'serving_size_g': 5.9,
            'ingredients': 'Wheat Flour, Salt, Dried Glucose Syrup, Flavour Enhancer (Monosodium Glutamate), Yeast Extract, Flavouring, Chicken Fat (Chicken), Potato Starch, Sugar, Chicken Extract (2%), Onion Extract, Colour (Ammonia Caramel).'
        },
        {
            'id': 'IJ8CPW57BSmNPgBkoKqK',
            'name': 'White Chocolate',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter, Whole Milk Powder, Emulsifier (Lecithins (Soya)), Vanilla Extract.'
        },
        {
            'id': 'IJLDwNcEEcYqeeSJwsBQ',
            'name': 'Lemon All Butter Shortbread Fingers',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Butter (Milk) (30%), Sugar, Maize Starch, Sicilian Lemon Oil (0.6%), Salt.'
        },
        {
            'id': 'IJgPw1CIjPWCxrShD10A',
            'name': 'Lighter Mature Cheddar',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Milk.'
        },
        {
            'id': 'IK9oMvzY35TClAdv7rN3',
            'name': 'More To Share! White NEW Maltesers',
            'brand': 'Mars',
            'serving_size_g': 126.0,
            'ingredients': 'Sugar, Cocoa Butter, Glucose Syrup, Whole Milk Powder, Barley Malt Extract, Skimmed Milk Powder, Whey Powder (Milk), Palm Fat, Palm Kernel Fat, Wheat Flour, Raising Agents (E341, E501, E500), Emulsifiers (Soya Lecithin, E476), Wheat Gluten, Glazing Agent (Gum Arabic), Natural Vanilla Flavouring, Salt.'
        },
        {
            'id': 'IKteQaFFxocbIYQuubfG',
            'name': 'Chicken Skewers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Leg (97%), Salt, Chilli Glaze (3%) (Spices (Chilli, Black Pepper, Ground Cayenne Pepper, Ground Allspice, Ground Fennel Seeds, Ground Ginger), Sea Salt, Sugar, Parsley, Maize Starch, Chilli Extract), Water.'
        },
        {
            'id': 'ILX6dMAbmj9xQd9sWV11',
            'name': 'Spray Light',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sunflower Oil (53%), Water, Emulsifier (Lecithins (Rapeseed)), Acidity Regulator (Citric Acid), Thickener (Xanthan Gum), Preservative (Potassium Sorbate).'
        },
        {
            'id': 'IMUYW240VUYF244L5C1d',
            'name': 'Bread',
            'brand': 'Baker Street',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Sourdough (Rye Flour, Water), Mixed Seeds and Flakes (11%) (Linseeds, Barley Flakes, Sunflower Seeds, Oat Flakes), Wholemeal Rye Flour, Rye Flour, Yeast, Salt, Caramelised Sugar Syrup (Sugar, Water), Malted Barley Flour, Wheat Gluten, Invert Sugar Syrup, Acidity Regulator (Sodium Acetate), Preservative (Sorbic Acid), Flour Treatment Agent (Ascorbic Acid), Flavouring.'
        },
        {
            'id': 'IN6J2iiSJdl4llu1pTkO',
            'name': 'Snackrite Delta Strips',
            'brand': 'Delta',
            'serving_size_g': 100.0,
            'ingredients': 'Corn, Sunflower Oil, Maltodextrin, Salt, Flavouring, Smoke Flavouring.'
        },
        {
            'id': 'INaqVFWcAcrzncEYpYEv',
            'name': 'Honey And Mustard Chicken Pasta',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 280.0,
            'ingredients': 'Cooked Pasta (Durum Wheat Semolina, Water, Rapeseed Oil), Honey & Mustard Mayonnaise Dressing (Water, Crème Fraîche (Cows\' Milk), Rapeseed Oil, Reduced Fat Greek Style Yogurt (Cows\' Milk), Honey, Cornflour, Lemon Juice, Spirit Vinegar, Pasteurised Egg Yolk, Mustard Seeds, Salt, Stabiliser (Xanthan Gum), Sugar, White Wine Vinegar, Garlic Purée, Black Pepper, Concentrated Lemon Juice, Thickener (Pectin), Allspice), Sweetcorn, Cooked Honey & Mustard Marinated Chicken 11% (Chicken Breast, Honey, Water, Mustard Flour, Salt, Mustard Seeds, Cornflour, White Wine Vinegar, Turmeric Powder, Pimento, Cinnamon Powder), Red Peppers, Tomato, Parsley.'
        },
        {
            'id': 'INiIbGNUmgfKSE0PZQvb',
            'name': 'Angel Delight',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Sugar, Palm Oil, Modified Starch, Maltodextrin, Milk Proteins, Emulsifiers (Propylene Glycol Ester of Fatty Acids, Lecithins), Natural Flavouring, Gelling Agents (Carrageenan, Locust Bean Gum, Guar Gum), Milk Calcium Complex, Whey Powder (Milk), Colour (Carmine).'
        },
        {
            'id': 'IOFdDVQmokFgvG9gpYgY',
            'name': 'Curlers Cheese Flavour',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable Oils (Rapeseed Oil, Sunflower Oil), Potato Flour, Wheat Flour, Maize Flour, Whey Powder (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Glucose, Spices (Paprika, Turmeric, White Pepper), Sugar, Onion Powder, Yeast Extract, Cheese Powder (Milk), Buttermilk Powder, Flavouring (contains Milk), Colour (Paprika Extract).'
        },
        {
            'id': 'IPZol5QxrAUE9znTCVlk',
            'name': 'Hot And Spicy Chicken Breast Slices',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast, Sugar, Chillies, Tapioca Starch, Cumin, Tomato Powder, Red Bell Peppers, Onion Fat Powder, Salt, Stabiliser (Diphosphates), Black Pepper, Garlic Powder, Parsley, Oregano, Colour (Paprika Extract), Coriander Extract, Sunflower Oil, Coriander Leaf.'
        },
        {
            'id': 'IQgFZkKYui8GQo9uuFBu',
            'name': 'Monster Claws',
            'brand': 'Aldi',
            'serving_size_g': 18.0,
            'ingredients': 'Maize, Rapeseed Oil, Pickled Onion Flavour (Rice Flour, Flavouring, Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium Guanylate, Disodium Inosinate), Salt, Acid (Citric Acid), Onion Powder, Potassium Chloride).'
        },
        {
            'id': 'IR8Pur11JqVoLaI0utNw',
            'name': 'Cheddar And Bacon Quiche',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Semi Skimmed Milk, Pasteurised Egg, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Beechwood Smoked Reformed Bacon with Added Water (13%) (Pork, Water, Dextrose, Salt, Stabilisers (Pentasodium Triphosphate, Sodium Polyphosphate), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Extra Mature Cheddar Cheese (Milk) (9%), Palm Oil, Red Leicester Cheese with Colour Annatto Norbixin (Milk), Cornflour, Double Cream (Milk), Maize Flour, Rapeseed Oil, White Pepper, Nutmeg.'
        },
        {
            'id': 'IRBqf8iOoECs11gh9uag',
            'name': 'Simple Sesame',
            'brand': 'Ryvita',
            'serving_size_g': 100.0,
            'ingredients': 'Rye Flour, Bran, Sesame Seeds (11%), Salt.'
        },
        {
            'id': 'IS68pFkSM3e7Q4WbYsta',
            'name': 'Dulanos 10 Frankfurters Beechwood Smoked',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': '75% Pork, Water, Pork Fat, Salt, Dextrose, Firming Agent (Potassium Chloride), Stabiliser (Diphosphates), Spices, Antioxidant (Sodium Ascorbate), Spice Extracts, Preservative (Sodium Nitrite).'
        },
        {
            'id': 'ITNNHazADDATkDAWaV2X',
            'name': 'Tomato Ketchup',
            'brand': 'Rubies In The Rubble',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes, Surplus Pears/Apples, Sugar, Spirit Vinegar, Salt, Preservative (Potassium Sorbate), Spices.'
        },
        {
            'id': 'IUVx8wB9LSHLEnierCVu',
            'name': 'Flapjacks',
            'brand': 'Asda Free From',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (36%), Golden Syrup (20%), Brown Sugar, Palm Oil, Rapeseed Oil, Glucose Syrup, Gluten Free Oat Flour, Water, Desiccated Coconut, Oligofructose, Salt, Emulsifier (Mono - and Diglycerides of Fatty Acids), Flavouring.'
        },
        {
            'id': 'IUe19R0NfoWoydrGBR6b',
            'name': 'Oat Milk Irish Cream Vegan Chocolate',
            'brand': 'Ombar',
            'serving_size_g': 35.0,
            'ingredients': 'Unrefined Cane Sugar, Oat Milk Powder, Cocoa Butter, Sunflower Oil, Gluten Free Naked Oats (12%), Unroasted Cacao, Almonds, Chicory Root Fibre, Cocoa Powder, Natural Vanilla Flavouring, Natural Whiskey Flavouring, Desert Salt, Coffee.'
        },
        {
            'id': 'IWjdghL6rvTg1Ln8NsMA',
            'name': 'Bounty',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Coconut (20%), Gluten Free Wheat Starch, Glucose-Fructose Syrup, Dextrose, Thickeners (Xanthan Gum, Locust Bean Gum), Cocoa Butter, Cocoa Mass, Almond Paste (9%), Dried Rice Syrup, Vanilla Extract, Salt, Flavouring.'
        },
        {
            'id': 'IXQWCVKW0NaRjwWrLpSg',
            'name': 'Milk Chocolate Buttons',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Cream Powder (Milk), Palm Oil, Shea Oil, Emulsifiers (Ammonium Phosphatides, Polyglycerol Polyricinoleate), Flavourings, Vanilla Extract.'
        },
        {
            'id': 'IXRGWFY3zSbjJixkOSV4',
            'name': 'Custard Slice',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 90.0,
            'ingredients': 'Custard 61% (Water, British Cream (Cows\' Milk), Sugar, Milk Protein Concentrate (Cows\' Milk), Maize Starch, Dextrose, Stabiliser (Pectins, Calcium Sulphate, Tetrasodium Diphosphate), Flavouring, Glucose, Gelling Agent (Sodium Alginate), Colour (Mixed Carotenes)), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Stearin, Palm Oil, Butter 1.5% (Cows\' Milk), Dried Glucose Syrup, White Chocolate (Sugar, Cocoa Butter, Whole Cows\' Milk Powder, Flavouring, Emulsifier (Soya Lecithin)), Rapeseed Oil, Invert Sugar Syrup, Soya Flour, Salt, Colours (Mixed Carotenes, Lutein), Flour Treatment Agent (L-Cysteine), Concentrated Lemon Juice.'
        },
        {
            'id': 'IY4gVwsSFmxkxfV8Bn0S',
            'name': '10 Rashers Unsmoked Dry Cured Bacon',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'British Pork Loin (97%), Salt, Sugar, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': 'IYHYqfxW1cs0tKzW0PUE',
            'name': 'Luxury Chocolate Drink',
            'brand': 'Twinings',
            'serving_size_g': 20.0,
            'ingredients': 'Sugar, Fat-Reduced Cocoa Powder (18%), Dried Glucose Syrup, Chocolate (7%) (Sugar, Cocoa Mass, Fat-Reduced Cocoa Powder, Vanillin), Calcium Phosphate, Emulsifier (Soy Lecithin), Vanillin, Salt, Vitamins (B1, B2, B6, B12, Folic Acid, Niacin, Pantothenic Acid).'
        },
        {
            'id': 'IZ7njuR3ydy3oIK9avnM',
            'name': 'Green Vegetable Medley',
            'brand': 'Tesco Finest',
            'serving_size_g': 99.0,
            'ingredients': 'Petit Pois, Cabbage, Tenderstem Broccoli, Spinach, Sea Salt and Black Pepper Butter (3.5%) (Butter (Milk), Sea Salt, Black Pepper).'
        },
        {
            'id': 'IZJ418IdDDldg2Q8IawZ',
            'name': 'Extra Cream Bourbon Cream',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (contains Gluten) (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Oil, Fat Reduced Cocoa Powder, Dried Whey (Milk), Raising Agent (E503, Sodium Bicarbonate), Emulsifier (Soya Lecithin), Salt, Flavourings.'
        },
        {
            'id': 'IZykSAfNkPPCynpuvwiE',
            'name': 'Plantastic Flapjack',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes 37%, Light Brown Sugar, Partially Inverted Refiners Syrup (Golden Syrup) 13%, Diced Dried Apricots 10%, Vegetable Oils (Rapeseed, Palm), Water, Apricot Flavoured Jam 4% (Glucose-Fructose Syrup, Apricot Purée, Acid (Citric Acid), Gelling Agent (Pectin), Acidity Regulator (Sodium Citrates), Preservative (Potassium Sorbate), Colour (Annatto Norbixin), Flavouring), Nibbed Almonds 3%, Humectant (Vegetable Glycerine), Ground Ginger 0.5%, Rice Flour, Salt, Preservative (Potassium Sorbate), Tapioca Starch.'
        },
        {
            'id': 'IbX59cCqCI6yQq2KTJ9L',
            'name': 'Tesco Finest Madagascan Vanilla Cheesecake',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Full Fat Soft Cheese (Milk) 25%, Soured Cream (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Pasteurised Egg, Palm Oil, Single Cream (Milk), Demerara Sugar, Cornflour, Rapeseed Oil, Invert Sugar Syrup, Double Cream (Milk), Pasteurised Egg Yolk, Salt, Madagascan Vanilla Extract, Raising Agent (Sodium Carbonates), Spent Madagascan Vanilla Seeds.'
        },
        {
            'id': 'IUfmvBVDUGlMGy3sqKEg',
            'name': 'Light Garlic And Herb Soft Cheese',
            'brand': 'Asda',
            'serving_size_g': 15.0,
            'ingredients': 'Medium Fat Soft Cheese (Milk), Garlic Powder (1%), Basil, Parsley, Black Pepper.'
        },
        {
            'id': 'IdrjTtiYxyomgONfQGJB',
            'name': 'Semi-skimmed Milk',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fresh Semi Skimmed Milk.'
        },
        {
            'id': 'IeiSx0OCega5LXhReOU5',
            'name': 'Biscuits For Cheese',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Palm Oil, Sugar, Glucose Syrup, Salt, Raising Agents (Ammonium Carbonates, Sodium Carbonates), Wheat Germ, Poppy Seeds, Wheat Starch, Sesame Seeds, Malted Barley Flour, Barley Malt Extract, Wheat Bran, Kibbled Wheat, Kibbled Rye, Sugar Beet Fibre, Egg Powder, Yeast, Whey Powder (Milk), Black Pepper, Chives, Flavouring.'
        },
        {
            'id': 'IevRbLvbsiYRZPsimGwu',
            'name': 'Walkers - Lightly Salted',
            'brand': 'Walkers',
            'serving_size_g': 45.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in varying proportions), Salt, Antioxidant (Rosemary Extract, Ascorbic/Citric Acid, Tocopherol Rich Extract).'
        },
        {
            'id': 'IewQafB0HYH6XmevYzAr',
            'name': 'Superstraccia',
            'brand': 'Julienne Bruno',
            'serving_size_g': 100.0,
            'ingredients': 'Soya Drink, Coconut Oil, Water, Salt, Stabiliser (Carrageenan), Dextrose, Acidity Regulator (Lactic Acid), Stabiliser (Xanthan Gum), Emulsifier (Soya Lecithins), Vegetable Fibres, Cultures.'
        },
        {
            'id': 'If6gfiz0iD8K5BKFlogo',
            'name': 'Meatster',
            'brand': 'Eat Go',
            'serving_size_g': 10.0,
            'ingredients': 'Pork, Salt, Dextrose, Spice Extracts, Antioxidant (Sodium Ascorbate), Spices, Preservative (Sodium Nitrite).'
        },
        {
            'id': 'IfHEno4cRiJl9vcuC7Bt',
            'name': '6 Classic Pork Sausages',
            'brand': 'Asda',
            'serving_size_g': 67.0,
            'ingredients': 'Pork (90%), Water, Rice Flour, Salt, Chickpea Flour, Spices, Stabiliser (Diphosphates), Preservative (Sodium Metabisulphite), Flavouring, Cornflour (contains Sulphites), Antioxidant (Ascorbic Acid), Dextrose (contains Sulphites), Sausage Casing (Calcium Alginate).'
        },
        {
            'id': 'IfwASMCKnDazbafpFPVR',
            'name': 'Tagliatelle',
            'brand': 'Inspired Cuisine',
            'serving_size_g': 100.0,
            'ingredients': 'Durum Wheat Semolina, Pasteurised Liquid Egg (20%), Water.'
        },
        {
            'id': 'IgVnTXZwz8e6KkJ8o6Wu',
            'name': 'Pepperoni Stonebaked Pizza',
            'brand': 'Morrisons',
            'serving_size_g': 135.0,
            'ingredients': 'Wheat Flour, Tomato, Water, Mozzarella Cheese (Milk) 14%, Pepperoni 11% (Pork 96%, Salt, Dextrose, Paprika, Cayenne Pepper, Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Garlic Powder, Paprika Extract, Pepper Extract, Preservative (Sodium Nitrite)), Mild Cheddar Cheese (Milk) 3%, Tomato Purée, Sugar, Yeast, Dried Wheat Sourdough, Cornflour, Salt, Rapeseed Oil, Acidity Regulator (Citric Acid), Oregano, Black Pepper, Enzymes (Wheat).'
        },
        {
            'id': 'IhKETw8eSK5HkmCTO9U5',
            'name': 'Tesco Finest Crinkle Cut Katsu Curry',
            'brand': 'Tesco Finest',
            'serving_size_g': 25.0,
            'ingredients': 'Potato, Rapeseed Oil, Rice Flour, Spices, Salt, Sugar, Onion Powder, Potassium Chloride, Yeast Extract Powder, Garlic Powder, Flavouring, Citric Acid, Colour (Paprika Extract).'
        },
        {
            'id': 'IhkiIE5y6MTOT78yF4Tc',
            'name': '4 Extra Fruity Hot Cross Buns',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Orange Soaked Fruits (30%) (Sultanas, Raisins, Currants, Flame Raisin, Concentrated Orange Juice), Water, Mixed Peel (Orange Peel, Lemon Peel), Butter (Milk), Honey (1.5%), Wheat Gluten, Demerara Sugar, Yeast, Mixed Spice, Salt, Buttermilk Powder (Milk), Emulsifiers (Mono - and Diglycerides of Fatty Acids, Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Potato Dextrin, Flavouring, Lemon Zest, Rapeseed Oil, Palm Oil, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'Ii4sgENk06qEeV2eRIA9',
            'name': 'Smoked Brunswick Ham',
            'brand': 'Aldi',
            'serving_size_g': 20.0,
            'ingredients': 'Pork (98%), Salt, Dextrose, Stabilisers (Diphosphates, Triphosphates), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite), Spice Extract (Pepper Extract, Juniper Berries, Garlic Extract, Nutmeg Extract), Potassium Iodate.'
        },
        {
            'id': 'IiDHbDsiZM8hiTeGZ3Ng',
            'name': 'Cinnamon Knots',
            'brand': 'Waitrose',
            'serving_size_g': 17.0,
            'ingredients': 'Wheat Flour, Unsalted Butter (Milk) 28%, Sugar, Yeast, Salt, Cinnamon.'
        },
        {
            'id': 'IiQ5SK8Xo8euBj438cdX',
            'name': 'Ready To Wok Medium Noodles',
            'brand': 'Asia Specialities',
            'serving_size_g': 150.0,
            'ingredients': 'Water, Wheat Flour, Wheat Gluten, Sunflower Oil, Iodized Salt (Sodium Chloride, Potassium Iodate), Acidity Regulator (Glucono-Delta-Lactone), Thickener (Guar Gum).'
        },
        {
            'id': 'IicJBPPholERYfySQhbN',
            'name': 'Ready To Eat Salmon',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Salmon (Fish) (97%), Sea Salt, Demerara Sugar (Sugar, Cane Molasses).'
        },
        {
            'id': 'IdMzjcIUYaByUIV74KdP',
            'name': 'Asda Garlic And Herb Porksteaks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Loin (95%), Garlic and Herb Marinade (Sugar, Herbs, Cornflour, Garlic Powder, Salt, Dried Garlic, Onion Powder, Dehydrated Lemon Peel, Flavouring, Lemon Oil, Paprika Extract, Garlic Extract).'
        },
        {
            'id': 'IjCUvrmeQFHmbhZ84sr1',
            'name': 'Sea Salt And Black Pepper Crackers',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), High Oleic Sunflower Oil, Sugar, Rice Flour, Glucose Syrup, Salt (1%), Dried Yeast, Black Pepper (0.5%), Flavouring, Emulsifier (Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids).'
        },
        {
            'id': 'IknbJXK8KATzegSKtkPn',
            'name': 'Smoky Prosciutto And Cheese Rollitos',
            'brand': 'Gran Castelli',
            'serving_size_g': 100.0,
            'ingredients': 'Gran Castelli Cheese (Milk) (64%), Smoked Spiced Prosciutto (36%) (Pork (made with 140g of raw pork per 100g of smoked spiced prosciutto), Curing Salt (Salt, Dextrose, Preservative (Sodium Nitrite)), Juniper Berries, Ground Coriander, Coriander Seeds, Ground Bay Leaves, Ground Black Pepper, Flavouring).'
        },
        {
            'id': 'IkxqeN7QWVXKmb9rnpAS',
            'name': 'Fish Cakes Youngs',
            'brand': 'Youngs',
            'serving_size_g': 100.0,
            'ingredients': 'Minced White Fish (42%) (Fish), Partially Reconstituted Dried Potato, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Sunflower Oil, Rapeseed Oil, Palm Oil, Salt, Wheat Starch, Water, Yeast, Seasoning (Salt, Parsley, Rapeseed Oil, Black Pepper Extract, Parsley Oil), Parsley, Mustard Flour, Black Pepper.'
        },
        {
            'id': 'Ill5MoEdCfSlNdOJKh4D',
            'name': 'Fat Free Greek Style Natural Yogurt',
            'brand': 'Brooklea',
            'serving_size_g': 125.0,
            'ingredients': 'Milk.'
        },
        {
            'id': 'IlvEWvQ1yRQPAvWZUyig',
            'name': 'Caffè Latte Cappuccino',
            'brand': 'Emmi',
            'serving_size_g': 370.0,
            'ingredients': 'Semi-Skimmed Milk 80% (1.5% fat), Brewed Arabica Coffee 15.7%, Sugar, Cocoa Powder 0.27%.'
        },
        {
            'id': 'ImGD6AoYyuPDTeG1cAu1',
            'name': 'Choco Hoops',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Wholemeal Wheat Flour, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Maltodextrin, Fat Reduced Cocoa Powder (4.5%), Salt, Flavouring, Niacin, Iron, Riboflavin, Thiamin, Vitamin D.'
        },
        {
            'id': 'Imun7aztGXrdpMKPf78s',
            'name': 'Chocolate Raisins',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (55%) (Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Emulsifier (Lecithins), Vanilla), Raisins (44%), Glazing Agents (Gum Arabic, Shellac), Modified Tapioca Starch.'
        },
        {
            'id': 'ImveyvRzq6lW0r6X5jag',
            'name': 'Asda Oven Baked Croutons',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Garlic Purée, Rapeseed Oil, Yeast, Sea Salt, Parsley.'
        },
        {
            'id': 'Ij4Rhv6Oi44ZXNdjo51w',
            'name': 'Brooklea',
            'brand': 'Brooklea',
            'serving_size_g': 100.0,
            'ingredients': 'Low Fat Yogurt (80%), Sugar, Mango (4%), Papaya (3%), Passion Fruit Juice from Concentrate (1.5%), Modified Maize Starch, Mango Purée from Concentrate (0.5%), Flavouring, Colours (Curcumin, Carotenes), Acidity Regulator (Citric Acid), Stabiliser (Pectins).'
        },
        {
            'id': 'IovqIoVjPcneFN7APoxv',
            'name': 'Feta',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Sheep\'s Milk, Goats Milk.'
        },
        {
            'id': 'Ip7if24LoMiUe0nZ6LGf',
            'name': 'Macaroni Cheese',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Macaroni (43%) (Water, Durum Wheat Semolina), Water, Medium Fat Soft Cheese (Cows\' Milk), Rapeseed Oil, Modified Maize Starch, Sugar, Skimmed Cows\' Milk Powder, Cheese Powder (Cows\' Milk), Mustard Flour, Maize Starch, Stabiliser (Sodium Phosphate), Salt, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Yeast Extract, Whey Powder (Cows\' Milk), Colour (Beta-carotene).'
        },
        {
            'id': 'IpjjleLDKL6VGQE0uY66',
            'name': 'Strawberry Laces',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose-Fructose Syrup, Wheat Flour, Sugar, Wheat Dextrin, Dextrose, Palm Oil, Concentrated Fruit Juices (Strawberry, Blackcurrant), Acid (Citric Acid), Fruit and Vegetable Concentrates (Apple, Pumpkin, Radish, Tomato), Natural Flavouring, Glazing Agent (Hydroxypropyl Cellulose), Antioxidants (Tocopherol-Rich Extract, Ascorbic Acid).'
        },
        {
            'id': 'IqpzwiuLQbqyhznqYmpK',
            'name': 'Vegetarian And Gluten Free Sweet And Salty Popcorn',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Popped Corn (53%), Demerara Sugar, Rapeseed Oil, Sea Salt.'
        },
        {
            'id': 'IrwD36jKjF4YFxjNisoT',
            'name': 'Cinnamon Chips',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Wheat Flour (37%), Rice Flour, Sugar, Palm Oil, Maltodextrin, Maize Starch, Glucose Syrup, Barley Malt Flour, Cinnamon, Stabiliser (Potassium Phosphates), Salt.'
        },
        {
            'id': 'Is8nk7KSZc9JO8tDm3HF',
            'name': 'Chicken Stock Pot',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '63% Concentrated Chicken Stock (Water, Chicken), Salt, Yeast Extract, Natural Flavourings, 4% Chicken Fat (Chicken Fat (Chicken), Antioxidant (Extracts of Rosemary)), Sugar, Vegetables (Carrot, Leek, Celery, Onion, Cabbage), Gelling Agents (Agar, Xanthan Gum), Spices (Turmeric, Parsley).'
        },
        {
            'id': 'IsDbvqh27BEcGyXFlGie',
            'name': 'Ribena',
            'brand': 'Ribena',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Sugar, Raspberry Juice from Concentrate (4%), Acids (Citric Acid, Malic Acid), Natural Flavourings, Vitamin C, Extracts of Carrot and Hibiscus, Preservatives (Potassium Sorbate, Dimethyl Dicarbonate).'
        },
        {
            'id': 'Isml8yoENFYUeXhJFUNS',
            'name': 'Meat-free Sausages',
            'brand': 'Heck',
            'serving_size_g': 65.0,
            'ingredients': 'Water, Textured Pea Protein (10%), Functional Binder (Pea Protein, Starch, Flavourings, Stabiliser (Methyl Cellulose), Psyllium, Pea Fibre, Yeast Extracts, Spices, Colour (Betanin), Herb, Salt, Rapeseed Oil), Gluten Free Crumb (Rice Flour, Water, Dextrose Monohydrate, Vegetable Fibre), Coconut Oil, Grilled White Onion, Vegetable Oil (Sunflower Oil, Rapeseed Oil), Citrus Fibre, Parsley, Preservative (Sodium Sulphite), Natural Flavouring, Colour (Maltodextrin, Plant and Fruit Concentrates).'
        },
        {
            'id': 'IssCqazzdOmC9p8ZEvq1',
            'name': 'Smoked Baked Ham',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Dextrose, Stabilisers (Diphosphates, Sodium Citrates, Sodium Acetate), Hydrolysed Vegetable Protein, Antioxidant (Sodium Erythorbate), Preservative (Sodium Nitrite), Ground Cardamom.'
        },
        {
            'id': 'ItL0xwNKLRVhhgYCbU4w',
            'name': 'Walkers Cheese & Onion',
            'brand': 'Walkers',
            'serving_size_g': 45.0,
            'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed, in varying proportions), Cheese & Onion Seasoning (Dried Onion, Salt, Dried Milk Whey, Lactose from Milk, Sugar, Flavouring (contains Milk), Cheese Powder from Milk, Dried Yeast, Dried Garlic, Acids (Citric Acid, Malic Acid), Colours (Annatto Bixin, Paprika Extract)).'
        },
        {
            'id': 'IuBp7WtHIgOSGt0ehI0G',
            'name': 'Sliced Beetroot',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Beetroot, Water, Barley Malt Vinegar, Sugar, Salt.'
        },
        {
            'id': 'IvuUfqcNTWNEkAvSuvLb',
            'name': 'Skittles Desserts',
            'brand': 'Skittles',
            'serving_size_g': 38.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Fat, Acid (Citric Acid), Dextrin, Maltodextrin, Flavourings, Modified Starch, Colours (E162, E163, E170, E160a, E100, E132), Acidity Regulator (Trisodium Citrate), Glazing Agent (Carnauba Wax).'
        },
        {
            'id': 'IwpTZiSW8iau4eW8FxcM',
            'name': 'Texan Style BBQ Crunch',
            'brand': 'Alesto',
            'serving_size_g': 100.0,
            'ingredients': '35% Sweet Chilli Flavoured Green Peas (Green Peas, Modified Corn Starch, Sunflower Oil, Wheat Flour, Sugar, Sweet Chilli Seasoning (Sugar, Dried Tomato, Yeast Extract, Dried Garlic, Dried Onion, Acidity Regulator (Citric Acid), Dried Chilli, Dried Cumin, Parsley Flakes, Dried Coriander, Dried Ginger, Dried Aniseed), Sunflower Oil, Colour (Paprika Extract), Lime Oil, Salt), 30% Fried and Salted Corn Snack (Cornflour, Sunflower Oil, Salt), 29% Fried and Salted Corn (Corn, Sunflower Oil, Salt), 4% Barbecue Seasoning (Sugar, Dried Onion, Smoked Paprika, Dried Tomato, Yeast Extract, Smoke Flavouring, Dried Garlic, Dried Chilli, Ground Fennel Seeds, Dried Ginger, Ground White Pepper), Sunflower Oil.'
        },
        {
            'id': 'IxDw7be9D2jT1w979khT',
            'name': 'Skimmed Milk',
            'brand': 'Dairy Pride',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk.'
        },
        {
            'id': 'IxYzvcWj5tmDBI3z098z',
            'name': 'Leios Greek Style Yoghurt - Strawberry',
            'brand': 'Milbona',
            'serving_size_g': 150.0,
            'ingredients': 'Yogurt (Milk), Water, 10% Strawberries, Sugar, 2% Strawberry Juice from Concentrate, Modified Maize Starch, Stabilisers (Pectins, Guar Gum), Beetroot Juice from Concentrate, Natural Flavourings (contains Milk), Acidity Regulators (Citric Acid, Sodium Citrates).'
        },
        {
            'id': 'IydGBJ4lDDfqr6JV8nz4',
            'name': 'All Butter Croissants',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Unsalted Butter (Milk) (18%), Water, Sugar, Salt, Yeast, Pasteurised Whole Egg, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'IyzSqR9Xxt5nhH2onO9K',
            'name': 'Scottish Strawberry Preserve',
            'brand': 'Mackays',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Scottish Strawberries, Gelling Agent (Fruit Pectin), Acidity Regulator (Citric Acid).'
        },
        {
            'id': 'IzoAoEvKkOOuCqDkSKc1',
            'name': 'Cod Fish Fingers',
            'brand': 'Birds Eye',
            'serving_size_g': 114.0,
            'ingredients': 'Cod Fish 58%, Breadcrumb Coating (Wheat Flour, Water, Potato Starch, Salt, Paprika, Yeast, Turmeric), Rapeseed Oil.'
        },
        {
            'id': 'J0Tz4EppKPQQOo6l0AEU',
            'name': 'Tropical Mix',
            'brand': 'Alesto',
            'serving_size_g': 30.0,
            'ingredients': '30% Blanched Peanuts, 25% Flame Raisins (Raisins, Sunflower Oil), 15% Dried Coconut Chips (Coconut, Preservative (Sulphur Dioxide)), 15% Sweetened Dried Banana Chips (Banana, Coconut Oil, Sugar, Natural Flavouring), 8% Almonds, 7% Cashew.'
        },
        {
            'id': 'J1wMKPEFIMiqkge70pvf',
            'name': 'Roast Turkey Breast - Tesco Finest',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Turkey Breast, Butter (Milk) 2%, Sea Salt, Turkey Powder, Yeast Extract, Salt, Chicken Extract, Colour (Plain Caramel), Sage, Garlic Powder, Rosemary, Thyme, Black Pepper.'
        },
        {
            'id': 'J2MKtHRy38D7UJGvVjW9',
            'name': 'British Butter Unsalted',
            'brand': 'Morrisons',
            'serving_size_g': 10.0,
            'ingredients': 'Unsalted British Butter.'
        },
        {
            'id': 'J2aR1FEh2FWHO2ZXnOic',
            'name': 'Cheese Puffs',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, Sunflower Oil, Whey Derivatives (Milk), Maltodextrin, Salt, Cheese Powder (Milk), Whey Powder (Milk), Buttermilk Powder (Milk), Flavouring, Yeast Extract, Colours (Paprika Extract, Curcumin).'
        },
        {
            'id': 'J38mnRxij8EI9h6UiZEs',
            'name': 'Skinny Crunch Light',
            'brand': 'Skinny Bars',
            'serving_size_g': 100.0,
            'ingredients': 'Crisped Cereal (26%) (Rice Flour, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Sugar, Cocoa Powder, Malted Barley Flour, Salt, Rapeseed Oil, Whey Powder (Milk), Emulsifier (Soya Lecithin)), Oats (16%), Bulking Agent (Polydextrose), Oligofructose, Milk Chocolate Coating (8%) (Sugar, Vegetable Fat (Palm), Fat Reduced Cocoa Powder, Whey Powder (Milk), Skimmed Milk Powder, Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Water, Glucose Syrup, Humectant (Glycerine), Fat Reduced Cocoa Powder, Rapeseed Oil, Natural Flavourings, Emulsifier (Soya Lecithin).'
        },
        {
            'id': 'IvIDcbnXWXQpqAQKyHjY',
            'name': 'Eat Natural',
            'brand': 'Eat Natural',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts 54%, Glucose Syrup, Soya Protein Crispies 11% (Soya Protein Isolate, Tapioca Starch, Salt), Dark Chocolate 8% (Cocoa Mass, Sugar, Dextrose, Emulsifier (Soya Lecithin)), Dried Apricots 7% (Apricots, Rice Flour), Honey, Orange Oil.'
        },
        {
            'id': 'J4B1EGMznK6WPiSsNpXW',
            'name': 'Tesco Chicken & Sweetcorn 100% Chicken Breast',
            'brand': 'Tesco',
            'serving_size_g': 47.0,
            'ingredients': 'Chicken Breast (35%), Water, Sweetcorn (23%), Rapeseed Oil, Cornflour, Pasteurised Egg Yolk, Salt, Sugar, Spirit Vinegar, Cornflour, Black Pepper, Lemon Juice from Concentrate.'
        },
        {
            'id': 'J4D3Zn89je6Y7OknQAW2',
            'name': 'Aceto Balsamico Di Modena IGP Invecchiato',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Grape Must, Wine Vinegar.'
        },
        {
            'id': 'J4D8WYd8jyM0sPdGrHgZ',
            'name': 'Doritos Cool Original 40g',
            'brand': 'Doritos',
            'serving_size_g': 40.0,
            'ingredients': 'Corn (Whole Maize Kernels), Sunflower Oil (14%), Rapeseed Oil, Original Flavour (Flavourings (contains Milk), Salt, Glucose Syrup, Sugar, Potassium Chloride, Cheese Powder (from Milk), Flavour Enhancers (Monosodium Glutamate, Disodium 5\'-Ribonucleotide), Acidity Regulators (Malic Acid, Sodium Acetate, Citric Acid), Colour (Annatto), Milk Proteins, Spice).'
        },
        {
            'id': 'J4xdgmspqd14mjo7qYqx',
            'name': 'Finest Sundried Tomato Pesto Rosso',
            'brand': 'Tesco Finest',
            'serving_size_g': 48.0,
            'ingredients': 'Extra Virgin Olive Oil, Rehydrated Sundried Tomatoes (17%), Water, Sundried Tomatoes, Tomato Purée, Water, Basil (6%), Tomato Passata, Pecorino Romano Cheese (Milk) 14.5%, Parmigiano Reggiano Cheese (Milk) 3%, Sugar, Salt, Pine Nuts, Acidity Regulator (Lactic Acid), Garlic, Flavouring, Antioxidant (Ascorbic Acid).'
        },
        {
            'id': 'J5TontsuOum74HYWJsoP',
            'name': 'Popped Oat Crunch',
            'brand': 'Jordans',
            'serving_size_g': 35.0,
            'ingredients': 'Wholegrain Cereals 64% (Oat Flakes, Rice Flour, Wheat Flour, Oat Flour), Sugar, Sunflower Oil, Chicory Root Fibre, Dark Chocolate 3% (Cocoa Solids 44.8% Minimum) (Sugar, Cocoa Mass, Cocoa Fat Butter, Emulsifier (Soya Lecithin)), Fat Reduced Cocoa Powder 2.5%, Puffed Cereals 2% (Wheat, Oat), Glucose Syrup, Natural Flavouring, Antioxidant (Tocopherol-rich Extract).'
        },
        {
            'id': 'J5YxhxSYzqmk1ows7Bvd',
            'name': 'Plantlife Vanilla Ice Cream',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Dried Glucose Syrup, Coconut Oil, Coconut Milk Powder, Maize Maltodextrin, Gluten-Free Oat Flour, Vanilla Extract (1.5%), Pea Protein, Stabilisers (Guar Gum, Locust Bean Gum, Sodium Alginate), Emulsifier (Mono-and Diglycerides of Fatty Acids), Vanilla Bean Seeds.'
        },
        {
            'id': 'J5ZzQra6yQ8CvtGbH14M',
            'name': 'Chicken & Bacon Mayo',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Chicken Breast (20%), Rapeseed Oil, Malted Wheat Flakes, Smoked Bacon (4.5%) (Pork Belly, Salt, Stabilisers (Pentapotassium Triphosphate, Pentasodium Triphosphate), Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Cornflour, Wheat Bran, Spirit Vinegar, Pasteurised Egg, Sugar, Salt, Pasteurised Egg Yolk, Yeast, Malted Barley Flour, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Wheat Gluten, Malted Wheat Flour, Concentrated Lemon Juice, Black Pepper, Yeast Extract, Onion Powder, Brown Mustard Seeds, Flour Treatment Agent (Ascorbic Acid), Palm Oil, Maltodextrin, Mushroom Extract Powder, Lemon Juice Powder.'
        },
        {
            'id': 'J6KYJkzvAhH4ejSzYoQt',
            'name': 'Dr. Oetker',
            'brand': 'Dr. Oetker',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Colours (Carmine (E120), Lutein (E161b)), Sugar, Water, Acidity Regulators (Citric Acid, Lactic Acid, Acetic Acid, Sodium Lactate), Gelling Agent (Carrageenan), Preservative (Potassium Sorbate).'
        },
        {
            'id': 'J744n6ynz0sKShW3Hntm',
            'name': 'Deliciously Free From Digestive Biscuit',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oat Flour, Margarine (Palm Fat, Rapeseed Oil, Water, Palm Oil, Salt, Emulsifier (Mono and Diglycerides of Fatty Acids)), Sugar, Gluten Free Oat Bran, Soya Flour, Cornflour, Partially Inverted Sugar Syrup, Cane Molasses, Raising Agent (Sodium Bicarbonate).'
        },
        {
            'id': 'J7C80zXHwTX9dKqWfpIV',
            'name': 'White Bloomer',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Calcium, Iron, Niacin (B3), Thiamin (B1)), Water, Yeast, Wheat and Rye Sourdough (1.5%), Fermented Wheat Flour, Salt, Vegetable Oils (Rapeseed, Sustainable Palm), Vinegar, Dried Malted Wheat Sourdough, Soya Flour, Wheat Semolina, Salt, Wheat Starch, Flour Treatment Agent (Ascorbic Acid (Vitamin C)).'
        },
        {
            'id': 'J7DRQruDDWfT1O0JomEn',
            'name': 'Middle Eastern Inspired Chicken Salad',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Marinated Bulgur Wheat (33%) (Bulgur Wheat, Water, Lemon Juice, Rapeseed Oil, Coriander, Garlic Purée, Parsley, Salt, Turmeric, Black Pepper, Ground Cumin, Ground Smoked Paprika, White Wine Vinegar, Ground Coriander, Stabilisers (Xanthan Gum)), Cos Lettuce, Marinated Cooked Sliced Chicken Breast (15%) (Chicken Breast, Water, Salt, Lemon Juice, Rapeseed Oil, Ground Coriander, Ground Cumin, Ground Smoked Paprika, Black Pepper, Cayenne Pepper), Yogurt Dressing (Water, Low Fat Yogurt (Milk), Rapeseed Oil, Lemon Juice, Garlic Purée, Cornflour, Sugar, Mint, Salt, Black Pepper, Modified Potato Starch, Dried Egg Yolk, Preservative (Potassium Sorbate), Stabilisers (Guar Gum, Xanthan Gum), Acidity Regulator (Acetic Acid), Colour (Carotenes)), Red Pepper, Cucumber, Chickpeas, Red Onion, Sliced Dried Sweetened Cranberries (Cranberries, Sugar).'
        },
        {
            'id': 'J7wtDiVc65zIL1kkATkb',
            'name': 'Wotsits Prawn Cocktail',
            'brand': 'Walkers',
            'serving_size_g': 13.5,
            'ingredients': 'Corn (Maize), Rapeseed Oil, Prawn Cocktail Seasoning (Flavourings, Sugar, Salt, Dextrose, Potassium Chloride, Yeast Powder, Acid (Citric Acid), Onion Powder, Tomato Powder, Yeast Extract, Colour (Paprika Extract), Sweetener (Sucralose)).'
        },
        {
            'id': 'J8F73gsHxzl9r3Keyvz8',
            'name': 'Fruits Skittles',
            'brand': 'Mars',
            'serving_size_g': 18.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Fat, Acids (Citric Acid, Malic Acid), Dextrin, Maltodextrin, Flavourings, Modified Starch, Colours (E162, E163, E170, E160a, E100, E132, E133), Acidity Regulator (Trisodium Citrate), Glazing Agent (Carnauba Wax).'
        },
        {
            'id': 'J8TD6pB0Js6mjP45wzmJ',
            'name': 'Dumpling Mix',
            'brand': 'Aunt Bessie\'s',
            'serving_size_g': 17.75,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Beef Suet (Beef Fat, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin)), Raising Agents (Monocalcium Phosphate, Sodium Bicarbonate, Potassium Hydrogen Carbonate).'
        },
        {
            'id': 'J8Y31v8a8WEfgUZ2x8vr',
            'name': 'High Protein Beef & Lentil Spaghetti Bolognese',
            'brand': 'Lidl',
            'serving_size_g': 380.0,
            'ingredients': '59% Bolognese Sauce (23% Beef, Tomatoes, Tomato Paste, Water, Carrot, Onion, Garlic Purée, Red Wine Vinegar (contains Sulphites), Low Sodium Salt (Potassium Chloride, Salt), Rapeseed Oil, Sugar, Vegetable Stock (Water, Onion, Carrot Juice, Tomato, Herb, Glucose Syrup, Yeast Extracts, Salt, Chicory Extract, Sugar, Rapeseed Oil, Natural Flavouring), Tapioca Starch, Black Pepper, Rosemary, Oregano), 41% Cooked Spaghetti (Water, Durum Wheat).'
        },
        {
            'id': 'J8ihUURfJb7YQgZGIPAw',
            'name': 'Skittles Giants',
            'brand': 'Skittles',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Fat, Malic Acid, Dextrin, Modified Starch, Flavourings, Maltodextrin, Colours (E162, E163, E160a, E170, E100, E153, E133), Citric Acid, Acidity Regulator (Trisodium Citrate), Glazing Agent (Carnauba Wax), Emulsifier (Lecithin).'
        },
        {
            'id': 'J8j4ABoVsWlLdY3YjUS8',
            'name': 'Mayonnaise Heinz Creamy And Smooth',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil 68%, Water, Pasteurized Egg Yolk 5.0%, Spirit Vinegar, Sugar, Salt, Thickeners (Guar Gum, Xanthan Gum), Mustard Seeds, Antioxidant (Calcium Disodium EDTA), Spice.'
        },
        {
            'id': 'J9VHq20OA7qmdyANz8lG',
            'name': 'Topside Of Beef',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Beef, Sea Salt.'
        },
        {
            'id': 'JAEwICuOmOCsz753F3Fy',
            'name': 'Hot Cross Buns',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Dried Fruit, Sugar, Yeast, Butter, Spices.'
        },
        {
            'id': 'JBDbLncxHifMlwFHidIA',
            'name': 'High Protein Granola Cranberry & Almond',
            'brand': 'Crownfield',
            'serving_size_g': 100.0,
            'ingredients': '29% Wholegrain Oat Flakes, 24% Soya Protein Crisps (Soya Protein Isolate, Rice Semolina, Soya Flour, Salt), Sugar, Pumpkin Seeds, Rapeseed Oil, Oat Bran, 2.5% Chopped Almonds, 2.5% Chopped Walnuts, Desiccated Coconut, Honey, 0.5% Freeze-Dried Cranberry Pieces, 0.5% Freeze-Dried Raspberry Pieces, 0.5% Sweetened Freeze-Dried Apricot Pieces (Apricot, Sugar).'
        },
        {
            'id': 'JBcuhW9S8aHnXdYuwYNT',
            'name': 'Corned Beef',
            'brand': 'M&S',
            'serving_size_g': 102.0,
            'ingredients': 'Cooked British Beef, Salt, Preservative (Sodium Nitrite).'
        },
        {
            'id': 'JCLJJlAeBsEgeIxlNb74',
            'name': 'Basil Pesto',
            'brand': 'Plant Menu',
            'serving_size_g': 100.0,
            'ingredients': 'Basil 38%, Sunflower Oil, Water, Tofu 5% (Soya Beans, Water, Firming Agent (Magnesium Chloride)), Cashew Nuts 5%, Pine Nuts 2%, Potato Flakes (Dried Potato, Emulsifier (Mono-and Diglycerides of Fatty Acids)), Sugar, Salt, Acidity Regulator (Lactic Acid).'
        },
        {
            'id': 'JDcZcJqpsjAemLtTw2wh',
            'name': 'MINI Summer Fruits',
            'brand': 'Robinsons',
            'serving_size_g': 100.0,
            'ingredients': 'Fruit (Blackcurrant 1%, Cherry 0.6%), Water, Acid (Citric Acid), Natural Colour (Anthocyanins), Acidity Regulator (Sodium Citrate), Natural Flavouring, Sweeteners (Sucralose, Acesulfame K), Preservatives (Potassium Sorbate, Sodium Metabisulphite).'
        },
        {
            'id': 'J8ovP9YAFKMgi7b8qhLr',
            'name': 'Bacon Bites',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Flour, Maize Flour, Rapeseed Oil, Potato Flour, Yeast Extract Powder, Sugar, Colours (Beetroot Red, Paprika Extract), Dextrose, Salt, Flavouring, Onion Powder.'
        },
        {
            'id': 'JEeqQvlMXOEN5MTbbGZw',
            'name': 'Nomadic Fuel Up',
            'brand': 'Nomadic',
            'serving_size_g': 500.0,
            'ingredients': 'Semi-Skimmed Milk 79%, Water, Milk Protein, Maltodextrin, Vegetable Oil 2.4% (Rapeseed, Sunflower), Coconut Milk, Gluten Free Oat Fibre, Soluble Corn Fibre, Rice Starch, Fat Reduced Cocoa Powder 1.5%, Vitamins (A, C, D, E, K, B1, B3, B5, B6, B12, Folic Acid, Biotin), Minerals (Magnesium, Iron, Copper, Manganese, Selenium, Chromium, Molybdenum, Iodine), Emulsifier (Lecithins), Sweetener (Acesulfame K, Sucralose), Thickener (Gellan Gum, Carrageenan), Lactase, Natural Flavours.'
        },
        {
            'id': 'JEi47qXxzFZBGWlhEY1o',
            'name': '6 Three Chilli & Pork Sausages',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (87%), Water, Red Jalapeño Chilli (3%), Rice Flour, Salt, Dextrose Monohydrate, Gram Flour, Garlic, Calcium Lactate, Paprika, Sugar, Stabiliser (Triphosphates), Smoked Paprika, Green Pepper, Maize Starch, Tomato Powder, Chipotle Chilli Powder, Onion Powder, Smoked Salt, Preservative (Sodium Metabisulphite), Chilli Flakes, Garlic Powder, Habanero Chilli, Oregano, Antioxidant (Ascorbic Acid), Paprika Extract.'
        },
        {
            'id': 'JEkXx1I4CYVhj8l2fKjb',
            'name': 'Reduced Salt Tesco Baked Beans',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Haricot Beans (48%), Water, Tomato Purée (19%), Sugar, Modified Maize Starch, Salt, Onion Powder, Ground Paprika, Maltodextrin, Onion Extract, Paprika Extract, Clove Extract, Capsicum Extract, Flavouring, Rapeseed Oil.'
        },
        {
            'id': 'J91XWkQ5bJp4G1OcZfal',
            'name': 'World Foods',
            'brand': 'Aldi',
            'serving_size_g': 125.0,
            'ingredients': 'Cooked Basmati Rice (92%) (Water, Basmati Rice), Coconut Cream (4%), Sunflower Oil, Coriander (1%), Lime Zest (0.5%), Sugar, Makrut Lime Leaf, Salt, Flavoring.'
        },
        {
            'id': 'J8lQ0ZydezOZFOSNF9EM',
            'name': 'Cup A Soup Chicken & Vegetable With Croutons 4 Pack',
            'brand': 'Batchelors',
            'serving_size_g': 258.0,
            'ingredients': 'Water, Glucose Syrup, Vegetables (3%) (Carrot, Onion, Peas), Maize Starch, Potato Starch, Palm Oil, Chicken (1%), Croutons (0.5%) (Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Palm Oil, Salt, Yeast, Antioxidant (Rosemary Extracts)), Salt, Flavourings, Parsley, Milk Protein, Potassium Chloride, Garlic, Yeast Extract (contains Barley), Sugar, Emulsifier (Mono- and Diglycerides of Fatty Acids), Sea Salt, Turmeric, Black Pepper Extract.'
        },
        {
            'id': 'JFV5L0cvBJ3tfVHu1G80',
            'name': 'Pastrami Beef',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'British Beef Brisket, Salt, Spices (Paprika, Coriander, Black Pepper), Sugar, Stabilisers (Diphosphates, Triphosphates), Potato Starch, Spice Extracts, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite).'
        },
        {
            'id': 'JFs44Ben0iaGxndkYrmg',
            'name': 'Yeo Valley Organic Kefir Strawberry Fermented Yoghurt',
            'brand': 'Yeo Valley',
            'serving_size_g': 100.0,
            'ingredients': 'Organic Milk Fermented with Live Kefir Cultures, Organic Strawberries (5%), Organic Sugar (5%), Organic Maize Starch, Natural Flavouring, Organic Concentrated Lemon Juice.'
        },
        {
            'id': 'JI20I9VPdoQjvZln7B76',
            'name': 'Salted Caramel Greek Style Yogurt',
            'brand': 'Leios',
            'serving_size_g': 150.0,
            'ingredients': 'Yogurt (Milk), Water, Sugar, Modified Maize Starch, 1% Caramel (Sugar, Glucose Syrup, Water), Flavouring, Salt, Stabiliser (Pectins), Colours (Calcium Carbonate, Plain Caramel), Acidity Regulator (Citric Acid).'
        },
        {
            'id': 'JIS9Ha0ZCBMKLmqh4UPR',
            'name': 'Sausage Rolls',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), 17% Pork, Margarine (Palm Oil, Rapeseed Oil, Water, Salt), 7% Pork Fat, Rusk (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Salt, Raising Agent (Ammonium Bicarbonates)), Seasoning (Salt, Onion Powder, Herbs (Ground Sage, Ground Thyme, Rubbed Parsley, Rubbed Sage), Dextrose, Spices (Ground Cayenne, Ground Pimento, Ground White Pepper), Rapeseed Oil), Flour Treatment Agent (L-Cysteine (Wheat)), Glaze (Water, Milk Proteins, Dextrose, Rapeseed Oil).'
        },
        {
            'id': 'JInMRQlndJ9TdEfX1bf5',
            'name': 'Mixed Fruits',
            'brand': 'Tesco',
            'serving_size_g': 30.0,
            'ingredients': 'Sultanas (50%), Raisins, Candied Citrus Peel (14%) (Glucose Syrup, Orange Peel, Lemon Peel, Sugar, Acidity Regulator (Citric Acid), Preservative (Sulphur Dioxide)), Currants, Sunflower Oil.'
        },
        {
            'id': 'JIuy2Dd1S09tB2oA366K',
            'name': 'Berry Granola',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oat Flakes (56%), Glucose Syrup, Rice Flour, Sunflower Oil, Sugar, Dried Berries (3%) (Strawberry, Raspberry, Cherry), Honey, Coconut Flakes (1.5%), Sunflower Seeds, Pumpkin Seeds, Salt, Antioxidant (Tocopherol-Rich Extract).'
        },
        {
            'id': 'JIvM21lC4IzOFgeiGP8N',
            'name': 'Aldi 30 Day Matured Rump Steak',
            'brand': 'Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Beef.'
        },
        {
            'id': 'JJVMdT8NtgsZsK9S5B6T',
            'name': 'Gochujang Pulled Chicken',
            'brand': 'Birchwood',
            'serving_size_g': 180.0,
            'ingredients': '73% Chicken, 16% Gochujang Style Sauce (Water, Glucose Syrup (contains Wheat), Sugar, Rice Wine Vinegar, Spices (Chilli Powder, Paprika Powder, Cayenne Powder), Ginger Purée, Spirit Vinegar, Garlic Purée, Yellow Bean Sauce (Fermented Soya Bean (Soya Bean, Water, Salt, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin)), Sugar, Salt), Maize Starch, Salt, Natural Flavouring, Red Bell Pepper, Dehydrated Garlic, Dehydrated Onion), 8% Marinade (Water, Glucose Syrup, Salt, Stabilisers (Diphosphates, Triphosphates), Modified Maize Starch, Acidity Regulators (Sodium Citrates, Citric Acid), Yeast Extract), 3% Spicy Flavour Glaze (Herbs and Spices (Garlic Powder, Chilli Pepper, Ginger Powder, Fenugreek Seed, Onion Powder, Black Pepper, Paprika Powder, Cumin, Oregano), Dextrose, Sugar, Maize Starch, Red Bell Pepper, Colour (Plain Caramel), Salt, Yeast Extract, White Vinegar Powder (Maltodextrin, White Vinegar), Spice Extracts (Chilli Pepper Extract, Paprika Extract)).'
        },
        {
            'id': 'JJqkQfo0gDoyCPFsPTHS',
            'name': 'Blisscoff Whip Bar',
            'brand': 'Bliss',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate 27% (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Skimmed Milk Powder, Emulsifiers (Soya Lecithin, E476)), Glucose Syrup, Sugar, Bulking Agent (Polydextrose), Water, Fibres (Bamboo, Inulin), Crisped Cereal 6% (Rice Flour, Sugar, Salt), Skimmed Milk Powder, Vegetable Fats (Palm, Palm Kernel), Dried Egg White, Salt, Natural Flavourings, Colour (Caramel E150d), Cinnamon, Emulsifier (Sunflower Lecithin).'
        },
        {
            'id': 'JEzw6IVxRdIBx9S5L7rE',
            'name': 'Whole Grain Super Seeded Cracker',
            'brand': 'Nairn\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Wholegrain Oats (77%), Seeds (12%) (Brown Flaxseeds, Millet, Chia (Salvia hispanica)), Sustainable Palm Fruit Oil, Maize Starch, Raising Agent (Ammonium Carbonates), Sea Salt, Brown Rice Syrup.'
        },
        {
            'id': 'JLr3GG1fMQpVZJzPnpCn',
            'name': 'Taste The Difference Brown Sourdough Bloomer',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Wholemeal Wheat Flour, Wholegrain Rye Flour, Malted Wheat Flour, Wheat Gluten, Kibbled Malted Wheat, Salt, Wheat Bran, Rye Flour, Roasted Barley Malt, Wheatgerm, Barley Malt Extract, Starter Culture.'
        },
        {
            'id': 'JM9KRZjt91rWb0S0JxKi',
            'name': 'Wholemeal Seeded',
            'brand': 'Lidl',
            'serving_size_g': 33.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, 14% Mixed Seeds (Brown Linseeds, Sunflower Seeds, Toasted Brown Linseeds, Toasted Sunflower Seeds, Pumpkin Seeds, Poppy Seeds, Millet Seeds, Golden Linseeds), Yeast, Wheat Gluten, Salt, Malted Barley Flour, Brown Sugar, Fermented Wheat Flour, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Soya Flour, Palm Oil, Spirit Vinegar, Palm Fat, Rapeseed Oil, Emulsifier (Rapeseed Lecithins), Caramelised Sugar Syrup, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'JMBpBVnzKzXrYWSK6rtg',
            'name': 'Luxury Cottage Pie',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes 34%, Beef 25%, Water, Double Cream (Milk), Red Wine, Whole Milk, Onions, Carrots 2.5%, Celery, Pasteurised Liquid Whole Free Range Egg, Modified Maize Starch, Beef Stock (Water, Beef Extract, Beef, Beef Fat, Modified Maize Starch, Sugar, Salt, Beef Bones, Concentrated Onion Juice), Tomato Paste, Tomato Purée, Garlic Purée, Worcester Sauce (Water, White Vinegar, Sugar, Onion, Salt, Tamarind Paste, Cloves, Ginger, Garlic, Barley Malt Extract), Red Wine Vinegar, Butter (Milk), Yeast Extract (contains Barley), Vegetable Bouillon (Salt, Maltodextrin, Potato Starch, Yeast Extract, Sugar, Onion Powder, Parsnip Powder, Sunflower Oil, Lovage Extract, Ground Turmeric, Ground White Pepper, Garlic Powder, Mace Powder, Nutmeg Powder, Dried Parsley), Rapeseed Oil, Barley Malt Extract, Brown Sugar, Thyme, Salt, Rosemary, Ground White Pepper, Cracked Black Pepper, Ground Nutmeg.'
        },
        {
            'id': 'JMK8RbdNgb1zgJ8wBcF4',
            'name': 'Tropical Pineapple',
            'brand': 'Activia',
            'serving_size_g': 100.0,
            'ingredients': 'Fat Free Yogurt (Milk), Pineapple (9%), Modified Starch, Acidity Regulators (Citric Acid, Sodium Citrate), Thickener (Locust Bean Gum), Flavouring, Sweeteners (Acesulfame K, Sucralose), Cultures (Lactobacillus bulgaricus, Streptococcus thermophilus, Lactococcus lactis, Bifidobacterium lactis (Bifidus Actiregularis)).'
        },
        {
            'id': 'JNltYUC9rrOfeDkyA7Aj',
            'name': 'Chilli & Lime Chicken',
            'brand': 'Glensallagh',
            'serving_size_g': 50.0,
            'ingredients': 'Chicken Fillet, Salt, Pea Starch, Glucose Syrup, Stabilisers (Triphosphates, Guar Gum), Potato Starch, Chicken Stock (Chicken, Salt), Brown Sugar (Sugar, Molasses), Natural Flavouring, Preservative (Sodium Lactate), 3% Chilli, Lime Coating (Chilli Powder, Caramelised Sugar Powder, Cayenne, Paprika, Cumin, Garlic Powder, Sugar, Cornflour, Rice Flour, Cumin, Cayenne Pepper, Colour (Paprika Extract), Salt, Lemon Powder, Garlic Powder, Onion, Ground Coriander, Herbs, Coriander, Parsley, Spice Extract, Natural Lime Flavouring).'
        },
        {
            'id': 'JNpJL55meEGa4QCrziM7',
            'name': 'Coronation Chicken Sandwich',
            'brand': 'Waitrose',
            'serving_size_g': 172.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Folic Acid, Iron, Niacin, Thiamin), Roast Chicken Breast 24% (Chicken Breast, Cornflour, Salt), Water, Spinach, Rapeseed Oil, Malted Wheat Flakes, Sultanas, Dried Apricots (Dried Apricots, Rice Flour, Preservative (Sulphur Dioxide)), Wheat Bran, Vinegar, Malted Kibbled Wheat, Coriander, Pasteurised Free Range Egg, Pasteurised Free Range Egg Yolk, Cornflour, Salt, Yeast, Sugar, Malted Barley Flour, Wheat Protein, Emulsifiers (Mono - and Diglycerides of Fatty Acids, Mono - and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Onion Powder, Ground Turmeric, Malted Wheat Flour, Red Wine, Concentrated Lemon Juice, Onion, Ground Coriander, Ground Cumin, Tomato Paste, Ground Fenugreek, Tomato Powder, Flour Treatment Agent (Ascorbic Acid), Palm Fat (Certified Sustainable), Ground Ginger, Ground Cloves, Garlic Powder, Colour (Plain Caramel), Ground Cayenne Pepper, Ground Fennel Seed, Turmeric Extract, Leek Extract, Mustard Powder, Ground Cardamom, Ground Cinnamon, Ground Black Pepper.'
        },
        {
            'id': 'JP7aBidDuxx5x77ZzDcz',
            'name': 'Golden Wonder Chippie',
            'brand': 'Golden',
            'serving_size_g': 25.0,
            'ingredients': 'Potatoes, Vegetable Oils (Rapeseed, Sunflower) in varying proportions, Salt & Vinegar Flavour (Flavouring, Potato Starch, Flavour Enhancer (Monosodium Glutamate), Salt, Stabiliser (Potassium Chloride), Acid (Citric Acid)).'
        },
        {
            'id': 'JPN6oFAHUORO9USZ7bUR',
            'name': 'Crumble Topping',
            'brand': 'Tesco',
            'serving_size_g': 55.0,
            'ingredients': 'Wheat Flour, Sugar, Palm Oil, Breadcrumbs, Water, Demerara Sugar, Rapeseed Oil.'
        },
        {
            'id': 'JQnBTov4tGEJkHxISmAF',
            'name': 'Rice Dish',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '42% Cooked Long Grain Rice (Water, Long Grain Rice, Salt), Water, Onion, 10% Seasoned and Cooked Chicken (Chicken Breast, Starch (Maize, Tapioca), Dextrose, Salt), Garlic, Rice Starch, Spices, Salt, 7% Coconut Paste (Coconut, Water), Cherry Tomatoes, 5% Mango, Triple Concentrated Tomato Purée, Spirit Vinegar.'
        },
        {
            'id': 'JR76zpfO25n3llyBgWV2',
            'name': 'Peri-peri Lemon And Herb',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rapeseed Oil, White Wine Vinegar, Glucose-Fructose Syrup, Onion Purée, Lemon Juice from Concentrate (4%), Salt, Modified Maize Starch, Acidity Regulator (Acetic Acid), Garlic (Water, Dried Garlic, Acidity Regulator (Citric Acid)), Cayenne Pepper, Parsley, Preservative (Potassium Sorbate), Dried Onion, Stabiliser (Xanthan Gum), Oregano, Paprika, Colour (Paprika Extract), Bird\'s Eye Chilli, Rosemary, Lemon Oil.'
        },
        {
            'id': 'JRfqqOALM7gyFWEE4e5U',
            'name': 'Onion Rings',
            'brand': 'M&S',
            'serving_size_g': 16.3,
            'ingredients': 'Potato (Potato Starch, Potato Flour), Responsibly Sourced Palm Oil, Wheat Flour (contains Gluten), Rye Flour (contains Gluten), Rapeseed Oil, Fried Onion Seasoning (Dried Onions, Sugar, Salt, Yeast Extract, Rice Flour, Acid (Citric Acid), Flavouring, Dried Garlic, Colour (Paprika Extract)), Dried Onions, Salt, Turmeric.'
        },
        {
            'id': 'JSBejXYTH9TmbErVrqUG',
            'name': 'Walkers Salt & Vinegar',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Vegetable Oil (Sunflower, Rapeseed, in varying proportions), Salt and Vinegar Seasoning (Flavouring, Corn (Maize) Starch, Salt, Acids (Citric Acid, Malic Acid), Yeast Extract, Potassium Chloride, Antioxidant (Rosemary Extract)).'
        },
        {
            'id': 'JSHdpRZzb1fZrqPwZfwe',
            'name': 'Free Range Milk Strawberries & Cream',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Free Range Whole Milk (94%), Raw Cane Sugar (3.5%), Strawberry Puree (1.0%), Strawberry (0.5%), Natural Flavouring, Natural Colour Concentrate (0.75%), Free Range Double Cream.'
        },
        {
            'id': 'JSR6suJlZf7S0XDUQNaB',
            'name': 'Lemon Zero Sugar',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Lemon Juice from Concentrate (3%), Acids (Citric Acid, Malic Acid), Acidity Regulator (Sodium Citrates), Sweeteners (Sucralose, Acesulfame K), Stabilisers (Gum Arabic, Guar Gum), Flavourings, Preservative (Potassium Sorbate), Antioxidant (Ascorbic Acid), Coconut Oil.'
        },
        {
            'id': 'JTU0LQVb2R7cuX3GCbtj',
            'name': 'Chin Chin',
            'brand': 'Jafro Foods',
            'serving_size_g': 100.0,
            'ingredients': 'Plain Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamine, Treatment Agent (Ascorbic Acid)), Sugar, Water, Salt, Baking Powder (Wheat Starch, Raising Agent (E500, E450)), Ground Nutmeg, Spread (Water, Rapeseed Oil, Palm Oil, Reconstituted Buttermilk, Salt, Emulsifiers (Mono & Diglycerides of Fatty Acids, Polyglycerol Polyricinoleate), Stabiliser (Sodium Alginate), Preservative (Potassium Sorbate), Colours (Annatto Bixin, Curcumin), Flavouring, Acidity Regulator (Lactic Acid), Vitamin A&D).'
        },
        {
            'id': 'JTqI71yplubm0MIinCzh',
            'name': 'Nairn\'s Fruit Oatcake',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oats 69%, Currants 12% (Currants, Sunflower Oil), Brown Sugar, Sustainable Palm Fruit Oil, Raising Agent (Sodium Carbonates), Sea Salt.'
        },
        {
            'id': 'JTqh04xNjhscUuptxNmT',
            'name': 'Mayonnaise',
            'brand': 'Hellmann\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Spirit Vinegar, Modified Maize Starch, Sugar, Egg and Egg Yolk 4%, Vegetable Oil (Rapeseed), Salt, Cream Powder (Milk), Citrus Fibre, Colours (Titanium Dioxide, Beta Carotene), Thickener (Xanthan Gum), Flavourings (contain Milk), Preservative (Potassium Sorbate), Lemon Juice Concentrate, Antioxidant (Calcium Disodium EDTA).'
        },
        {
            'id': 'JTzq96k8ochvMdUIFPOF',
            'name': 'Fudge',
            'brand': 'Cadbury',
            'serving_size_g': 22.0,
            'ingredients': 'Sugar, Glucose Syrup, Palm Oil, Cocoa Butter, Cocoa Mass, Whey Powder from Skimmed Milk Powder, Whey Permeate Powder from Milk, Milk Fat, Emulsifiers (Lecithins, E471, E442), Flavourings, Acidity Regulator (Sodium Carbonates), Salt, Stabiliser (E509).'
        },
        {
            'id': 'JUJp1KwyAT3NFBP5mYvM',
            'name': 'Seeded Loaf',
            'brand': 'Tesco Finest',
            'serving_size_g': 33.0,
            'ingredients': 'Water, Rice Flour, Seeds (12%) (Brown Linseed, Sunflower Seed, Millet Seed, Golden Linseed, Poppy Seed), Maize Starch, Tapioca Starch, Potato Starch, Yeast, Rapeseed Oil, Psyllium Husk Powder, Maize Flour, Sugar, Dried Egg White, Rice Protein, Stabilisers (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Salt, Bamboo Fibre, Fermented Maize Starch.'
        },
        {
            'id': 'JUfdhPLDduq1mGDF62ta',
            'name': 'Baked Beans In Tomato Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Haricot Beans (53%), Tomato Purée (24%), Water, Sugar, Modified Maize Starch, Rapeseed Oil, Salt, Onion Powder, Paprika, Clove Extract, Cinnamon Extract, Paprika Extract, Flavouring, Capsicum Extract, Garlic Oil.'
        },
        {
            'id': 'JUryEabcZ7vbAQ9Gh1Bv',
            'name': 'Raspberry Yoghurt',
            'brand': 'Brooklea',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (80%) (Milk), Water, Modified Maize Starch, Flavouring, Sweeteners (Acesulfame K, Sucralose), Acidity Regulator (Citric Acid), Bifido Cultures.'
        },
        {
            'id': 'JVBvSz3J6DKmmiFwm7Hp',
            'name': 'Crispy & Rich Mini Cornflake Cluster Bites',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (60%) (Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Milk Fat, Lactose (Milk), Emulsifier (Soya Lecithin)), Corn Flakes (40%) (Maize, Sugar, Salt, Barley Malt Extract, Dextrose, Niacin, Iron, Vitamin B6, Riboflavin, Vitamin B1, Folic Acid, Vitamin B12).'
        },
        {
            'id': 'JVRrfPoeFgBJoUErWx5U',
            'name': 'Garlic Herb Breaded Prawns',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'King Prawn (Penaeus Vannamei) (Crustacean) (43%), Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Water, Rapeseed Oil, Wheat Starch, Salt, Garlic Powder, Olive Oil, Yeast, Onion Powder, Yeast Extract, Dried Chives, Dried Parsley, Black Pepper, Parsley Oil, Garlic Extract, Thyme Extract, Sage Extract, Rosemary Extract.'
        },
        {
            'id': 'JWJhADpKck0dt6Ofw5Q5',
            'name': 'Chicken Casserole',
            'brand': 'Crestwood',
            'serving_size_g': 400.0,
            'ingredients': 'Water, Cooked Marinated Chicken (25%) (Chicken Breast Inner Fillet, Chicken Thigh, Potato Starch, Salt, Lemon Juice from Concentrate, White Pepper), Herb Dumplings (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm Oil, Sunflower Oil), Raising Agents (Diphosphates, Sodium Carbonates), Parsley, Salt, Thyme, White Pepper), Carrot, Onion, Swede, Red Wine, Cornflour, Tomato Purée, Chicken Stock (Water, Yeast Extract, Chicken Fat, Chicken, Salt, Carrot, Onion, Tomato Purée, Ground Bay Leaf, Thyme), Rapeseed Oil, Garlic Purée, Yeast Extract, Salt, Gelling Agent (Pork Gelatine), Sugar, Thyme, Colour (Plain Caramel), Black Pepper, Sage.'
        },
        {
            'id': 'JWkqMCfrZfgADOahTaR8',
            'name': 'Multigrain Crunchy Rye Breads',
            'brand': 'Ryvita',
            'serving_size_g': 10.5,
            'ingredients': 'Rye Flour, Bran, Toasted Seeds & Grains (17%) (Buckwheat, Brown Linseed, Kibbled Soya, Sesame Seeds, Kibbled Rye), Salt.'
        },
        {
            'id': 'Jaa1wNNPPwfo0G0HpwTB',
            'name': 'Indian Style Cauliflower Baked Crackers',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Corn Flour, Tapioca Starch, Modified Corn Starch, Rapeseed Oil, Cauliflower (5%), Mixed Spices (3%) (Turmeric Powder, Jalapeño Chilli, Onion Powder, Cumin Powder, Coriander Powder, Fennel Powder, Cardamom, Nutmeg, Garlic Powder, Cinnamon Powder, Allspice), Rice Syrup, Sea Salt, Flavouring (Extracts of Rosemary).'
        },
        {
            'id': 'JarSQ9HmoTH53HiQJuyP',
            'name': 'Mini Vanilla Cupcakes',
            'brand': 'Oggs',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Water, Palm Oil, Chickpea Water, Humectant (Glycerol), Invert Sugar Syrup, Maize Starch, Gluten Free Oats, Fava Bean Protein, Modified Potato Starch, Modified Maize Starch, Raising Agents (E450(i), E500(ii), E501(i)), Wheat Starch, Emulsifiers (E471, E477, E481), Sunflower Oil, Dextrose, Cocoa Butter, Preservative (Potassium Sorbate), Rice Flour, Wheat Gluten, Flavouring, Acidity Regulator (Citric Acid), Thickener (Tragacanth), Plant Concentrates (Beetroot, Safflower, Spirulina), Colour (Curcumin), Salt, Stabiliser (Xanthan Gum).'
        },
        {
            'id': 'Jf8QLj9IJOu8o4mXgxAz',
            'name': 'Four Cheese Tortelloni',
            'brand': 'Morrisons',
            'serving_size_g': 150.0,
            'ingredients': 'Fresh Egg Pasta (58%) (Wheat Flour, Durum Wheat Semolina, Egg, Water), Ricotta Cheese (Milk) (10%), Sunflower Oil, Wheat Flour, Whey Powder (Milk), Water, Low Fat Cheese (Milk) (3%), Emmental Cheese (Milk), Edam Cheese (Milk), Potato Starch, Grana Padano Cheese (Cheese (Milk), Preservative (Lysozyme (Egg))), Gorgonzola Cheese (Milk), Salt, Flavouring (contains Milk, Barley), Emulsifier (Sodium Citrates), Acidity Regulator (Citric Acid), Yeast.'
        },
        {
            'id': 'JfNw6BGMN0vuWqTMTtxi',
            'name': 'Smoky BBQ Flavour Coated Peanuts',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 30.0,
            'ingredients': 'Peanuts 44%, Rapeseed Oil, Potato Starch, Modified Maize Starch, Maize Starch, Sugar, Modified Tapioca Starch, Wheat Starch, Rice Flour, Salt, Yeast Extract Powder, Onion Powder, Thickener (Acacia Gum), Garlic Powder, Flavouring, Tomato Powder, Colours (Paprika Extract, Curcumin), Red Bell Pepper, Black Pepper, Acid (Citric Acid), Chilli, Cumin, Oregano.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())
    updated = 0

    for product in clean_data:
        try:
            cursor.execute("""
                UPDATE foods
                SET ingredients = ?, serving_size_g = ?, updated_at = ?
                WHERE id = ?
            """, (product['ingredients'], product['serving_size_g'], current_timestamp, product['id']))

            if cursor.rowcount > 0:
                updated += 1
                print(f"✅ {product['brand']} - {product['name']}")
                print(f"   Serving: {product['serving_size_g']}g\n")
        except Exception as e:
            print(f"❌ Error updating {product['name']}: {str(e)}\n")

    conn.commit()
    conn.close()

    print(f"✨ BATCH 102 COMPLETE: {updated} products cleaned")

    # Calculate new total
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM foods WHERE updated_at IS NOT NULL AND updated_at > 0")
    total = cursor.fetchone()[0]
    conn.close()

    print(f"📊 TOTAL PROGRESS: {total} products cleaned")

    # Check for milestones with MASSIVE batch size
    milestones = [2100, 2125, 2150, 2175, 2200, 2225, 2250, 2275, 2300, 2325, 2350, 2375, 2400]
    previous_total = total - updated

    for milestone in milestones:
        if previous_total < milestone <= total:
            print(f"\n🎉🎉 {milestone} MILESTONE ACHIEVED! 🎉🎉")

    if total >= 2100:
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
        print("\n🚀 BATCH 102 - MASSIVE 300 PRODUCT BATCH! 6X SPEED BOOST! 🚀")

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    else:
        db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🧹 CLEANING INGREDIENTS - BATCH 102 (MASSIVE 300 PRODUCT BATCH!)\n")
    update_batch102(db_path)
