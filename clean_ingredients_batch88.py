#!/usr/bin/env python3
"""
Clean ingredients for batch 88 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch88(db_path: str):
    """Update batch 88 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 88: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'F6PIWxCgDaNcBjsOxcZF',
            'name': 'ASDA Golden Vegetable Savoury Rice',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Long grain rice (86%), dried vegetables 6% (peas, carrot, red pepper, onion), maltodextrin, flavourings (contains wheat, celery), palm oil, ground turmeric, salt, dried garlic, onion powder, colour (paprika extract).'
        },
        {
            'id': 'Ezu7PEIH1tXWc8X39RUG',
            'name': 'Multigrain Cheerios',
            'brand': 'Cheerios',
            'serving_size_g': 100.0,
            'ingredients': 'Whole grain oat flour (29.6%), whole grain wheat (29.6%), whole grain barley flour (17.9%), sugar, wheat starch, invert sugar syrup, whole grain maize flour (2.1%), whole grain rice flour (2.1%), molasses, calcium carbonate, sunflower oil, salt, colours: carotene, annatto norbixin, caramelized sugar syrup, antioxidant (tocopherols), iron, vitamin C, B3, B5, B9, B6, B2.'
        },
        {
            'id': 'F7xnYvkwLk4JwERfqkTn',
            'name': 'Yeo Valley Mango & Vanilla Yogurt',
            'brand': 'Yeo Valley',
            'serving_size_g': 100.0,
            'ingredients': 'Organic whole MILK yogurt, organic mango purée (5%), organic sugar (5%), organic maize starch, organic concentrated lemon juice, organic vanilla extract, natural flavouring.'
        },
        {
            'id': 'F8Lf2MULfnZ2inSsej9a',
            'name': 'Sparkling Water',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Spring Water, Acid: Citric Acid, Flavourings (Blood Orange, Orange), Acidity Regulator: E331, Preservative: E202, Sweetener: Steviol Glycosides (from Stevia).'
        },
        {
            'id': 'F8ZETYglZkEb2hFehSB1',
            'name': 'Chicken Shawarma',
            'brand': 'Chef Select',
            'serving_size_g': 380.0,
            'ingredients': '29% Cooked Bulgur Wheat (Water, Bulgur Wheat), 22% Green Lentils, 20% Turmeric Couscous (Water, Couscous (Wheat), Turmeric), 20% Shawarma Chicken (94% Cooked Chicken (Chicken, Salt), Rapeseed Oil, Cumin, Paprika, Mint, Coriander), Carrot, Grilled Aubergine, Sultanas (Sultanas, Sunflower Oil), Salt, Parsley, Mint, Cinnamon, 7% Mint Yogurt (Water, Natural Yogurt (Milk), Rapeseed Oil, Sugar, Spirit Vinegar, Tapioca Starch, Mint, Salt, Garlic Purée), Zinc, Niacin, 3% Pickled Red Cabbage (Red Cabbage, Spirit Vinegar, Water, Sugar).'
        },
        {
            'id': 'F8jTE6mUKLB9lTtxaxv8',
            'name': 'Strawberry Shortcake',
            'brand': 'Müller',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), sugar, water, wheat flour (gluten), cocoa butter, milk powder, coconut oil, salt, modified starch, flavourings, glazing agents: acacia gum, shellac, whey powder (milk), emulsifier: soya lecithin, salt, stabiliser: pectins, colour: carmines.'
        },
        {
            'id': 'F91Ftn5aNsoVg4TetABP',
            'name': 'Barley Water Lemon Squash',
            'brand': 'Robinsons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Lemon Juice from Concentrate (17%), Barley Flour (2.5%), Acid (Citric Acid), Sweetener (Saccharin), Natural Flavouring.'
        },
        {
            'id': 'F9TNx7URCCXjOZfQIrUS',
            'name': 'Chocolate Batons',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa solids (cocoa butter, cocoa mass), sugar, full cream milk powder, emulsifier (soya lecithin).'
        },
        {
            'id': 'F9ipGkVvhUiHcUP1NNQO',
            'name': 'Tesco Salted Caramel Churro Flavour Popcorn Light',
            'brand': 'Tesco',
            'serving_size_g': 25.0,
            'ingredients': 'Maize, Sugar, Rapeseed Oil, Milk Sugar, Sea Salt, Buttermilk Powder (Milk), Yeast Extract Powder, Caramelised Sugar, Salt, Acidity Regulator (Citric Acid), Cinnamon, Paprika Extract, Molasses Extract, Flavouring.'
        },
        {
            'id': 'FAhxqO6vYSkhhiwWPJoY',
            'name': 'TREK Power Chocorange Bar',
            'brand': 'Trek',
            'serving_size_g': 100.0,
            'ingredients': 'Soya protein isolate (23%), Chocolate alternative (dates, Cocoa butter, cocoa mass, tigernuts, rice flour, emulsifier: Sunflower lecithin, natural flavouring) (14%), Vegan caramel (glucose syrup, cane sugar, water, coconut oil, stabiliser: glycerol, coconut milk powder, apple fibres, salt, emulsifier: sunflower lecithin) (13%), Peanut butter, Chicory fibre, Dates, Date syrup, Cocoa crispies (soya protein isolate, cocoa, tapioca starch) (3.5%), Cashews, Concentrated grape juice, Rice starch, Cocoa powder, Natural flavouring, Orange oil (0.15%).'
        },
        {
            'id': 'FBNviluKPkdKI1HDTf5p',
            'name': 'Tomato & Mascarpone Sauce',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tomatoes, Cheese (Milk), Sugar, Modified Maize Starch, Mascarpone Cheese (Milk), Whey Powder (Milk), Acidity Regulator (Sodium Citrates), Salt, Garlic, Vegetables, Potato, Basil, Flavouring, Chilli Powder, Concentrated Carrot.'
        },
        {
            'id': 'FBnWysOjbNFGdgAu7NBG',
            'name': 'Pumpkin Crispy Fritters',
            'brand': 'Itsu',
            'serving_size_g': 40.0,
            'ingredients': 'Pumpkin 38%, water, panko breadcrumbs 13% (wheat flour, salt, yeast, sugar), miso 7% (water, soya beans, rice, salt, alcohol), wheat flour, edamame beans (soya) 6%, red pepper, onion, linseeds 3%, rapeseed oil, chives, tapioca starch, ginger, yeast extract, black pepper, dried parsley.'
        },
        {
            'id': 'FBvPYuPg7hxGWcZA3R9v',
            'name': 'Puff Pastry',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, vegetable fats (palm, rapeseed), water, salt.'
        },
        {
            'id': 'FDaBKyfJD8D0tRmFLeyq',
            'name': 'Crisp Rice Bar',
            'brand': 'Harvest Morn',
            'serving_size_g': 20.0,
            'ingredients': 'Rice, Oligofructose, Skimmed Milk Fat Glaze (Palm Kernel Fat, Sugar, Skimmed Milk Powder, Dried Glucose Syrup, Stabiliser: Calcium Carbonate, Emulsifier: Lecithins), Glucose Syrup, Sugar, Skimmed Milk, Palm Oil, Calcium Carbonate, Humectant: Glycerol; Barley Malt Extract, Salt, Emulsifier (Lecithins), Natural Vanilla Flavouring, Vitamin D.'
        },
        {
            'id': 'FDbF4Dg6VnQKHa7oppgc',
            'name': 'Muesli Bars Chocolate & Banana',
            'brand': 'Crownfield',
            'serving_size_g': 25.0,
            'ingredients': '24% milk chocolate couverture (sugar, cocoa mass, cocoa butter, whole milk powder, skimmed milk powder, clarified butter, emulsifier: lecithins, natural vanilla flavor), glucose-fructose syrup, 15.4% wheat-rice-corn crispies (wheat flour, rice flour, barley malt flour, sugar, corn flour, table salt), 14.1% whole grain cereal flakes (oat flakes, wheat flakes, barley flakes), 5.2% whole wheat crispies (whole wheat flour), 5% banana chips (2.9% banana, coconut oil, sugar), 4.8% cornflakes (corn, table salt, barley malt extract), sunflower oil, humectant: glycerin, sugar, peanuts chopped roasted, honey, natural flavor, emulsifier: lecithins, caramel sugar syrup (glucose syrup, sugar), table salt.'
        },
        {
            'id': 'FEkWN1eap63Dd8691CTo',
            'name': 'Linwoods Cold Milled Flaxseed, Sunflower, Pumpkin & Chia Seeds & Goji Berries',
            'brand': 'Linwoods',
            'serving_size_g': 20.0,
            'ingredients': '46% organic flaxseed, 15% organic sunflower seeds, 15% organic pumpkin seeds, 12.5% organic chia (Salvia hispanica) seeds, 10% organic sun-dried goji berries, waxy maize starch.'
        },
        {
            'id': 'FF5JelJWKUBCBT42T3e4',
            'name': 'Smoked Salmon And Cream Cheese',
            'brand': 'Tesco Finest',
            'serving_size_g': 200.0,
            'ingredients': 'Wheat flour [wheat flour, calcium carbonate, iron, niacin, thiamin], smoked salmon (26%) [salmon (fish), sea salt, demerara sugar], water, full fat soft cheese (milk) (11%), oats, rapeseed oil, barley flakes, wheat bran, cornflour, yeast, pasteurised egg yolk, salt, wheat gluten, white wine vinegar, spirit vinegar, emulsifiers (mono - and di-glycerides of fatty acids, mono - and di-acetyl tartaric acid esters of mono - and di-glycerides of fatty acids), lemon zest, concentrated lemon juice, mustard flour, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'FG0KPYHnkczNINYN3y1Y',
            'name': 'Free Peach Passion Fruit 0% Fat & 0% Added Sugar Yogurt 4 X',
            'brand': 'Danone',
            'serving_size_g': 115.0,
            'ingredients': 'Yogurt (Milk), Peach (7%), Passion Fruit (1%), Potato and Tapioca Starch, Modified Maize Starch, Acidity Regulators (Sodium Citrate, Lactic Acid), Stabilisers (Carrageenan), Sweeteners (Acesulfame K, Sucralose), Flavourings, Colour (Paprika Extract), Vitamin D.'
        },
        {
            'id': 'FGWeQhnzTmWIT8w4qPco',
            'name': 'Coop Corned Beef Hash',
            'brand': 'Co-op',
            'serving_size_g': 400.0,
            'ingredients': 'Roasted diced potatoes (29%) (potato, rapeseed oil, black pepper), onion (22%), corned beef (21%) (beef, preservatives (potassium lactate, sodium acetate, sodium nitrite), spirit vinegar, salt), potato (20%), water, cornflour, Worcester sauce (water, spirit vinegar, sugar, tamarind paste, onion, garlic, ginger, concentrated lemon juice, ground cloves, chili), tomato ketchup (tomato, spirit vinegar, sugar, salt, pepper extract, celery extract, pepper), tomatoes, butter (milk), beef stock (water, beef extract, salt, yeast extract, sugar, beef fat, tomato paste, onion, carrots, onion juice concentrate), tomato purée, Dijon mustard (water, mustard seeds, spirit vinegar, salt), rapeseed oil, black pepper.'
        },
        {
            'id': 'FGaWO4YT8EhvmH1zbxVD',
            'name': 'Luxury Hot Cross Buns',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), 23% Orange Juice Soaked Fruits (Sultanas, Raisins, Currants, Orange Juice from Concentrate), Water, 7% Orange Juice Soaked Flame Raisins (Flame Raisins, Orange Juice from Concentrate), Yeast, Butter (Milk), 2.5% Mixed Peel (Orange, Lemon Peel), Wheat Gluten, Palm Oil, Potato Dextrin, Salt, Rapeseed Oil, Sugar, Cane Molasses, Honey, Natural Flavouring, Palm Fat, Soya Flour, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': 'FGspzZygJgvPwCJG5trV',
            'name': 'The Ghast BBQ',
            'brand': 'Doritos',
            'serving_size_g': 100.0,
            'ingredients': 'Corn (Maize), Rapeseed Oil, BBQ Sweet Tang Flavour [Dextrose, Acids (Sodium Acetates, Citric Acid, Malic Acid), Tomato Powder, Paprika Powder, Onion Powder, Hydrolysed Vegetable Protein, Sugar, Flavour Enhancer (Monosodium Glutamate), Potassium Chloride, Flavouring, Garlic Powder, Salt, Molasses Powder, Smoked Maltodextrin, Smoked Sunflower Oil, Colour (Paprika Extract)], Antioxidants (Rosemary Extract, Ascorbic Acid, Tocopherol Rich Extract, Citric Acid).'
        },
        {
            'id': 'FGtpTM37oD2gu06fWBvW',
            'name': 'Veggie Biryani',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Mushrooms 19%, Vegetable Stock 16%, Organic Sweet Potatoes 14%, Organic Onions 11%, Organic Tomatoes 11%, Cooked Rice 15%, Organic Cooked Lentils 7% (Water, Organic Red Lentils), Organic Mangoes 4%, Organic Spinach 2%, Organic Extra Virgin Olive Oil 1%, Organic Herbs and Spices.'
        },
        {
            'id': 'FH040cPTSEowT7bomYVi',
            'name': 'British Banana Flavoured 1% Milk',
            'brand': 'Cowbelle',
            'serving_size_g': 200.0,
            'ingredients': '1% fat milk (95%), sugar, skimmed milk powder, concentrated banana juice, stabilisers: carrageenan, xanthan gum, calcium sulphate, flavourings, colour: carotenes.'
        },
        {
            'id': 'FHKICyBD14uNp8hW4Tq2',
            'name': 'Free From Jammy Wheels',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oat Flour, Sugar, Raspberry Filling (14%) (Fructose, Humectant (Glycerol), Dextrose, Glucose Syrup, Raspberry Concentrate, Palm Oil, Acidity Regulators (Citric acid, Sodium citrate, Calcium citrate), Gelling Agent (Pectin), Colour (Anthocyanins), Emulsifiers (Polyphosphates, Polysorbate 60), Flavouring), Palm Fat, Potato Starch, Rapeseed Oil, Soya Flour, Tapioca Flour, Palm Oil, Partially Inverted Sugar Syrup, Flavouring, Stabiliser (Xanthan gum), Raising Agent (Sodium hydrogen carbonate), Salt, Emulsifier (Mono - and diglycerides of fatty acids - Vegetable).'
        },
        {
            'id': 'FHd1lEkhNyq9AFXU17LT',
            'name': 'Aldi Hot Smoked Salmon Lemon Herb',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'ATLANTIC SALMON (Salmo salar) (FISH) 98%, Salt, Lemon Zest, Dried Parsley, Flavouring.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 88\n")

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

    updated = update_batch88(db_path)

    print(f"✨ BATCH 88 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1586 + updated} products cleaned")

    # Check if we hit the 1600 milestone
    total = 1586 + updated
    if total >= 1600:
        print("\n🎉🎉 1600 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
