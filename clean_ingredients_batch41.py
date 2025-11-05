#!/usr/bin/env python3
"""
Clean ingredients batch 41 - Pushing Toward 550!
"""

import sqlite3
from datetime import datetime

def update_batch41(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 41 (Toward 550!)\n")

    clean_data = [
        {
            'id': 'D03ECZJdoY01e2CB8W1Y',
            'name': 'Penne',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Durum Wheat Semolina (100%). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'pzuHy1DArxmqL3MWKASc',
            'name': 'Superstix Choco Filling',
            'brand': 'Superstix',
            'serving_size_g': 32.0,
            'ingredients': 'Sugar, Wheat (Gluten) Flour, Vegetable Oil and Fat (Palm and Coconut Oil), Cocoa Powder (4.5%), Milk Powder, Cassava Starch, Egg Powder, Salt, Artificial Chocolate Flavour, Vanillin, Emulsifier (Lecithin (Soya)), Colour (Caramel IV-Ammonia Sulphite Process, Allura Red). Contains Cereals Containing Gluten, Eggs, Milk, Soybeans, Wheat.'
        },
        {
            'id': '7KdFtR4Ib1nWBHYoi64V',
            'name': 'Mozzarella And Cheddar Cheese',
            'brand': 'Morrisons',
            'serving_size_g': 30.0,
            'ingredients': 'Mozzarella Cheese (Milk) (49%), White Cheddar Cheese (Milk) (49%), Potato Starch. Contains Milk.'
        },
        {
            'id': 'pecKQm54GbjknJuUEx4j',
            'name': 'Salter Popped Snacks',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Rice Flour, Potato Flake, Chickpea Flour, Cornflour, Sunflower Oil, Dehydrated Sweet Potato, Tapioca Starch, Cornmeal, Maltodextrin, Cane Sugar, Sea Salt, Spinach Powder, Beetroot Powder, Salt, Colour (Paprika Extract). May Contain Milk.'
        },
        {
            'id': 'CXVB4N1rdlIVePFUFJmJ',
            'name': 'Shortcrust Chicken Pie',
            'brand': 'Birds Eye',
            'serving_size_g': 155.0,
            'ingredients': 'Wheat Flour, Water, Chicken Breast (20%), Pork Lard, Carrots, Peas, Modified Maize Starch, Chicken Stock (Water, Chicken, Salt), Brown Sugar, Salt, Glucose Syrup, Yeast Extract, Celery Salt (Salt, Celery Extract, Celery Seed Oil), Chicory Fibre, Calcium Carbonate, Fat Reduced Cocoa Powder, Barley Malt Extract, Onion Powder, Black Pepper, Sage, Niacin, Iron, Thiamin. Contains Barley, Celery, Cereals Containing Gluten, Pork, Wheat.'
        },
        {
            'id': 'NH9VdDhP2m4ct5FFjwL5',
            'name': 'Ready To Serve Custard',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted Skimmed Milk, Reconstituted Buttermilk, Water, Sugar, Modified Maize Starch, Vegetable Oils (Palm, Coconut), Milk Protein, Flavouring, Colours (Carotenes, Paprika Extract). Contains Milk.'
        },
        {
            'id': 'MruozxOxLQoYVLDkekMz',
            'name': 'Plant Based Harissa, Chickpea & Grain Salad',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Bulgur Wheat (24%), Mixed Leaves in Varying Proportions (Green Multileaf Lettuce, Red Multileaf Lettuce), Chickpeas (15%), Carrots, Rapeseed Oil, Water, Red Peppers (4%), Harissa Paste (4%) (Red Pepper Purée, Sunflower Oil, Sugar, Onion Purée, Concentrated Lemon Juice, Salt, Coriander Powder, Paprika Powder, Chilli Powder, Cumin Powder, Garlic Powder, Caraway, Black Pepper Powder, Colour (Paprika Extract)), Diced Dried Apricots (3%) (Apricots, Rice Flour, Preservative (Sulphur Dioxide)). Contains Cereals Containing Gluten, Sulphites, Wheat.'
        },
        {
            'id': '2zMMgzynPiUx1BABuFKm',
            'name': 'Fruit & Fibre',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flakes (75%) (Wheat, Sugar, Barley Malt Extract, Salt, Iron, Vitamin E, Niacin, Pantothenic Acid, Vitamin B12, Vitamin D, Thiamin, Folic Acid, Riboflavin, Vitamin B6), Raisins (17%), Toasted Coconut Chips, Sweetened Dried Banana Chips (3%) (Bananas, Coconut Oil, Sugar, Flavouring), Dried Apple, Hazelnuts. Contains Barley, Cereals Containing Gluten, Nuts, Wheat. May Contain Almonds, Brazil Nuts, Cashews, Macadamia Nuts, Pecan Nuts, Pistachio Nuts, Walnuts, Milk.'
        },
        {
            'id': '2yum9FqYhxUrRVTSb5JB',
            'name': 'Cumberland Sausages',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (85%), Water, Rice Flour, Chickpea Flour, Salt, Cracked Black Pepper, Dextrose (contains Sulphites), White Pepper, Black Pepper, Herbs, Cornflour (contains Sulphites), Nutmeg, Preservative (Sodium Metabisulphite), Mace, Onion Powder, Stabiliser (Diphosphates), Antioxidant (Sodium Ascorbate), Sausage Casing (Calcium Alginate). Contains Pork, Sulphites.'
        },
        {
            'id': 'dU0rrYuCazJCCltuax1I',
            'name': 'Halloumi',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Pasteurised Cow\'s Milk, Goat\'s Milk, Ewe\'s Milk, Dried Mint. Contains Milk.'
        },
        {
            'id': 'EOvEXvglYwhY7cdGlCNS',
            'name': 'Wholemeal',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 50.0,
            'ingredients': 'Wholemeal British Wheat Flour, Water, Yeast, Salt, Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Palm Stearin, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'fa2mAduKyZtFLrXrFn85',
            'name': 'Proviact Bifido Culture',
            'brand': 'Milbona Lidl',
            'serving_size_g': 115.0,
            'ingredients': '80% Fat Free Yogurt (Milk), Water, Diced Peaches (8%), Modified Maize Starch, Flavourings, Acidity Regulator (Citric Acid), Sweeteners (Acesulfame K, Sucralose), Bifidobacterium, Colour (Paprika Extract), Antioxidants (Ascorbic Acid, Citric Acid). Contains Milk.'
        },
        {
            'id': '8jFitMT1gOPzx9Btp872',
            'name': 'Oatcakes',
            'brand': 'M&S',
            'serving_size_g': 12.5,
            'ingredients': 'Oatmeal (76%), Wheatflour (with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Palm Oil, Sugar, Sea Salt, Raising Agent (Sodium Bicarbonate), Dried Skimmed Milk. Contains Cereals Containing Gluten, Milk, Oats, Wheat. May Contain Nuts, Peanuts.'
        },
        {
            'id': 'KCMGfY9MPqelHoScVnC8',
            'name': 'Lactose Free Organic Semi-skimmed Milk',
            'brand': 'Arla',
            'serving_size_g': 200.0,
            'ingredients': 'Semi Skimmed Milk, Lactase Enzyme. Contains Milk.'
        },
        {
            'id': '6YCgMpFsTZaNYBnjrLpf',
            'name': 'Double Chocolate Muffins GF',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Dark Chocolate Chips (17%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Rice Flour, Rapeseed Oil, Water, Pasteurised Egg, Humectant (Glycerol), Cocoa Powder, Modified Maize Starch, Rice Starch, Potato Starch, Raising Agents (Disodium Diphosphate, Sodium Carbonates), Stabiliser (Sodium Stearoyl-2-Lactylate), Preservative (Potassium Sorbate), Salt, Stabiliser (Xanthan Gum), Natural Vanilla Flavouring. Contains Eggs, Soybeans.'
        },
        {
            'id': 'MeVgCYnNFhRtDdJub67Z',
            'name': 'Roasted Salted Cashews',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Cashews (97%), Rapeseed Oil, Salt. Contains Nuts. May Contain Other Nuts, Peanuts.'
        },
        {
            'id': 'InjKzTfuzXnjKLdplV2j',
            'name': 'Huel Ready-to-drink - Salted Caramel',
            'brand': 'Huel',
            'serving_size_g': 500.0,
            'ingredients': 'Water, Pea Protein, Tapioca Starch, Rapeseed Oil, Gluten-Free Oat Flour, Ground Flaxseed, Medium-Chain Triglyceride Powder from Coconut, Soluble Vegetable Fiber (Chicory, Corn), Natural Flavorings, Micronutrient Blend (Minerals (Potassium as Potassium Citrate, Potassium Chloride, Chloride, Calcium as Calcium Carbonate, Magnesium as Magnesium Citrate, Phosphorus as Magnesium Phosphate, Copper as Copper Gluconate, Zinc as Zinc Oxide, Iodine as Potassium Iodide, Chromium as Chromium Picolinate), Vitamins). Contains Oats.'
        },
        {
            'id': 'D3Kpj0YTl7Tni51dLfsD',
            'name': 'Mozzarella With Pesto',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mozzarella Full Fat Soft Cheese (Milk), Sunflower Oil, Basil, Water, Medium Fat Hard Cheese (Milk), Concentrated Lemon Juice, Garlic Purée, Salt, Acidity Regulator (Citric Acid), Antioxidant (Ascorbic Acid). Contains Milk.'
        },
        {
            'id': 'YFqzrSjm8E6TN5C0UVlc',
            'name': 'Jerk Chicken',
            'brand': 'Island Rice',
            'serving_size_g': 400.0,
            'ingredients': 'Basmati Rice (36%), Smoked Chicken (23%), Water, Carrots, Wheat Flour (Wheat Flour, Calcium, Iron, Niacin, Thiamin), Dried Onions, Red Kidney Beans, Tomatoes, Jerk Paste (Scallions, Hot Peppers, Salt, Black Pepper, Pimento, Nutmeg, Citric Acid, Sugar, Thyme), Seasoning Mix (Salt, Sugar, Spices (contains Mustard, Celery), Flavour Enhancer (Monosodium Glutamate), Colour (Paprika Extract, Ammonia Caramel)), Rapeseed Oil, Coconut Milk, Garlic Purée, Ginger Powder. Contains Celery, Cereals Containing Gluten, Mustard, Wheat.'
        },
        {
            'id': 'iolsSntlxg8C3mr9nrFJ',
            'name': 'Mint Humbugs',
            'brand': 'Tesco',
            'serving_size_g': 50.0,
            'ingredients': 'Glucose Syrup, Sugar, Palm Oil, Condensed Skimmed Milk, Invert Sugar Syrup, Colour (Plain Caramel), Butteroil (Milk), Salt, Flavourings, Emulsifier (Lecithins). Contains Milk.'
        },
        {
            'id': '9Y09HpZLIbEyiF2safgR',
            'name': 'Pasta In Sauce Cheese And Broccoli',
            'brand': 'Tesco',
            'serving_size_g': 440.0,
            'ingredients': 'Dried Pasta (77%) (Durum Wheat Semolina), Cheese Powder (Milk) (5%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Whey Powder (Milk), Dried Broccoli (1.5%), Dried Skimmed Milk, Dried Glucose Syrup, Flavourings (contain Barley, Celery), Maize Starch, Palm Oil, Onion Powder, Salt, Milk Proteins, Stabilisers (Dipotassium Phosphate, Trisodium Citrate), Dried Garlic, Yeast Extract. Contains Barley, Celery, Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'tNCM7LejvNUIu3ZpuScS',
            'name': 'Impact Whey Isolate',
            'brand': 'Myprotein',
            'serving_size_g': 30.0,
            'ingredients': 'Whey Protein Concentrate (Milk), Sunflower Lecithin. Contains Milk. May Contain Eggs, Soybeans, Cereals Containing Gluten, Fish, Crustaceans, Molluscs, Mustard, Sesame, Sulphur Dioxide, Sulphites.'
        },
        {
            'id': '4sP72gFQSzH82ZV4glBy',
            'name': 'Apple And Sultana Dino Fruit Bars',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Dried Dates, Dried Apple (33%), Sultanas (16%). May Contain Nuts, Soybeans.'
        },
        {
            'id': 'uPMqzljTKmzFhsFQVoWD',
            'name': 'Caramel Latte',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Skimmed Milk Powder (20%), Glucose Syrup, Coconut Fat, Coffee Extract (6%), Flavouring, Whey Permeate (Milk), Acidity Regulator (Potassium Carbonates), Stabilisers (Potassium Phosphates, Sodium Phosphates), Maltodextrin, Emulsifier (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids). Contains Milk.'
        },
        {
            'id': '75azt2i66WsAEyWJxMxE',
            'name': 'Spaghetti Loops',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (49%), Cooked Spaghetti Pasta Loops (43%) (Water, Durum Wheat Semolina), Sugar, Water, Modified Maize Starch, Onion Powder, Salt, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Acidity Regulator (Citric Acid), Paprika, Rapeseed Oil, Paprika Extract, Yeast Extract, Flavourings. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'dZ2Vz7v4ueX4xsM7lZm3',
            'name': 'Zesty Lime Flavour Corn',
            'brand': 'Doritos',
            'serving_size_g': 30.0,
            'ingredients': 'Corn (Maize), Rapeseed Oil, Zesty Lime Seasoning (Salt, Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium Guanylate, Disodium Inosinate), Acids (Citric Acid, Sodium Acetates), Flavourings, Potassium Chloride, Antioxidants (Rosemary Extract, Ascorbic Acid, Tocopherol Rich Extract, Citric Acid)). May Contain Milk, Soybeans, Wheat, Cereals Containing Gluten.'
        },
        {
            'id': '3ezyGxh2Mo5uA7ocNoxt',
            'name': 'Greek Feta And Red Pepper Rolls',
            'brand': 'Higgidy',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (contains Calcium Carbonate, Iron, Niacin, Thiamin), Water, Butter (Milk), Chickpeas, Red Peppers (8%), Feta Cheese (Milk) (8%), Free-Range Whole Egg, Mature Cheddar Cheese (Milk), Ricotta Cheese (Milk), SunBlush Pepper Tapenade, Free-Range Egg Yolk, Salt, Emmental Cheese (Milk), Butternut Squash Purée, Parsley, Garlic Purée, SunBlush Tomatade, Black Pepper, Cayenne Pepper, Yeast. Contains Cereals Containing Gluten, Eggs, Milk, Wheat.'
        },
        {
            'id': 'IUP69QQ0uCYG619SSivF',
            'name': 'Rich Hoisin Sauce',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Water, Soybean Paste (22%) (Water, Ground Fermented Soybeans (6%), Salt, Wheat Flour), Glucose-Fructose Syrup, Salt, Ground Sesame Seeds, Modified Maize Starch, Acid (Acetic Acid), Colour (Plain Caramel), Spices. Contains Cereals Containing Gluten, Sesame, Soybeans, Wheat. May Contain Peanuts, Nuts.'
        },
        {
            'id': 'kh72RPIUfoB3VHvaybRH',
            'name': 'Bourbon Creams',
            'brand': 'Tesco',
            'serving_size_g': 14.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Palm Oil, Fat Reduced Cocoa Powder, Glucose Syrup, Dextrose, Wheat Starch, Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Flavouring. Contains Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'pamV42IREvD9523nieQa',
            'name': 'Free From Rice Squares',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Salted Caramel (30%) (Invert Sugar Syrup, Sugar, Palm Oil, Rapeseed Oil, Soya Flour, Fructose, Water, Salt, Flavourings, Emulsifiers (Soya Lecithins, Mono- and Diglycerides of Fatty Acids), Colour (Carotenes)), Belgian Dark Chocolate (18%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithins), Flavouring), Sugar, Crisped Rice (12%) (Rice Flour, Sugar, Rice Extract), Invert Sugar Syrup, Palm Oil, Rapeseed Oil, Soya Flour, White Chocolate Flavour Swirls (2%) (Sugar, Rice Flour, Shea Oil, Cocoa Butter, Flavouring). Contains Soybeans.'
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

    total_cleaned = 506 + updates_made

    print(f"✨ BATCH 41 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 550:
        print(f"\n🎉🎉🎉 550 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {600 - total_cleaned} products until 600!\n")
    else:
        remaining_to_550 = 550 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_550} products until 550!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch41(db_path)
