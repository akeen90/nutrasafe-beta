#!/usr/bin/env python3
"""
Clean ingredients batch 20 - Mixed Brands (Larger Batch)
"""

import sqlite3
from datetime import datetime

def update_batch20(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 20 (Mixed Brands - Larger Batch)\n")

    clean_data = [
        {
            'id': 'y5POGRvIO7Wrnd4lpT4o',
            'name': 'AG1',
            'brand': 'Ag1',
            'serving_size_g': 12.0,
            'ingredients': 'Dairy-based blend (of which 29% is Fermented) [Lactose (from Milk), Vegetable Oils (High Oleic Sunflower Oil, Coconut Oil, Rapeseed Oil, Sunflower Oil), Spirulina, Lecithin (Soya), Alkaline Pea Protein Isolate, Apple Powder, Inulin, Citrus Bioflavonoids Extract, Ascorbic Acid, Wheatgrass Juice Powder, Chlorella Powder, Alfalfa Powder], Vitamins (Vitamins A, C, E, B-complex (B1, B2, B6, B12), Folate, Biotin, Pantothenic Acid, Calcium, Phosphorus, Magnesium, Zinc), Probiotics (Bifidobacterium bifidum, Lactobacillus acidophilus). Contains Milk, Soya, Wheat.'
        },
        {
            'id': 'sAo5to46xiOgGJ0ygewm',
            'name': 'Sweet Chili Crunch',
            'brand': 'Alesto',
            'serving_size_g': 100.0,
            'ingredients': 'Sweet Chilli Flavoured Green Peas (33%) (Green Peas, Modified Corn Starch, Sunflower Oil, Wheat Flour, Sugar, Sweet Chilli Seasoning [Sugar, Dried Tomato, Yeast Extract, Dried Garlic, Dried Onion, Acidity Regulator: Citric Acid, Dried Chilli, Dried Cumin, Parsley Flakes, Dried Coriander, Dried Ginger, Dried Anise, Sunflower Oil, Colour: Paprika Extract, Lime Oil], Salt), Sweet Chilli Flavour Fried Broad Beans (29%) (Broad Beans, Sunflower Oil, Sweet Chilli Flavour Seasoning [Salt, Sugar, Ground Spices (Black Pepper, Cayenne Pepper), Dried Tomato, Dried Onion, Maltodextrin, Dried Garlic, Dried Paprika, Dried Cumin, Dried Oregano, Yeast Extract, Acidity Regulator: Citric Acid, Colour: Paprika Extract]), Fried Salted Corn (19%) (Corn, Sunflower Oil, Salt), Sweet Chilli Flavour Fried Corn Snack (19%) (Corn, Sunflower Oil, Sweet Chilli Seasoning [Glucose Syrup, Fructose, Sugar, Ground Spices (Onion, Paprika, Cayenne Pepper), Dried Tomato, Salt, Natural Flavouring, Dried Lemon Juice, Dried Beetroot]). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'XBSIXcVDCzguEbYqnHnN',
            'name': 'Alpen Chocolate Caramel & Shortbread',
            'brand': 'Alpen',
            'serving_size_g': 24.0,
            'ingredients': 'Cereals (40%) (Oats, Rice, Wheat), Oligofructose Syrup, Milk Chocolate (14%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Milk Powder, Milk Fat, Emulsifier: Soya Lecithin), Cereal Flours (Rice, Wheat, Malted Barley), Caramel Pieces (4.5%) (Sugar, Glucose Syrup, Condensed Milk, Palm Oil, Shea Kernel Oil, Maize Starch, Humectant: Glycerol, Palm Stearin, Flavouring, Emulsifiers (Glycerol Monostearate, Sunflower Lecithin), Salt), Plain Chocolate (4.5%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier: Soya Lecithin, Flavouring), Glucose Syrup, Humectant: Glycerol, Shortbread Pieces (1.5%) (Fortified Wheat Flour (Wheat, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Shea Kernel, Rapeseed), Sugar, Invert Sugar Syrup, Tapioca Starch, Salt, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Emulsifier: Sunflower Lecithin), Vegetable Oils (contains Sunflower and/or Rapeseed), Sugar, Flavouring, Salt, Emulsifier: Soya Lecithin. Contains Barley, Milk, Oats, Soya, Wheat. May Contain Nuts.'
        },
        {
            'id': 'UXmzZD7aI1wIPgsXafJS',
            'name': 'Follow On Milk',
            'brand': 'Aptamil',
            'serving_size_g': 100.0,
            'ingredients': 'Dairy-Based Blend (of which 29% is Fermented) [Lactose (from Milk), Vegetable Oils (High Oleic Sunflower Oil, Coconut Oil, Rapeseed Oil, Sunflower Oil), Skimmed Milk, Demineralised Whey (from Milk), Whey Concentrate (from Milk), Calcium Phosphate, Fish Oil, Potassium Chloride, Potassium Citrate, Choline Chloride, Sodium Citrate, Vitamin C, Calcium Carbonate, Emulsifier (Soy Lecithin), Inositol, Magnesium Chloride, Vitamin E, Antioxidant (Vitamin C), Pantothenic Acid, Nicotinamide, Thiamin, Riboflavin, Vitamin B₆, Folic Acid, Potassium Iodide, Vitamin K₁, Biotin, Vitamin B₁₂], Galacto-Oligosaccharides (GOS) (from Milk), Fructo-Oligosaccharides (FOS), Milk Protein, Magnesium Hydrogen Phosphate, Oil from Mortierella Alpina, Sodium Chloride, L-Tryptophan, Ferrous Sulphate, Zinc Sulphate, L-Carnitine, Copper Sulphate, Vitamin A, Manganese Sulphate, Sodium Selenite, Vitamin D₃. Contains Fish, Milk, Soya.'
        },
        {
            'id': 'cVBq2yq6CrWsE6GzqB2i',
            'name': 'Breaded Chicken Breast Mini Fillets',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast Mini Fillets (75%) [Chicken Breast (95%), Water, Salt, Spirit Vinegar, Concentrated Lemon Juice], Breadcrumb Coating (18%) [Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Water, Wheat Starch, Wheat Gluten, Vegetable Oils [Extra Virgin Olive Oil, Sunflower Oil], Yeast, Cider Vinegar, Salt, Sugar, Yeast Extract, Garlic Powder, Onion Powder, Sage, White Pepper], Rapeseed Oil. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'md3ECz5nQixG6Fsr4YbH',
            'name': 'Bacon',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork 88%, Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': 'Xn2HybnqBI7Ui8j4p82x',
            'name': 'Chicken Soup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Chicken (2%), Modified Maize Starch, Chicken Fat, Cornflour, Rapeseed Oil, Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Sugar, Flavourings, Skimmed Milk Powder, Salt, Stabilisers (Diphosphates, Polyphosphates), Yeast Extract, Onion Powder, Garlic Powder, White Pepper, Sage Extract, Colour (Carotenes). Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '0keoqMNJTEANXg9pNezz',
            'name': 'Crispy Fries',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Flour, Vegetable Oils in varying proportions [Rapeseed, Sunflower], Potato Starch, Potato Maltodextrin, Salt (2%), Potassium Chloride, Maize Starch, Acidity Regulator (Sodium Acetate), Colour (Paprika Extract), Citric Acid, Spirit Vinegar Powder, Sugar, Yeast Extract, Flavouring. Contains Barley, Milk, Oats, Rye, Soya, Sulphur Dioxide/Sulphites, Wheat.'
        },
        {
            'id': '1TOHvxe544DorEPFvsBH',
            'name': 'Fennel Sausage, N\'duja & Red Pepper',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Italian \'00\' Fortified Wheat Flour (33%) [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Mozzarella Cheese (Milk) (15%), Water, Fennel Pork Sausage Crumb (8%) [Pork (61%), San Marzano Tomatoes [Tomatoes, Tomato Juice], Pork Fat, Rapeseed Oil, Tomatoes, Fennel Seeds, Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Salt, Black Pepper, Olive Oil, Tomato Purée, Cornflour, Smoked Paprika, Sage, Flavouring, Ground Fennel, Extra Virgin Olive Oil, Yeast], San Marzano Tomatoes (7%) [Tomatoes, Tomato Juice], Tomato Passata [Tomatoes, Acidity Regulator (Citric Acid)], N\'duja Pork Sausage Tomato Sauce (4%) [San Marzano Tomatoes [Tomatoes, Tomato Juice], N\'duja Pork Sausage Paste (33%) [Pork (63%), Extra Virgin Olive Oil, Chilli Peppers, Smoked Paprika, Salt, Paprika, Dextrose, Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Sodium Nitrite)], Tomatoes, Olive Oil, Tomato Purée, Cornflour, Salt, Extra Virgin Olive Oil]. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'nmE3op8SXghgwl9LEj5Q',
            'name': 'Fruit Splits',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Partially reconstituted skimmed milk concentrate, Water, Glucose Sugar, Fruit Content (Strawberry Purée (5%) for Strawberry, Blackcurrant Juice from Concentrate (5%) for Blackcurrant, Pineapple Juice from Concentrate for Pineapple), Palm Oil, Whey Powder (Milk), Flavourings, Colours (Beetroot Red, Carotenes, Curcumin), Citric Acid, Stabilisers (Guar Gum, Carob Bean Gum), Emulsifier (Mono- and Diglycerides of Fatty Acids). Contains Milk.'
        },
        {
            'id': 'oia3sR0jLfxFvJ8aDcTS',
            'name': 'Mini Rocky Road Bites',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate (44%) [Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Anhydrous Milk Fat, Lactose (Milk), Emulsifier (Soya Lecithins)], Sultanas (14%), Biscuit Pieces (10%) [Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Wholemeal Wheat Flour, Sugar, Palm Oil, Rapeseed Oil, Partially Inverted Sugar Syrup, Raising Agents (Sodium Carbonates, Ammonium Carbonates), Salt], Palm Oil, Mini Marshmallows (10%) [Glucose-Fructose Syrup, Sugar, Water, Pork Gelatine, Maize Starch, Colour (Beetroot Red), Flavouring], Crisped Rice (6%) [Rice Flour, Sugar, Malted Barley Extract, Firming Agent (Calcium Carbonate), Sunflower Oil, Emulsifier (Soya Lecithins)], Glucose Syrup, Glacé Cherries (2%) [Cherries, Glucose-Fructose Syrup, Acidity Regulator (Citric Acid), Blackcurrant Concentrate, Carrot Concentrate, Radish Concentrate]. Contains Barley, Milk, Soya, Wheat. May Contain Nuts.'
        },
        {
            'id': 'WX6JdL6dAaeDwwGo4ZmO',
            'name': 'Plant Based Sweet Potato Katsu Curry',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Breaded Battered Sweet Potato (38%) [Sweet Potato (58%), Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Rapeseed Oil, Yeast, Wheat Starch, Potato Starch, Dextrose, Salt, Turmeric, Black Pepper, Extract], Cooked Jasmine Rice (32%) [Water, Rice], Water, Coconut Milk [Coconut, Water], Soy Sauce [Water, Soya Beans, Salt], Brown Sugar, Ginger Purée, Cornflour, Garlic Purée, Gram Flour, Yeast Extract, Spices, Sesame Seed Oil, Onion Powder, Herbs, Red Chillies, Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Salt, Garlic Powder, Fennel. Contains Cereals Containing Gluten, Sesame, Soya, Wheat.'
        },
        {
            'id': '52CQtmCXRvMxNcjsAnUk',
            'name': 'Savoury Extra Tasty Chicken Breast Steaks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (93%), Sunflower Oil, Sugar, Red Bell Peppers, Yeast Extract, Dried Onion, Salt, Dried Garlic, Caramelised Sugar Syrup, Onion Powder, Parsley, Black Pepper, Smoked Salt, Paprika Extract.'
        },
        {
            'id': 'K85irm9Ev0HLqopMQInF',
            'name': 'Sliced Cured Ham On The Bone',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Stabilisers (Triphosphates, Potassium Phosphates, Polyphosphates), Preservative (Sodium Nitrite).'
        },
        {
            'id': 'SYpOwbPNUrBWRDshjIrw',
            'name': 'Smoky Fajita Chicken Stir-fry Kit',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Diced Chicken Breast (52%), Mexican Style Stir Fry Sauce Sachet [Water, Dextrose, Tomatoes, Tomato Paste, Spirit Vinegar, Spices [Cumin, Paprika, Chilli Powder], Onion Purée, Rapeseed Oil, Cornflour, Lemon Juice from Concentrate, Salt, Garlic Purée, Smoked Maltodextrin, Parsley, Oregano], White Onions, Yellow Peppers (10%), Red Peppers (9%), Sugar, Spices [Chillies, Coriander, Black Pepper, Cumin, Cayenne Pepper, Oak Smoked Paprika], Maltodextrin, Salt, Garlic Powder, Dried Onions, Green Bell Peppers, Parsley, Spice Extracts, Stabiliser (Guar Gum), Key Lime Oil.'
        },
        {
            'id': 'J4QP27qSQOZYySLTdKSy',
            'name': 'Smoky Tofu Burrito',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Bar Marked Tortilla Wrap (23%) [Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Water, Vegetable Oils [Palm Oil, Rapeseed Oil], Sugar, Raising Agents (Sodium Carbonates, Diphosphates, Malic Acid), Salt], Cooked White Rice (15%) [Water, Rice], Marinated Tofu (9%) [Water, Soya Beans, Sunflower Oil, Firming Agent (Calcium Sulphate), Spices, Salt, Flavouring, Onion Powder, Garlic Powder, Maize Starch, Herbs, Acidity Regulator (Citric Acid)], Red Peppers (9%), Red Onions, Sweetcorn, Tomato Passata, Yellow Peppers (4%), Onions, Sweet Potato (3%), Non-Dairy Alternative to Cheddar [Water, Coconut Oil, Modified Potato Starch, Maize Starch, Oat Fibre, Modified Maize Starch, Thickeners (Carrageenan, Guar Gum), Salt, Flavourings, Yeast Extract, Acidity Regulators (Lactic Acid, Sodium Lactate), Colour (Carotenes)], Spring Onions, Black Turtle Beans, Tomato Ketchup [Water, Sugar, Tomato Purée, Spirit Vinegar, Cornflour, Salt, Spices], Coriander Leaf. Contains Oats, Soya, Wheat.'
        },
        {
            'id': 'QbPD4TJif20SY5KkI1QO',
            'name': 'Spiced Chicken & Wholewheat Pasta Salad',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sun-dried Tomato Vinaigrette Dressed Wholewheat Pasta (38%) [Whole Durum Wheat Flour, Water, Sun-dried Tomato Purée (Sun-dried Tomatoes, Tomato Purée, Water, Salt, Acidity Regulator (Citric Acid), Glucose), Coriander, Basil, White Wine Vinegar, Rapeseed Oil, Black Pepper, Dijon Mustard, Sugar, Stabilisers (Xanthan Gum, Guar Gum), Extra Virgin Olive Oil, Garlic Purée], Vegetable Mix (22%) [Carrots, Cucumber, Sweetcorn], Piri Piri Style Marinated Chicken (14%) [Chicken Breast (85%), Salt], Sugar, Water, Spirit Vinegar, Tomato Purée, Garlic Purée, Cornflour, Red Chillies, Salt, Cayenne Pepper, Cumin Powder, Coriander Powder, Lemon Juice, Parsley, Paprika], Iceberg Lettuce (13%), Sour Cream and Chive Dressing (13%). Contains Eggs, Milk, Mustard, Wheat.'
        },
        {
            'id': 'kWsMK0ae3kmqpqtEo3Sw',
            'name': 'Spicy Mexican Style Salad Bowl',
            'brand': 'Asda',
            'serving_size_g': 280.0,
            'ingredients': 'Chickpeas (16%), Bulgur Wheat (14%), Green Lentils (13%), Mixed Leaves in varying proportions [Green Multileaf Lettuce, Red Multileaf Lettuce], Carrots, Water, Sweetcorn, Red Peppers, Cucumber, Tomato Purée, Salted Black Soya Beans (2%) [Black Soya Beans, Salt], Rapeseed Oil, Spices, Sugar, Coriander Leaf, Lime Juice, Onion Purée, Garlic Purée, Red Chillies, Cornflour, Salt, Spirit Vinegar, White Wine Vinegar, Stabilisers (Xanthan Gum, Guar Gum), Preservative (Potassium Sorbate). Contains Cereals Containing Gluten, Soya, Wheat.'
        },
        {
            'id': 'jHc2nFC3XnVhMx73iVdN',
            'name': 'Spicy Vegetable Couscous',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Cous Cous (89%) [Durum Wheat Semolina], Dried Vegetables (4%) [Onions, Tomatoes, Red Peppers], Flavourings (contains Wheat, Barley), Palm Oil, Dried Herbs [Parsley, Coriander], Salt, Dried Garlic, Carrot Powder, Onion Powder, Maltodextrin, Ground Cayenne Pepper, Ground Paprika. Contains Barley, Eggs, Milk, Mustard, Soya, Wheat.'
        },
        {
            'id': 'EIBQyGqznGxXCzblgRRP',
            'name': 'Sweet And Smoky Bbq Chicken Pasta Salad',
            'brand': 'Asda',
            'serving_size_g': 355.0,
            'ingredients': 'Cooked Pasta (47%) [Water, Durum Wheat Semolina], Water, Cooked Chicken Breast (11%) [Chicken Breast (98%), Salt, Water], Rapeseed Oil, Tomato Paste, Red Peppers (4%), Tomatoes, White Wine Vinegar, Sugar, Brown Sugar [Sugar, Molasses], Spirit Vinegar, Dijon Mustard [Water, Mustard Powder, Spirit Vinegar, Salt, Mustard Husk, Pimento, Turmeric], Parsley, Garlic Purée, Onions, Salt, Stabilisers (Carob Bean Gum, Xanthan Gum), Barley Malt Vinegar, Cornflour, Black Treacle, Smoked Water, Glucose Syrup, Yeast Extract, Concentrated Lemon Juice, Smoked Salt, Spices, Smoked Maltodextrin, Preservative (Potassium Sorbate), Tamarind Concentrate, Onion Powder, Garlic Powder, Flavouring. Contains Barley, Mustard, Wheat.'
        },
        {
            'id': 'gV88mHm4pS5WSiwSs1tW',
            'name': 'Thin Stonebaked Spicy Meat Feast Pizza',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)], Tomato Sauce (19%) [Tomatoes, Tomato Purée, Cornflour, Sugar, Acidity Regulator (Citric Acid), Oregano, Black Pepper], Mozzarella Cheese (Milk) (14%), Water, Mild Cheddar Cheese (Milk) (7%), Pepperoni (7%) [Pork (97%), Salt, Dextrose, Chilli Powder, Antioxidants (Extracts of Rosemary, Sodium Ascorbate), Anise Powder, Paprika Extract, Garlic Powder, Sugar, Pepper Extract, Preservative (Sodium Nitrite), Ginger Extract], Spicy Minced Beef with added water (7%) [Beef (69%), Dextrose, Water, Spices, Cornflour, Spirit Vinegar, Onion Powder, Tomato Paste, Garlic Powder, Tomato Powder, Salt, Garlic Purée, Onions, Red Peppers, Fortified Wheat Flour, Flavouring, Barley Malt Extract, Raising Agent (Ammonium Carbonates)], Green Chillies (3%), Red Chillies (3%), Rapeseed Oil, Yeast, Sugar, Salt, Wheat Gluten. Contains Barley, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'phUIJDLWfbeo8XvrZImP',
            'name': 'Sweet Chili Chicken Thighs',
            'brand': 'Ashfields Grill',
            'serving_size_g': 175.0,
            'ingredients': 'Chicken Thigh (94%), Sugar, Salt, Cornflour, Dried Garlic, Stabiliser (Guar Gum), Sunflower Oil, Dried Red Pepper, Ginger Powder, Paprika Extract, Ground Chilli Pepper, Onion Powder, Capsicum Extract, Acidity Regulator (Citric Acid), Ground Red Chili Pepper, Capsicum Powder, Flavouring, Yeast Extract, Cumin Powder, Dried Oregano, Black Pepper Extract, Garlic Powder. Contains bone.'
        },
        {
            'id': 'O2l8QRS3QYlD7UYgFWHn',
            'name': 'Scotch Pies',
            'brand': 'Bells',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Beef (15%), Margarine (Palm Oil, Rapeseed Oil, Water, Palm Stearin, Salt), Rusk (contains: Gluten), Salt, Glaze (Rapeseed Oil, Milk Proteins, Emulsifiers: Soya Lecithin, Polysorbate 60, Glucose, Acidity Regulator: Sodium Citrate), Coriander, Pepper, Nutmeg Extract, Dextrose, Rapeseed Oil, Flour Treatment Agent (E920). Contains Cereals Containing Gluten, Milk, Soya, Wheat.'
        },
        {
            'id': 'UWxOxbFFB1uNJwim9j8W',
            'name': 'Teriyaki Chicken Noodles',
            'brand': 'Better',
            'serving_size_g': 280.0,
            'ingredients': 'Cooked Egg Noodles (24%) (Wheat Flour (with Calcium, Iron, Niacin and Thiamin), Water, Pasteurised Free Range Whole Egg, Salt, Tumeric, Paprika), Chicken (15%), Water, Sweetheart Cabbage (10%), Julienne Carrots (8%), Dry Sherry [Sulphites], Demerara Sugar, Edamame Beans. Contains Cereals Containing Gluten, Eggs, Sulphites, Wheat.'
        },
        {
            'id': 'LMnMBEL5bpdGT2JdooY4',
            'name': 'Chocolate Fudge Gluten Free Brownie Mix',
            'brand': 'Betty Crocker',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Rice Flour, Milk Chocolate Chips (8%) (Sugar, Milk Solids (Skimmed Milk Powder, Butter Oil), Cocoa Mass, Whey Powder (Milk), Emulsifier (Soy Lecithin), Flavoring), Fat-Reduced Cocoa Powder (7%), Potato Starch, Dark Chocolate Chips (4.5%) (Sugar, Cocoa Mass, Cocoa Butter, Flavoring, Emulsifier (Soy Lecithin), Palm Fat, Salt. Contains Milk, Soya. May Contain Eggs.'
        },
        {
            'id': 'rAymAb0VfsgFHM9Y7rJP',
            'name': 'Beyond Meat',
            'brand': 'Beyond Meat',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Pea Protein (15%), Rapeseed Oil, Flavouring, Rice Protein, Coconut Oil, Dried Yeast, Preservative (Potassium Lactate), Vinegar, Stabilisers (Methylcellulose, Calcium Chloride), Potato Starch, Salt, Apple Extract, Colour (Beetroot Red), Concentrated Pomegranate Juice, Potassium Salt.'
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

    print(f"✨ BATCH 20 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {80 + updates_made} / 681\n")
    print(f"🎯 MILESTONE: {((80 + updates_made) / 681 * 100):.1f}% complete!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch20(db_path)
