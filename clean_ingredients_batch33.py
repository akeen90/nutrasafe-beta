#!/usr/bin/env python3
"""
Clean ingredients batch 33 - Maintaining Momentum to 350!
"""

import sqlite3
from datetime import datetime

def update_batch33(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 33 (Pushing to 350!)\\n")

    clean_data = [
        {
            'id': 'AWIbs0xGfqvGLtBbslb5',
            'name': 'Chilli Crusted Hot Smoked Mackerel Fillets',
            'brand': 'Asda Extra Special',
            'serving_size_g': 100.0,
            'ingredients': 'Mackerel (Scomber Scombrus) (Fish), Rapeseed Oil, Water, Salt, Spices (Chilli Flakes, Black Pepper, Paprika, Pimento, Chillies), Herbs (Coriander, Bay Leaf, Oregano, Basil, Tarragon), Smoked Paprika, Dried Onion, Dried Garlic. Contains Fish.'
        },
        {
            'id': 'SzppaEIKj14k5smGVWeb',
            'name': 'Belgium Chocolate Sauce',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Single Cream (Milk) (12%), Water, Belgian Dark Chocolate (4%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin), Flavouring), Fat Reduced Cocoa Powder, Skimmed Milk Powder, Cornflour, Preservative (Potassium Sorbate), Vanilla Flavouring. Contains Milk, Soybeans.'
        },
        {
            'id': 'SVYiff7Qyc2vqmx1L1PV',
            'name': 'Tomato & Basil Soup',
            'brand': 'New Covent Garden Soup Co',
            'serving_size_g': 280.0,
            'ingredients': 'Tomato (47%) (Tomato, Concentrated Tomato Juice, Tomato Paste), Water, Onion, Sugar, Basil, Rapeseed Oil, Cornflour, Salt, Garlic Purée, Black Pepper.'
        },
        {
            'id': 'udcE2Scw8zqeeutxNsgj',
            'name': 'Olive Spread',
            'brand': "Sainsbury's",
            'serving_size_g': 10.0,
            'ingredients': 'Water, Vegetable Oils (Palm Oil, Rapeseed Oil), Olive Oil (10%), Salt (1%), Vitamin E, Acidity Regulator (Citric Acid), Flavouring, Colour (Carotenes), Vitamin A, Vitamin D.'
        },
        {
            'id': 'D6AbJz0GVh64UvERVUAv',
            'name': 'Aqua Libra',
            'brand': 'Aqua Libra',
            'serving_size_g': 330.0,
            'ingredients': 'Sparkling Water, Lemon Juice from Concentrate, Natural Flavourings.'
        },
        {
            'id': 'M52CXC0hte8dB93lqAMp',
            'name': 'Sweet & Sour Noodle Box',
            'brand': 'M&S',
            'serving_size_g': 300.0,
            'ingredients': 'Wheat Noodles (Wheat Flour, Water, Wheat Gluten, Modified Tapioca Starch, Rice Bran Oil, Salt), Sweet and Sour Sauce (40%) (Water, Capsicum, Sugar, Carrots, Pineapple, Rice Vinegar, Onions, Tomatoes, Rice Bran Oil, Modified Tapioca Starch, Garlic, Chillies, Salt, Celery, Ginger, Sesame Oil, Paprika Extract). Contains Celery, Cereals Containing Gluten, Sesame, Wheat. Not Suitable for Nut Allergy.'
        },
        {
            'id': 'h85LK7sbHmpS46TtqSai',
            'name': 'Immunity Boosting Power Soup',
            'brand': 'Bol',
            'serving_size_g': 300.0,
            'ingredients': 'Water, Sweetcorn (19%), Carrots, Sweet Potato, Red Peppers (3%), Roasted Onion Purée (Onion, Rapeseed Oil), Coconut Cream (3%), Vegetable Stock (Water, Carrots, White Onions, Salt, Leeks, Red Onions, Garlic, Kaffir Lime Leaf, Spring Onions, Fennel, Coriander, Bay Leaf Infusion (Water, Bay Leaf), Black Pepper, White Pepper), Red Lentils, Tomato Paste, Cornflour, Garlic Purée, Lime Juice, Ground Coriander, Salt, Smoked Paprika, Ground Cumin, Chopped Coriander, Parsley, Crushed Chillies, Ground White Pepper.'
        },
        {
            'id': 'ReqXN2850f0o3xcgxlxp',
            'name': 'Turmeric Latte Ice Cream',
            'brand': 'Vitasia Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted Skimmed Milk Concentrate (Milk), Water, Sugar, Glucose-Fructose Syrup, Coconut Fat, Glucose Syrup, Chopped Whipping Cream (Milk), Emulsifier (Mono- and Diglycerides of Fatty Acids), Stabilisers (Locust Bean Gum, Modified Maize Starch), Spices (Ginger, Black Pepper, Turmeric, Nutmeg, Cassia), Natural Flavouring. Contains Milk.'
        },
        {
            'id': 'no9O2JfXyX5Q5hbgaf08',
            'name': 'Mint Sauce',
            'brand': 'Bramwells',
            'serving_size_g': 10.0,
            'ingredients': 'Water, Mint (25%), Sugar, Spirit Vinegar, Salt, Stabiliser (Xanthan Gum), Acidity Regulator (Acetic Acid), Colour (Copper Complexes of Chlorophylls and Chlorophyllins).'
        },
        {
            'id': 'sf89ZVeqar9rhlQvbmyb',
            'name': 'Marabel Creamy Mash',
            'brand': 'Extra Special',
            'serving_size_g': 100.0,
            'ingredients': 'Marabel Potatoes (91%), Double Cream (Milk) (4%), Semi-Skimmed Milk, Salted Butter (2%) (Butter (Milk), Salt), Sea Salt, White Pepper. Contains Milk.'
        },
        {
            'id': 'EgZgJH7bTo89y82p0LSp',
            'name': 'Beef And Dumpling Casserole',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'British Beef (30%), Water, Onions, Wheat Flour, Carrots (8%), Swede (8%), Red Wine, Beef Suet, Roast Beef Stock (Water, Beef Bones, Yeast Extract, Salt, Sugar), Tomato Purée, Salt, Beef Gelatine, Raising Agent (E450, Sodium Bicarbonate), Parsley, Balsamic Vinegar, Vinegar, Sugar Syrup, Ground Spices (White Pepper, Black Pepper, Cloves), Dried Onions, Tamarind Extract, Garlic Purée, Lemon Oil, Cornflour. Contains Beef, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'btWTynajxT4k5Wu0JDSh',
            'name': 'BBQ Ribs',
            'brand': 'Birchwood',
            'serving_size_g': 121.0,
            'ingredients': 'Pork Ribs (76%), Smoky Barbecue Flavour Sauce (15%) (Water, Sugar, Tomato Paste, Spirit Vinegar, Cane Molasses, Cornflour, Caramelised Sugar Syrup, Smoked Water, Salt, Garlic Powder, Cumin Powder, Onion Powder, Ground Coriander Seeds, Ground Black Pepper, Red Paprika, Oregano Powder), Marinade (7%) (Water, Glucose Syrup, Salt, Stabilisers (Diphosphates, Triphosphates), Modified Maize Starch, Acidity Regulators (Sodium Citrates, Citric Acid), Yeast Extract), Barbecue Flavour Glaze (2%) (Sugar, Spices (Paprika Powder, Onion Powder, Chilli Pepper, Black Pepper, Garlic Powder), Salt, Tomato Powder, Maize Starch, Rice Flour, Smoke Flavouring, Red Bell Pepper, Colour (Paprika Extract)). Contains Pork. May Contain Nuts, Peanuts.'
        },
        {
            'id': 'R8zQkrAM3AZ9sEoIcnmK',
            'name': 'Topped Ploughmans Dip',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Full Fat Soft Cheese (Milk) (17%), Red Cheddar Cheese (17%) (Cheddar Cheese (Milk), Natural Colour (Beta-Carotenes)), Rapeseed Oil, Pulled Ham Hock (11%) (British Ham Hock Made with 120g of Raw Pork per 100g of Pulled Ham Hock, Curing Salt (Salt, Preservatives (Sodium Nitrite, Potassium Nitrate))), Water, Silverskin Onions, Vintage Cheddar Cheese (Milk) (5%), Pasteurised Egg Yolk, Sugar, Cornflour, Carrots, Barley Malt Vinegar, Onions, Vinegar, Salt, Parsley, Swede, Courgette, Gherkins, Tomato Paste, Barley Malt Extract, Bramley Apples, Dates, Garlic Purée, Concentrated Lemon Juice, Rice Flour, Ground Spices (Cinnamon, Ginger, Nutmeg, Black Pepper, Cayenne Pepper, Cloves, Coriander, Cumin, Paprika, Allspice, Fenugreek). Contains Barley, Cereals Containing Gluten, Eggs, Milk, Pork.'
        },
        {
            'id': 'DgaM7QRC3RZVG3vMbXVV',
            'name': 'Soy & Ginger Sauce With Garlic',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Light Soy Sauce (15%) (Water, Salt, Soya Beans, Wheat, Sugar, Alcohol), Sugar, Rice Wine Vinegar, Ginger Purée (5%), Tomato Purée, Cornflour, Garlic Purée (3%), Ginger (3%), Colour (Plain Caramel). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'BRQSa87h52fPJRUR4kM4',
            'name': 'Garlic And Herb Nooch Flavoured Seasoning',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Inactive Yeast (80%), Garlic, Salt, Parsley, Black Pepper, Rosemary, Rubbed Sage, Anti-Caking Agent (Silicon Dioxide), Coconut Oil, Flavouring.'
        },
        {
            'id': 'qcibHOxMAqjls1Cx7a6J',
            'name': 'St James Christmas Pudding',
            'brand': 'Fortnum & Mason',
            'serving_size_g': 100.0,
            'ingredients': 'Vine Fruits (34%) (Turkish Raisins, Turkish Sultanas, Vostizza Currants, Non-Hydrogenated Cotton Seed Oil, Non-Hydrogenated Sunflower Oil), Molasses Sugar, Non-Hydrogenated Vegetable Suet (8%) (Palm Oil, Sunflower Oil, Wheat Flour), Pasteurised Free Range Eggs, Stoneground Wholemeal Wheat Flour, Water, Candied Mixed Peel (Orange Peel, Lemon Peel, Glucose-Fructose Syrup, Salt, Preservative (Sulphur Dioxide), Citric Acid), Fortnum & Mason Cognac (3.5%), Lemon Zest, Pasteurised Whole Milk, Almond Strips, Single Cream (Milk), Wheat Flour Crumb (Wheat Flour, Salt), Pussers Navy Rum (0.8%), Orange Juice, Nutmeg, Cinnamon, Mixed Spice, Sea Salt, Black Treacle. Contains Cereals Containing Gluten, Eggs, Milk, Nuts, Sulphites, Wheat.'
        },
        {
            'id': '8IyZFaeQ2zG27md2ItGZ',
            'name': '4 All Butter Croissants',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Unsalted Butter (Milk) (25%), Water, Sugar, Pasteurised Whole Egg, Skimmed Milk Powder, Salt, Yeast, Inactive Wheat Sourdough, Acetic Acid, Flour Treatment Agent (Ascorbic Acid), Lactic Acid. Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': '47ejZFI3XOByJrkPUMHn',
            'name': 'Fudge Dessert',
            'brand': 'Ambrosia',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Fudge Sauce (36%) (Water, Skimmed Milk, Buttermilk, Sugar, Modified Starch, Butter Powder (Milk) (3.5%) (Dried Butter (Milk), Glucose Syrup, Milk Proteins), Inulin, Dried Glucose Syrup, Colour (Plain Caramel), Thickeners (Carrageenan, Xanthan Gum), Glucose, Flavouring), Sugar, Buttermilk, Modified Starch, Palm Oil, Fat Reduced Cocoa Powder (1%), Whey (Milk), Thickener (Carrageenan), Flavouring. Contains Milk.'
        },
        {
            'id': 'uYBmZ7nDWN022PSBV8j4',
            'name': 'Egg Fried Rice',
            'brand': 'Asda',
            'serving_size_g': 150.0,
            'ingredients': 'Water, Long Grain Rice, Peas (9%), Scrambled Egg (6%) (Pasteurised Whole Egg, Water, Rapeseed Oil, Lemon Juice, Salt), Rapeseed Oil, Garlic Purée, Toasted Sesame Seed Oil, Ginger Purée, Salt. Contains Eggs, Sesame. May Contain Nuts, Peanuts.'
        },
        {
            'id': 'KXY6B1aWPY7ZwNIQHnJs',
            'name': 'Chicken Vegetable Chow Mein',
            'brand': 'M&S',
            'serving_size_g': 380.0,
            'ingredients': 'Cooked Egg Noodles (23%) (Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Pasteurised Egg, Raising Agent (E501, Sodium Bicarbonate), Salt, Ground Paprika, Turmeric, Acidity Regulator (Citric Acid)), Beansprouts (16%), Chicken Breast (16%), Water, Carrots (10%), Red Peppers (5%), Cabbage (3%), Cloud Ear Mushrooms (2.5%), Shaoxing Rice Wine (Contains Wheat), Dark Soy Sauce (Water, Soybeans, Wheat, Salt), Cornflour, Sugar, Rapeseed Oil, Ginger Purée, Garlic Purée, Toasted Sesame Oil, Vinegar, Salt, Chicken Stock (Water, Chicken Bones, Soybeans, Caramelised Sugar Syrup, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Concentrated Mushrooms, Ground Star Anise, Acidity Regulator (Acetic Acid), Dried Mushrooms). Contains Cereals Containing Gluten, Eggs, Sesame, Soybeans, Wheat.'
        },
        {
            'id': 'j40cnqI24WWzUHedaiUL',
            'name': 'Soft White Medium Bread',
            'brand': 'Hovis',
            'serving_size_g': 40.0,
            'ingredients': 'Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Water, Yeast, Soya Flour, Salt, Preservative (E282), Emulsifiers (E472e, E471, E481), Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'rQ58I93R98qKTTU4vLqX',
            'name': 'Finest Marzipan',
            'brand': 'Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Ground Almonds (14%), Glucose Syrup, Cocoa Mass, Cocoa Butter, Orange Juice from Orange Juice Concentrate (5%), Whole Milk Powder, Apple Purée, Orange Liqueur, Orange Cells (1%), Jamaica Rum (1%), Bitter Oranges (<1%), Thickener (Pectins), Emulsifier (Lecithins), Acid (Citric Acid), Humectant (Invertase), Natural Orange Flavouring, Acidity Regulator (Sodium Citrates). Contains Milk, Nuts.'
        },
        {
            'id': 'LsmHSQ932YTDlRpXod24',
            'name': 'Wholegrain Wheat Bisks',
            'brand': 'M&S',
            'serving_size_g': 40.0,
            'ingredients': 'Wholewheat (95%), Barley Malt Extract, Sugar, Salt, Niacin, Iron, Thiamin, Riboflavins, Folic Acid. Contains Barley, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': '9GDcSZVORFdog2vVRuDA',
            'name': 'Discos Salt & Vinegar',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Starch, Dried Potato, Sunflower Oil, Wheat Flour (with Calcium, Iron, Niacin, Thiamin), Salt & Vinegar Flavour (Natural Flavouring, Rice Flour, Salt, Acids (Citric Acid, Malic Acid), Dried Barley Malt Vinegar Extract, Dried Yeast Extract), Emulsifier (Mono- and Diglycerides of Fatty Acids). Contains Barley, Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'SvGFq2fLrXqe9oLUmLm1',
            'name': 'Red Bull Pink Edition Forest Fruits',
            'brand': 'Red Bull',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Acid (Citric Acid), Taurine (0.4%), Sodium Citrates, Sweetener (Acesulfame K), Caffeine (0.03%), Vitamins (Niacin, Pantothenic Acid, Vitamin B6, Vitamin B12), Colours (Anthocyanins, Riboflavin), Flavourings. Contains Taurine, Caffeine.'
        },
        {
            'id': '2ZLMV2iBqsjGIpmZ6t6Z',
            'name': 'Hazelnut Chocolate Spread',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Vegetable Oils (Palm, Rapeseed), Hazelnuts (13%), Fat-Reduced Cocoa Powder (8%), Skimmed Milk Powder, Dried Glucose Syrup, Sweet Whey Powder (Milk), Emulsifier (Lecithins). Contains Milk, Nuts.'
        },
        {
            'id': 'ExSqyDtfUp8eVmXDqbVw',
            'name': 'Vegetable Stock Pots',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Concentrated Vegetable Stock (62%) (Water, Carrot (1.5%), Tomato, Red Pepper, Celery, Red Onion, Leek (0.2%), Cabbage), Salt, Sunflower Oil, Flavourings (Contains Celery), Sugar, Yeast Extract, Gelling Agents (Agar, Xanthan Gum), Spices (Turmeric, Parsley), Acidity Regulator (Lactic Acid). Contains Celery.'
        },
        {
            'id': 'AwaMVhI9uPANE3SQ42Kv',
            'name': 'Soft White Toasting Muffins',
            'brand': 'Village Bakery',
            'serving_size_g': 68.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Durum Wheat Semolina, Wheat Gluten, Sugar, Salt, Soya Flour, Spirit Vinegar, Vegetable Fats (Palm Oil, Palm Stearin, Rapeseed Oil), Preservative (Potassium Sorbate), Skimmed Milk Powder, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat.'
        },
        {
            'id': 'P0GduhMa6Zln1fxG5lUy',
            'name': 'Cheesy Slices',
            'brand': 'Asda',
            'serving_size_g': 17.0,
            'ingredients': 'Reconstituted Whey Powder (Milk), Palm Oil, Cheese (11%) (Milk), Acidity Regulator (Lactic Acid), Milk Proteins, Emulsifying Salts (Polyphosphates, Calcium Phosphates), Modified Potato Starch, Flavouring (Contains Milk), Colours (Carotenes, Paprika Extract). Contains Milk.'
        },
        {
            'id': 'tVuTGMYSlThqFiYuqgYy',
            'name': 'Gluten Free Golden Syrup Flavour Porridge Pot',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oats (75%), Sugar, Golden Syrup Flavouring, Salt. Contains Oats.'
        },
        {
            'id': 'cGo7IxxR0AP2gkEcBhJo',
            'name': 'Broth For Noodles Sesame Chicken',
            'brand': 'Itsu',
            'serving_size_g': 250.0,
            'ingredients': 'Water, Chicken Stock (Roast British Chicken (50%), Yeast Extract, Salt, Chicken Fat, Water, Lemon Juice from Concentrate, Sugar, Onion Powder, Leek Powder, Natural Black Pepper Flavouring, Sage Oil), Sesame Seed Paste (3%), Soy Sauce (Water, Soya Beans, Wheat, Salt), Sesame Oil, Sugar, Mirin Rice Wine (Fermented Rice, Water, Maltose, Alcohol), Salt, Garlic, Ginger, Leek Powder, Onion Powder, Colour (Paprika Extract), Pepper Extract. Contains Cereals Containing Gluten, Sesame, Soybeans, Wheat.'
        },
        {
            'id': 'BFBPdFSQE6iEcLJrHKpt',
            'name': 'Fishermans Pie With Mash Potato',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (41%), Milk, Pollock (Fish) (20%), Water, Butter (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Extra Mature Cheddar Cheese (Milk) (2%), Mature Cheddar Cheese (Milk) (2%), Cornflour, Salt, Gelling Agent (Pectins), Palm Oil, Fish Stock (Salt, Water, Thickener (Maltodextrin), Pollock Powder (Fish), Sunflower Oil, Anchovy Extract (Fish), Lemon Powder, Stabiliser (Guar Gum), Cod Powder (Fish), Pepper Extract, Onion Powder), Yeast, Spices (Contains Mustard), Parsley. Contains Cereals Containing Gluten, Fish, Milk, Mustard, Wheat.'
        },
        {
            'id': 'XPu9EI1f8VHqdNYrv9d2',
            'name': 'Chicken Arrabbiata',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Penne Pasta (32%) (Water, Durum Wheat Semolina), Passata, Chopped Tomatoes (19%) (Tomatoes, Tomato Juice), Cooked Seared Chicken Strips (13%) (Chicken Breast (97%), Water, Chicken Bouillon (Sugar, Tapioca Starch, Spices (Garlic Powder, Onion Powder, White Pepper), Chicken Powder (Chicken, Flavouring, Yeast Extract, Salt, Sunflower Oil), Dried Parsley), Modified Tapioca Starch, Salt, Smoke Flavouring), Water, Mozzarella Cheese (Milk) (3.5%), Modified Maize Starch, White Sugar, Olive Oil, Tomato Paste, Rapeseed Oil, Garlic Purée, Salt, Smoked Paprika, Parsley, Yeast Extract (Contains Barley), Extra Virgin Olive Oil, Chilli Powder, Oregano, Cracked Black Pepper. Contains Barley, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'RLaJyH78tqBENP9gfGOp',
            'name': 'Oat & Dairy Butter',
            'brand': 'Smug Dairy',
            'serving_size_g': 10.0,
            'ingredients': 'Butter (50%) (Milk), Rapeseed Oil, Oat Drink (24%) (Water, Gluten Free Oat Flour), Salt, Fava Bean Protein, Vitamin B12, Colour (Carotenes), Vitamin E, Vitamin A, Vitamin D. Contains Milk, Oats.'
        },
        {
            'id': 'Dxk7KSv9OMoeEbDqKJVN',
            'name': 'Kefir Yoghurt',
            'brand': 'Biotiful',
            'serving_size_g': 100.0,
            'ingredients': 'Pasteurised Milk Fermented with Live Kefir and Yogurt Cultures, Water, Fruit Extract (Apple, Carob, Grape), Tapioca Starch, Natural Flavouring, Lemon Concentrate, Stabiliser (Pectin), Madagascan Vanilla Extract, Vanilla Seeds. Contains: Bifidobacterium, Streptococcus Thermophilus, Lactobacillus Bulgaricus, Lactobacillus Acidophilus. Contains Milk.'
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

    total_cleaned = 301 + updates_made

    print(f"✨ BATCH 33 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    remaining_to_350 = 350 - total_cleaned
    if remaining_to_350 > 0:
        print(f"🎯 Next milestone: {remaining_to_350} products until 350!\\n")
    else:
        print(f"\\n🎉🎉🎉 350 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {400 - total_cleaned} products until 400!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch33(db_path)
