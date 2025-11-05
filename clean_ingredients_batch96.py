#!/usr/bin/env python3
"""
Clean ingredients for batch 96 of messy products - DOUBLED BATCH SIZE (50 products)
"""

import sqlite3
from datetime import datetime

def update_batch96(db_path: str):
    """Update batch 96 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 96: Products with cleaned ingredients (50 products - doubled batch size!)
    clean_data = [
        {
            'id': '6kDj4sR0wspdYV31OKMS',
            'name': 'Mr Kipling Apple Pear & Custard Tarts',
            'brand': 'Mr Kipling',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, sugar, vegetable oils (rapeseed, palm), apple and pear (24%), custard (22%) (water, dried cream, apple puree, salt, thickener: cellulose, flavouring, colour: carotenes), water, glucose syrup, dextrose, humectant (vegetable glycerine), whey powder (milk), raising agent (sodium bicarbonate), emulsifier (soya lecithin), salt, flavouring.'
        },
        {
            'id': '6kUGFpDPR2HxifVsKdnk',
            'name': 'Cappuccino Unsweetened Taste Improved Recipe',
            'brand': 'Alcafe',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed milk powder (30%), lactose (milk), glucose syrup, coffee extract (17%), coconut fat, whey permeate (milk), acidity regulator: potassium carbonates, stabilisers: potassium phosphates, sodium phosphates.'
        },
        {
            'id': '6kWCCxOYmZ6V4tXgyonE',
            'name': 'Rich & Intense Tomato & Olive Stir Through Sauce',
            'brand': 'Aldi',
            'serving_size_g': 95.0,
            'ingredients': 'Black and green olives (38%), tomato puree (32%) (concentrated paste tomato pulp), sunflower oil, onions, capers, basil, sugar, garlic granules, acidity regulator: citric acid, olive oil, dried chilli, black pepper.'
        },
        {
            'id': '6lzWCVJF7u0cuM5XuwtI',
            'name': 'Greek Halkidiki And Kalamata Olives And Feta',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Pitted green Halkidiki and black Kalamata olives (74%), feta cheese (milk) (15%), vegetable oils (sunflower, refined rapeseed), coriander, lemon zest, extra virgin olive oil, lemon juice, salt, acidity regulator (lactic acid), oregano, black pepper.'
        },
        {
            'id': '6mBvLuhNHKr4hb6hGJDT',
            'name': 'Pork Faggots',
            'brand': 'Mr Brain\'s',
            'serving_size_g': 219.0,
            'ingredients': 'West country sauce (62%) (water, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), modified starch, pork lard, tomato puree, salt, colour: plain caramel, flavouring), pork (28%), pork liver, rusk (wheat flour), onion, water, salt, herbs, spices.'
        },
        {
            'id': '6ooRKBHxh0IvsjzV2pXp',
            'name': 'Goodies Banana & Date Fruit Bars 6 X',
            'brand': 'Organix Chunky Fruit',
            'serving_size_g': 100.0,
            'ingredients': 'Dates (84.3%), dried banana (15.0%), sunflower oil (0.7%).'
        },
        {
            'id': '6oxnnnMU02cW8TmhCWkD',
            'name': 'Multigrain Dino Shape',
            'brand': 'Harvest Morn',
            'serving_size_g': 100.0,
            'ingredients': 'Rice flour (56%), wholegrain oat flour (28%), sugar, maize flour (6%), soluble corn fibre, calcium carbonate, carrot juice concentrate, curcuma extract, salt, flavouring, antioxidant (tocopherol-rich extract).'
        },
        {
            'id': '6pJdaMfuiAB0w0Siam0K',
            'name': 'Tiger Baguette 200 G',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, vegetable oils (rapeseed, palm), yeast, salt, flour treatment agents (ascorbic acid, l-cysteine), wheat flour, rapeseed oil, rice flour.'
        },
        {
            'id': '6pn1hkkQP4uQQkPFA267',
            'name': 'Ricotta And Spinach Tortellini',
            'brand': 'Dell Ugo',
            'serving_size_g': 100.0,
            'ingredients': 'Pasta (60%) (durum wheat semolina, water, pasteurised free range egg (5%)), filling (40%) (ricotta cheese (milk) (42%), spinach (37%), breadcrumbs (wheat flour, water, salt, yeast), whey powder (milk), sunflower oil, salt, garlic, nutmeg, black pepper).'
        },
        {
            'id': '6qMnQRURqRm8HpSsdecJ',
            'name': 'Chocolate Spread',
            'brand': 'Nutella',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, palm oil, hazelnuts (13%), skimmed milk powder (8.7%), fat-reduced cocoa (7.4%), emulsifier: lecithins (soya), vanillin, salt.'
        },
        {
            'id': '6qRvyg91CrpWJ1zFRXfB',
            'name': 'Gut Feel Hint Of Vanilla',
            'brand': 'The Collective',
            'serving_size_g': 130.0,
            'ingredients': 'Yogurt (milk) (91%), acacia fibre, chicory root fibre, tapioca flour, natural flavouring, lemon juice, vanilla extract. Contains 14 live and active cultures including: L. bulgaricus, S. thermophilus, Bifidobacterium lactis.'
        },
        {
            'id': '6rOUhyqrO6PC30QiV76h',
            'name': 'All Butter Strawberry And Clotted Cream Shortbread',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), butter (milk) (30%), sugar, cornflour, clotted cream (milk) (4%), sweetened dried strawberry pieces (strawberries, sugar, rice flour), natural flavouring, salt.'
        },
        {
            'id': '6oKt3BmTRSAwqjfoWd66',
            'name': 'Free From Stem Ginger Cookie',
            'brand': 'Tesco',
            'serving_size_g': 19.0,
            'ingredients': 'Gluten-free oat flour (32%), sugar, vegetable oils (sustainable palm, rapeseed), crystallised ginger (10%) (ginger, sugar), rice flour, tapioca starch, raising agents (ammonium bicarbonate, sodium bicarbonate), ground ginger, natural flavouring, salt.'
        },
        {
            'id': '6nmvwL0GRBK956BrbFrL',
            'name': 'Zesty Orange Dark Chocolate',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa mass, milk fat, cocoa butter, emulsifier (sunflower lecithins), orange oil, flavouring.'
        },
        {
            'id': '6nrJmRpTcY5v9wMYy5gv',
            'name': 'Salad Cream Original',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Water, spirit vinegar, rapeseed oil (22%), sugar, mustard powder, modified cornflour, pasteurised egg yolk, salt, colour (riboflavin), flavouring.'
        },
        {
            'id': '77XO5vv5qYsN1XIslkey',
            'name': 'Vegetable Samosa Vegan Rolls',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Puff pastry (wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, vegetable oils (palm, rapeseed), emulsifiers: mono-and diglycerides of fatty acids, salt), sautéed onion, mango chutney (water, sugar, mango, salt, garlic, black onion seeds, cumin seeds, mixed spice), potato, spinach (3%), tomato, garlic purée, rapeseed oil, cumin, coriander, turmeric, chilli powder, salt, ginger.'
        },
        {
            'id': '77wHiqldk1gDSZGO7c1F',
            'name': 'Cheddar & Black Pepper Flatbread Thins',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), cheddar cheese (10%) (milk), cheese powder (9%) (cheese (milk), whey powder (milk), emulsifier: sodium phosphates), wholemeal rye flour (8%), rapeseed oil, malted wheat flour, yeast, black pepper (1%), salt, barley malt extract.'
        },
        {
            'id': '786wlLxNB3aYdo5DILtQ',
            'name': 'Costa Rica Dark Chocolate 75%',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa mass, cane sugar, cocoa butter, ground vanilla pods.'
        },
        {
            'id': '78fsA3Y9KvmLIYTB0U9m',
            'name': 'Chicken Korma & Pilau Rice',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Pilau rice (38%) (water, white rice, rapeseed oil, cumin seeds, turmeric extract, ground cardamom, ground cinnamon, ground bay leaf, ground cloves), marinated chicken (21%) (chicken breast, water, rapeseed oil, lemon juice, salt, stabiliser: triphosphates), water, single cream (milk), onion, tomato, korma paste (rapeseed oil, coconut, coriander, cumin, ginger, garlic, turmeric, salt, chilli, fennel, black pepper), cornflour, sultanas, sugar, ground almonds, desiccated coconut, salt.'
        },
        {
            'id': '79g4XGyqRvb2PSbsfo27',
            'name': 'Whole Baby Beetroot',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Baby beetroot, water, barley malt vinegar, acid: acetic acid, salt, sugar, preservative: potassium sorbate, sweetener: saccharin.'
        },
        {
            'id': '7AH8Ae1ZUbF90gj2n5rX',
            'name': 'Skipjack Tuna Chunks',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Skipjack tuna (Katsuwonus pelamis) (fish), water, salt.'
        },
        {
            'id': '7DvxcIXfjIrTSWPsBmTG',
            'name': 'Hula Hoops BBQ Beef Potato Rings',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (81%), sunflower oil (9%), rice flour, dried potato, flavouring, sugar, salt, yeast extract, paprika powder, stabiliser: hydroxypropyl methyl cellulose, ground white pepper, dried onion, dextrose.'
        },
        {
            'id': '7F6mLzEHhIsUKLFlXytY',
            'name': 'Doritos A Hint Of Paprika',
            'brand': 'Doritos',
            'serving_size_g': 30.0,
            'ingredients': 'Corn (maize), sunflower oil, hint of paprika flavour (sugar, paprika, salt, whey permeate (from milk), onion powder, potassium chloride, flavouring, colour: paprika extract, garlic powder), carob flour.'
        },
        {
            'id': '7G1vx6sdFQkMIAgHFNJ8',
            'name': 'Bacon Rashers',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (40%), sunflower oil, dried potatoes, potato starch, dried yeast extract, salt, dextrose, rice flour, fruit and vegetable concentrates (radish, carrot, red cabbage, beetroot), bacon flavouring, smoked paprika, black pepper.'
        },
        {
            'id': '7Go69grxlYFDPxSXpSai',
            'name': 'Prawn Crackers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Tapioca flour, vegetable oils (sunflower, rapeseed), prawn (crustacean) (17%), sugar, salt, garlic, raising agent (sodium carbonate).'
        },
        {
            'id': '7C1Zkw9MkIBxoy0QdWZm',
            'name': 'British Chicken Breast Slices',
            'brand': 'Ashfields',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (94%), pea starch, reduced sodium sea salt, dextrose, emulsifier: triphosphates, yeast extract, onion powder, ground black pepper, salt.'
        },
        {
            'id': '7Kgum35CGxJZcuntFzqJ',
            'name': 'Ambrosia Devon Custard 150g',
            'brand': 'Ambrosia',
            'serving_size_g': 150.0,
            'ingredients': 'Milk, buttermilk, sugar, modified starch, palm oil, whey (milk), natural flavouring, colours (curcumin, annatto norbixin).'
        },
        {
            'id': '7KhHjLo9RINc1SJJ0NDT',
            'name': '2 Smoked Haddock Gratins',
            'brand': 'Waitrose',
            'serving_size_g': 150.0,
            'ingredients': 'Smoked haddock (20%), haddock (Melanogrammus aeglefinus) (fish) (17%), extra mature white cheddar cheese (milk), water, ale (9%) (contains barley, wheat), single cream (milk), unsalted butter (milk), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), cornflour, salt, black pepper, nutmeg.'
        },
        {
            'id': '7MEJpipS3N3CVlzeDBvo',
            'name': 'Heart Shaped Waffles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, sugar, egg, margarine (vegetable oil and fat (palm), water, salt, emulsifiers: lecithin, mono-and diglycerides of fatty acids, acidity regulator: citric acid, flavouring, colour: carotenes), water, yeast, salt.'
        },
        {
            'id': '7MEopJaraYgKqiMPI6Mn',
            'name': 'Mackerel Fillets With Harissa',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Hot smoked mackerel (64%) (mackerel (fish), salt), sunflower oil, water, tomato purée, garlic powder, crushed chillies, coriander, spices, flavouring.'
        },
        {
            'id': '7NFK3nL2ytKCEx2SU8ws',
            'name': 'Slow Cooked Heritage Gold Pork Casserole',
            'brand': 'M&S Food Collection',
            'serving_size_g': 100.0,
            'ingredients': 'British pork (56%), cider and mustard sauce (20%), chestnut mushrooms (9%), silverskin onions (6%), smoked bacon (5%) (British pork belly, curing salt (salt, preservative: sodium nitrite, sodium nitrate), sugar, antioxidant: E301), water, cider (3%), single cream (milk), cornflour, Dijon mustard (water, mustard seeds, spirit vinegar, salt), chicken stock, garlic purée, thyme, black pepper.'
        },
        {
            'id': '7ON1lRBiwUtkamF5ywRi',
            'name': 'Vegetable Antipasti Pizza',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, water, mozzarella cheese (milk), marinated artichokes (10%), tomatoes, chargrilled mixed peppers (6%), wheat semolina, pitted black olives (2%), rapeseed oil, spinach, tomato purée, yeast, salt, sugar, extra virgin olive oil, garlic, oregano, basil.'
        },
        {
            'id': '7d1T66AkrRDYfnCE7lkn',
            'name': 'Classic Pork Chipolata Sausages Gluten Free Extra Special',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (90%), water, egg white, salt, rice flour, chickpea flour, spices, stabiliser (diphosphates), preservative (sodium metabisulphite), flavouring, antioxidant (ascorbic acid), cornflour, dextrose, sugar.'
        },
        {
            'id': '7dY19z9VOXOlR973gfb6',
            'name': 'Indian Spiced Veg Quinoa And Rice',
            'brand': 'Jamie Oliver',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked wholegrain basmati rice (37%) (water, wholegrain basmati rice), peas (12%), spinach (12%), cooked quinoa (11%) (water, white quinoa), tomatoes, herbs and spices (spring onion, curry powder (1.5%), turmeric, coriander, cumin, ginger, chilli), rapeseed oil, red onion, garlic, lemon juice, salt.'
        },
        {
            'id': '7dthVFChpZXFgnzL4jLc',
            'name': 'Avocado Oil Mayo',
            'brand': 'Dr. Will\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Avocado oil (65%), free range egg yolk (11%), water, apple vinegar, Dijon mustard (water, mustard seeds, spirit vinegar, salt), lemon juice, salt.'
        },
        {
            'id': '7e2nUGTzPZ6DeAvyqcnF',
            'name': 'Cherry Yogurt',
            'brand': 'Brooklea',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk) (77%), cherries (9%), sugar, water, cherry juice from concentrate (1%), modified maize starch, plant extract (black carrot concentrate), stabiliser: pectins, acidity regulators: sodium citrates, citric acid, flavouring.'
        },
        {
            'id': '7euqOgykxzAWjAaxPTxi',
            'name': 'Smooth Brussels Pate',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork liver (34%), pork (27%), water, pork fat (13%), tapioca starch, iodised salt (salt, potassium iodate), onions, dextrose, spices (mustard seeds, white pepper, ginger, cardamom, coriander, nutmeg, paprika), natural flavouring, antioxidant (sodium ascorbate), preservative (sodium nitrite).'
        },
        {
            'id': '7fZvGxca0sxboQxfelBC',
            'name': 'Fridge Raiders Poppers',
            'brand': 'Fridge Raiders',
            'serving_size_g': 68.0,
            'ingredients': 'Chicken breast (52%), cornmeal, wheat flour, vegetable oils (rapeseed, sunflower), water, rusk (wheat), salt, dried paprika, maize flour, flavourings, garlic powder, spices, starch (wheat), potato starch, raising agents (disodium diphosphate, sodium bicarbonate), yeast extract.'
        },
        {
            'id': '7fdm8qORFmNADxmJgcmO',
            'name': 'Cheddar And Onion Quiche',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Semi skimmed milk, wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), pasteurised egg, onion (10%), mature cheddar cheese (milk) (8%), extra mature cheddar cheese (milk) (7%), red Leicester cheese (milk), water, margarine (vegetable oils (palm, rapeseed), water, salt, emulsifier: mono-and diglycerides of fatty acids), modified maize starch, salt, white pepper, nutmeg.'
        },
        {
            'id': '7flr8C9HKneK5DAetapM',
            'name': 'Baked Prawn Cocktail Flavour',
            'brand': 'Walkers',
            'serving_size_g': 22.0,
            'ingredients': 'Potato flakes, starch, rapeseed oil, prawn cocktail seasoning (flavouring, sugar, yeast powder, salt, tomato powder, citric acid, onion powder, colour: paprika extract), emulsifier (lecithins), sunflower oil, colour (annatto norbixin).'
        },
        {
            'id': '7gs2b4YBXtmPXJNCLJYU',
            'name': 'Spiced Rum Mince Pies',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Mincemeat (47%) (sugar, sultanas, apple purée, raisins, glucose-fructose syrup, glucose syrup, rum, orange peel, date, palm oil, currants, ginger, lemon peel, rice flour, sunflower oil, preservative: acetic acid, spices), wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), butter (milk), water, sugar, pasteurised egg.'
        },
        {
            'id': '7hDmWC6qzvIF3KSxIUEL',
            'name': 'Datiles',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Deglet Nour dates with stones.'
        },
        {
            'id': '7iA8xs8ZBPxXP5eCgyYS',
            'name': 'Strawberry Jam',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, strawberries, acid (citric acid), gelling agent (pectin), acidity regulator (sodium citrates).'
        },
        {
            'id': '7j7SEJwak6Xk0s94Zt13',
            'name': 'Low Sugar Berry Granola',
            'brand': 'Waitrose',
            'serving_size_g': 73.0,
            'ingredients': 'Oat flakes (64%), wheat flakes (11%), rapeseed oil, maize starch, sunflower seeds (4%), chicory fibre, black treacle, freeze dried berries (2%) (cherries, redcurrants, raspberry pieces, strawberry pieces), salt, natural flavouring.'
        },
        {
            'id': '7lTm710fYWMoDJXx1l6p',
            'name': 'Blackforest Fruits',
            'brand': 'Morrisons',
            'serving_size_g': 80.0,
            'ingredients': 'Cherries (30%), blackberries (25%), blackcurrants (25%), blueberries (20%).'
        },
        {
            'id': '7m70yZzj9l1A9B7hUULl',
            'name': 'Bolognese Pasta Sauce',
            'brand': 'Aldi',
            'serving_size_g': 85.0,
            'ingredients': 'Tomato pulp (34%), tomato paste (18%), water, cherry tomato (10%), Vino Chianti DOP Chianti wine (7%), onions (4%), carrots, celery, extra virgin olive oil (1.5%), garlic purée (1.5%), olive oil, sugar, salt, acidity regulator (citric acid), basil, oregano, black pepper.'
        },
        {
            'id': '7mogwaWKrjLnGDV6zZJZ',
            'name': 'Quorn Roast Chicken Style Slices',
            'brand': 'Quorn',
            'serving_size_g': 100.0,
            'ingredients': 'Mycoprotein (83%), water, flavourings, gelling agents: agar, locust bean gum, preservative: potassium sorbate.'
        },
        {
            'id': '7nJpFajMp9vTPDHkb698',
            'name': 'Bulgur',
            'brand': 'Tesco',
            'serving_size_g': 125.0,
            'ingredients': 'Cooked bulgur wheat (52%) (water, bulgur wheat), cooked green lentils (18%) (water, green lentils), tomato, red pepper, yellow pepper, red onion, spring onion, sunflower oil, parsley, dried onion, garlic purée, salt, yeast extract, black pepper.'
        },
        {
            'id': '7nkRLUMoEdR9OJivXoZg',
            'name': 'Oats So Easy Golden Syrup',
            'brand': 'Crownfield',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flakes (81%), sugar, natural flavouring, salt.'
        },
        {
            'id': '7gQ550IntZDRAUOu97YD',
            'name': 'Lentil Bites',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Lentil flour (40%), potato starch, corn flour, rapeseed oil, salt.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 96 (DOUBLED BATCH SIZE!)\n")

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

    updated = update_batch96(db_path)

    print(f"✨ BATCH 96 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1786 + updated} products cleaned")

    # Check if we hit the 1800 milestone
    total = 1786 + updated
    if total >= 1800:
        print("\n🎉🎉 1800 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
