#!/usr/bin/env python3
"""
Clean ingredients for batch 92 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch92(db_path: str):
    """Update batch 92 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 92: Products with cleaned ingredients
    clean_data = [
        {
            'id': '0rbEk5CV7aWn0N4ujdFk',
            'name': 'Dark Chocolate',
            'brand': 'Godiva',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa mass, sugar, cocoa butter, fat reduced cocoa powder, emulsifier: soya lecithin, salt, butter oil (milk).'
        },
        {
            'id': '0s36zHwn0lQXyjGfnFaB',
            'name': 'Chicken Parfait',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken liver (32%), pork fat (15%), water, pork (8%), chicken fat, sweet white wine (6%) (contains sulphites), chicken (6%), onion, potato starch, rice flour, salt, spices, stabiliser (triphosphates), dextrose, antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': '0s8sIDOgsuNLTFMTfbEm',
            'name': 'Fat Free Vinaigrette Dressing',
            'brand': 'Batts',
            'serving_size_g': 100.0,
            'ingredients': 'Water, spirit vinegar, sugar, white wine vinegar, stabiliser: xanthan gum, dried red pepper, parsley, preservative: potassium sorbate, colour: paprika extract.'
        },
        {
            'id': '0saA1e4rxveF8Xb4BViK',
            'name': 'Vanilla Mini Cupcakes',
            'brand': 'Co-op',
            'serving_size_g': 19.0,
            'ingredients': 'Sugar, vegetable oils (rapeseed, palm, coconut, palm kernel), potato starch, egg, humectant: glycerol-vegetable, invert sugar syrup, flavouring, raising agents: disodium diphosphate, sodium bicarbonate, emulsifier: mono-and diglycerides of fatty acids, salt, skimmed milk powder, glucose syrup, colours (beetroot red, curcumin).'
        },
        {
            'id': '0tBiY0pzTRgAyM6oS0Bf',
            'name': 'Easy Lemongrass',
            'brand': 'Cook By Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Lemongrass (54%), water, acidity regulators: acetic acid, citric acid, ascorbic acid, salt, sugar, rapeseed oil, stabiliser: xanthan gum, preservative: potassium sorbate.'
        },
        {
            'id': '0tXDgABvhX6PrKeG0XIr',
            'name': 'Tomato, Onion And Herb Pasta',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Dried pasta (68%) (durum wheat semolina, wheat flour), tomato powder (13%), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), sugar, onion powder (2%), flavourings (contains celery), herbs (basil, oregano, parsley), salt, garlic powder, colour (paprika extract).'
        },
        {
            'id': '0uNOaQVNzrVRORZPur70',
            'name': 'Honey Roasted Cashews',
            'brand': 'Tesco',
            'serving_size_g': 25.0,
            'ingredients': 'Cashew nuts (80%), sugar, sunflower oil, honey (1.5%), glucose syrup, salt, stabiliser: xanthan gum.'
        },
        {
            'id': '0ubH8AVG21okUbSNXOyG',
            'name': 'Free Range Pork Chipolata',
            'brand': 'Waitrose',
            'serving_size_g': 93.75,
            'ingredients': 'Pork (98%), sea salt, rice flour, maize flour, stabiliser (triphosphates), black pepper, preservative (sodium metabisulphite), white pepper, onion, mace, antioxidant (ascorbic acid), maize starch, salt.'
        },
        {
            'id': '0ul6MDV62N2cAx8xeGLT',
            'name': 'Pepperoni',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, pork fat, salt, paprika, chilli powder, garlic powder, dextrose, maltodextrin, spice extracts (black pepper, paprika), antioxidants (sodium ascorbate, extracts of rosemary), preservative (sodium nitrite).'
        },
        {
            'id': '0v0EG1CDTDRE9j5QLlNW',
            'name': 'Chunky Chopped Tomatoes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (65%), concentrated tomato juice, sugar, oregano extract, dried oregano, dried basil, acidity regulator: citric acid.'
        },
        {
            'id': '0v4hDZ77XiKCJKelEZeR',
            'name': 'Fruit Salad',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose syrup, sugar, beef gelatine, water, modified potato starch, acids (citric acid, acetic acid), flavourings, palm oil, colours (lutein, vegetable carbon, paprika extract, carmine, chlorophyll, curcumin), glazing agent (beeswax).'
        },
        {
            'id': '0xTksGq5pdC5cCuYEZHS',
            'name': 'Dry Sausage',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Meat (134g of pork meat and 15g of beef per 100g of finished product), salt, spices, antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': '0u9RkWc1KAQdTiVEXj7O',
            'name': 'Cantucci',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, sugar (23%), almonds (20%), eggs, egg white, sugar cane (2.5%), baking powder (disodium diphosphate, sodium hydrogen carbonate), butter (milk), honey, flavours, salt.'
        },
        {
            'id': '12UOGL1XAo1atZxRoznd',
            'name': 'Peppered Salami',
            'brand': 'Dulano',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, black peppercorns (3%), salt, pork gelatine, glucose syrup, spices, garlic, antioxidant (sodium ascorbate), acidity regulator (sodium acetate), acid (acetic acid), preservative (sodium nitrite).'
        },
        {
            'id': '12xgwrKNL6VtqlJZamN4',
            'name': 'Maple Pork Belly Slices',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Pork belly (100%), water, sugar, maple syrup (2%), salt, stabiliser (triphosphates), natural flavouring, preservative (sodium nitrite).'
        },
        {
            'id': '14CEb9dsIF7KAWuIsmG4',
            'name': 'Salted Caramel Crunch',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, rice powder (dried rice syrup, rice starch, rice flour), cocoa mass, glucose syrup, emulsifier: sunflower lecithin, sea salt (0.4%), natural flavourings.'
        },
        {
            'id': '15gjYSkbk98Nfko1NxJh',
            'name': 'Cocoa Rice Cakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Brown rice (75%), chocolate powder (11%) (sugar, cocoa mass, cocoa powder), sugar, flavourings.'
        },
        {
            'id': '19OI8OAuyGfEW4KiPviv',
            'name': 'Tesco Finest Beef Dripping Gravy',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Water, cabernet sauvignon (6%), cornflour, beef dripping (3%), beef extract, yeast extract, caramelised sugar, salt, balsamic vinegar (wine vinegar, concentrated grape must), beef fat, demerara sugar, garlic powder, black pepper, onion powder.'
        },
        {
            'id': '1Af4GDTNorHGTwVnJm3i',
            'name': 'Crispy & Fluffy Homestyle Chips',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (95%), sunflower oil (3%), rice flour, dextrin, potato starch, salt, turmeric powder, paprika flavouring, dextrose.'
        },
        {
            'id': '1DLedu0hY7GIMiPHQHgR',
            'name': 'Henry Hippo',
            'brand': 'Sweet Corner',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose syrup, sugar, modified potato starch, water, acid: citric acid, concentrated fruit juice (0.7%) (apple, blackcurrant, cherry, raspberry, strawberry, orange, apricot, pineapple, passion fruit, lemon), flavourings, colours (E100, E120, E131, E141, E160a), glazing agent (vegetable oil, carnauba wax).'
        },
        {
            'id': '1ERj3jHz25Cz8wpanBJc',
            'name': 'Galaxy Smooth Orange',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, skimmed milk powder, cocoa butter, cocoa mass, milk fat, palm fat, lactose, whey permeate from milk, emulsifier: soya lecithin, natural orange flavouring, vanilla extract.'
        },
        {
            'id': '1FJcTDO6oc09jTdvQrt4',
            'name': 'Unicorn Shortbread Biscuits',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Shortbread mix (fortified wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), caster sugar, rapeseed oil), white chocolate flavour candy (15%) (sugar, palm oil, whey powder (from milk), emulsifier: soya lecithin, natural flavouring), icing sugar, colours (beetroot red, spirulina extract, curcumin), glucose syrup.'
        },
        {
            'id': '1FnJTqDsn2mHQ9oUt9QN',
            'name': 'Bisto Chicken Gravy',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato starch, maltodextrin, palm fat, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), flavouring, sugar, salt, chicken fat, flavour enhancers (monosodium glutamate, disodium 5\'-ribonucleotides), colour (plain caramel), emulsifier: soya lecithin, black pepper extract, sage extract.'
        },
        {
            'id': '1FymNXNWrmVTOTR8azgp',
            'name': 'Scottish Rough Oatcakes',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Oatmeal (91%), palm oil, sea salt, raising agent (sodium bicarbonate).'
        },
        {
            'id': '1GKRYvOh54niWZjGSwuM',
            'name': 'Blue Stilton, With Red Onion & Thyme. Hand Cooked Potato Crisp',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes (65%), high oleic sunflower oil (28%), Blue Stilton, red onion, thyme flavoured seasoning (7%) (sugar, dried whey powder (milk), salt, dried onion, dried red onion, dried cheeses (dried cheese (milk), buttermilk powder (milk)), flavourings, yeast extract powder, colour (paprika extract), acid (citric acid)).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 92\n")

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

    updated = update_batch92(db_path)

    print(f"✨ BATCH 92 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1686 + updated} products cleaned")

    # Check if we hit the 1700 milestone
    total = 1686 + updated
    if total >= 1700:
        print("\n🎉🎉 1700 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
