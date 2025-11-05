#!/usr/bin/env python3
"""
Clean ingredients for batch 90 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch90(db_path: str):
    """Update batch 90 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 90: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'G74dmSILcNAniwa3mqZ7',
            'name': 'Chocolate & Orange Tarts',
            'brand': 'Mr Kipling',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (with added calcium, iron, niacin, thiamin), sugar, vegetable oils (rapeseed, palm), glucose syrup, water, dextrose, fat reduced cocoa powder, icing sugar, gold and bronze sugar pieces (sugar, colour (iron oxides and hydroxides), glazing agent (shellac), glucose syrup, water), humectant (vegetable glycerine), whey powder (milk), tapioca starch, skimmed milk powder, emulsifiers (sorbitan monostearate, polyglycerol esters of fatty acids, polysorbate 60), barley malt extract, salt, dried egg white, preservatives (potassium sorbate, sulphur dioxide), flavourings (contain sulphites), soya flour, gelling agent (sodium alginate).'
        },
        {
            'id': 'G7bHfqQiQ1IsNXSYDozW',
            'name': 'Breaded Haddock Fillets',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Haddock (fish) (55%), breadcrumbs (45%) (fortified wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), water, rapeseed oil, salt, yeast, mustard powder, wheat starch, white pepper, garlic powder, onion powder, raising agents: diphosphates, sodium carbonates).'
        },
        {
            'id': 'G8eg005e3YXwnkyfwlO6',
            'name': 'Roasted Salted Peanuts',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Peanuts (97%), rapeseed oil, salt.'
        },
        {
            'id': 'GA1D8vBgjNONM6IEbnG7',
            'name': 'Exotic Fruit Lollies',
            'brand': 'Tropico',
            'serving_size_g': 40.0,
            'ingredients': 'Exotic fruit mini lolly: skimmed milk, whey concentrate (milk), sugar, water, glucose syrup, peach puree (8%), passion fruit juice from concentrate (6%), coconut oil, mango puree (4%), pineapple juice from concentrate (4%), stabilisers: guar gum, locust bean gum, plant extracts (carrot concentrate, black carrot concentrate, curcuma extract), emulsifier: mono-and diglycerides of fatty acids, acid: citric acid, flavouring, bourbon vanilla extract. Forest fruit mini lolly: skimmed milk, whey concentrate (milk), sugar, water, glucose syrup, strawberry puree (7%), coconut oil, blackcurrant juice from concentrate (4.5%), raspberry puree (4%), blackberry puree (3.5%), blueberry puree (3.5%), stabilisers: guar gum, locust bean gum, emulsifier: mono-and diglycerides of fatty acids, glucose-fructose syrup, plant extracts (elderberry concentrate, carrot concentrate), acid: citric acid, flavouring, bourbon vanilla extract.'
        },
        {
            'id': 'GAl9pi8MLaxmMPdzP2s2',
            'name': 'Prosciutto Crudo',
            'brand': 'Morrisons',
            'serving_size_g': 90.0,
            'ingredients': 'Pork leg, salt.'
        },
        {
            'id': 'GBW1kCzQfbExeP4JQGwJ',
            'name': 'Proactiv',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable oils (rapeseed, coconut, sunflower), water, plant sterol esters (9%) (equivalent to 5.4% plant sterols), salt (0.8%), emulsifier (lecithin), natural flavourings, vitamin A and D.'
        },
        {
            'id': 'GBgPCms6smUjO5gKzAqL',
            'name': 'Pork Gyoza',
            'brand': 'Itsu',
            'serving_size_g': 20.0,
            'ingredients': 'Gyoza filling (shredded cabbage, pork shoulder (21%), pork fat (10%), white onion, soy sauce (water, soya beans, wheat, salt), spring onion, garlic, apple puree (apple, acidity regulator: citric acid, antioxidant: ascorbic acid), tofu (soya beans, water), sesame oil, yeast extract, sugar, textured soya protein, water, salt, black pepper, ginger powder), gyoza skin (wheat flour, water, tapioca starch, wheat gluten, rapeseed oil, salt).'
        },
        {
            'id': 'GBqVqx7LK7ymOiWSSQWq',
            'name': 'Jalfrezi Cooking Sauce',
            'brand': 'Tesco',
            'serving_size_g': 125.0,
            'ingredients': 'Tomato purée (30%), water, onion (13%), pepper (12%) (red pepper, green pepper), tomato, curry paste (rapeseed oil, water, sugar, onion purée, concentrated lemon juice, salt, coriander, ground ginger, ground cumin, ground coriander, ground cardamom, paprika, ground cassia, garlic powder, cumin seed, ground fennel, ground clove, chilli powder, ground fenugreek, acidity regulator: acetic acid, black pepper, black onion seed), cornflour, lemon juice from concentrate, curry powder (coriander, fenugreek, cumin seed, rice flour, salt, mustard seed, turmeric, chilli, paprika, ginger, fennel, garlic powder, cassia, bay leaf, nutmeg, black pepper, clove, onion), rapeseed oil, coriander, sugar, dried chilli, salt, ground coriander, ground cumin, acidity regulator (lactic acid), firming agent (calcium chloride).'
        },
        {
            'id': 'GBqk9LRsa53Vyvb6DUYx',
            'name': 'Choco Pops Cereals',
            'brand': 'Kellogg\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour (72%), sugar, chocolate powder (10%) (sugar, cocoa powder, fat reduced cocoa powder), glucose syrup, salt, natural flavouring, cinnamon, niacin, iron, vitamin B6, riboflavin, thiamin, folic acid, vitamin D, vitamin B12.'
        },
        {
            'id': 'GBzDuNLmgpqdB7lh5fa1',
            'name': 'Gf Cauliflower Gnocchi',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cauliflower (74%), cassava flour, potato starch, extra virgin olive oil, sea salt.'
        },
        {
            'id': 'GC0N4gL7JGXF0bLQHuNq',
            'name': 'Barretta Mem\'s Peanut',
            'brand': 'M&m\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, cocoa butter, skimmed milk powder, cocoa mass, peanuts, milk fat, lactose, whey permeate from milk, full cream milk powder, emulsifier: soya lecithin, palm fat, starch, glucose syrup, shea fat, stabiliser: gum arabic, colours: e100, e133, e160a, e162, e170, e172, dextrin, vanilla extract, glazing agent: carnauba wax, palm kernel oil, salt, flavouring.'
        },
        {
            'id': 'GCOSDw49DED1t7QtoL5F',
            'name': 'Lion\'s Mane',
            'brand': 'Happiee',
            'serving_size_g': 90.0,
            'ingredients': 'Lion\'s mane mushroom (62%), water, marinade (6%) (maltodextrin, sugar, yeast extract, modified maize starch, flavourings, salt, spice, anti-caking agent, spice extract, smoked maltodextrin, acidity regulators: lactic acid, calcium lactate).'
        },
        {
            'id': 'G5bNUr6bNUgviG75Lp8N',
            'name': 'Mango Chutney',
            'brand': 'Taste Of India',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, mango (47%), salt, acidity regulator: acetic acid, spices.'
        },
        {
            'id': 'GCclg9afLggKIz49S5L1',
            'name': 'Doritos Nacho Cheese 280g',
            'brand': 'Doritos',
            'serving_size_g': 100.0,
            'ingredients': 'Corn, rapeseed oil, sour cream flavouring from milk (5%), medium fat soft cheese from milk (4%), modified starch, acidity regulator (lactic acid), white wine vinegar, dried egg yolk, salt, garlic powder, colour (paprika extract), dried red pepper, preservative (potassium sorbate).'
        },
        {
            'id': 'GD3is1RuxBpWSHTBtAfz',
            'name': 'Chilli Non Carne',
            'brand': 'Ben\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (18%), red kidney beans (13%), onion, red pepper (10%), sweetcorn (10%), haricot beans (9.0%), black beans (6.9%), garlic, tomato paste, sunflower oil, lemon juice, sugar, yeast extract, salt, basil, cumin, parsley, natural flavouring, green chilli (0.1%), red chilli, oregano, black pepper, colour: paprika oleoresin, smoke oil.'
        },
        {
            'id': 'GDxrCm5AlcPutkgB5Byb',
            'name': 'Southern Fried Chicken Steaks',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken breast (63%), fortified wheat flour (wheat flour, calcium carbonate, iron, niacin (B3), thiamin (B1)), vegetable oils (rapeseed, sunflower), water, rice flour, pea fibre, wheat starch, salt, black pepper, fennel, dextrose, yeast, yeast extract, spice extracts, spirit vinegar powder, lemon powder, paprika, thyme extract, thyme, aniseed, flavouring.'
        },
        {
            'id': 'GE7xwIVPLVDVRV3Ft9S3',
            'name': 'Tonys Chocolate Milk Pecan Caramel Crunch',
            'brand': 'Tony\'s Chocolonely',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, dried whole milk, cocoa butter, cocoa mass, pecans (8%), caramel (3%) (sugar, glucose syrup), crunchy biscuit (2%) (wheat flour, sugar, concentrated butter (milk), lactose (milk), milk protein, salt, malt extract (barley), raising agent: sodium hydrogen carbonate), emulsifier (soya lecithin).'
        },
        {
            'id': 'GEiLA4O3d96pqefewlMy',
            'name': 'Chicken & Bacon Pasta Bake',
            'brand': 'Chef Select',
            'serving_size_g': 400.0,
            'ingredients': 'Cheese sauce (45%) (water, white mild cheddar cheese, potato starch, cream, stabilizer: carrageenan, béchamel sauce mix (modified starch, full cream milk powder, wheat flour, sugar, rapeseed oil, salt, yeast extract, onion, acidity regulator: citric acid, white pepper)), cooked rigatoni pasta (40%) (water, durum wheat semolina), chicken (11%) (chicken, water, salt), bacon (3%) (pork (98%), water, salt, preservative: sodium nitrite, dextrose, brown sugar, smoke flavoring, stabilizer: sodium triphosphate, antioxidant: sodium ascorbate).'
        },
        {
            'id': 'GEjYosaDkbALVQuJmmh3',
            'name': 'Dairy Milk Trifle Caramel',
            'brand': 'Cadbury',
            'serving_size_g': 90.0,
            'ingredients': 'Water, cream, sugar, concentrated skimmed milk, sponge (5%) (wheat flour, sugar, egg), palm oil, fat reduced cocoa powder, milk chocolate (1.5%) (milk, sugar, cocoa mass, vegetable fats (palm, shea), emulsifier: e442, flavourings), modified maize starch, dextrose, pork gelatine, dried buttermilk, emulsifiers (e472b, e471), caramelised sugar syrup, maltodextrin, stabilisers (e412, e450, e401, e407, pectin), flavouring, salt, dried glucose syrup.'
        },
        {
            'id': 'GFNrELNlAbuZPs1Xwd2I',
            'name': 'Breakfast Biscuits Soft Bakes Filled Strawberry',
            'brand': 'Belvita',
            'serving_size_g': 100.0,
            'ingredients': 'Cereals (41.1%) (wheat flour (22.1%), wholegrain cereals (16.6%) (wholegrain crushed buckwheat (13%), wholegrain wheat flour (0.9%), wholegrain barley flour (0.9%), wholegrain spelt flour (wheat) (0.9%), oat flakes (0.9%)), rice flour (2.3%), malted wheat flour (0.1%)), sugar, rapeseed oil, humectant: glycerol, bulking agents: polydextrose, wheat starch, maltitol, modified starch, inulin, glucose-fructose syrup, isomaltulose, strawberry puree concentrate (1.3%) (equivalent to 5.1% strawberry puree), starch, salt, raising agent: sodium hydrogen carbonate, emulsifier: soya lecithin, acidity regulators: citric acid, malic acid, sodium citrate, minerals: magnesium oxide, elemental iron, flavourings, wheat gluten, dextrose, black carrot juice concentrate, gelling agent: pectin, vitamins: vitamin B6 (pyridoxine), vitamin B9 (folic acid).'
        },
        {
            'id': 'GGXEx6rBvFDgAXz0EX53',
            'name': 'Soba Teriyaki Noodles',
            'brand': 'Nissin',
            'serving_size_g': 180.0,
            'ingredients': 'Noodles: wheat flour, palm oil, salt, flavour enhancer (e621), flour treatment agents (e500, e451), antioxidant (e306), acidity regulator (citric acid). Seasoning sauce: soy sauce (water, soybean, salt, wheat), sugar, rapeseed oil, dextrose, flavour enhancers (e621, e635), hydrolysed maize protein, salt, spice, colour (plain caramel), chicken meat powder, modified starch, flavourings (contain celery), cabbage, carrot, shiitake mushroom, spring onion.'
        },
        {
            'id': 'GGvMAhZfLKCU9OYSV2eE',
            'name': 'Gluten Free Prosciutto Ricotta Cappelletti',
            'brand': 'M&S',
            'serving_size_g': 125.0,
            'ingredients': 'Gluten free egg pasta (60%) (potato starch, pasteurised egg, water, vegetable fibre, pasteurised egg white, maize starch, rice flour, buckwheat flour, extra virgin olive oil, salt, yeast extract, flavouring, thickening agent: E412, guar gum), mortadella (12%) (pork (97%), curing salt (salt, preservative: sodium nitrite), dried garlic, antioxidant: E301), prosciutto (10%) (pork (99%), salt), ricotta cheese (milk) (5%), cornflour, lactose (milk), salt, skimmed milk powder, medium fat hard cheese (milk), caramelised sugar.'
        },
        {
            'id': 'GHoc49riqRNVihitB1Il',
            'name': 'BBQ Flavored Pop Crisps',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Soya flour (36%), tapioca starch, chickpea flour (11%), sunflower oil, rice flour, sugar, yeast extract powder, salt, smoked dextrose powder, paprika, garlic powder, acids (citric acid, malic acid), fructose, chilli powder, flavouring, colour (paprika extract), black pepper, rapeseed oil.'
        },
        {
            'id': 'GI3UiBpWwjWuJGS6qEaQ',
            'name': 'Tikka Paste',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, tomato purée (30%), tomato (5%), paprika, ground coriander (5%), coriander (3%), coconut (2.5%), sugar, onion powder, ginger purée, turmeric, rapeseed oil, cumin, acidity regulator (lactic acid), chilli powder, salt, fenugreek, cardamom, dried garlic, potassium chloride, black pepper, preservative (potassium sorbate), colour (paprika extract), flavouring, maltodextrin.'
        },
        {
            'id': 'GI9evEQNAfVS8bTlcGZn',
            'name': 'Nerds',
            'brand': 'Ferrara Candy Company',
            'serving_size_g': 100.0,
            'ingredients': 'Dextrose, sugar, acid: malic acid, glucose syrup, plant and vegetable concentrates (black carrot, spirulina, radish), thickener: gum arabic, glazing agent: carnauba wax, flavourings, colour: curcumin.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 90\n")

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

    updated = update_batch90(db_path)

    print(f"✨ BATCH 90 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1636 + updated} products cleaned")

    # Check if we hit the 1650 milestone
    total = 1636 + updated
    if total >= 1650:
        print("\n🎉🎉 1650 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
