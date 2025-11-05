#!/usr/bin/env python3
"""
Clean ingredients batch 26 - Continuing Toward Larger Batches
"""

import sqlite3
from datetime import datetime

def update_batch26(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 26 (Post-200 Milestone)\n")

    clean_data = [
        {
            'id': '0ONknJLyT03DgnRHi3zB',
            'name': 'Aberdeen Angus Steak & Caramelised Onion',
            'brand': 'Co-op',
            'serving_size_g': 211.0,
            'ingredients': 'Onion Bread (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Toasted Kibbled Onion, Yeast, Salt, Wheat Protein, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Cooked Aberdeen Angus (24%) (Beef Topside, Salt, Stabilisers (Diphosphates, Triphosphates)), Balsamic Onion Chutney (9%) (Red Onion, Sugar, Balsamic Vinegar (White Wine Vinegar, Grape Must), White Wine Vinegar, Water, Molasses, Cornflour, Salt, Garlic Purée, Ginger Purée, Black Pepper), Miso Caramelised White Onions (7%) (White Onion, Miso Paste (Water, Soya Beans, Rice), Muscovado Sugar, Sunflower Oil, Salt), Rocket (6%), French Style Mayonnaise (4%) (Rapeseed Oil, Water, Free Range Egg Yolk, Spirit Vinegar, Sugar, Mustard Flour, Salt), Mayonnaise (Water, Rapeseed Oil, Pasteurised Egg Yolk, Cornflour, Spirit Vinegar, Sugar, Dijon Mustard, White Wine Vinegar, Concentrated Lemon Juice, Salt), Chicken Stock Paste (Yeast Extract, Glucose Syrup, Rapeseed Oil, Water, Salt, Chicken Fat, Chicken, Flavourings, Rosemary Extract). Contains Cereals Containing Gluten, Eggs, Mustard, Soybeans, Wheat.'
        },
        {
            'id': '7aharDy3pqY7yzYrtkXD',
            'name': 'Beetroot Falafel & Giant Cous Cous Salad',
            'brand': 'Co-op',
            'serving_size_g': 230.0,
            'ingredients': 'Cous Cous (33%) (Wheat Flour, Water), Beetroot (17%), Beetroot Falafel (17%) (Beetroot, Chickpeas, Onion, Potato Flakes, Red Pepper, Garlic Purée, Rapeseed Oil, Cumin, Chilli, Coriander, Lemon Juice, Paprika, Salt, White Pepper), Spicy Coconut Dressing (11%) (Coconut Milk (Coconut, Water), Water, Harissa Paste (Spirit Vinegar, Coriander, Red Chilli Purée, Red Pepper, Garlic Purée, Water, Rapeseed Oil, Cumin, Muscovado Sugar, Salt, Caraway Seeds, Concentrated Lemon Juice), White Miso Glaze (White Miso Paste (Water, Soya Beans, Rice, Salt, Alcohol), Rice Vinegar, Mirin (Glutinous Rice, Water, Alcohol, Rice), Sugar, Ginger), Concentrated Lemon Juice, Orange Zest, Maple Syrup, Cornflour, Garlic Purée, Chipotle Chilli Flakes, Cumin), Black Beluga Lentils (8%), Black Rice (7%) (Rice, Water), Spinach, Balsamic Dressing (1%) (Balsamic Vinegar (Red Wine Vinegar, Grape Must), Salt), Cranberries (Sugar, Cranberries, Sunflower Oil), Pumpkin Seeds. Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '0nXQBnAcctZ9zP9nyBYP',
            'name': 'Meat Feast Pizza',
            'brand': 'Co-op',
            'serving_size_g': 160.0,
            'ingredients': 'Pizza Base (42%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Rapeseed Oil, Sugar, Malted Wheat Flour, Salt, Malted Barley Flour), Tomato Sauce (23%) (Passata, Water, Tomato Purée, Basil, Garlic Purée, Cornflour, Salt, Black Pepper, Acidity Regulator (Citric Acid)), Mozzarella Cheese (Milk) (15%), Chilli Beef (8%) (Beef, Onion, Dextrose, Water, Cornflour, Spirit Vinegar, Tomato Paste, Paprika, Cumin, Onion Powder, Garlic Powder, Tomato Powder, Salt, Garlic Purée, Red Pepper, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cayenne Chilli Powder, Natural Flavourings, Ground Coriander, Malt Extract (Barley), Black Pepper, Raising Agent (Ammonium Carbonates)), Smoked Ham (8%) (Pork, Salt, Stabiliser (Triphosphates), Water, Preservative (Sodium Nitrite), Antioxidant (Sodium Ascorbate)), Pepperoni (4%) (Pork, Sea Salt, Salt, Dextrose, Antioxidants (Sodium Ascorbate, Rosemary Extract), Paprika Extract, Anise, Garlic, Pepper Extract, Ginger Extract). Contains Barley, Beef, Cereals Containing Gluten, Milk, Pork, Wheat.'
        },
        {
            'id': 'Fk2LPL6ZXLUSRZ8eWNxw',
            'name': 'Chicken Katsu Rice Bowl - Co Op',
            'brand': 'Co-op',
            'serving_size_g': 260.0,
            'ingredients': 'Cooked White Rice (38%) (Long Grain Rice, Water), Katsu Dressing (17%) (Water, Coconut Milk (Coconut, Water), Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol, Distilled Vinegar), Rapeseed Oil, Brown Sugar, Rice Wine Vinegar, Ginger Purée, Cornflour, Madras Curry Paste, Spices, Vegetable Bouillon, Yeast Extract Powder, Garlic Purée, Salt, Tapioca Starch), Cooked Marinated Chicken (13%) (Chicken Breast, Sugar, Cornflour, Brown Sugar, Tomato Powder, Salt, Ginger Purée, Garlic Purée, Garlic Powder, Yeast Extract Powder, Burnt Sugar, Spices (Star Anise, Cinnamon, Fennel Seed, Black Pepper, Clove), Onion Powder, Dried Parsley, Citric Acid, Dried Red Bell Pepper, Flavouring, Water, Maltodextrin, Soya Beans, Spirit Vinegar), Cooked Black Rice (12%) (Black Rice, Water), Pickled Vegetable Mix (12%) (Red Cabbage, Carrot, Sugar, Spirit Vinegar, Salt), Lettuce (8%). Contains Celery, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '2v5QAixWpfiKSxE6azNa',
            'name': 'Harissa Spiced Falafel Wrap',
            'brand': 'Co-op',
            'serving_size_g': 219.0,
            'ingredients': 'White Tortilla Wrap (41%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Raising Agents (Sodium Hydrogen Carbonate, Malic Acid, Disodium Diphosphate), Sugar, Salt, Wheat Starch), Spiced Falafel (18%) (Chickpeas, Red Pepper, Sweet Potato, Bread Rusk (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast), Self Raising Flour (Wheat Flour, Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate, Monocalcium Phosphate)), Apple, Onion, Coriander, Red Chilli, Garlic Purée, Potato Flakes, Sultanas (Sultanas, Cottonseed Oil), Salt, Lemon Juice, Cumin, Ground Coriander, Onion Powder, Dried Red Bell Pepper, Smoked Paprika, Ground Paprika, Tomato Purée), Harissa Sauce (10%) (Water, Mango Purée, Red Pepper, White Wine Vinegar, Sugar, Cornflour, Tomato Paste, Extra Virgin Olive Oil, Mint, Cumin, Ginger Purée, Garlic Purée, Dried Chilli, Coriander, Salt, Rose Petals, Ground Coriander, Black Pepper), Spiced Houmous (7%) (Chickpeas, Water, Rapeseed Oil, Extra Virgin Olive Oil, Concentrated Lemon Juice, Salt, Spices (Ground Coriander, Cinnamon, Cumin, Turmeric, Paprika, Cayenne Chilli, Allspice, Black Pepper), Cumin Seeds, Garlic Purée, Ground Coriander), Mango Chutney (5%) (Sugar, Mango, Water, Spirit Vinegar, Cornflour, Salt, Ginger Purée, Garlic Purée, Red Chilli Purée), Spinach (5%), Chickpeas (3%), Cabbage (2%), Cucumber (2%), Tomato (2%), Carrot (2%), Lemon Juice, Coriander, Cornflour. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'YEFiaNubQAfN9iLo0s7b',
            'name': 'Korean Style Chicken Dragon Rolls',
            'brand': 'Co-op',
            'serving_size_g': 188.0,
            'ingredients': 'Cooked Sushi Rice (Water, Rice, Sugar, Rice Vinegar, Salt, Vegetable Oils (Sunflower, Rapeseed), Rice Wine), Sesame Seeds (7%), Chopped and Shaped Chicken Breast (6%), Water, Rapeseed Oil, Korean Style Chilli Sauce (Water, Dark Brown Soft Sugar, Soya Beans, Glucose Syrup, Rice Wine Vinegar, Salt, Ground Paprika, Onion Powder, Smoked Paprika, Molasses, Cayenne Pepper, Concentrated Lemon Juice, Treacle, Cornflour, Habanero Chilli, Dried Chilli, Garlic Powder, Malt Vinegar (Barley), Malt Extract (Barley), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Preservative (Acetic Acid)), Spring Onion (3%), Carrot (3%), Red Cabbage (2%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Nori Seaweed, Sugar, Cornflour, Spirit Vinegar, Paprika Flakes, Glucose Syrup, Salt, Pasteurised Liquid Egg Yolk, Wheat Starch, Ginger Purée, White Wine Vinegar, Rice Flour, Wheat, Ginger, Garlic Powder, Chilli Powder, Yeast Extract, Onion Juice Concentrate. Contains Eggs, Cereals Containing Gluten, Mustard, Sesame Seeds, Soybeans, Wheat.'
        },
        {
            'id': 'sJar3QAq9mGHPDdtWuzI',
            'name': 'Cherry And Almond Porridge',
            'brand': 'Dorset Cereals',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oat Flakes (65%), Cherry Purée Pieces (17%) (Sugar, Fructose Syrup, Apple Purée Concentrate, Cherry Juice Concentrate, Cherry Purée, Rice Flour, Acidity Regulators (Citric Acid, Potassium Citrate), Cocoa Butter, Gelling Agent (Pectin), Natural Flavouring), Cherry & Almond Flavour Oats (Wholegrain Oat Flakes (10%), Black Cherry Concentrate (1%), Maize Starch, Rapeseed Oil, Natural Flavouring), Sliced Almonds (3.5%), Freeze Dried Sliced Cherries (2%). Contains Cereals Containing Gluten, Nuts, Oats. May Contain Other Gluten Sources, Other Nuts.'
        },
        {
            'id': '8oWXXo8EHQCzauZQRSx6',
            'name': 'No Turkey Feast',
            'brand': 'Co-op',
            'serving_size_g': 198.0,
            'ingredients': 'Wheat & Oatmeal Bread (45%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Oatmeal, Wheat Bran, Yeast, Salt, Wheat Protein, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Malted Barley Flour, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Soya Protein Pieces (18%) (Water, Soya Protein (Soya Protein Isolate, Wheat Protein, Wheat Starch), Rapeseed Oil, Soya Protein Concentrate, Wheat Protein, Stabiliser (Methyl Cellulose), Thickener (Carrageenan), Flavourings, Yeast Extract, Sea Salt), Roast Seasoned Carrot & Parsnip (10%) (Carrot, Parsnip, Brown Sugar, Maple Syrup, Rapeseed Oil, Salt, Black Pepper), Cranberry Chutney (9%) (Cranberries, Plums, Water, Sugar, Red Wine Vinegar, Cornflour, Concentrated Plum Juice, Sweetened Dried Cranberries (Sugar, Cranberries, Sunflower Oil)), Vegan Seasoned Mayo (7%) (Water, Rapeseed Oil, Cornflour, Mushroom Stock, Spirit Vinegar, Sugar, Yeast Extract, Concentrated Lemon Juice, Dijon Mustard, Pea Protein, Garlic Powder, Onion Powder, Black Pepper, Salt, Paprika), Spinach (5%), Sage, Onion & Oat Stuffing (3%) (Water, Breadcrumbs, Rusk, Onion, Oats, Sage, Salt, Parsley), Vegan Mayo (2%) (Water, Rapeseed Oil, Spirit Vinegar, Sugar, Stabilisers (Guar Gum, Xanthan Gum), Pea Protein, Salt, Dijon Mustard, White Pepper), Black Pepper. Contains Barley, Cereals Containing Gluten, Mustard, Oats, Soybeans, Wheat.'
        },
        {
            'id': 'ZrKBYzPnHFhnIF2UWrT9',
            'name': 'Onion Bhaji & Mango Chutney Sandwich',
            'brand': 'Co-op',
            'serving_size_g': 195.0,
            'ingredients': 'Fibre Enriched White Bread with Black Onion Seeds (45%) (Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Wheat Fibre, Black Onion Seeds, Yeast, Salt, Emulsifiers (Mono- and Diglycerides of Fatty Acids, Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides), Wheat Protein, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Wheat Flour, Wheat Starch), Onion Bhaji (20%) (Onion, Rapeseed Oil, Gram Flour (Maize Flour, Tyson Peas, Yellow Split Peas), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Coriander Leaf, Salt, Ginger Purée, Ground Fenugreek, Garam Masala (Coriander, Cumin, Ginger, Black Pepper, Cloves, Cardamom, Nutmeg, Star Anise), Cumin Powder, Cumin Seeds, Chilli Powder, Raising Agent (Sodium Hydrogen Carbonate), Turmeric), Carrot (8%), Spiced Cauliflower and Sweet Potato Purée (8%) (Cauliflower, Sweet Potato, Ground Cumin, Coriander Seeds, Turmeric), Mango and Apricot Chutney (8%) (Sugar, Mango Purée, Apricot Pulp, Malt Vinegar (Barley), Apple (Apple, Salt), Dried Apricot (Apricot, Rice Flour, Preservative (Sulphur Dioxide)), Dried Onion, Mango, Coriander Leaf, Salt, Ginger Purée, Ground Ginger, Coriander, Garlic Powder), Apollo Lettuce (5%), Steam Roasted Pickled Beetroot (4%) (Beetroot, White Wine Vinegar, Sugar), Fried Onions (2%) (Palm Oil, Wheat Flour, Onion, Salt). Contains Barley, Cereals Containing Gluten, Mustard, Sulphur Dioxide/Sulphites, Wheat. May Contain Sesame.'
        },
        {
            'id': 'vYe9Td2Mn6r8uGXoOE1X',
            'name': 'Pork Pickle And Cheese Pies',
            'brand': 'Co-op',
            'serving_size_g': 270.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pork (17%), Pork Lard, Pickle (7%) (Sugar, Swede, Onion, Spirit Vinegar, Tomato Paste, Carrot, Gherkin, Cornflour, Dates, Malted Barley Extract, Salt, Rice Flour, Garlic Powder, Onion Extract, Ginger, Cayenne Pepper, Clove Powder, Nutmeg, Cinnamon, Preservative (Potassium Sorbate)), Water, Pork Fat, Red Leicester Cheese (Milk) (4%) (Contains Colour (Annatto)), Palm Oil, Rapeseed Oil, Potato Starch, Poppy Seed, Egg (Free Range), Salt, Cornflour, Pork Gelatine, White Pepper. Contains Barley, Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': 'uBaiXQPeqiIPx9ruZNia',
            'name': 'Tikka Chicken Sizzlers',
            'brand': 'Co-op',
            'serving_size_g': 175.0,
            'ingredients': 'Chicken Breast (82%), Water, Tikka Glaze (6%) (Sugar, Maize Starch, Onion Powder, Garlic Powder, Coriander Seeds, Cumin, Salt, Black Pepper, Cayenne Pepper, Nigella Seeds, Red Bell Pepper, Ginger, Parsley, Fenugreek, Turmeric, Paprika Extract, Stabiliser (Guar Gum), Coconut Oil, Clove, Cinnamon, Coriander, Flavouring, Antioxidant (Rosemary Extract)), Curried Yoghurt Marinade (5%) (Rapeseed Oil, Natural Greek Style Yoghurt (Milk), Water, Apricot Purée, Tomato Paste, Mango Purée, Sugar, Spirit Vinegar, Desiccated Coconut, Ground Coriander, Cornflour, Salt, Lime Juice, Ground Turmeric, Ground Ginger, Ground Cumin, Black Pepper, Paprika, Garlic Powder, Caraway Seeds, Cayenne Chilli Powder, Ground Fenugreek, Ground Cinnamon, Ground Oregano), Indian Style Garnish (Nigella Seeds, Green Bell Pepper, Red Bell Pepper, Coriander, Parsley, Chilli, Black Pepper), Salt, Sugar. Contains Milk.'
        },
        {
            'id': 'v3n7SphWpfH5XTvBIoEN',
            'name': "Hunter's Chicken With Paprika Spiced Potatoes",
            'brand': 'Co-op',
            'serving_size_g': 350.0,
            'ingredients': 'Roasted Diced Potatoes (46%) (Potato, Rapeseed Oil, Paprika, Thyme, Cayenne Pepper, Salt), Marinated Cooked Chicken (20%) (Chicken Breast, Cornflour, Molasses, Garlic Purée, Salt, Smoked Paprika, Black Pepper), Water, Passata, Demerara Sugar, Tomato Ketchup (Tomato, Spirit Vinegar, Sugar, Salt, Pepper Extract, Celery Extract, Pepper), Monterey Jack Cheese (Milk) (2%), Onion, Red Wine Vinegar, Worcester Sauce (Water, Spirit Vinegar, Sugar, Tamarind Paste, Onion, Garlic, Ginger, Concentrated Lemon Juice, Ground Cloves, Chilli), Smoked Bacon Lardons (1%) (Pork, Salt, Water, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite)), Rapeseed Oil, Cornflour, Molasses, Garlic Purée, Mesquite Seasoning (Sugar, Salt, Dried Glucose Syrup, Yeast Extract, Tomato Powder, Cumin, Turmeric, Smoke Flavouring, Onion Powder, Garlic Powder, Malt Extract (Barley)), Salt, Colour (Plain Caramel), Smoked Paprika, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), Smoke Flavouring. Contains Barley, Cereals Containing Gluten, Celery, Milk, Mustard, Pork.'
        },
        {
            'id': 'CW5fBH8AMA7omHMZwI6t',
            'name': 'Co-op Pasta Bowl Chicken & Bacon',
            'brand': 'Co-op',
            'serving_size_g': 270.0,
            'ingredients': 'Cooked Dressed Pasta (37%) (Durum Wheat Semolina, Water, Rapeseed Oil), Mayonnaise Dressing (20%) (Mayonnaise (Water, Rapeseed Oil, Cornflour, Pasteurised Egg Yolk (Egg, Salt), Spirit Vinegar, Sugar, Salt, Lemon Juice, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt), White Wine Vinegar), Water, Chives, Cornflour, Onion Granules, Chipotle Paste (Water, Jalapeño Pepper, Spirit Vinegar, Sugar, Salt, Tomato Paste), Brown Sugar, Yeast Extract Powder, Rapeseed Oil, Dijon Mustard (Water, Mustard Seeds, Spirit Vinegar, Salt, Acidity Regulator (Citric Acid)), Salt, Garlic Purée, White Pepper), Sweetcorn (15%), Cooked Barbecue Marinated Chicken (10%) (Chicken Breast, BBQ Spice Seasoning (Sugar, Tomato Powder, Dried Glucose Syrup, Spices (Ground Paprika, Chilli Powder, Cassia, Turmeric, Cloves, Cumin Powder), Garlic Powder, Onion Powder, Acidity Regulator (Citric Acid), Lemon Juice Powder, Caramelised Sugar Powder, Smoked Salt, Yeast Extract Powder, Spirit Vinegar Powder, Flavouring, Rapeseed Oil), Water, Vegetable Oil, Salt), Tomato (10%), Smoked Bacon Pieces (3%) (Pork, Water, Salt, Dextrose, Yeast Extract, Smoke Flavourings, Preservative (Sodium Nitrite)). Contains Cereals Containing Gluten, Eggs, Mustard, Pork, Wheat.'
        },
        {
            'id': 'C9nBtdE0WuucvPQTOYho',
            'name': 'Middle Eastern Menu: Spinach & Pine Nut Falafel Wrap',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Tortilla Wrap (48%) (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Vegetable Oils (Palm, Rapeseed), Sugar, Palm Fat, Raising Agents (Sodium Hydrogen Carbonate, Disodium Diphosphate), Acidity Regulator (Malic Acid), Salt, Wheat Starch), Spinach & Pine Nut Falafel (21%) (Peas, Chickpeas, Spinach, Pine Kernels, Potato Flakes, Red Onion, Rapeseed Oil, Self Raising Flour (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Raising Agents (Disodium Diphosphate, Sodium Hydrogen Carbonate)), Garlic, Salt, Lemon Juice, Cumin, Ground Coriander, Black Pepper, Mint), Steam Roasted Pickled Onion (8%) (Red Onion, Lime Juice, Sugar, Spirit Vinegar, Salt), Spinach (4%), Coconut Oil Derived Greek Style Pieces (4%) (Water, Coconut Oil, Potato Starch, Potato Protein, Sea Salt, Flavouring, Acidity Regulator (Lactic Acid), Olive Fruit Extract), Coconut Oil and Coconut Cream with added Starch, Flavourings, Calcium and Vitamins D2 and B12 (4%) (Water, Coconut Oil). Contains Cereals Containing Gluten, Nuts, Wheat.'
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

    print(f"✨ BATCH 26 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {200 + updates_made} / 681\n")
    print(f"🎯 Next milestone: {250 - (200 + updates_made)} products until 250!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch26(db_path)
