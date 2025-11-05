#!/usr/bin/env python3
"""
Clean ingredients batch 37 - Pushing Toward 450!
"""

import sqlite3
from datetime import datetime

def update_batch37(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 37 (Toward 450!)\n")

    clean_data = [
        {
            'id': 'AyvVGiESzvctcouyZ1PV',
            'name': 'Metro Rolls Italian Style',
            'brand': 'Village Bakery',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Semolina (Wheat), Sugar, Fermented Wheat Flour, Rapeseed Oil, Salt, Yeast, Palm Oil, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Wheat. May Contain Barley, Eggs, Milk, Oats, Soybeans, Spelt, Rye.'
        },
        {
            'id': 'jVjUyP7oK0bIlJgN0PWC',
            'name': 'Roasted Mushroom Pâté',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Mushroom (25%), Full Fat Soft Cheese (Cows\' Milk) (17%), Crème Fraîche (Cows\' Milk), Water, Single Cream (Cows\' Milk), Onion, Rapeseed Oil, Tapioca Starch, Lemon Juice, Garlic Purée, Pasteurised Free Range Egg, Salt, Spirit Vinegar, Yeast Extract, Mushroom Concentrate, Thyme, Parsley, Rosemary, Black Pepper, Porcini Mushroom, White Pepper, Potato Flake, Sugar, Nutmeg, Acidity Regulator (Acetic Acid), Lemon Juice Powder, Rapeseed Oil. Contains Eggs, Milk.'
        },
        {
            'id': 'rR62thbw8MFRYA7L4APM',
            'name': 'Roasted Salted Pistachios',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Roasted Pistachios in Shell, Salt. Contains Nuts. May Contain Peanuts, Other Nuts, Sesame, Cereals Containing Gluten, Milk, Mustard, Soybeans.'
        },
        {
            'id': '0IzAwM3QF7OLBNWTzwx5',
            'name': 'Pan Poppin Pasanda & Nutty Pilau Rice',
            'brand': 'Pinch',
            'serving_size_g': 400.0,
            'ingredients': 'Cooked Basmati Rice (Water, Basmati Rice, Sweetened Dried Cranberries (Sugar, Cranberries, Sunflower Oil), Ginger Purée, Rapeseed Oil, Cumin Seeds, Salt, Cardamom Powder, Colour (Curcumin)), Cooked Marinated Chicken (20%) (Chicken, Tomato Purée, Ginger Purée, Garlic Purée, Cornflour, Salt, Soya Oil, Yogurt Powder (Milk), Green Chilli Purée, Water, Palm Oil, Chilli Powder, Yogurt (Milk), Skimmed Milk, Coriander Powder, Cumin Powder, Colour (Paprika Extract), Ginger Powder, Cinnamon, Black Pepper). Contains Milk, Soybeans.'
        },
        {
            'id': '1scGiBkvf65CI83aeWCd',
            'name': 'Tesco Finest Madagascan 71% Dark Chocolate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Sugar, Cocoa Butter, Vanilla Extract. Dark Chocolate Contains Cocoa Solids 71% Minimum. May Contain Milk, Nuts.'
        },
        {
            'id': 'W9ub36esYFmzbCCpdVJB',
            'name': 'American Style Burger Sauce Imp',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sunflower Oil, Water, Spirit Vinegar, Concentrated Tomato Purée, Sugar, Glucose-Fructose Syrup, Egg Yolk, Salt, Modified Starch, Worcester Sauce (Barley Malt Vinegar, Molasses, Invert Sugar Syrup, Water, Onion, Salt, Tamarind Extract, Garlic, Spices, Lemon Oil), Mustard Powder, Thickeners (Xanthan Gum, Guar Gum), Flavourings, Colour (Riboflavin), Spice Extract. Contains Barley, Cereals Containing Gluten, Eggs, Mustard.'
        },
        {
            'id': 'eVEpAKDeZDk9JNZcuVms',
            'name': 'Cashews & Jumbo Raisins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cashews (40%), Jumbo Raisins (60%). Contains Nuts. May Contain Cereals Containing Gluten, Peanuts, Other Nuts, Soybeans, Milk, Sulphites.'
        },
        {
            'id': 'orKatXgTmjhA0QDgf3To',
            'name': 'Soft Wholemeal Rolls',
            'brand': 'Rowan Hill Bakery',
            'serving_size_g': 68.0,
            'ingredients': 'Wholemeal Wheat Flour, Water, Yeast, Sugar, Wheat Protein, Wheat Flour (Calcium Carbonate, Iron, Niacin, Thiamin), Fermented Wheat Flour, Vegetable Oils and Fats (Rapeseed Oil, Palm Fat), Salt, Malted Barley Flour, Emulsifiers (Mono- and Diacetyl Tartaric Acid Esters of Mono- and Diglycerides of Fatty Acids, Mono- and Diglycerides of Fatty Acids), Soya Flour, Spirit Vinegar, Flour Treatment Agent (Ascorbic Acid). Contains Barley, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'wN4L63fNexolKDl9jDkG',
            'name': 'Nut Granola',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes (47%), Mixed Nuts (22%) (Brazil Nuts, Almonds, Hazelnuts, Pecan Nuts, Cashew Nuts, Pistachio Nuts, Macadamia Nuts), Sugar, Rapeseed Oil, Coconut, Desiccated Coconut, Acacia Honey (1.5%), Black Treacle, Pumpkin Seeds, Sunflower Seeds, Golden Linseed. Contains Cereals Containing Gluten, Oats, Nuts. May Contain Other Nuts, Milk, Wheat.'
        },
        {
            'id': 'oAUx6uEa7dlRRyUN8pGw',
            'name': 'Smoky BBQ Pork Stir Fry Strips',
            'brand': 'Ashfields',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (89%), Water, Sugar, Tomato Powder, Smoked Paprika, Dextrose, Yeast Extract, Modified Waxy Maize Starch, Onion Powder, Garlic Powder, Acidity Regulator (Citric Acid), Smoked Salt, Ground Allspice, Salt, Caramelised Sugar Powder, Spirit Vinegar Powder, Ground Bay Leaf, Thickener (Guar Gum), Allspice Extract. Contains Pork.'
        },
        {
            'id': 'DKuigvozIOmN6Ul6NRt4',
            'name': 'Popadoms',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Lentil Flour, High Oleic Sunflower Oil, Sea Salt, Raising Agent (Calcium Oxide).'
        },
        {
            'id': 'ahkJVoRgdWx6tDxg9oFQ',
            'name': 'Shawarma Seasoning',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Salt, Smoked Paprika (12%), Cumin (11%), Rice Flour, Dried Garlic, Turmeric (6%), Dried Onion, Lemon Peel, Fenugreek Seeds, Black Pepper, Coriander Seeds, Cinnamon Powder, Dried Red Pepper, Dried Coriander Leaf, Anti-Caking Agent (Silicon Dioxide), Sumac.'
        },
        {
            'id': '8G3IITlnQvROPCE6rPuK',
            'name': 'Low Cal Raspberry Flavour Jelly Pot',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Gelling Agents (Carrageenan, Carob Bean Gum), Acidity Regulators (Sodium Citrates, Calcium Lactate, Potassium Citrate, Citric Acid), Flavouring, Colours (Anthocyanins, Carotenes), Sweeteners (Sucralose, Acesulfame K).'
        },
        {
            'id': 'Ikkfxcc1mSXZyHMFBemH',
            'name': 'Strawberry Yoghurt',
            'brand': 'Brooklea',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (60%) (Milk), Cream (20%) (Milk), Sugar, Strawberries (6%), Water, Modified Maize Starch, Stabiliser (Pectins), Colour (Beetroot Juice from Concentrate), Flavouring, Acidity Regulators (Citric Acid, Sodium Citrates). Contains Milk.'
        },
        {
            'id': 'VoyuRuBWv0vAIj01d7hO',
            'name': 'Carrot Cake Soft Oaty Bar',
            'brand': 'Organix',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Oats (46%), Raisins (32%), Sunflower Oil (12%), Carrot Juice Concentrate (7%), Apple Juice Concentrate (2%), Cinnamon, Orange Oil. Contains Cereals Containing Gluten, Oats. May Contain Nuts, Soybeans, Milk.'
        },
        {
            'id': '3Yl2UiRKTgGKwjeADRnS',
            'name': 'Illegal Gianduja',
            'brand': 'Hotel Chocolat',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Solids (Cocoa Mass, Cocoa Butter), Hazelnut Paste (26%), Sugar, Full Cream Milk Powder, Butter Oil (from Milk), Emulsifier (Soya Lecithin), Flavouring. Milk Chocolate Contains Minimum 50% Cocoa Solids, Minimum 20% Milk Solids. Contains Milk, Nuts, Soybeans. May Contain Other Tree Nuts, Peanuts, Cereals Containing Gluten, Wheat, Eggs, Sesame.'
        },
        {
            'id': 'BEtghN6oZZ2iEg1UrqmM',
            'name': 'Rocky Road Bites',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 13.0,
            'ingredients': 'Milk Chocolate (44%) (Cocoa Mass, Sugar, Cocoa Butter, Skimmed Cows\' Milk Powder, Cows\' Milk Fat, Lactose (Cows\' Milk), Emulsifier (Soya Lecithin), Natural Vanilla Flavouring), Sultanas (23%), Marshmallow (9%) (Glucose-Fructose Syrup, Sugar, Water, Pork Gelatine, Corn Starch, Flavouring, Colour (Beetroot Red)), Palm Kernel Oil, Digestive Biscuit (4.5%) (Fortified British Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Wholemeal Wheat Flour, Sugar, Palm Oil, Rapeseed Oil, Partially Inverted Sugar Syrup, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Salt). Contains Cereals Containing Gluten, Milk, Pork, Soybeans, Wheat.'
        },
        {
            'id': '5iJoObvPKOcVrHuUlVUl',
            'name': 'Clear Vegan Protein Raspberry Mojito',
            'brand': 'Myvegan',
            'serving_size_g': 16.0,
            'ingredients': 'Hydrolysed Pea Protein (77%), Raspberry Juice Powder (10%), Vitamin B Blend (Niacin, Pantothenic Acid, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Biotin, Vitamin B12), Acid (Citric Acid), Sweetener (Sucralose), Product Flavourings, Colour (Beetroot Red), Anti-Foaming Agents (Dimethyl Polysiloxane, Silicon Dioxide). May Contain Milk.'
        },
        {
            'id': 'LC51BYWwFlB7QrQha0AO',
            'name': 'Morrisons Seeded Bloomer',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Mixed Seeds (11%) (Golden Linseed, Millet, Sunflower Seeds, Pumpkin Seeds, Poppy Seeds), Fermented Wheat Flour, Yeast, Salt, Soya Flour, Sugar, Caramelised Sugar, Flour Treatment Agent (Ascorbic Acid). Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'gtZEWHnENFL8ugX89HUG',
            'name': 'Baked Beans And Pork Sausages',
            'brand': 'Newgate',
            'serving_size_g': 100.0,
            'ingredients': 'Haricot Beans (38%), Tomatoes (29%), Pork Sausages (18%) (Pork (62%), Water, Pork Rind, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Salt, Sugar, Calcium Lactate, Raising Agent (Ammonium Carbonate), Ground Ginger, Ground White Pepper, Cardamom, Mustard Flour, Pepper Extract, Nutmeg Extract, Coriander Extract, Sage), Water, Sugar, Modified Maize Starch, Salt, Onion Oil. Contains Cereals Containing Gluten, Mustard, Pork, Wheat.'
        },
        {
            'id': 'KXdMsV9hISSm11dCpjco',
            'name': 'Prime Cut Beef',
            'brand': 'Tesco',
            'serving_size_g': 20.0,
            'ingredients': 'Beef, Mineral Sea Salt, Stabilisers (Potassium Triphosphate, Sodium Triphosphate). Prepared from 105g of British Beef per 100g of Roast Beef. Contains Beef.'
        },
        {
            'id': 'alux0BKuxxa0IQhDKuNs',
            'name': 'Burger Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Reconstituted Tomato Purée (20%), Rapeseed Oil, Gherkin (7%), Onion (6%), Sugar, White Wine Vinegar, Modified Maize Starch, Mustard Flour, Salt, Ground Paprika, Spirit Vinegar, Dried Egg Yolk, Acidity Regulator (Acetic Acid), Ground Turmeric, Stabiliser (Xanthan Gum), Dill, Garlic Powder, White Pepper, Flavouring, Colour (Paprika Extract). Contains Eggs, Mustard.'
        },
        {
            'id': 'qYgaiK78KmCgGUGFVYuV',
            'name': 'Fruit And Barley Tropical Squash',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Fruit Juices from Concentrate (10%) (Pineapple, Orange, Lemon, Passion Fruit, Apricot, Mango), Citric Acid, Acidity Regulator (Sodium Citrates), Preservatives (Potassium Sorbate, Sodium Metabisulphite), Sweeteners (Acesulfame K, Sucralose), Stabilisers (Acacia Gum, Xanthan Gum, Guar Gum), Barley Extract, Flavourings, Antioxidant (Ascorbic Acid), Coconut Oil, Colour (Carotenes). Contains Barley, Cereals Containing Gluten, Sulphites.'
        },
        {
            'id': 'FmxLpdFMp00sKyXEDpFD',
            'name': 'King Prawn Makhani',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Pilau Rice (Water, Basmati Rice, Onion, Rapeseed Oil, Salt, Cumin, Cardamom, Turmeric, Clove, Bay Leaf), Fat Cream (Cows\' Milk) (16%), Cooked Marinated King Prawns (14%) (King Prawn (Penaeus Vannamei) (Crustacean), Sunflower Oil, Cornflour, Skimmed Cows\' Milk Powder, Paprika, Chilli Powder, Garlic Powder, Ginger Powder, Rice Vinegar, Coriander, Cumin, Fenugreek, Salt, Cardamom, Black Pepper, Fennel, Cinnamon, Clove), Onion, Tomato Paste, Water, Garlic Purée, Butter (Cows\' Milk), Rapeseed Oil. Contains Crustaceans, Milk.'
        },
        {
            'id': 'D0bllF0vxSnJ1a5noIXn',
            'name': 'Gianduja Chocolate Bar',
            'brand': 'Gro',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Mass, Hazelnut Paste (20%), Cocoa Butter, Emulsifier (Lecithins (Soya)), Vanilla Extract. Cocoa Solids 31% Minimum. Contains Nuts, Soybeans. May Contain Milk, Other Nuts.'
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

    total_cleaned = 406 + updates_made

    print(f"✨ BATCH 37 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    if total_cleaned >= 450:
        print(f"\n🎉🎉🎉 450 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {500 - total_cleaned} products until 500!\n")
    else:
        remaining_to_450 = 450 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_450} products until 450!\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch37(db_path)
