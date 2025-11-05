#!/usr/bin/env python3
"""
Clean ingredients batch 52 - Continuing messy ingredients cleanup
Removing marketing text, allergen advice, nutrition info, storage instructions
"""

import sqlite3
from datetime import datetime

def update_batch52(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 52\n")

    clean_data = [
        {
            'id': '3CXTUL11TCJWswAIOxNn',
            'name': 'Smooth Brussels Pâté',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Liver (34%), Water, Pork Fat (20%), Pork (6.0%), Pork Rind, Salt, Tapioca Starch, Sugar, Dried Onions, Emulsifier (Citric Acid Esters of Mono and Diglycerides of Fatty Acids), Potato Fibre, Flavouring, Tomato Powder, Acidity Regulators (Sodium Acetates, Citric Acid), Pork Protein, Antioxidant (Ascorbic Acid), Brandy, Spices, Preservative (Sodium Nitrite). May Contain Nuts.'
        },
        {
            'id': '3Dh8JGDG5DZ9pV55tInA',
            'name': 'GF Choco Pops',
            'brand': 'M&S',
            'serving_size_g': 30.0,
            'ingredients': 'Brown Rice Flour (78%), Sugar, Cocoa (3%), Salt, Rice Bran Extract.'
        },
        {
            'id': '3FtJoS82kK7AWjf2HQPa',
            'name': 'Turkey Burgers',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British Turkey (85%), Water, Rusk (Rice Flour, Gram Flour, Maize Starch, Salt, Dextrose), Seasoning (Rice Flour, Spices (Nutmeg, Cracked Black Pepper, Ginger Powder), Onion Powder, Garlic Powder, Emulsifier (Trisodium Diphosphate), Salt, Herbs (Sage, Parsley, Thyme), Preservative (Sodium Metabisulphite (Sulphites)), Yeast Extract, Antioxidant (Ascorbic Acid)), Pea Fibre. Contains Sulphites.'
        },
        {
            'id': '3I1hx0h4DoPz9psi4H7w',
            'name': 'Sardines In Tomato Sauce',
            'brand': 'The Fishmonger',
            'serving_size_g': 100.0,
            'ingredients': 'Sardines (Sardina Pilchardus) (Fish) (70%), Tomato Paste (14%), Water, Sunflower Oil, Salt. Contains Fish.'
        },
        {
            'id': '3K6mO5XPJ5L4AeDvxt7f',
            'name': 'Super Nutty Granola',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes, Spelt (Wheat) Flakes, Sugar, Barley Flakes, Almonds (6%), Honey, Hazelnut (5%), Rapeseed Oil, Cashew Nut (2%), Brazil Nut Slices (1%), Pecan Nut Pieces (1%), Sugar Syrup Powder, Salt, Flavouring. Contains Barley, Cereals Containing Gluten, Nuts, Oats, Wheat. May Contain Milk, Peanuts.'
        },
        {
            'id': '3EGHp9oru4oHQav0Nda4',
            'name': 'Giannis Salted Caramel Ice Cream',
            'brand': 'Giannis',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Coconut Oil, Salted Caramel Sauce (8%) (Water, Glucose-Fructose Syrup, Sugar, Whey Powder (Milk), Skimmed Milk Powder, Salt, Burnt Sugar, Thickener (Pectins), Stabilizer (Sodium Alginate), Flavoring), Glucose Syrup, Whey Powder (Milk), Skimmed Milk Powder, White and Dark Chocolate Flavored Curls (2%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Lactose (Milk), Whey Powder (Milk), Lemon Concentrate, Safflower Concentrate, Emulsifier (Lecithins (Sunflower)), Natural Vanilla Flavoring, Plant Extracts (Radish Concentrate, Apple Concentrate, Blackcurrant Concentrate), Flavoring), Emulsifier (Mono- and Diglycerides of Fatty Acids), Burnt Sugar, Thickeners (Locust Bean Gum, Guar Gum), Salt, Flavoring, Flavoring (contains Milk). Contains Milk. May Contain Almonds, Eggs, Hazelnuts, Peanuts, Pistachio Nuts, Soybeans.'
        },
        {
            'id': '3MsboHWKNC3zVoxd3qPz',
            'name': 'Pret Marvellous Milk Chocolate',
            'brand': 'Pret A Manger',
            'serving_size_g': 100.0,
            'ingredients': 'Cane Sugar, Cocoa Butter, Milk Powder, Cocoa Mass, Emulsifier (Soya Lecithin). Milk Chocolate Contains: Cocoa Solids 38%, Milk Solids 24% Minimum. Contains Milk, Soybeans. Not Suitable for Nut and Milk Allergy Sufferers.'
        },
        {
            'id': '3N08lJgmgTv3oqCdiIzp',
            'name': 'Cookies And Cream Milkshake',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Water, Cream (Milk) (10%), Syrup (Maltodextrin, Sugar, Lactose, Cookie Pieces (25%) (Sugar, Cocoa Powder, Glucose Syrup, Wheat Starch, Powder (Milk), Sunflower Oil, Corn Flour, Humectant), Salt), Milk Protein, Stabilisers (Locust Bean Gum, Guar), Natural Flavouring, Natural Vanilla Extract. Contains Cereals Containing Gluten, Milk, Wheat. May Contain Nuts, Soybeans.'
        },
        {
            'id': '3N5Ldafx8qFiLwJAEcYo',
            'name': 'Tesco Summer Edition 4 Pineapple. Coconut & LIME L',
            'brand': 'Tesco',
            'serving_size_g': 74.0,
            'ingredients': 'Pineapple Juice (69%), Coconut Milk (17%), Sugar, Lime Juice (3%). May Contain Milk.'
        },
        {
            'id': '3NpLFNn6RWJK7KkgGa8f',
            'name': 'Butter Fudge',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Butter (Milk) (12%), Glucose Syrup, Whole Milk Powder, Invert Sugar (Sugar, Glucose-Fructose Syrup, Water, Acidity Regulator (Citric Acid)), Sea Salt, Emulsifier (Sunflower Lecithins). Contains Milk. May Contain Eggs, Nuts, Peanuts.'
        },
        {
            'id': '3ObwIs801ziMiEIInAwB',
            'name': 'Strawberry Yoghurt Flakes',
            'brand': 'Fruit Bowl',
            'serving_size_g': 18.0,
            'ingredients': 'Yogurt Flavoured Coating (60%) (Sugar, Palm Fat, Whey Powder (Milk), Rice Flour, Yogurt Powder (Milk) (3%), Emulsifier (Sunflower Lecithins), Glazing Agent (Shellac, Gum Arabic)), Fruit Flakes (40%) (Concentrated Apple Purée, Fructose-Glucose Syrup, Strawberry Purée, Sugar, Gluten Free Wheat Fibre, Palm Fat, Gelling Agent (Pectin), Concentrated Aronia Juice, Acidity Regulator (Malic Acid), Natural Flavouring). Contains Milk, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': '3OtYyxlysCT1Xc2HNHrZ',
            'name': 'Minis Ice Creams',
            'brand': 'Alsi',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate Covered Ice Cream Lolly: Reconstituted Skimmed Milk, Milk Chocolate (34%) (Sugar, Cocoa Mass, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods. Milk Chocolate Covered Ice Cream Lolly with Chopped Almonds: Reconstituted Skimmed Milk, Milk Chocolate (33%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Cocoa Mass, Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Chopped Almonds (5%), Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods. White Chocolate Covered Ice Cream Lolly: Reconstituted Skimmed Milk, White Chocolate (34%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods. Contains Milk, Nuts. May Contain Peanuts, Soybeans.'
        },
        {
            'id': '3PHK6zdHigkJRZoIvjiw',
            'name': 'Soft Bun With Sultanas And Lemon Custard',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Folic Acid, Iron, Niacin, Thiamin), Sugar, Water, Sultanas (10%), Palm Oil (Certified Sustainable), Whole Milk, Pasteurised Free Range Egg White, Pasteurised Free Range Egg, Glacé Cherry (Cherry, Glucose-Fructose Syrup, Sugar, Fruit and Vegetable Concentrates (Sweet Potato, Apple, Radish, Cherry), Acidity Regulator (Citric Acid)), Invert Sugar Syrup, Rapeseed Oil, Lactose (Milk), Milk Powder, Raising Agents (Diphosphates, Sodium Bicarbonate, Tetrasodium Diphosphate), Emulsifiers (Citric Acid Esters of Mono- and Diglycerides of Fatty Acids, Mono-and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Polysorbate 60), Yeast, Flavourings, Glucose Syrup, Colour (Carotenes), Salt, Lemon Comminute, Modified Maize Starch, Modified Tapioca Starch, Gelling Agents (Sodium Alginate, Agar), Preservative (Potassium Sorbate), Flour Treatment Agent (Ascorbic Acid), Lemon Oil, Acidity Regulator (Citric Acid). Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': '3RxVGtOAxQTGgwKwfjag',
            'name': 'Bramwells Seafood Sauce',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rapeseed Oil, Sugar, Tomato Paste, Egg Powder, Modified Potato Starch, Acidity Regulator (Acetic Acid), Salt, Dried Onions, Preservative (Potassium Sorbate), Stabilisers (Guar Gum, Xanthan Gum), Dried Garlic. Contains Eggs.'
        },
        {
            'id': '3T0zGpDuZ2YNNRgGMvlM',
            'name': 'Nescafe Green Triangle Mocha',
            'brand': 'Nescafe',
            'serving_size_g': 19.0,
            'ingredients': 'Skimmed Milk Powder (19%), Glucose Syrup, Drinking Chocolate (14.7%) (Sugar, Cocoa Powder (25%)), Sugar, Fat-Reduced Drinking Chocolate (14.7%) (Sugar, Fat-Reduced Cocoa Powder (25%)), Coconut Oil, Instant Coffee (5%), Lactose (Milk), Natural Flavourings, Acidity Regulators (Sodium Bicarbonate, Citric Acid), Thickener (Xanthan Gum), Salt. Contains Milk.'
        },
        {
            'id': '3T80ZKNtU2kz9CTUMWf5',
            'name': 'Galaxy Dairy Free Hazelnut Praline',
            'brand': 'Galaxy',
            'serving_size_g': 25.0,
            'ingredients': 'Sugar, Hazelnut Paste Filling (25%) (Sugar, Hazelnut Paste, Cocoa Butter, Emulsifier (Lecithin (Soya))), Cocoa Butter, Cocoa Mass, Hazelnut Paste (9%), Rice Flour, Emulsifier (Lecithin (Soya)). Contains Nuts, Soybeans. May Contain Other Nuts.'
        },
        {
            'id': '3TZUi8ijt6TqhIjMo3Ir',
            'name': 'Raspberry Jam Sponge Puddings',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Raspberry Jam (Glucose-Fructose Syrup, Raspberry Purée, Sugar, Gelling Agent (Pectin (from Fruit)), Acid (Citric Acid), Acidity Regulator (E331)), Wheatflour (contains Gluten with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Whole Milk, Pasteurised Egg, Butter (Milk), Palm Oil, Rapeseed Oil, Raising Agent (E450, E501), Emulsifier (E471), Salt, Flavouring. Contains Cereals Containing Gluten, Eggs, Milk, Wheat. Not Suitable for Nut and Peanut Allergy Sufferers due to Manufacturing Methods.'
        },
        {
            'id': '3UjHbgjTX61gQuMVzXcb',
            'name': 'Tasty Minted LAMB Kebabs Gluten FREE Delicious',
            'brand': 'Asda',
            'serving_size_g': 360.0,
            'ingredients': 'Lamb (28%), Dried Mint (6%), Onions, Water, Rice, Fine Gram Flour, Brown Sugar (Sugar, Cane Molasses), White Sugar, Sea Salt, Black Pepper, Maize Starch, Salt, Preservative (Sodium Metabisulphite), Antioxidant (Ascorbic Acid), Dextrose (contains Sulphites). Contains Sulphites.'
        },
        {
            'id': '3Vm89GAQ2S93hF3eb4DO',
            'name': 'Orange Squash',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted Tomato Purée (63%), Water, Tomato (9%), Rapeseed Oil, Sugar, Double Cream (Milk) (3%), Modified Maize Starch, Medium Fat Soft Cheese (2%) (Water, Cream (Milk), Milk Protein, Salt), Onion, Lemon Juice from Concentrate, Herbs (1%), Salt, Acidity Regulator (Citric Acid), Stabilizer (Xanthan Gum), Garlic Powder, Yeast, Maltodextrin, Flavoring. Contains Milk.'
        },
        {
            'id': '3X22dh2dlZyB2oTaoWRX',
            'name': 'Feta And Mixed Grains Salad',
            'brand': 'Sainsbury\'s Taste The Difference',
            'serving_size_g': 288.0,
            'ingredients': 'Giant Couscous (21%) (Durum Wheat Semolina, Water), Bulgur Wheat (15%) (Bulgur Wheat, Water), Beetroot & Crème Fraîche Dressing (14%) (Beetroot, Water, Rapeseed Oil, Reduced Fat Greek Style Yogurt (Cows\' Milk), Crème Fraiche (Cows\' Milk), Sugar, Balsamic Vinegar (Red Wine Vinegar, Concentrated Grape Must, Water), Cornflour, Concentrated Lemon Juice, Spearmint, Salt, Garlic Purée), Spinach, Feta Cheese PDO (9%) (Sheep\'s and Goats\' Milk), Pickled Carrot & Red Cabbage (Red Cabbage, Carrot, Sugar, Spirit Vinegar, Salt), Red Quinoa (8%) (Quinoa, Water), Sweet Drop Peppers (4.5%) (Pepper, Sugar, Spirit Vinegar, Salt, Antioxidant (Ascorbic Acid), Firming Agent (Calcium Chloride)), Rapeseed Oil, Water, Parsley, Coriander, White Wine Vinegar, Garlic Purée, Salt, Concentrated Lemon Juice, Cornflour, Cumin Powder, Black Pepper, Cayenne Pepper, Smoked Paprika. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': '3XNZ8dOFvaCloHinFbN0',
            'name': 'Exceptional Sicilian Lemon Yoghurt',
            'brand': 'Generic',
            'serving_size_g': 112.5,
            'ingredients': 'Whole Milk Yogurt (65%), Whipping Cream from Concentrate (4%), Pasteurised Egg (Milk) (13%), Water, Sugar, Sicilian Lemon Juice, Unsalted Butter (Milk), Maize Starch, Colours (Paprika Extract, Curcumin), Flavouring, Live Bacterial Cultures (Bifidobacterium, Lactobacillus Acidophilus, Streptococcus Thermophilus). Contains Eggs, Milk.'
        },
        {
            'id': '3XgnaCumWva1jPFJyQ5C',
            'name': 'Sliced Tiger Loaf',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Yeast, Rapeseed Oil, Wheat Gluten, Salt, Soya Flour, Palm Oil, Emulsifiers (Sodium Stearoyl-2-Lactylate, Mono- and Diacetyltartaric Acid Esters of Mono- and Diglycerides of Fatty Acids), Pregelatinized Wheat Flour, Flour Treatment Agents (Ascorbic Acid, L-Cysteine), Wheat Flour, Dextrose, Sugar, Barley, Diphosphates, Barley Malt. Contains Barley, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': '3YbIsgnyOL145bloayzx',
            'name': 'Protein Bites',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Flour, Date Paste, Almond Paste (20%), Chicory Fibre, Soya Protein Isolate, Freeze Dried Raspberries (0.8%), Flavouring, Tapioca Stabiliser, Calcium Carbonate. Contains Nuts, Soybeans. May Contain Milk, Peanuts.'
        },
        {
            'id': '3ZQ6ITQRIgGhfMPNbbMV',
            'name': 'Italian Antipasto Selection',
            'brand': 'Aldi',
            'serving_size_g': 120.0,
            'ingredients': 'Prosciutto Crudo (33%) (Pork, Salt, Preservative (Potassium Nitrate)). Made with 144g of Raw Pork per 100g of Finished Product. Milano Salami (33%) (Pork, Salt, Flavouring, Dextrose, Sugar, Spices, Garlic, Antioxidant (Sodium Ascorbate), Preservatives (Potassium Nitrate, Sodium Nitrite)). Made with 130g of Raw Pork per 100g of Finished Product. Napoli Salami (33%) (Pork, Salt, Flavourings, Spices, Dextrose, Sugar, Garlic, Antioxidant (Sodium Ascorbate), Smoke Flavouring, Preservatives (Potassium Nitrate, Sodium Nitrite)). Made with 136g of Raw Pork per 100g of Finished Product.'
        },
        {
            'id': '3aDOhQylvho9MEFUgJfH',
            'name': 'Sausage Rolls',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 60.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), British Pork (27%), Water, Palm Oil, Potato Starch, Onion, Wheat Flour, Salt, Rapeseed Oil, Skimmed Cow\'s Milk Powder, Black Pepper, Sugar, Nutmeg, Yeast Extract, Parsley, Mace, Onion Powder, White Pepper, Garlic Powder. Contains Cereals Containing Gluten, Milk, Wheat.'
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

    total_cleaned = 686 + updates_made

    print(f"✨ BATCH 52 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Breaking 700 milestone check
    if total_cleaned >= 700:
        print(f"\n🎉🎉🎉 700 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 10.8% progress through the messy ingredients!")

    print(f"🎯 Approximately {6448 - total_cleaned} products with messy ingredients remaining\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch52(db_path)
