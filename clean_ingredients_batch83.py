#!/usr/bin/env python3
"""
Clean ingredients for batch 83 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch83(db_path: str):
    """Update batch 83 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 83: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'D5XIlDValjdnJfBcBIwt',
            'name': 'Worcester Sauce French Fries',
            'brand': 'Walkers',
            'serving_size_g': 18.0,
            'ingredients': 'Potato Granules, Potato Starch, Sunflower Oil, Worcester Sauce Flavour (Flavourings, Salt, Sugar, Acid (Citric Acid), Fructose, Dried Onion, Dried Garlic, Spices, Cocoa Powder, Yeast Extract, Colour (Paprika Extract, Annatto Norbixin), Flavour Enhancer (Monosodium Glutamate)).'
        },
        {
            'id': 'D5d3Es7Ev3epM3dnFnNn',
            'name': 'Organic Mixed Beans',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Organic Cannellini Beans, Organic Pinto Beans, Organic Red Kidney Beans.'
        },
        {
            'id': 'D69ULcCjcnPYd5Qnotqi',
            'name': 'Cheese & Chive Dip',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Mayonnaise (Water, Rapeseed Oil, Pasteurised Egg, Cornflour, Spirit Vinegar, Sugar, Rice Starch, Salt, Citrus Fibre, Dried Egg White, Potato Fibre), Soured Cream (Cows\' Milk), Mature Red Cheddar Cheese (6%) (Cows\' Milk) (Colour: Annatto Norbixin), Mature Cheddar Cheese (5%) (Cows\' Milk), Rapeseed Oil, Onion, Chives (1%), Cornflour, Concentrated Lemon Juice, Potato Starch.'
        },
        {
            'id': 'D6QkWrEnQfQoVa1SS1u2',
            'name': 'Flamingo Shortbread',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), sugar, palm oil, water, rapeseed oil, glucose syrup, colours (calcium carbonate, carotenes, carbon black, beetroot red), salt, emulsifier (e471), flavouring.'
        },
        {
            'id': 'D6vXKqlEyhfYshBX57FF',
            'name': 'Dijon Mustard',
            'brand': 'Tesco',
            'serving_size_g': 5.0,
            'ingredients': 'Water, Mustard Seed (30%), Spirit Vinegar, Salt, Preservative (Sodium Metabisulphite).'
        },
        {
            'id': 'D7Pi0xsFBfVfBMqwN06P',
            'name': 'Pigs In Blanket Combo Mix',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Dried Potato, Rapeseed Oil, Rice Flour, Maize Starch, Modified Potato Starch, Salt, Sugar, Spices (White Pepper, Black Pepper, Coriander, Nutmeg), Flavouring (Yeast Powder, Onion Powder, Caramelised Sugar Powder, Garlic Powder, Yeast Extract), Colour (Paprika Extract), Paprika Extract, Turmeric Extract.'
        },
        {
            'id': 'D7cPal1rw9dD59oCBUk6',
            'name': 'Raspberry Ripple Ice Cream',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted skimmed milk concentrate, glucose syrup, raspberry sauce (7%) [sugar, water, glucose syrup, raspberry purée, cornflour, acidity regulators (citric acid, sodium citrates), colour (anthocyanins), gelling agent (pectins), flavouring], water, coconut oil, sugar, whey powder (milk), emulsifier (mono - and diglycerides of fatty acids), flavourings, stabilisers (carob bean gum, guar gum), colours (beetroot red, carotenes).'
        },
        {
            'id': 'D7ove70mbq04MXcTwpca',
            'name': 'Artisanal Belgian Chocolates',
            'brand': 'Guylian',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, whole milk powder, hazelnuts, cocoa mass, emulsifier (soy lecithin), natural vanilla flavouring.'
        },
        {
            'id': 'D7rCLMqkoABKLv4JVSZE',
            'name': 'Spanish Omelette',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes 56%, pasteurised free range egg 28%, fried onion 12% (onion, olive oil, salt).'
        },
        {
            'id': 'D8b80U31ob3FUJKFkKid',
            'name': 'Duchy Organic Raspberry Preserve Extra Jam',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Raspberries, sugar, concentrated lemon juice, gelling agent (pectin).'
        },
        {
            'id': 'D8kySjuUKAJqUKSl30rr',
            'name': 'Mini Loaves',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Candied Diced Ginger (7%)(Ginger, Sugar, Glucose Fructose Syrup), Sugar, Maize Starch, Pear Juice Concentrate, Barley Malt Extract, Malted Barley Flour, Vegetable Fats (Rapeseed, Palm), Salt, Natural Flavourings, Preservative: Calcium Propionate, Yeast.'
        },
        {
            'id': 'D98KXKlT6RShOLK37I4v',
            'name': 'Hash Brown',
            'brand': 'Company Shop',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, non-hydrogenated vegetable oils (sunflower, rapeseed), salt, maize flour, dehydrated potato, dextrose, stabiliser (diphosphates), black pepper extract.'
        },
        {
            'id': 'D9qnJ3hT9rtodtusXe5S',
            'name': 'Mighty Meaty Balls',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Seitan (Water, Gluten, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Onion, Salt), Mushrooms (10%), Parsnip, Pea Flour, Vegetable Suet (Palm Oil, Rice Flour), Onion, Stabiliser (Methyl Cellulose), Rice Flour, Flavouring, Pea Fibre, Maize Flour, Pea Starch, Parsley, Salt, Yeast Extract, Porcini Mushroom Powder, Thyme, Black Pepper, Colour (Caramel), Maize Starch, Preservative (Sodium Metabisulphite), Mace, Dextrose.'
        },
        {
            'id': 'D9qrAPFQhS6wYwmlf5r8',
            'name': 'Portidge Oats',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes.'
        },
        {
            'id': 'D9tgj4d17w2X7WfzODPa',
            'name': 'Sour',
            'brand': 'Chupa Chups',
            'serving_size_g': 2.6,
            'ingredients': 'Sugar, glucose syrup, wheat flour, glucose-fructose syrup, acids (malic acid, citric acid), coconut oil, acidity regulator (sodium malates), flavouring, cocoa butter, colours (curcumin, carmine, brilliant blue FCF).'
        },
        {
            'id': 'D9y7m4YVaz8pC0XqaPTA',
            'name': 'Pasta N Sauce',
            'brand': 'Batchelors',
            'serving_size_g': 100.0,
            'ingredients': 'Pasta Spirals (51%) (Durum Wheat Semolina), Tomato Powder (13%), Potato Starch, Sugar, Dried Glucose Syrup, Buttermilk Powder (Milk), Onion Powder (3%), Salt, Yeast Extract, Flavourings, Vegetable Oils (Sunflower, Palm), Roasted Garlic, Cheese Powder (Cheese Powder (Milk), Emulsifying Salts (Disodium Phosphate)), Dried Basil, Dried Parsley, Colour (Beetroot Red).'
        },
        {
            'id': 'DAbrQBFuy34txqBDsFvY',
            'name': 'Ramen Head Teriyaki',
            'brand': 'Ramen Head',
            'serving_size_g': 225.0,
            'ingredients': 'Cooked Noodles (99.65%) (Water, Durum Wheat Semolina), Sunflower Oil. Broth: Water (75%), Soya Sauce (3.4%) (Sugar, Water, Soybean Extract (13%), Salt, Garlic Powder, Onion Powder, Spices & Condiments, Acidity Regulator (E260), Preservative (E211)), Brown Sugar, Shaoxing Wine (Water, Rice, Wheat, Salt, Lemongrass Extract & Black Pepper Extract, E150d), Sesame Seed Oil (Sesame Oil, Antioxidant E319), Miso Paste (3%) (Water, Soybeans, Rice, Salt), Rice Vinegar (Water, Rice, Sugar, Salt), Vegetable Broth (Salt, Corn Starch, Potato Powder, Onion, Maltodextrin, Sugar, Hydrolyzed Vegetable Protein (Wheat, Soy), Edible Vegetable Fat (Palm Fat), Yeast Extract, Garlic, Spices & Condiments (contains Celery), Flavour Enhancers (E627 & E631), Anticaking Agent (E551), Acidity Regulator (E330)), Spring Onion (1.1%), Garlic, Modified Starch.'
        },
        {
            'id': 'DBGbLWv1WauGz25uErzs',
            'name': 'Tomato Ketchup',
            'brand': 'HP Foods',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes, Spirit Vinegar, Sugar, Modified Cornflour, Salt, Preservative (Potassium Sorbate), Spice Extract.'
        },
        {
            'id': 'DBJ9dI61cxnKpy7ujBzq',
            'name': 'Double Chocolate Mini Muffins',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Rapeseed Oil, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Milk Chocolate Chips (10%) (Sugar, Cocoa Butter, Dried Skimmed Milk, Dried Whole Milk, Cocoa Mass, Whey Powder, Milk Fat, Emulsifier, Flavouring), Pasteurised Egg, Fat Reduced Cocoa Powder, Water, Humectant, Pasteurised Egg White, Maize Starch, Whey Powder, Raising Agents, Milk Proteins, Emulsifier, Cornflour, Preservative, Flavouring, Stabiliser, Acidity Regulator.'
        },
        {
            'id': 'DBVSDHpU49PAhmfEpyNB',
            'name': 'Deluxe Custard',
            'brand': 'Ambrosia',
            'serving_size_g': 120.0,
            'ingredients': 'Skimmed Milk, Buttermilk, Sugar, Modified Starches, Cream (5%), Sustainable Palm Oil, Inulin, Whey (Milk), Skimmed Milk Powder, Colours (Plain Caramel, Carotenes), Vanilla Extract, Natural Flavourings.'
        },
        {
            'id': 'DBozAbeemReXhLkmpwAQ',
            'name': 'Lime 40% Fruit Juice From Concentrate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Lime Juice from Concentrate (40%), Citric Acid, Flavourings, Acidity Regulator (Sodium Citrate), Sweeteners (Sucralose, Acesulfame K), Preservatives (Potassium Sorbate, Sodium Metabisulphite).'
        },
        {
            'id': 'D7b2pMLVLnufkrsUkc6h',
            'name': 'Tartare Sauce',
            'brand': 'Bramble Foods',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil, Water, Onion, Gherkins (7%), EGG Yolk Powder (4%), White Wine Vinegar, Sugar, MUSTARD Flour, Concentrated Lemon Juice, Capers (1.6%), Salt, Thickener: Modified Maize Starch, Dill, White Pepper, Garlic Powder, Acidity Regulator: Ascorbic Acid.'
        },
        {
            'id': 'DESVmfUUwDhj7U4FUJ8t',
            'name': 'Brot Protein Bread',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, 12% protein mix (wheat protein, pea protein), linseed brown, whole rye flour, 6% soya meal, 3% soya flour, wheat bran, linseed gold, sunflower seeds, sesame, yeast, oat fibre, salt, acidity regulator: sodium diacetate, protein enriched whey powder.'
        },
        {
            'id': 'DEb1UiEvbaCf9azr9q8L',
            'name': 'Toffee Granola',
            'brand': 'Fuel',
            'serving_size_g': 173.0,
            'ingredients': 'Toffee Flavour Yogurt (84%) (Yogurt (Milk), Sugar, Glucose Syrup, Sweetened Condensed Milk (Milk, Sugar), Salted Butter (Milk), Tapioca Starch, Colour (Ammonia Caramel), Butter Oil (Milk), Modified Maize Starch, Sweetener (Sucralose), Salt, Preservative (Potassium Sorbate)), Granola with Dark Chocolate (16%) (Wholegrain Oat Flakes, Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Lecithins)), Cereal Crisps (Rice Flour, Wheat Protein, Sugar, Salt), Sugar, Glucose Syrup, Sunflower Oil, Wheat Protein, Wholegrain Wheat Flakes, Cocoa Powder, Fat Reduced Cocoa Powder, Caramelised Sugar Syrup, Dextrose, Vitamins (Vitamin E, Niacin, Pantothenic Acid, Vitamin B6, Thiamin, Riboflavin, Vitamin B12, Folic Acid), Flavourings, Salt, Antioxidant (Tocopherol-Rich Extract)).'
        },
        {
            'id': 'DEsSIBRW8Ar459Eu29Dc',
            'name': 'Tesco Finest Piccante Pepperoni Pizza',
            'brand': 'Tesco Finest',
            'serving_size_g': 235.0,
            'ingredients': 'Wheat Flour, Water, Mozzarella Full Fat Soft Cheese (Milk), Tomato Purée, San Marzano Tomatoes, Mascarpone Full Fat Soft Cheese (Milk) 3.5%, Salsiccia Piccante Pepperoni 3.5% (Pork, Salt, Flavouring, Dextrose, Paprika, Fennel Seeds, White Pepper, Fennel Seeds Powder, Antioxidant: Sodium Ascorbate, Preservatives: Sodium Nitrite, Potassium Nitrate), Rapeseed Oil, Semolina (Wheat), Pecorino Medium Fat Hard Cheese (Milk), Rocket, Regato Medium Fat Hard Cheese (Milk), Tomato Paste, Extra Virgin Olive Oil, \'Nduja Paste (Pork, Extra Virgin Olive Oil, Red Pepper, Smoked Paprika, Salt, Paprika, Dextrose, Antioxidants: Sodium Ascorbate, Ascorbic Acid, Acidity Regulator: Citric Acid, Preservatives: Potassium Nitrate, Sodium Nitrite), Salt, Yeast, Tomato Purée, Maize Starch, Basil, Dextrose, Black Pepper, Deactivated Yeast, Wheat Gluten, Wheat Starch, Malted Wheat Flour.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 83\n")

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

    updated = update_batch83(db_path)

    print(f"✨ BATCH 83 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1461 + updated} products cleaned")

    # Check if we hit the 1475 milestone
    total = 1461 + updated
    if total >= 1475:
        print("\n🎉🎉 1475 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
