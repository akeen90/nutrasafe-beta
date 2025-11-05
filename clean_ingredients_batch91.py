#!/usr/bin/env python3
"""
Clean ingredients for batch 91 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch91(db_path: str):
    """Update batch 91 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 91: Products with cleaned ingredients
    clean_data = [
        {
            'id': '0031Mj0fWpr0DebXx6tN',
            'name': 'Refried Beans',
            'brand': 'Gran Luchito',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked pinto beans (83%) (pinto beans, water), red bell pepper, chipotle adobo (5.6%) (chipotle, corn starch, vinegar, onion, spices, garlic), green anaheim chilli, onion, salt, cumin, black pepper, acidity regulator (citric acid).'
        },
        {
            'id': '04lHJwhfkF0qFHXrA4lA',
            'name': 'Beef Ragu',
            'brand': 'Babease',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato passata (23%), beef mince (20%), cooked spelt (wheat) wholegrain spaghetti (19%), sweet potato (14%), water, onions, carrot, garlic puree, olive oil, parmesan cheese (milk), basil, rosemary, black pepper.'
        },
        {
            'id': '066VIq19HsFka0he5lY9',
            'name': 'Gammon Ham',
            'brand': 'Morrisons',
            'serving_size_g': 31.0,
            'ingredients': 'Pork, preservative (potassium lactate, sodium acetates, sodium nitrate, sodium nitrite), salt, stabiliser (triphosphates), spirit vinegar.'
        },
        {
            'id': '07Y7kca36JaXPvb8MK8s',
            'name': 'Organic Unsalted Crunchy Peanut Butter',
            'brand': 'Equal Exchange',
            'serving_size_g': 100.0,
            'ingredients': 'Organic roasted peanuts (100%).'
        },
        {
            'id': '095iFJHynYUKkzxNcPI5',
            'name': 'Honey Siracha Chicken',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked jasmine rice (water, jasmine rice), chicken breast (14%), cabbage, tenderstem broccoli, water, muscovado sugar, red pepper, ginger purée, honey, garlic purée, concentrated lime juice, rice wine vinegar, sriracha sauce, soy sauce, cornflour, sesame oil.'
        },
        {
            'id': '0Aa0ARmNUrjZZDU3u6gv',
            'name': 'Asda Free From 4 Tea Cakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, gluten-free flour blend (rice flour, potato starch, tapioca starch, maize flour, buckwheat flour), sultanas (14%), rapeseed oil, sugar, yeast, psyllium husk powder, salt, rice bran, raising agents (glucono delta-lactone, sodium bicarbonate), thickeners (hydroxypropyl methyl cellulose, xanthan gum), emulsifier (mono-and diglycerides of fatty acids), natural flavouring, acidity regulator (citric acid).'
        },
        {
            'id': '0CKqWomm1J5KGWZNSM6W',
            'name': 'Distilled Vinegar',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, malted barley, barley. Acidity 5%.'
        },
        {
            'id': '0FAendDwdje3L58EUC3t',
            'name': 'Moroccan Spiced Couscous',
            'brand': 'Al Fez',
            'serving_size_g': 100.0,
            'ingredients': 'Couscous (85%) (durum wheat), sultanas (5%), seasoning (sugar, dextrose, ground spices (cumin, paprika, turmeric, cinnamon, black pepper), salt, onion powder), rusk (wheat flour (calcium carbonate, iron, niacin, thiamin)).'
        },
        {
            'id': '0FBWstErJDeekhRRry3r',
            'name': 'Instant Hot Chocolate',
            'brand': 'Galaxy',
            'serving_size_g': 25.0,
            'ingredients': 'Sugar, whey permeate (milk), fat reduced cocoa powder, coconut oil, dried glucose syrup, lactose (milk), milk chocolate (3.0%) (sugar, cocoa butter, skimmed milk powder, cocoa mass, lactose and protein from whey (milk), palm fat, milk fat, emulsifier: soya lecithin, natural vanilla flavouring), stabiliser (E340), flavouring, salt.'
        },
        {
            'id': '0FVRPdl5angTAEqXrj0t',
            'name': 'Veg Medley',
            'brand': 'Four Seasons',
            'serving_size_g': 100.0,
            'ingredients': 'Broccoli, cauliflower, carrots, sweetcorn.'
        },
        {
            'id': '0FyikOgWufIZHDsrodMy',
            'name': 'Cherry Liqueurs',
            'brand': 'Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa mass, liqueur filling (23%) (sugar, water, glucose syrup, alcohol, flavourings), morello cherries (16%), cocoa butter, butter oil (milk), emulsifier: lecithins (soya), flavouring.'
        },
        {
            'id': '0GWp4s4PyNOjom7thego',
            'name': 'Brioche Buns',
            'brand': 'St. Pierre',
            'serving_size_g': 63.0,
            'ingredients': 'Wheat flour, egg, water, sugar, yeast, invert sugar, rapeseed oil, wheat gluten, concentrated butter (milk), malted rye flour, milk proteins, salt, emulsifier (mono-and diglycerides of fatty acids), flour treatment agent (ascorbic acid).'
        },
        {
            'id': '0H8tqmXJK6Y7PUye6JTS',
            'name': 'Monster Munch Pickled Onion',
            'brand': 'Walkers',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, rapeseed oil, pickled onion seasoning (flavourings, whey permeate from milk, onion powder, sugar, flavour enhancers: monosodium glutamate, disodium 5\'-ribonucleotide, salt, potassium chloride), garlic powder, colours (paprika extract, curcumin).'
        },
        {
            'id': '0Hcsa6PogeSMN1waJU68',
            'name': 'Moonpig Chocolate Coins',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, whole milk powder, cocoa mass, cocoa butter, emulsifier: sunflower lecithin, natural vanilla flavouring.'
        },
        {
            'id': '0HkRgBBFGcnl1idIpFi2',
            'name': 'Stonebaked Pizza New Recipe Margarita',
            'brand': 'Carlos',
            'serving_size_g': 137.0,
            'ingredients': 'Pizza base (wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, yeast, rapeseed oil, dextrose, salt), tomato sauce (22%) (water, tomato purée, cornflour, sugar, acidity regulator: citric acid, salt, oregano, garlic powder), mozzarella cheese (milk) (19%), vegetable oil (rapeseed oil, extra virgin olive oil), basil.'
        },
        {
            'id': '0I7oPU2BbDoEh6Mr85Sk',
            'name': 'After Dinner Mints',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Dark chocolate (65%) (cocoa mass, sugar, cocoa butter, emulsifier: sunflower lecithins, vanilla extract), sugar, glucose syrup, invert sugar syrup, peppermint extract.'
        },
        {
            'id': '0Mqdeb2DiK0M6hmBPV1t',
            'name': 'GRO Plant-based Eating',
            'brand': 'Gro',
            'serving_size_g': 67.0,
            'ingredients': 'Water, dried glucose syrup, sugar, cocoa powder, coconut milk powder, caramel sauce (4%) (caramel syrup, sugar, flavourings, thickener: pectin), chocolate brownie pieces (4%) (brown sugar, fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), cocoa powder, rapeseed oil, water, salt, raising agent: sodium bicarbonate), stabilisers (locust bean gum, guar gum), emulsifier (mono-and diglycerides of fatty acids), natural flavouring, colour (caramel).'
        },
        {
            'id': '0NDCj6OzMGew8f9UpXBb',
            'name': 'Prawn Cocktail Crisps',
            'brand': 'Aldi Specially Selected',
            'serving_size_g': 100.0,
            'ingredients': 'Potato, sunflower oil, sugar, flavouring, salt, onion powder, spirit vinegar powder, yeast extract powder, tomato powder, acid: citric acid, colour: paprika extract, shrimp powder (Pandalus borealis) (0.01%).'
        },
        {
            'id': '0O6svipqpphdeYsPyaoD',
            'name': 'Aldi Dessert Menu Custard',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed milk, water, sugar, modified maize starch, palm oil, buttermilk powder (milk), whey powder (milk), flavouring, colour: carotenes.'
        },
        {
            'id': '0O83zzeo5fU57GXyKjOF',
            'name': 'Salami',
            'brand': 'Dulano',
            'serving_size_g': 26.0,
            'ingredients': 'Pork, nitrite curing salt (salt, preservative: sodium nitrite), glucose syrup, spices, dextrose, antioxidant: sodium ascorbate.'
        },
        {
            'id': '0OIuL0ADfQgPoO25mNg6',
            'name': 'Prawn Cocktail Crisps',
            'brand': 'Walkers',
            'serving_size_g': 32.5,
            'ingredients': 'Potatoes, sunflower oil, rapeseed oil, corn starch, sugar, salt, dextrose, potassium chloride, acid (citric acid), dried yeast, dried onion, tomato powder, colour (paprika extract), sweetener (sucralose), flavourings.'
        },
        {
            'id': '0PDrWfOsYfN6MsS92fDO',
            'name': 'Aldi Pitted Green Olives',
            'brand': 'Aldi',
            'serving_size_g': 16.0,
            'ingredients': 'Green olives, water, salt, acidity regulator: lactic acid.'
        },
        {
            'id': '0Q3Q7od2MEpQvOIoZoc9',
            'name': 'Aldi No Lamb Koftas',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Water, fava bean flour (18%), textured pea protein (8%), vegetable oils (shea, coconut), stabiliser: methyl cellulose, flavourings, rapeseed oil, pea fibre, smoked paprika, pea starch, ground coriander, salt, garlic powder, dried parsley, ground cumin, black pepper, turmeric, ground ginger, chilli powder.'
        },
        {
            'id': '0QDqL4NYJAFMewFry529',
            'name': 'Asda Tomato Mug Soup',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Potato starch, tomato powder (18%), sugar, dried glucose syrup, maltodextrin, palm oil, salt, flavourings, onion powder, colours (beetroot red, paprika extract), cream powder (milk), milk proteins, yeast extract, garlic powder, acidity regulator (citric acid).'
        },
        {
            'id': '0QFIEAUiAZ1cDgrkgiHd',
            'name': '4 Soft Sliced Focaccia',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, extra virgin olive oil (7%), yeast, sugar, spirit vinegar, raising agents: diphosphates, sodium carbonates, calcium phosphates, salt, emulsifier: mono-and diglycerides of fatty acids, flour treatment agent: ascorbic acid.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 91\n")

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

    updated = update_batch91(db_path)

    print(f"✨ BATCH 91 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1661 + updated} products cleaned")

    # Check if we hit the 1675 milestone
    total = 1661 + updated
    if total >= 1675:
        print("\n🎉🎉 1675 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
