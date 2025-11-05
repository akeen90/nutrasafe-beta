#!/usr/bin/env python3
"""
Clean ingredients batch 22 - Mixed Brands (Continuing Large Batches)
"""

import sqlite3
from datetime import datetime

def update_batch22(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 22 (Mixed Brands)\n")

    clean_data = [
        {
            'id': 'c0IuBJxAsdBZCuMAQ3kS',
            'name': 'Alpen Delight #15 Imp',
            'brand': 'Alpen',
            'serving_size_g': 24.0,
            'ingredients': 'Cereals (40%) (Oats, Rice, Wheat), Oligofructose Syrup, Milk Chocolate (14%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Milk Powder, Milk Fat, Emulsifier: Soya Lecithin), Cereal Flours (Rice, Wheat, Malted Barley), Caramel Pieces (4.5%) (Sugar, Glucose Syrup, Condensed Milk, Palm Oil, Shea Kernel Oil, Maize Starch, Humectant: Glycerol, Palm Stearin, Flavouring, Emulsifiers (Glycerol Monostearate, Sunflower Lecithin), Salt), Plain Chocolate (4.5%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier: Soya Lecithin, Flavouring), Glucose Syrup, Humectant: Glycerol, Vegetable Oils (contains Sunflower and/or Rapeseed), Sugar, Flavouring, Salt, Emulsifier: Soya Lecithin. Contains Barley, Milk, Oats, Soya, Wheat. May Contain Nuts.'
        },
        {
            'id': 'omBn6QCS2FbrrdWaRKGH',
            'name': 'Takis',
            'brand': 'Bimbo',
            'serving_size_g': 100.0,
            'ingredients': 'Pre-Cooked Cornflour, Palm Fat, Chilli and Lime Flavour Seasoning [Maltodextrin, Salt, Flavour Enhancers (Monosodium Glutamate, Potassium Chloride, Disodium Inosinate, Disodium Guanylate), Flavouring, Cornstarch, Acidity Regulator (Citric Acid), Sugar, Colours (Paprika Extract, Beetroot Red Concentrate), Stabiliser (Gum Arabic), Antioxidant (Tocopherol-Rich Extract)], Sunflower Oil. May Contain Milk, Soya.'
        },
        {
            'id': 'rAZCGunMBYmHCgJCEIPu',
            'name': 'Chocolate Cake Doughnuts',
            'brand': 'Black Label Bakery',
            'serving_size_g': 73.0,
            'ingredients': 'Wheat Flour (Wheat), Vegetable Fats: Palm, Coconut, (in varying proportions), Belgian Milk Chocolate (Sugar; Cocoa Butter; Whole Milk Powder (Milk); Cocoa Mass; Whey Powder (Milk); Emulsifier: Lecithins (Soy); Natural Vanilla Flavouring), Sugar, Water, Vegetable Oils: Rapeseed, Sunflower, Palm (in varying proportions), White Chocolate (Sugar; Cocoa Butter; Whole Milk Powder (Milk); Skimmed Milk Powder (Milk); Lactose (Milk); Whey Powder (Milk); Emulsifier: Lecithins (Soy); Natural Vanilla Flavouring), Belgian Dark Chocolate (Cocoa Mass; Sugar; Cocoa Butter; Anhydrous Butterfat (Milk); Emulsifier: Lecithins (Soy); Natural Vanilla Flavouring), Fat Reduced Cocoa Powder, Yeast, Rye Flour (Rye), Whole Milk Powder (Milk), Dextrose; Emulsifier: Mono- and Diglycerides of Fatty Acids, Lecithins, Sodium Stearoyl-2-Lactylate, Glucose Syrup, Salt, Raising Agent: Diphosphates, Sodium Carbonates, Cocoa Mass, Skimmed Milk Powder (Milk), Thickener: Xanthan Gum, Lecithins (Soy), Flour Treatment Agent: Ascorbic Acid. Contains Eggs, Milk, Rye, Soya, Wheat.'
        },
        {
            'id': 'j7aWqk0rjHEA2riHDK7J',
            'name': 'Dark Chocolate & Raspberry Whip Bars',
            'brand': 'Bliss',
            'serving_size_g': 25.0,
            'ingredients': 'Chocolate 27% [Sugar, Cocoa Mass, Cocoa Butter, Vegetable Fats (Palm, Shea), Milk Fat, Emulsifiers (Soybean Lecithin, E476)], Glucose Syrup, Sugar, Bulking Agent (Polydextrose), Water, Fibres (Inulin, Bamboo), Crisped Cereal 5.5% (Rice Flour, Sugar, Salt), Vegetable Fats (Palm, Palm Kernel), Dried Egg White, Skimmed Milk Powder, Acid (Citric Acid), Freeze Dried Raspberry 0.28%, Colour (Beetroot Extract), Natural Flavouring, Flavouring, Emulsifier (Sunflower Lecithin). May Contain Peanuts, Nuts. Contains Eggs, Milk, Soya.'
        },
        {
            'id': 'CooqLnM7b5qLgaApHTmZ',
            'name': 'Chicken Collection',
            'brand': 'Boots',
            'serving_size_g': 100.0,
            'ingredients': 'Bread (Fortified Wheat Flour with Calcium Carbonate, Iron, Niacin, Thiamin, Water, Malted Wheat Flakes, Wheat Bran, Yeast, Malted Barley Flour, Salt, Emulsifiers (E471, E472e), Wheat Gluten, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid)), Chicken 25% (Chicken Breast 98%, Rice Starch, Salt), Reduced Fat Mayonnaise (Water, Rapeseed Oil, Cornflour, Spirit Vinegar, Egg Yolk, Dijon Mustard, Sugar, White Wine Vinegar, Concentrated Lemon Juice), Mayonnaise, Pork, Sage 3%, Onion Stuffing 3%, Pork 28%, Water, Breadcrumbs. Contains Barley, Eggs, Milk, Mustard, Wheat.'
        },
        {
            'id': 'TwXCK4vzZRBoOQiRmVrI',
            'name': 'Chicken Tikka With Yoghurt & Mint Mayo',
            'brand': 'Boots',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Diced (50%) (Chicken breast (98%), salt), Mayonnaise (Water, Rapeseed Oil, Thickener (Modified Starch), Sugar, Salt, Pasteurised Egg Yolk, Acidity Regulator (Acetic Acid) Stabilisers (Xanthan Gum, Guar Gum), Preservatives (Potassium Sorbate, Sodium Benzoate), Flavouring, Natural Colour (Beta Carotene)), Yogannaise (15%) (Rapeseed Oil, Yogurt (Milk), Water, Sugar, Salt, Preservative (E202), Thickener (E415, E412)), Tikka Marinade (5%) (Wheat Flour (Wheat, Calcium, Iron, Niacin, Thiamin), Salt, Sugar, Rusk (Wheat Flour (Wheat, Calcium, Iron, Niacin, Thiamin), Salt), Whey Powder (Milk), Tomato Powder, Curry Powder (Coriander Seed, Turmeric, Fenugreek Seed, Rice Flour, Salt, Cumin Seed, Chilli Powder, Fennel Seed, Onion Powder), Garam Masala, Maltodextrin, Flavouring (Yeast Extract, Salt, Maltodextrin), Garlic Powder, Onion Powder, Acidity Regulator (Citric Acid), Paprika Extract, Malic Acid, Flavouring), Mint (1%). Contains Eggs, Milk, Wheat.'
        },
        {
            'id': 'OqYpYJpkpeKmLxk4E8oz',
            'name': 'Chefselect Cajun Chicken Pizza',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Stonebaked Pizza Base (Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin], Water, Rapeseed Oil, Salt, Yeast, Dried Wholemeal Spelt Wheat Flour), 21% Tomato Sauce (Concentrated Tomato Purée, Water, Salt, Sunflower Oil, Acid: Citric Acid; Dried Herbs, Dried Garlic), 12% Mozzarella Cheese (Milk), 11% Cajun Seasoned Chicken (75% Chicken Breast, Cajun Seasoning [Sugar, Maltodextrin, Dried Spices (Paprika, Cayenne Pepper, Cumin, Chilli Powder), Salt, Maize Starch, Dried Garlic, Dried Pepper, Dried Herbs (Oregano, Thyme, Parsley), Colour: Paprika Extract; Yeast Extract, Barley Malt Extract, Rapeseed Oil], Water, Pea Starch, Dextrose, Acidity Regulator: Sodium Lactate; Salt, Stabiliser: Triphosphates), 11% Roasted Red Peppers, 6% Cheddar Cheese (Milk), 4% Cajun Sauce (Water, Sugar, Tomato Purée, Soy Sauce [Water, Soya Beans, Salt, Wheat Flour], Worcester Sauce [Malt Vinegar, Water, Spirit Vinegar, Tamarind Extract, Salt, Onions, Garlic, Spice, Flavouring, Molasses]). Contains Barley, Milk, Soya, Wheat.'
        },
        {
            'id': 'xsBWzrMDRWDQxQardrxT',
            'name': 'Chicken & Bacon Pasta Bake',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': '29% Cooked Penne Pasta (Water, Durum Wheat Semolina), Water, 11% Cooked Chicken (98% British Chicken Breast, Water, Salt), Single Cream (Milk), Whole Milk, 3% White Wine, 3% Bacon (87% British Pork, Water, Salt, Preservatives: Sodium Nitrite, Potassium Nitrate), Onion, Medium Fat Hard Cheese (Medium Fat Hard Cheese (Milk, Anti-caking Agent: Potato Starch)). Contains Milk, Wheat.'
        },
        {
            'id': '3FCs6mPpJxCcNcPUWXSJ',
            'name': 'Chicken Tikka Masala',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': '44% Pilau Rice (Water, Basmati Rice, Rapeseed Oil, Turmeric, Cumin Seeds, Salt), 38% Tikka Masala Sauce (Onion, Water, Single Cream (Milk), Tomato, Yogurt (Milk), Garlic Purée, Tomato Purée, Rapeseed Oil, Sugar, Unsalted Butter (Milk), Ground Coriander, Ginger Purée, Salt, Cashews, Maize Flour, Coriander Leaf, Paprika, Garam Masala [Coriander, Cumin, Ginger, Black Pepper, Nutmeg, Cloves, Cardamom, Bay Leaf], Cumin, Green Chilli, Almonds, Turmeric, Colour: Paprika Extract, Fenugreek), 18% Marinated Chicken (86% Chicken Breast, Tomato Purée, Ginger Purée, Garlic Purée, Masala Powder [Salt, Chilli, Fenugreek, Coriander, Cumin, Ginger, Cinnamon, Black Pepper, Mace, Star Anise, Turmeric, Basil], Colour: Paprika Extract, Yogurt (Milk), Cornflour, Green Chilli). Contains Almonds, Cashews, Milk.'
        },
        {
            'id': 'SDMjWHlYZ0BRSstYQ3zz',
            'name': 'Stone Baked BBQ Chicken and Bacon Pizza',
            'brand': 'Chefselect Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Stonebaked Pizza Base (Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin], Water, Rapeseed Oil, Salt, Yeast, Wholemeal Spelt Wheat Flour), 12% Mozzarella Soft Cheese, 12% Barbecue Flavoured Chicken (75% Chicken Breast, 17% Barbecue Sauce (Concentrated Tomato Purée, Agave Syrup, Worcester Sauce, Water, Cider Vinegar, Soya Sauce, Dried Smoked Paprika, Salt, Dried Onion, Dried Garlic, Sunflower Oil, Acidity Regulator: Citric Acid; Dried Herbs, Dried Ginger), Water, Pea Starch, Dextrose, Acidity Regulator: Sodium Lactate; Salt, Stabiliser: Sodium Triphosphate), 10% Tomato Sauce (Concentrated Tomato Purée, Water, Salt, Sunflower Oil, Acid: Citric Acid; Dried Herbs, Dried Garlic). Contains Milk, Soya, Wheat.'
        },
        {
            'id': 'dO9AujNMhV4KIY5TQrrl',
            'name': 'Cheesy Stuffed Crust Takeaway Loaded Pepperoni',
            'brand': 'Chicago Town',
            'serving_size_g': 161.732,
            'ingredients': 'Wheat Flour (with calcium, niacin (B3), iron, thiamin (B1)), Water, Mozzarella Cheese (14%), Tomato Purée, Pork and Beef Pepperoni (8%) (Pork, Beef Fat, Salt, Dextrose, Spices, Sugar, Garlic Powder, Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Smoke Flavouring, Spice Extract, Preservative (Sodium Nitrite), Smoke), Full Fat Soft Cheese (5%), Vegetable Oils (Palm, Rapeseed), Yeast, Cheddar Cheese (1.5%), Salt, Sugar, Modified Starch (Potato, Tapioca), Emulsifying Salts (Sodium Phosphate, Sodium Citrates), Garlic, Stabiliser (Guar Gum), Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Herbs and Spices, Acidity Regulator (Lactic Acid), Flour Treatment Agent (Ascorbic Acid), Flavouring, Colour (Beta-Carotene). May Contain Soya, Mustard. Contains Milk, Wheat.'
        },
        {
            'id': 'gtmgHSKLVOZmYkiEC7tl',
            'name': 'Tomato Stuffed Crust Takeaway Magnificent Meat Feast',
            'brand': 'Chicago Town',
            'serving_size_g': 173.015,
            'ingredients': 'Wheat Flour (with Calcium, Niacin (B3), Iron, Thiamin (B1)), Tomato Purée, Water, Mozzarella Cheese (13%), Pork and Beef Pepperoni (4%) (Pork, Beef Fat, Salt, Dextrose, Spices, Sugar, Garlic Powder, Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Smoke Flavouring, Preservative (Sodium Nitrite), Spice Extracts, Smoke), Pork Meatballs (3.5%) (Pork, Pork Fat, Breadrusk (Wheat Flour (with Calcium, Niacin (B3), Iron, Thiamin (B1), Salt, Yeast), Tomato Paste, Dried Onions, Salt, Sugar, Spices, Garlic Powder, Onion Powder), Fennel Sausage (3.5%) (Pork, Pork Fat, Spices, Wheat Protein, Fennel Seeds, Sugar, Salt, Yeast, Stabilisers (Diphosphates, Triphosphates), Rosemary Extract, Spice Extract), Vegetable Oils (Palm, Rapeseed), Smoke Flavoured Ham (2%) (Pork, Water, Salt, Acidity Regulator (Sodium Ascorbate), Stabilisers (Diphosphates, Triphosphates), Preservative (Sodium Nitrite), Smoke Flavouring, Dextrose, Flavouring). Contains Milk, Wheat.'
        },
        {
            'id': 'SXCHKdLgwgzQqbIKNajA',
            'name': '4 White Iced Finger Buns',
            'brand': 'Co-op',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium carbonate, Iron, Niacin, Thiamin), White Icing (19%) (Sugar, Palm Kernel Oil, Water, Lactose (Milk), Palm Oil, Emulsifiers (Citric acid esters of mono - and diglycerides of fatty acids - Vegetable, Sorbitan monostearate), Gelling Agent (Agar), Preservative (Potassium sorbate), Flavouring, Acidity Regulator (Citric acid)), Water, Sugar, Yeast, Rapeseed Oil, Maize Starch, Emulsifiers (Mono - and diglycerides of fatty acids - Vegetable, Sodium stearoyl-2-lactylate - Vegetable, Mono - and diacetyl tartaric acid esters of mono - and diglycerides of fatty acids-Vegetable), Salt, Palm Oil, Potato Dextrin, Flavouring, Wheat Flour, Acidity Regulator (Acetic Acid), Flour Treatment Agent (Ascorbic acid). Contains Milk, Wheat.'
        },
        {
            'id': 'UUbpabHT1VKxMOGr5GP6',
            'name': '6 Assorted Jam Tarts',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Blackcurrant and Apple Flavoured Jam (50%) (Glucose-Fructose Syrup, Blackcurrant Purée, Apple Purée, Acid (Citric Acid), Colour (Anthocyanins), Gelling Agent (Pectin), Acidity Regulator (Sodium Citrates), Preservatives (Potassium Sorbate, Sodium Metabisulphite), Flavouring), Apricot Flavoured Jam (50%) (Glucose-Fructose Syrup, Apricot Purée, Acid (Citric Acid), Gelling Agent (Pectin), Acidity Regulator (Sodium Citrates), Preservative (Potassium Sorbate), Colour (Annatto Norbixin), Flavouring), Strawberry Flavoured Jam (50%) (Glucose-Fructose Syrup, Strawberries), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Vegetable Oils (Palm, Rapeseed), Sugar, Glucose Syrup, Salt, Preservative (Potassium Sorbate). Contains Sulphites, Wheat.'
        },
        {
            'id': 'ZrV2MBurh6d24aGTPvuc',
            'name': 'All Day Breakfast Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 210.0,
            'ingredients': 'White Bread (43%) (Wheat Flour, Water, Yeast, Salt, Wheat Protein, Emulsifiers, Rapeseed Oil, Flour Treatment Agent), Pork Sausage (21%) (Pork, Water, Rusk, Potato Starch, Seasoning, Pork Rind, Rapeseed Oil, Parsley, Sage, Pork Fat, Flavouring), Egg Mayonnaise (19%) (Hard Boiled Egg, Reduced Fat Mayonnaise (Rapeseed Oil, Cornflour, Spirit Vinegar, Pasteurised Egg Yolk, Dijon Mustard, Sugar, White Wine Vinegar, Concentrated Lemon Juice, Salt)). Contains Eggs, Milk, Mustard, Wheat.'
        },
        {
            'id': '7aharDy3pqY7yzYrtkXD',
            'name': 'Beetroot Falafel & Giant Cous Cous Salad',
            'brand': 'Co-op',
            'serving_size_g': 230.0,
            'ingredients': 'Cous Cous (33%)(Wheat Flour,Water), Beetroot(17%), Beetroot Falafel(17%)(Beetroot,Chick Peas, Onion, Potato Flakes, Red Pepper, Garlic Purée, Rapeseed Oil, Ground Cumin, Chilli, Ground Coriander, Lemon Juice, Paprika, Salt, White Pepper), Spicy Coconut Dressing (11%)(Coconut Milk(Coconut Extract, Water), Water, Harissa Paste (Spirit Vinegar, Ground Coriander, Red Chilli Purée, Red Pepper Purée, Garlic Purée, Water, Rapeseed Oil, Cumin, Muscovado Sugar, Salt, Caraway Seeds, Concentrated Lemon Juice), White Miso Glaze (White Miso Paste (Water, Soya Beans, Rice, Salt, Alcohol), Rice Vinegar, Mirin(Glutinous Rice, Water, Alcohol, Rice), Sugar, Ginger Purée), Concentrated Lemon Juice, Orange Zest, Maple Syrup, Cornflour, Roasted Garlic Purée, Chipotle Chilli Flakes, Roasted Ground Cumin), Black Beluga Lentils (8%), Black Rice (7%)(Rice, Water), Spinach, Balsamic Dressing (1%)(Balsamic Vinegar(Red Wine Vinegar, Grape Must Concentrate), Salt), Sweetened Dried Cranberries (Sugar, Cranberries, Sunflower Oil). Contains Soya, Wheat.'
        },
        {
            'id': 'R10okr9og91O5b2NRaZW',
            'name': 'Boil In The Bag Long Grain Rice',
            'brand': 'Co-op',
            'serving_size_g': 125.0,
            'ingredients': 'Parboiled Long Grain White Rice.'
        },
        {
            'id': 'O6WhCn5QVa0pl9U0CGx7',
            'name': 'Chicken Arrabiata',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Pasta (33%) (Water, Durum Wheat Semolina), Tomatoes, Water, Cooked Chicken Breast Pieces (15%) (Chicken Breast, Water, Salt), Tomato Purée, Mozzarella (Milk), Rapeseed Oil, Onion, Garlic Purée, Chilli Purée, Cornflour, Sugar, Basil, Salt, Black Pepper, Oregano. Contains Milk, Wheat.'
        },
        {
            'id': 'Fk2LPL6ZXLUSRZ8eWNxw',
            'name': 'Chicken Katsu Rice Bowl - Co Op',
            'brand': 'Co-op',
            'serving_size_g': 260.0,
            'ingredients': 'Cooked White Rice (38%) (Long Grain Rice, Water) Katsu Dressing (17%) (Water, Coconut Milk (Coconut, Water), Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol, Distilled Vinegar), Rapeseed Oil, Brown Sugar, Rice Vinegar, Ginger Purée, Cornflour, Madras Curry Paste (Water, Spices (Cumin, Ground Coriander, Turmeric, Cayenne Pepper, Ground Ginger, Paprika, Fenugreek, Nutmeg, Cinnamon, Cloves), Salt, Rapeseed Oil, Yeast Extract (Yeast Extract, Salt),White Wine Vinegar, Garlic Powder, Tomato Powder), Spices (Turmeric, Black Pepper, Ground Cumin, Cassia, Fennel, Ginger, Star Anise, Cloves), Vegetable Bouillion (Salt, Yeast Extract Powder, Sugar, Onion Powder, Potato Starch, Celery Seeds, Dried Yeast, Flavouring), Yeast Extract Powder, Garlic Purée, Salt, Tapioca Starch) Cooked Marinated Chicken (13%) (Chicken Breast, Sugar, Cornflour, Brown Sugar, Tomato Powder, Salt, Ginger Purée, Garlic Purée, Garlic Powder, Yeast Extract Powder, Burnt Sugar, Spices (Star Anise, Cinnamon, Fennel Seed)). Contains Celery, Soya, Wheat.'
        },
        {
            'id': 'ZIX1302ld6njXzLzCvu5',
            'name': 'Chicken Tikka Masala With Lentil Rice',
            'brand': 'Co-op',
            'serving_size_g': 400.0,
            'ingredients': 'Seasoned Lentils and Rice (40%) (Water, White Rice, Red Lentils, Rapeseed Oil, Cumin Seeds, Turmeric Extract, Salt, Cardamom Pods, Whole Cloves, Ground Bay Leaf, Ground Cinnamon), Marinated Chicken (20%) (Chicken Breast, Marinade (Water, Low Fat Yogurt (Milk), Potato Starch, Garam Masala (Coriander, Cassia, Cumin, Ginger, Allspice, Cloves, Nutmeg, Fennel, Dill, Mace, Black Pepper, Chilli), Paprika, Salt, Green Chillies, Chopped Coriander, Concentrated Lemon Juice, Chilli Powder, Ground Fenugreek, Colour (Paprika Extract))), Onion, Water, Tomatoes, Skimmed Milk, Crème Fraîche (Milk), Single Cream (Milk), Tomato Purée, Cornflour, Chopped Coriander, Skimmed Milk Powder, Garlic Purée, Ginger Purée. Contains Milk.'
        },
        {
            'id': 'vrJaqchBJeHFQ2xo3XN5',
            'name': 'Co-op 6 Frankfurters',
            'brand': 'Co-op',
            'serving_size_g': 50.0,
            'ingredients': 'Pork (82%), Water, Salt, Spice Mix (Dextrose, White Pepper, Ginger, Salt, Nutmeg, Coriander, Mace, Onion Powder, Cardamom, Lovage), Stabiliser (Diphosphates), Dextrose, Antioxidant (Ascorbic Acid), Preservative (Sodium Nitrite), Potassium Lodate. Sausage skins made using sheep. May Contain Celery, Mustard, Nuts.'
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

    print(f"✨ BATCH 22 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {131 + updates_made} / 681\n")
    print(f"🎯 MILESTONE: {((131 + updates_made) / 681 * 100):.1f}% complete!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch22(db_path)
