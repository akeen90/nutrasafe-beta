#!/usr/bin/env python3
"""
Clean ingredients for batch 89 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch89(db_path: str):
    """Update batch 89 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 89: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'Fcoqza0VrFOpkqqlD0YT',
            'name': 'Monster Claw Crisps',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Maize, high oleic sunflower oil (26%), roast beef flavour seasoning (12%) (rice flour, dried yeast extract, dried onion, dextrose, sugar, salt, dried paprika, dried carrot, acid: citric acid, ground oregano, natural flavouring, ground sage, ground black pepper, ground cinnamon, onion extract), emulsifier: mono-and diglycerides of fatty acids.'
        },
        {
            'id': 'Ffmg3ZMmYCxRblLZfDhe',
            'name': 'Zesty Lemon Sorbet',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, lemon juice from concentrate (30%), sugar, glucose syrup, fructose, lime juice from concentrate, tapioca starch, stabiliser (xanthan gum), flavouring.'
        },
        {
            'id': 'Fg26horGtbc9508FrEgi',
            'name': 'Quality Street Orange Crunch',
            'brand': 'Nestlé',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, vegetable fats (palm, palm kernel, shea), cocoa butter, dried whole milk, cocoa mass, skimmed milk powder, fat-reduced cocoa powder, glucose syrup, hazelnut paste, butterfat (milk), whey powder (milk), emulsifier (lecithins), natural flavourings, acid (citric acid).'
        },
        {
            'id': 'FgxDXxHwBpNoIaVHINKg',
            'name': 'Beef Bone Broth Powder',
            'brand': 'Freja',
            'serving_size_g': 20.0,
            'ingredients': 'Swedish beef bone broth powder (53%), bone broth, sunflower lecithin, coconut sugar, cacao powder (11%), natural flavouring, salt (0.28g), collagen (11g).'
        },
        {
            'id': 'FhVXNzFVytkOuE87iq0S',
            'name': 'Choco Leibniz',
            'brand': 'Bahlsen',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, wheat flour, cocoa mass, cocoa butter, butter (3.7%), glucose syrup, whey products (milk), clarified butter, raising agents (sodium carbonates, diphosphates), emulsifier: lecithins (soya), whole milk powder, salt, acid: citric acid, flavourings, hen\'s egg yolk powder.'
        },
        {
            'id': 'FhlZYAkwUJG8Nv2W3MP8',
            'name': 'GF Cod Goujons',
            'brand': 'Whitby Seafoods',
            'serving_size_g': 112.5,
            'ingredients': 'Cod (50%), water, rice flour, gram flour, maize starch, potato starch, maize flour, rapeseed oil, salt, dextrose, black pepper, raising agents: E450, E500, thickener: E415.'
        },
        {
            'id': 'FhligaDcgfzUtiogrmcO',
            'name': 'Sourdough',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 50.0,
            'ingredients': 'Fortified British wheat flour (wheat flour, calcium carbonate, niacin, iron, thiamin), water, rye flour, salt, wholemeal wheat flour, malted wheat flour, wheat gluten.'
        },
        {
            'id': 'FkRtHyw049VTVz8O9NSg',
            'name': 'Magnum',
            'brand': 'Magnum',
            'serving_size_g': 100.0,
            'ingredients': 'Reconstituted skimmed milk, sugar, water, cocoa butter, cocoa mass, coconut fat, glucose-fructose syrup, glucose syrup, whole milk powder, whey solids (milk), butter oil (milk), emulsifiers (e471, lecithins (contains soy), e476), exhausted vanilla bean pieces, stabilisers (guar gum, locust bean gum, carrageenan), natural vanilla flavouring (with milk), flavouring, colour (carotenes).'
        },
        {
            'id': 'Ff5e2P1ROdtijPNEvgnz',
            'name': 'Pickle Flavoured Ketchup',
            'brand': 'Heinz',
            'serving_size_g': 15.0,
            'ingredients': 'Tomatoes (14g per 100g tomato ketchup), vinegar, sugar, salt, natural dill flavour, onion powder, spice and herb extracts (celery), spice, natural flavouring.'
        },
        {
            'id': 'Fl6JiaZaiChEpS2JRx2f',
            'name': 'Fuel High Protein Porridge Apple And Cinnamon',
            'brand': 'Fuel',
            'serving_size_g': 70.0,
            'ingredients': 'Rolled oats (66%), skimmed milk powder, sugar, milk protein concentrate, freeze dried apple pieces (1.5%), ground cinnamon powder (0.2%).'
        },
        {
            'id': 'FlmiFVLhVrwxet5VaeAG',
            'name': 'Moroccan Inspired Couscous',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Water, cooked giant couscous (water, durum wheat flour, rapeseed oil), wholewheat couscous, roasted red pepper (6%), cooked chickpeas (5%) (chickpeas, water, salt), raisins, apricot (sulphites), sugar, rapeseed oil, red onion, cranberries, lemon purée, red chilli, sea salt, paprika, cayenne pepper.'
        },
        {
            'id': 'Fm5PfxWYvSua19MDou5h',
            'name': 'Perfect For Cakes',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Vegetable oils in varying proportions (70%) (rapeseed oil, palm oil, sunflower oil), water, salt (1.3%), buttermilk, acid: citric acid, emulsifier: mono-and diglycerides of fatty acids, flavouring, vitamin A, vitamin D, colour: carotenes.'
        },
        {
            'id': 'FmzK6TS1Fk2Ib5FGeNEH',
            'name': 'Summer Fruits Squash Litres',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, apple juice from concentrate (16%), citric acid, strawberry juice from concentrate (1%), raspberry juice from concentrate (1%), acidity regulator (sodium citrates), flavourings, sweeteners (acesulfame K, sucralose), preservatives (potassium sorbate, sodium metabisulphite), plant concentrates (black carrot, hibiscus), antioxidant (ascorbic acid).'
        },
        {
            'id': 'FnEmuJ0kr8T7DetjqvHi',
            'name': 'Mango & Lime Roast Chicken Burger Fillets',
            'brand': 'Tesco',
            'serving_size_g': 75.0,
            'ingredients': 'Chicken breast (88%), sugar, rapeseed oil, maltodextrin, cornflour, salt, flavouring, onion powder, rice flour, dried red pepper, ginger, potato starch, dextrose, stabilisers (pentasodium triphosphate, pentapotassium triphosphate), citric acid, dried garlic, garlic powder, mango juice powder, coriander leaf, spirit vinegar powder, burnt sugar, lemon juice powder, lime juice powder.'
        },
        {
            'id': 'FnUIpsUB85W3clYpsOHr',
            'name': 'Light Greek Style Lemon Yogurts',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (78%) (milk), water, modified maize starch, coconut powder (0.5%) (contains milk), gelatine, flavourings (contains milk), sweetener: aspartame, stabiliser: pectins, acidity regulator: citric acid, vanilla pods.'
        },
        {
            'id': 'FoUa6UJuRZF8yeT5axAp',
            'name': 'Chow Mein Stir Fry Sauce',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Water, sugar, dark soy sauce (7%) (water, salt, sugar, barley malt extract, defatted soya bean flakes, colour: plain caramel, yeast extract), spirit vinegar, roasted wheat, ginger purée (4.5%), spring onion (4.5%), modified maize starch, garlic purée (3.5%), onion purée (3%), toasted sesame oil, red chilli paste (1%) (red chilli peppers, salt, acidity regulator: acetic acid), colour: plain caramel, yeast extract paste, acidity regulator: citric acid.'
        },
        {
            'id': 'Fp9nSh7EpvrF0xD24WKO',
            'name': 'Galaxy Vegan Hot Choc',
            'brand': 'Galaxy',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, maltodextrin, dried glucose syrup, fat reduced cocoa powder (10%), coconut oil, soya, E466, E340, flavourings, anti-caking agents (E551, E341), salt, potassium chloride, emulsifier: E472e, magnesium sulfate, modified starch, sweetener: E955, protein, stabilizers (E412).'
        },
        {
            'id': 'Fq2XutJ6dxznp3pahppz',
            'name': 'Banana Raisin Oaty Fingers',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Organic wholegrain oats (42%), organic dried bananas (23%), organic malted barley extract (14%), organic raisins (12%), organic palm oil (6%), organic sunflower oil (3%).'
        },
        {
            'id': 'FqwxvvEpw2QFmcY5pETQ',
            'name': 'Milk Collection Organic',
            'brand': 'Green & Black\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Raw cane sugar, whole milk powder, cocoa butter, cocoa mass, chopped roasted almonds, emulsifier: soya lecithin, glucose syrup, salted butter, palm oil, Anglesey sea salt, vanilla extract, molasses, natural flavouring, vanilla pod.'
        },
        {
            'id': 'Frc7oRnEv7ytTang3AXj',
            'name': 'Golden Vegetable Rice',
            'brand': 'Morrisons',
            'serving_size_g': 125.0,
            'ingredients': 'Cooked long grain rice (82%) (water, long grain rice), red pepper (5%), carrot (4%), sweetcorn (3%), peas (2%), vegetable oils (sunflower, rapeseed), yeast extract, onion powder, sugar, colour (curcumin), flavouring, stabiliser (guar gum), salt, maltodextrin, garlic powder, carrot powder, spices.'
        },
        {
            'id': 'FrxwZPqQMMq7PVe1HyNU',
            'name': 'Sea Salt And Vinegar Handcooked Crisps',
            'brand': 'The British Crisp Company',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, vegetable oil (sunflower, rapeseed in varying proportions), salt & vinegar flavouring (rice flour, salt, acidity regulator: sodium diacetate, dextrose, citric acid: E330).'
        },
        {
            'id': 'FsAksiXFobp65523iGyq',
            'name': 'Hula Hoops BBQ',
            'brand': 'KP Snacks',
            'serving_size_g': 24.0,
            'ingredients': 'Potato (potato starch, dried potato), sunflower oil (24%), rice flour, barbecue beef flavour (salt, rice flour, dried yeast extract, dried whey (milk), dried onion, potassium chloride, sugar, natural flavourings, dried tomato, colour: paprika extract), maize flour, natural flavouring (contains potassium chloride, salt, maltodextrin, dried onion, salt).'
        },
        {
            'id': 'FsI0vrD4cBLDJbSmkKnH',
            'name': 'Biomel Complete Gut',
            'brand': 'Biomel',
            'serving_size_g': 15.0,
            'ingredients': 'Fibre blend (91%) (apple fibre, beta glucan, chicory root fibre, guar fibre, rice bran, soluble corn fibre), vitamin blend (B6 (pyridoxine HCL), B12 (methylcobalamin), D (plant-derived cholecalciferol), calcium (tricalcium phosphate)), culture blend (0.8%) (Bacillus coagulans, Bifidobacterium bifidum, Bifidobacterium lactis, Bifidobacterium longum, Lactobacillus acidophilus, Lactobacillus bulgaricus, Lactobacillus casei, Lactobacillus gasseri, Lactobacillus paracasei, Lactobacillus plantarum, Lactobacillus reuteri, Lactobacillus rhamnosus, Streptococcus thermophilus), enzyme blend (0.3%) (amylase, protease, lipase, cellulase, lactase).'
        },
        {
            'id': 'FsNu7l29k82FMQ5lwG0j',
            'name': 'Crunchy Peanut Butter',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Peanuts (100%).'
        },
        {
            'id': 'FswZv82Ic4bCrAPnJQ29',
            'name': 'Prawn Bhuna With Saffron Pilau Rice',
            'brand': 'Tesco',
            'serving_size_g': 371.0,
            'ingredients': 'Cooked saffron pilau rice (water, basmati rice, ginger purée, rapeseed oil, cardamom powder, saffron, colour: curcumin), king prawn (crustacean) (13%), tomato, tomato purée, onion, red pepper, rapeseed oil, tomato juice, water, garlic purée, salt, cumin powder, coriander, coriander powder, ginger purée, cornflour, green chilli purée, turmeric, muscovado sugar, acidity regulator: sodium bicarbonate, cumin seed, black pepper, concentrated lemon juice, cinnamon, clove powder, chilli flakes, chilli powder, fennel, nigella seed, cardamom powder, bay leaf, butter, milk.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 89\n")

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

    updated = update_batch89(db_path)

    print(f"✨ BATCH 89 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1611 + updated} products cleaned")

    # Check if we hit the 1625 milestone
    total = 1611 + updated
    if total >= 1625:
        print("\n🎉🎉 1625 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
