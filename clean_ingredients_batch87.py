#!/usr/bin/env python3
"""
Clean ingredients for batch 87 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch87(db_path: str):
    """Update batch 87 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 87: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'EjoC0MRgjkYT6K67OxH2',
            'name': 'Plant Based Garlic & Herb Spread',
            'brand': 'Boursin',
            'serving_size_g': 100.0,
            'ingredients': 'Water, coconut oil (22%), potato starch, inulin, sunflower oil, garlic & herbs (1.7%), salt, potato protein, white pepper, preservative (potassium sorbate), thickener (xanthan gum), natural flavouring.'
        },
        {
            'id': 'EjozxMAEFfNlGD2YVhjc',
            'name': 'Cheese Tasters',
            'brand': 'M&S',
            'serving_size_g': 19.0,
            'ingredients': 'Corn Grits 53%, Sunflower Oil, Dried Whey (Milk), Dried Cheese (Milk) 3.7%, Lactose (Milk), Dried Yeast Extract, Salt, Dried Cream (Milk), Dried Skimmed Milk, Colour: Paprika Extract, Curcumin.'
        },
        {
            'id': 'EkFRY2W6qOIVn2AkWytC',
            'name': 'Mediterranean Style No Chicken Pieces',
            'brand': 'Plant Menu Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Texturised Soya Protein (Water, CONCENTRATED SOYA PROTEIN (40%)), Rapeseed Oil, Tomato Concentrate, Salt, Flavouring, Paprika, Maltodextrin, Marinade [Herbs (Parsley, Rosemary, Thyme, Chervil, Oregano, Marjoram, Bay Leaf, Tarragon, Basil), Spices (Paprika, Fennel, Turmeric, Black Pepper, Cloves, Mace, Nutmeg, White Pepper), Garlic, Onion, Sunflower Oil].'
        },
        {
            'id': 'EkO6MxEFzeCAgm0TmKyL',
            'name': 'Black\'s Dark Almond Chocolate Bar',
            'brand': 'Green & Black\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa mass, sugar, cocoa butter, almonds, vanilla bean powder.'
        },
        {
            'id': 'Ekopc3uzX4F3gcTvsma0',
            'name': 'Chargrilled Peppers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'GRILLED RED AND YELLOW PEPPER (62%), Sunflower Oil, White Wine Vinegar, Sugar, Sea Salt, Garlic, Acidity Regulator (Citric Acid), Antioxidant: Ascorbic Acid.'
        },
        {
            'id': 'EkpdCbid6Jc7ChPmwH79',
            'name': 'Toddler Milk',
            'brand': 'Cowgate',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed milk, Lactose from milk, Vegetable oils (Palm oil, Sunflower oil, Rapeseed oil), Whey product (Demineralised whey, Whey protein concentrate) from milk, Maltodextrin, Galacto-oligosaccharides (GOS) from milk, Potassium hydrogen phosphate, Calcium phosphate, Fructo-oligosaccharides (FOS), Calcium carbonate, Magnesium citrate, Vitamin C, Potassium citrate, Sodium chloride, Emulsifier (Soy lecithin), Potassium chloride, Iron sulphate, Zinc sulphate, Vitamin D3, Vitamin E, Pantothenic acid, Vitamin B12, Folic acid, Niacin, Vitamin A, Riboflavin, Biotin, Vitamin B6, Thiamin, Potassium iodide, Vitamin K₁.'
        },
        {
            'id': 'En4sXhdrYZ1AC7zAUInY',
            'name': 'All Butter Sweethearts',
            'brand': 'Chloe\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Sugar (25%), Butter (Milk) (22%), Salt, Barley Malt Flour.'
        },
        {
            'id': 'EnLoi18S6s2bsfGsiVwD',
            'name': 'Chicken Flavour Instant Noodles',
            'brand': 'Maggi',
            'serving_size_g': 180.0,
            'ingredients': 'Durum wheat semolina.'
        },
        {
            'id': 'EnPrdv8hcQoAe2GHLgbz',
            'name': 'Double Chocolate Oat Muffin',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flour 40%, fat reduced chocolate flavour muffin mix with oats & cocoa powder 12.5%, dried egg white, maltodextrin, water, oats 6%, skimmed milk powder, chocolate pieces, raising agents (monocalcium phosphate, sodium bicarbonate), stabiliser (xanthan gum), natural flavouring, sweetener (sucralose).'
        },
        {
            'id': 'EnldRVepHGn3fFXn7oXz',
            'name': 'Le Petit Biscotte Crunchy Cinnamon And Brown Sugar Biscuits',
            'brand': 'Lu',
            'serving_size_g': 23.6,
            'ingredients': 'Wheat flour 45%, sugar, palm oil, brown sugar 9.5%, fructose syrup, liquid whole egg, brown sugar syrup, raising agent (sodium carbonates), colour (caramel E150a), glucose syrup, cinnamon 0.2%, salt, flavouring.'
        },
        {
            'id': 'EnqVRjHm0IWWX9mnzdXY',
            'name': 'Dirty Fries',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potato tubes (dried potato, potato starch, salt, sugar), Lactose (milk), sugar, salt, smoked paprika, yeast extract powder, onion powder, tomato powder, garlic powder, flavourings, acidity regulator (citric acid), chilli powder, cumin, black pepper, parsley, paprika extract.'
        },
        {
            'id': 'EoYl7VTwkK1IeUjfJJnW',
            'name': 'Snax Sour Cream And Onion',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Flakes, High Oleic Sunflower Oil, Wheat Starch, Glucose Syrup, Sour Cream and Onion Flavour Seasoning (Salt, Dextrose, Sour Cream Powder (Milk), Lactose (Milk), Onion Powder, Whey Powder (Milk), Sugar, Flavouring, Citric Acid, Malic Acid, Cayenne Pepper Extract, Onion Extract), Potato Starch, Emulsifier (Mono - and Diglycerides of Fatty Acids), Rapeseed Oil, Salt.'
        },
        {
            'id': 'EohFPRPRzwgy5PLofpnf',
            'name': 'Jammy Wheels',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flour, jam filling (20%) (fructose, dextrose, glucose syrup, humectant (glycerol), raspberry concentrate, water, palm oil, acid (citric acid), antioxidant (sodium citrate), acidity regulator (trisodium citrate), gelling agent (pectin), colour (anthocyanins), stabiliser (sodium polyphosphate), flavouring, emulsifier (sorbitan monostearate)), sugar, palm fat, potato starch, soya flour, rapeseed oil, tapioca flour, golden syrup, flavouring, stabiliser (xanthan gum), raising agent (sodium hydrogen carbonate), salt, emulsifier (mono - and diglycerides of fatty acids-vegetable).'
        },
        {
            'id': 'EourbIIajO1EYkrcD7Md',
            'name': 'Smooth Peanut Butter',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (90%), peanut oil, palm oil, cane sugar, sea salt.'
        },
        {
            'id': 'EpZVptkZAuBqrLr5uV5T',
            'name': 'Cajun Seasoning',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Salt, maltodextrin, chili, 8% paprika, black pepper, fennel, cardamom, spice extracts.'
        },
        {
            'id': 'EqoQDAzQ1HqFRTOfETSN',
            'name': 'Gnocchi',
            'brand': 'Ciemme',
            'serving_size_g': 100.0,
            'ingredients': 'Mashed potatoes 70% (water, dehydrated potato flake 16% (potatoes 99.9%, natural extract of rosemary), corn flour, potato starch, corn starch, rice flour, salt, acidity regulator: lactic acid, turmeric).'
        },
        {
            'id': 'Ers4x8rdJ1XRMrWkvvuQ',
            'name': 'Sriracha Hot Chilli Sauce',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, chilli (13%), garlic (9%), vinegar, salt, modified tapioca starch, preservative (potassium sorbate).'
        },
        {
            'id': 'EmWyX3XcnRhHp8kemdSO',
            'name': 'Fat Free Greek Inspired Strained Natural Yogurt',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fat Free Natural Greek Yogurt, Milk.'
        },
        {
            'id': 'EmYegrmVk0PK2pMqtLBe',
            'name': 'Duck Spring Roll',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British Duck (19%), Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Carrot, Onion, Hoisin Sauce (Water, Demerara Sugar, Soya Bean, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rice Wine Vinegar, Salt, Cornflour, Garlic Purée, Anise, Cinnamon Powder, Fennel Powder, Clove Powder, Black Pepper, Sugar), Rice Flour, Water, Water Chestnut, Spring Onion (4.5%), Ginger Purée, Sugar, Soy Sauce (Water, Soya Bean, Salt, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin)), Sesame Oil, Rice Vermicelli (Rice, Water), Garlic Purée, Potato Starch, Salt, Yeast Extract, Aniseed, Cinnamon Powder, Fennel Powder, Stabiliser: Hydroxypropyl Methyl Cellulose, Soya Bean, Wheat, Black Pepper, Star Anise, Clove Powder, Ginger Powder.'
        },
        {
            'id': 'Es1gJmvL0YRKAJIw2wkZ',
            'name': 'Doritos Pepperoni Pizza',
            'brand': 'Doritos',
            'serving_size_g': 75.0,
            'ingredients': 'Corn (71%) (maize), sunflower oil, pepperoni pizza seasoning (flavouring (contains milk), sugar, buttermilk powder, smoked paprika powder, acidity regulators (citric acid, malic acid), flavour enhancers (monosodium glutamate, disodium 5\'-ribonucleotide), salt, potassium chloride, garlic powder, onion powder, tomato powder, spices (black pepper, white pepper, anise powder, clove powder), colours (paprika extract, annatto bixin, plain caramel), dried herbs, smoke flavouring), rapeseed oil.'
        },
        {
            'id': 'EsJ3285HTrbI3UJ21OY7',
            'name': 'Peanut Butter Dark Chocolate',
            'brand': 'Kind',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts, dark chocolate (sugar, cocoa mass, cocoa butter, fat-reduced cocoa powder, emulsifier: soya lecithin, vanilla extract), glucose syrup, honey, almonds, protein crisps (soya protein isolate, tapioca starch, salt), peanut butter, cocoa mass, fructo-oligosaccharide, emulsifier: soya lecithin.'
        },
        {
            'id': 'EsJQcHrkCBGdBydKVKib',
            'name': 'Love Corn',
            'brand': 'Love Corn',
            'serving_size_g': 20.0,
            'ingredients': 'Corn, sea salt, sunflower oil.'
        },
        {
            'id': 'EsNaOZsHP8wzsBhAHQ1w',
            'name': 'Claws Apple, Pear & Pumpkin Snack',
            'brand': 'Bear',
            'serving_size_g': 100.0,
            'ingredients': 'Apples, pears, pumpkin, spirulina.'
        },
        {
            'id': 'EsqH1D1FKg4cBuduAN2E',
            'name': 'Dairy Milk 30% Less Sugar Chocolate Bar',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, sugar, soluble maize fibre, cocoa butter, cocoa mass, vegetable fats (palm, shea), milk fat, skimmed milk powder, emulsifier (E442), flavourings.'
        },
        {
            'id': 'Et8WoZHG1rDBWCxoRHUR',
            'name': 'Salt And Pepper Parmentier Potatoes',
            'brand': 'Four Seasons',
            'serving_size_g': 100.0,
            'ingredients': 'Fried potatoes (96%) (potato, sunflower oil), butter (milk), salt, cracked black pepper.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 87\n")

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'], current_timestamp, product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g\n")
            updated_count += 1

    conn.commit()
    conn.close()

    return updated_count

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    updated = update_batch87(db_path)

    print(f"✨ BATCH 87 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1561 + updated} products cleaned")

    # Check if we hit the 1575 milestone
    total = 1561 + updated
    if total >= 1575:
        print("\n🎉🎉 1575 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
