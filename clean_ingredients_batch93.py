#!/usr/bin/env python3
"""
Clean ingredients for batch 93 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch93(db_path: str):
    """Update batch 93 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 93: Products with cleaned ingredients
    clean_data = [
        {
            'id': '1YxygaToceFIAJs7Wxm3',
            'name': 'FREE FROM Sliced Brown Bread',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Water, gluten-free flour blend (rice flour, potato starch, tapioca starch, maize flour), rapeseed oil, sugar, yeast, psyllium husk powder, rice bran, salt, emulsifier (mono-and diglycerides of fatty acids), natural caramel colour.'
        },
        {
            'id': '1ccQ6OLVSBBe4dmdJiFQ',
            'name': 'M&S Chicken Caesar Dip',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Full fat soft cheese (milk), rapeseed oil, water, parmigiano reggiano cheese (milk), chicken breast (4.5%) (chicken breast (96%), rapeseed oil, salt), roast chicken stock (water, roast chicken bones, chicken meat, carrots, onions, celery), pasteurised egg yolk, white wine vinegar, garlic purée, salt, black pepper, dijon mustard (water, mustard seeds, spirit vinegar, salt), anchovy paste (anchovies, salt, olive oil).'
        },
        {
            'id': '1eecYT6LpxQ1q88STEP1',
            'name': 'Granola Nut & Seed No Added Sugar',
            'brand': 'M&S',
            'serving_size_g': 45.0,
            'ingredients': 'Oat flakes (70%), chicory fibre, hazelnuts (5%), rapeseed oil, almonds (4%), sunflower seeds (3.5%), pumpkin seeds (3.5%).'
        },
        {
            'id': '1fL6fWlhUo0mudphEwWi',
            'name': 'Fruit Snoothie Jellies',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose syrup, sugar, water, concentrated fruit purées (5%) (apple, banana, strawberry, pineapple, mango), gelatine, pectin, acid (citric acid), concentrated fruit juices (strawberry, raspberry, blackcurrant), natural flavourings, colours (anthocyanins, curcumin, paprika extract).'
        },
        {
            'id': '1fQ524yZ7Xfe7WX5mtwt',
            'name': 'Bourneville Easter Egg',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa mass, palm oil, cocoa butter, emulsifiers (soya lecithins, E476).'
        },
        {
            'id': '1hjhrOUhCRghF2N5V64D',
            'name': 'British Outdoor Bred Dry Cured Smoked Back Bacon',
            'brand': 'M&S Collection',
            'serving_size_g': 73.0,
            'ingredients': 'British pork, curing salt (salt, preservative: sodium nitrite, sodium nitrate), demerara sugar, sugar, antioxidant: E301.'
        },
        {
            'id': '1i4XNqP6K9PRv4PqpWAr',
            'name': 'Selected Cut Corned Beef',
            'brand': 'Tesco',
            'serving_size_g': 31.0,
            'ingredients': 'Beef, salt, preservative (sodium nitrite).'
        },
        {
            'id': '1iOe57Yw0clNsfm1HKo6',
            'name': 'Pancake Shaker',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, niacin (B3), iron, thiamin (B1)), sugar, whey powder (milk), egg yolk powder, dextrose, salt.'
        },
        {
            'id': '1iPN8Lj1M273BhZUnHbH',
            'name': 'Classic Scottish Broth Soup',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, vegetables (25%) (carrot, onion, potato, garden peas, swede), pearl barley (5%), mutton (4%), modified maize starch, fortified wheat flour (wheat flour, iron, thiamin, nicotinic acid, calcium carbonate), salt, yeast extract, sugar, natural flavouring, white pepper.'
        },
        {
            'id': '1iQag0sQlwPUAhXkzy2q',
            'name': 'Clotted Cream Fudge',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, sweetened condensed milk (milk, sugar), golden syrup, butter (milk, salt), invert sugar syrup, clotted cream (milk) (7%), glucose syrup.'
        },
        {
            'id': '1itbyEP5Z8AJeMNX9loJ',
            'name': 'Dry Cured Unsmoked Streaky Bacon',
            'brand': 'Aldi',
            'serving_size_g': 27.0,
            'ingredients': 'Pork belly, sea salt, sugar, preservatives: potassium nitrate, sodium nitrite.'
        },
        {
            'id': '1l0SoYvh2ajvtp7yNE4i',
            'name': 'Jumbo Cashew Nuts',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Jumbo cashew nuts (96%), rapeseed oil, salt.'
        },
        {
            'id': '1m4CE0GQdkutD2BSZRQR',
            'name': 'Sea Salt Crackers',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, niacin, iron, thiamin, riboflavin, folic acid), sunflower oil, palm oil, sea salt (1.5%), yeast powder (contains wheat, barley, sugar), rice flour, cane sugar syrup, flavouring, yeast extract.'
        },
        {
            'id': '1fpKRtzN2ZgDdMyDeK7Y',
            'name': 'Triple Chocolate Trifle',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Milk, cream (milk), skimmed milk, sugar, milk chocolate, double cream (milk), water, tapioca starch, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), caster sugar, fat reduced cocoa powder, cocoa mass, cocoa butter, palm oil, vegetable fat (palm), emulsifiers (E471, soya lecithin, E475), modified starch, whey powder (milk), stabilisers (E401, E407, E410, E412), gelling agent (pectin), flavourings, glucose syrup, pasteurised egg, salt, raising agent (E500).'
        },
        {
            'id': '1nCBs77zLtSvjt490NfD',
            'name': 'Tuna Chunks In Brine',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack tuna (Katsuwonus pelamis) (fish), water, salt.'
        },
        {
            'id': '1rMhGECZ7yaQuk2y9Vh2',
            'name': 'Sicilian Blood Orange Marmalade',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, blood orange, antioxidant: ascorbic acid, gelling agent: pectins, acidity regulator: sodium citrates, acid: citric acid.'
        },
        {
            'id': '1sB975HVw3sGICVmwV3x',
            'name': 'Choco Shells',
            'brand': 'Crownfield',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat semolina (56%), sugar, wholegrain wheat flour (14%), fat reduced cocoa powder (7.5%), glucose syrup, cocoa powder (1.5%), barley malt extract, salt, natural flavouring, cinnamon.'
        },
        {
            'id': '1sQjQRqBXRxXmnNG6rlP',
            'name': 'Original Hot Pepper Sauce',
            'brand': 'Encona',
            'serving_size_g': 100.0,
            'ingredients': 'Pepper mash (habanero peppers, scotch bonnet peppers, salt, acid: acetic acid (64%)), water, acid: acetic acid, salt, onion, mustard, modified maize starch, stabiliser: xanthan gum.'
        },
        {
            'id': '1spr8p6PptsZjHYOFHx5',
            'name': 'Ambrosia Custard Pot Low Fat 150g',
            'brand': 'Ambrosia',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed milk, buttermilk, modified starch, sugar, palm oil, whey (milk), natural flavourings, colours (curcumin, annatto norbixin).'
        },
        {
            'id': '1tQao8VcmcKq7BTkUg1m',
            'name': 'Golden Vegetable Rice',
            'brand': 'Asda',
            'serving_size_g': 150.0,
            'ingredients': 'Cooked long grain rice (57%) (water, long grain rice), sweetcorn (15%), peas (15%), red peppers (10%), rapeseed oil, maltodextrin, yeast extract, salt, sugar, onion powder, garlic powder, mushroom extract, colour (curcumin), natural flavouring.'
        },
        {
            'id': '1u1zzL3hWbRIYkJnRvgu',
            'name': 'Kitkat Family Pack 14pk',
            'brand': 'Nestlé',
            'serving_size_g': 20.7,
            'ingredients': 'Sugar, wheat flour (contains calcium, iron, thiamin and niacin), milk powders (whole and skimmed), cocoa mass, cocoa butter, vegetable fats (palm, shea, mango kernel, sal), lactose and proteins from whey (milk), whey powder (milk), emulsifier (sunflower lecithin), raising agent (sodium bicarbonate), natural flavouring.'
        },
        {
            'id': '1u7xAWHtv2ugED8fvjQa',
            'name': 'Chicken And Bacon On White Bread',
            'brand': 'Simply Lunch',
            'serving_size_g': 100.0,
            'ingredients': 'White bread (55%) (wheat flour with added calcium carbonate, iron, niacin, thiamin, water, salt, yeast, emulsifiers: mono-and diglycerides of fatty acids, mono-and diacetyltartaric acid esters of mono-and diglycerides of fatty acids, flour treatment agent: ascorbic acid), mayonnaise (rapeseed oil, water, pasteurised egg yolk, spirit vinegar, sugar, salt, mustard flour), chicken (12%) (chicken, water, salt, stabiliser: triphosphates), bacon (5%) (pork, water, salt, sugar, preservative: sodium nitrite).'
        },
        {
            'id': '1uZTCJJwzF9cEbucAriW',
            'name': 'Roast Chicken & Avocado',
            'brand': 'M&S',
            'serving_size_g': 239.0,
            'ingredients': 'Wheat flour (contains gluten) (wheat flour, calcium carbonate, iron, niacin, thiamin), marinated roast British chicken breast (23%) (chicken breast, rapeseed oil, salt, black pepper, water, stabiliser: triphosphates), avocado (14%), mayonnaise (rapeseed oil, water, pasteurised egg yolk, spirit vinegar, sugar, salt, mustard flour), salad leaves, water, yeast, wheat gluten, rapeseed oil, sugar, salt, flour treatment agent (ascorbic acid).'
        },
        {
            'id': '1uw6ld7miL9W7VE9ACrY',
            'name': 'Raspberry Sponge Roll',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Buttercream (25%) (sugar, butter (cows\' milk), glucose syrup, rapeseed oil, palm stearin, humectant: vegetable glycerine, palm oil, salt, maize starch, emulsifier: mono-and diglycerides of fatty acids, natural flavouring, colour: beetroot red), sponge (wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), sugar, pasteurised egg, rapeseed oil, raising agents: E450, E500, flavouring), raspberry jam (14%) (glucose-fructose syrup, raspberry, gelling agent: pectin, acidity regulator: citric acid), water.'
        },
        {
            'id': '1v63TSsNmVgkywTs6HW4',
            'name': 'Flying Saucers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Maize starch, dextrose, sugar, acids (citric acid, malic acid), stabiliser (sodium bicarbonate), emulsifier (soya lecithin), plant extract (safflower), colours (E162, E160c, E132), anti-caking agent (magnesium stearate).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 93\n")

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

    updated = update_batch93(db_path)

    print(f"✨ BATCH 93 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1711 + updated} products cleaned")

    # Check if we hit the 1725 milestone
    total = 1711 + updated
    if total >= 1725:
        print("\n🎉🎉 1725 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
