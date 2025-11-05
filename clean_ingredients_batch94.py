#!/usr/bin/env python3
"""
Clean ingredients for batch 94 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch94(db_path: str):
    """Update batch 94 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 94: Products with cleaned ingredients
    clean_data = [
        {
            'id': '2ZS0MA1BsP8tcNJ3lXFa',
            'name': 'Rainbow Orzo Salad',
            'brand': 'Tesco Finest',
            'serving_size_g': 245.0,
            'ingredients': 'Plum tomatoes (30%), cooked orzo pasta (28%) (water, durum wheat semolina, rapeseed oil), wild garlic pesto dressing (water, rapeseed oil, wild garlic, basil, medium fat hard cheese (milk), spirit vinegar, salt, garlic, black pepper), red peppers, yellow peppers, green beans, rocket, pine nuts, lemon juice.'
        },
        {
            'id': '2aiwj5hHVT99st40g7TV',
            'name': 'Solid White Chocolate Coins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, whole milk powder, whey powder (milk), lactose (milk), emulsifier: soya lecithin, natural vanilla flavouring.'
        },
        {
            'id': '2cIIzbtCaNqFUj8PmEca',
            'name': 'Munch Bars Peanut',
            'brand': 'Aldi',
            'serving_size_g': 32.0,
            'ingredients': 'Oat flakes (26%), glucose syrup, milk chocolate (19%) (sugar, cocoa butter, whole milk powder, cocoa mass, emulsifier: lecithins (soya, sunflower), flavouring), peanuts (11%), palm oil, whole wheat flakes (4.5%), rice flour, flavouring, salt.'
        },
        {
            'id': '2dkQFfq9RMSyl9yD4Ce3',
            'name': '8 Honey And Rosemary Pork Chipolatas',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (56%), oak smoked dry cured bacon (30%) (pork belly, salt, sugar, preservatives: sodium nitrite, potassium nitrate, antioxidant: sodium ascorbate), water, honey (2%), pea flakes, potato starch, pea fibre, rosemary, salt, black pepper, dextrose, stabiliser (triphosphates), preservative (sodium metabisulphite).'
        },
        {
            'id': '2fOM69uR59qw9aHwcKWT',
            'name': 'Ketchup Tomates Anciennes',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mincemeat (43%), sugar, sultanas, apple pulp, currants, brandy, glucose syrup, cornflour, orange peel, apple, glucose-fructose syrup, water, sunflower oil, rapeseed oil, cherry, port, mixed spices, preservative (potassium sorbate), acidity regulator (citric acid).'
        },
        {
            'id': '2h0HWRqfwJBzPWrNovWR',
            'name': 'Mint Sauce',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Mint (33%), white wine vinegar (contains sulphites), water, sugar, balsamic vinegar (4.5%), cornflour, salt, flavourings.'
        },
        {
            'id': '2hXg4QaxmklRn7ycW4FB',
            'name': 'Stir In Pasta Sauce With Tomato And Bacon',
            'brand': 'Aldi',
            'serving_size_g': 75.0,
            'ingredients': 'Tomatoes (58%), onion, tomato purée from concentrate (10%), smoked reformed bacon with added water (7%) (pork, water, pork fat, salt, dextrose, stabilisers: triphosphates, polyphosphates, antioxidant: sodium ascorbate, preservative: sodium nitrite), water, red wine, modified maize starch, rapeseed oil, sugar, garlic purée, salt, herbs, black pepper.'
        },
        {
            'id': '2hYaW8gkRKWBujM3Yll4',
            'name': 'Garlic Baguettes',
            'brand': 'Alfredo',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, margarine (rapeseed oil, palm oil, water, emulsifier: mono-and diglycerides of fatty acids, natural flavouring, colour: carotenes), garlic (5%), yeast, sugar, salt, rapeseed oil, parsley, flour treatment agent (ascorbic acid).'
        },
        {
            'id': '2hdIGprPaBzUTVV2a5oj',
            'name': 'Country Crisp Strawberry',
            'brand': 'Jordans',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain cereals (54%) (oat flakes, oat flour), sugar, barley flakes, vegetable oil (rapeseed and sunflower in varying proportions), rice flour, freeze dried strawberry pieces (2.5%), desiccated coconut, honey, salt, natural flavouring.'
        },
        {
            'id': '2hy1cJ7IpRWLJeeDPOfs',
            'name': 'Shredded Beef Chilli And Rice',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Black turtle beans, cherry tomato, water, tomato, sweetcorn, pulled beef (7%) (beef (98%), pea starch, salt), green pepper, kidney beans, beef (5%), red pepper, onion, red quinoa, brown long grain rice, cooked white long grain rice, rapeseed oil, tomato purée, garlic purée, chilli powder, cumin, paprika, coriander, salt, oregano.'
        },
        {
            'id': '2sshs6rwYadkR0WQrm8Z',
            'name': 'Wagyu - Marinated Air Dried Strips',
            'brand': 'Kings',
            'serving_size_g': 45.0,
            'ingredients': 'Beef (156g per 100g of finished product), sugar, cider vinegar, salt, onion extract, paprika, dried red bell pepper, dried onion, yeast extract, thyme, flavouring, potato fibre, preservative (potassium sorbate).'
        },
        {
            'id': '2zXKPLyZ3dwmiDUmXprx',
            'name': 'Tomato Ketchup 50%',
            'brand': 'Fairy',
            'serving_size_g': 15.0,
            'ingredients': 'Tomatoes (174g per 100g tomato ketchup), spirit vinegar, sugar, salt, spice and herb extracts (contain celery), sweetener (steviol glycosides), spice.'
        },
        {
            'id': '2zbBP6VKtHT1fWmVrNWZ',
            'name': 'Strawberries And Clotted Cream Ice Cream',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'British cows\' milk (43%), strawberry (17%), British double cream (cows\' milk) (13%), sugar, British clotted cream (cows\' milk) (6%), skimmed cows\' milk powder, cornflour, pasteurised free range egg yolk, colour (beetroot red), natural flavouring, stabiliser (locust bean gum).'
        },
        {
            'id': '2zeJB8lpCH7dBowoJTV5',
            'name': 'Tesco Guacamole Dip 163G',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Avocado (80%), water, lime juice, tomato, onion, coriander, salt, antioxidant (ascorbic acid), garlic purée, red chilli.'
        },
        {
            'id': '2wOMnBYiAcukWxMaL73a',
            'name': 'Breaded Ham Slices',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, salt, gluten free breadcrumb (rice flour, maize flour, rapeseed oil, colour: paprika extract, turmeric powder, maize starch, salt, dextrose), water, stabiliser: triphosphates, sugar, pork gelatine, preservative (sodium nitrite), antioxidant (sodium ascorbate).'
        },
        {
            'id': '32HXyzthqklPSSIGzm3F',
            'name': 'Thai Sweet Chilli Egg Noodles',
            'brand': 'Naked',
            'serving_size_g': 328.0,
            'ingredients': 'Dried egg noodles (71%) (soft wheat, durum wheat semolina, egg, salt, acidity regulator: potassium carbonate), sugar, potato starch, flavourings, garlic powder, dried spring onion (1.5%), dried red peppers, chilli powder, salt, colour (paprika extract).'
        },
        {
            'id': '32V3I8ehC3oxMAr8lpDk',
            'name': 'Mini Tortillas',
            'brand': 'Capsicana',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, niacin, iron, thiamin), water, sugar, humectant (glycerol), extra virgin olive oil, sustainable palm oil, rapeseed oil, raising agents (disodium diphosphate, sodium bicarbonate), salt, emulsifier (mono-and diglycerides of fatty acids), preservative (calcium propionate), flour treatment agent (l-cysteine hydrochloride).'
        },
        {
            'id': '32iSwh9VEvGclWerZ2Sw',
            'name': 'All Butter Pastry Mince Pie',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), mincemeat (35%) (sultanas, sugar, bramley apple, currants, water, candied mixed peel (orange peel, glucose-fructose syrup, lemon peel, sugar, acidity regulator: citric acid), vegetable suet (palm oil, sunflower oil, wheat flour), treacle, mixed spice, orange oil, lemon oil), butter (milk) (28%), water, sugar, pasteurised free range egg.'
        },
        {
            'id': '330belqrY9QaSeVR6mm0',
            'name': 'Sunflower Seeds',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Sunflower seeds.'
        },
        {
            'id': '34A305LDV4M4rJu76xsk',
            'name': 'Salted Caramel Chocolate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, isomaltooligosaccharide, cocoa mass, caramel (8%) (sugar, glucose syrup), emulsifier (soya lecithins), sea salt.'
        },
        {
            'id': '35Qftriho9V6x9CMFtgn',
            'name': 'Dairy Milk Fruitier & Nuttier Orange Boost',
            'brand': 'Cadbury',
            'serving_size_g': 30.0,
            'ingredients': 'Milk, date paste (24%), dried apricot pieces (23%), roasted hazelnuts (15%), almond paste (11%), sugar, humectant (glycerol), rice flour, cocoa butter, cocoa mass, fat-reduced cocoa powder (1%), vegetable fats (palm, shea), emulsifier (soya lecithin), natural flavourings, salt.'
        },
        {
            'id': '369IoQW243IMGy7iQWJ8',
            'name': 'Vegetarian Black Pudding',
            'brand': 'The Bury Black Pudding Company',
            'serving_size_g': 100.0,
            'ingredients': 'Water, black beans, wheat flour (with added calcium, iron, niacin & thiamin), onions, pearl barley, modified starch, wheat starch, oatmeal, vegetable oil (palm, sunflower), barley flour, spices, salt, yeast extract, natural flavouring, colour (plain caramel).'
        },
        {
            'id': '32RrRHsDOzSzRjQtkTKw',
            'name': 'Iceland Criss Cross Fries 700g',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (76%), sunflower oil (11%), maize flour, modified potato starch, rice flour, maize starch, spices (chilli pepper powder, paprika powder, cayenne pepper powder, ground black pepper, cumin powder), salt, dextrose, raising agent (sodium bicarbonate).'
        },
        {
            'id': '32TLqpFGmHlOpGt7iFBe',
            'name': 'No Artificial Colours, Flavours Or Preservatives 4',
            'brand': 'Nestlé',
            'serving_size_g': 60.0,
            'ingredients': 'Partially reconstituted skimmed milk concentrate, sugar, coconut oil, glucose syrup, strawberry puree, whey powder from milk, emulsifier: mono-and diglycerides of fatty acids, stabilisers (guar gum, locust bean gum), beetroot juice concentrate, natural flavouring, acidity regulator (citric acid).'
        },
        {
            'id': '383Emw1bBIdFoCdMU7HR',
            'name': 'Beef Gravy Granules',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Potato starch, palm oil, salt, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), barley malt extract, maltodextrin, flavourings (contain wheat), onion powder, emulsifier (soya lecithin), colour (plain caramel), beef extract, yeast extract.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 94\n")

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

    updated = update_batch94(db_path)

    print(f"✨ BATCH 94 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1736 + updated} products cleaned")

    # Check if we hit the 1750 milestone
    total = 1736 + updated
    if total >= 1750:
        print("\n🎉🎉 1750 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
