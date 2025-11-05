#!/usr/bin/env python3
"""
Clean ingredients for batch 85 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch85(db_path: str):
    """Update batch 85 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 85: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'DvGMtDiieWcl3HeAjs0v',
            'name': 'Potato Cakes',
            'brand': 'Warburtons',
            'serving_size_g': 45.0,
            'ingredients': 'Wheat flour (with calcium, iron, niacin B3 and thiamin B1), water, dehydrated potato, salt, emulsifier: e471.'
        },
        {
            'id': 'DvkO2kdrt2HpeOV6566O',
            'name': 'Farmhouse Butter',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Whey Butter (Cows\' Milk) 98%, Salt 2%.'
        },
        {
            'id': 'DpKY8eqbunU2VQ7pM6n3',
            'name': 'Soy Bean Spaghetti',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Organic soya beans (100%).'
        },
        {
            'id': 'Dvj2UMHRy6VQ4Hju0cpq',
            'name': 'Morrison\'s Melton Mowbray Large Pork Pie',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (34%), Wheat flour (wheat flour, calcium carbonate, iron, niacin, thiamin), Water, Pork lard, Pork fat, Potato starch, Palm oil, Rapeseed oil, Salt, Ground white pepper, Pork gelatine, Pasteurised egg, Ground nutmeg.'
        },
        {
            'id': 'DvmfMgyC6sGCXghnbS5y',
            'name': 'Bluey Fromage Frais Strawberry',
            'brand': 'Bluey',
            'serving_size_g': 100.0,
            'ingredients': 'Fromage Frais (MILK), Water, Strawberry Purée (4.5%), Sugar, Cornflour, MILK Mineral Concentrate, Flavourings, Colour (Anthocyanins), Concentrated Lemon Juice, Lactase Enzyme, Vitamin D.'
        },
        {
            'id': 'DxTtg85K3m7wZdXKb95f',
            'name': 'Mrs Crimble\'s Coconut Macaroon',
            'brand': 'Mrs Crimble\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Coconut (29%), glucose syrup, sugar, rice flour, humectants (sorbitol, glycerol), potato starch, water, dextrose, modified starch.'
        },
        {
            'id': 'Dxd2bCNhxCueH4MNhvoc',
            'name': 'Dried Blueberries',
            'brand': 'Supervalue Musgraves',
            'serving_size_g': 30.0,
            'ingredients': 'Dried Blueberries 100% (Blueberries, Sugar, Vegetable Oils in varying proportions (Sunflower, Rapeseed)).'
        },
        {
            'id': 'DzFaZwvtEpNa64VQsgYL',
            'name': 'Lemon And Raspberry',
            'brand': 'Robinsons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Fruit Juices from Concentrate (Apple 11%, Lemon 6%, Raspberry 3%), Acid (Citric Acid), Natural Lemon and Raspberry Flavourings with other Natural Flavourings, Acidity Regulator, Preservatives (Potassium Sorbate, Sodium Metabisulphite), Sweeteners (Sucralose, Acesulfame), Stabilizer (Cellulose Gum), Natural Colour (Anthocyanins), Apple and Hibiscus Concentrate, Emulsifier (Esters of Wood Rosins).'
        },
        {
            'id': 'DzRnziew1xTyyW6YP98h',
            'name': 'Chocolate Victoria Sponge Cakes Chocolate Flavour Fain',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Rapeseed Oil, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Egg, Fat-Reduced Cocoa Powder, Palm Oil, Wheat Starch, Palm Fat, Raising Agents (Diphosphates, Calcium Phosphates, Potassium Carbonates), Emulsifiers (Mono-and Diglycerides of Fatty Acids, Polyglycerol Esters of Fatty Acids, Soya Lecithins), Whey Powder (Milk), Salted Butter (Butter (Milk), Salt), Dextrose, Salt, Preservative (Potassium Sorbate), Stabiliser (Xanthan Gum), Acidity Regulator (Citric Acid), Soya Flour, Cornflour, Flavourings, Colours (Annatto Bixin, Curcumin).'
        },
        {
            'id': 'E07TnGn0vXvQEMUvC0Lw',
            'name': 'Mini Mint Crisp',
            'brand': 'Terry\'s',
            'serving_size_g': 28.0,
            'ingredients': 'Sugar, cocoa mass, cocoa butter, skimmed milk powder, whey powder from milk, vegetable fats (palm, shea), milk fat, emulsifiers (soya lecithin, e476), rice starch, gum arabic, flavourings, whole milk powder, glucose syrup.'
        },
        {
            'id': 'E0AEsVXOC5V99F3hjjyJ',
            'name': 'Mango Chutney',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Mango (44%), Salt, Acid (Acetic acid), Paprika, Chilli Powder, Cardamom.'
        },
        {
            'id': 'E0FngNGghnWttVfxleq8',
            'name': 'Seasonal Pears',
            'brand': 'Stockwell Co',
            'serving_size_g': 100.0,
            'ingredients': 'Tomato purée (55%), water, reconstituted whey powder (milk), sugar, modified maize starch, rapeseed oil, salt, antioxidant (ascorbic acid), acidity regulator (citric acid), mustard flour, capsicum extract, clove extract, flavouring, oregano extract, garlic oil.'
        },
        {
            'id': 'E0r8uKAX6buYamvw950d',
            'name': 'Red Fruit Crunch',
            'brand': 'Whole Earth',
            'serving_size_g': 100.0,
            'ingredients': 'Organic whole oat flakes (42%), organic raw cane sugar, organic coconut, organic whole wheat flour, organic rice syrup, organic sunflower oil, organic crisp rice (organic rice flour), organic freeze dried red fruit 3.5% (in changeable weights: organic red currant, organic raspberries, organic strawberries), sea salt, antioxidant: tocopherol-rich extract.'
        },
        {
            'id': 'E1FQTWLlpqx0wZ7VXod2',
            'name': 'Fruit And Nut Bar Almond And Apricot',
            'brand': 'B Good',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt coating (milk) 30% (sugar, vegetable fat (palm kernel, palm, shea), yoghurt powder (milk), emulsifier: sunflower lecithin, natural flavouring), dried apricot 17% (apricot, rice flour), glucose syrup, desiccated coconut, nuts 10% (almonds), crispies (rice, sugar, pea protein extract, chickpea, salt), honey, sugar, emulsifier (sunflower lecithin).'
        },
        {
            'id': 'Dvtd12SmHukW3GSKuKsY',
            'name': 'Creamy Butternut Squash Linguine',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Butternut Squash and Sage Sauce Sachet 33%: Butternut Squash, Water, Onions, Single Cream (Milk) 8%, Mature Cheddar Cheese (Milk), Lemon Juice, Low Fat Soft Cheese (Soft Cheese (Milk), Salt), Garlic Purée, Rapeseed Oil, Salt, Sugar, Sage, Cornflour, Maltodextrin, Flavouring, Yeast Extract, Onion Powder. Cooked Wholewheat Linguine 32%: Water, Durum Whole Wheat Semolina, Rapeseed Oil. Marinated Butternut Squash 15%: Butternut Squash, Garlic Purée, Rapeseed Oil, Parsley, Sage. Red Onions, Green Beans, Baby Spinach, Garlic.'
        },
        {
            'id': 'E1Y2IU6hE9NTT9gN8ca3',
            'name': 'Honey Roast Peanuts',
            'brand': 'Snackrite',
            'serving_size_g': 30.0,
            'ingredients': 'Peanuts, honey, sugar, salt.'
        },
        {
            'id': 'E2iLySKFyXwHVWSgyOp1',
            'name': 'Puy Lentil & Mixed Mushroom Bolognese With Basil & Sundried Tomato',
            'brand': 'Merchant Gourmet',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Puy Lentils (37%) (Water, Puy Lentils), Cooked Brown Lentils (28%) (Water, Brown Lentils), Carrots (8%), Mushrooms (8%), Onions, Chopped Tomatoes (3.6%) (Tomato, Tomato Juice), Tomato Paste (3.6%), Sundried Tomato Paste (2.1%) (Tomato Puree, White Wine Vinegar, Garlic Purée, Rapeseed Oil, Salt, Sugar, Sundried Tomato Powder (0.1%)), Water, Onion Powder, Natural Flavouring, Black Pepper, Rosemary, Cornflour, Red Wine Vinegar, Roasted Garlic Purée, Onion Powder, Vegetable Bouillon (Salt, Yeast Extract, Dextrose, Potato Starch, Onion Extract, Carrot Powder, Parsley, Spice Extracts [Pepper, Celery], Colour [Curcumin], Herb Extracts [Marjoram, Thyme, Sage]), Yeast Extract Powder, Rehydrated Mushrooms (0.4%) (Yellow Boletus, Oyster, Black Fungus, Ceps), Basil (0.2%), Colour (Paprika Extract), Bay Leaf, Black Pepper, Dried Oregano (0.1%), Thyme, Turmeric Extract.'
        },
        {
            'id': 'E32xysZeu9TNjlx5m8BB',
            'name': 'Medium Noodles Wok Ready Imp',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Wheat Flour, Wheat Gluten, Sunflower Oil, Salt, Acidity Regulator (Lactic Acid), Stabiliser (Guar Gum).'
        },
        {
            'id': 'E4cdikVwqDF5dWZPwRcM',
            'name': 'Corned Beef',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked beef, salt, preservative: sodium nitrite.'
        },
        {
            'id': 'E5QkKNLdAnTGiFAY9khc',
            'name': 'Smooth Peanut Butter',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Roasted peanuts (99.5%), sea salt.'
        },
        {
            'id': 'E5yQOdwucRJLDKgwFoZx',
            'name': 'Apple Strudel',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '45% apple, wheat flour, vegetable margarine (palm fat, water, vegetable oil (rapeseed oil, palm oil), emulsifier: mono - and diglycerides of fatty acids), water, sugar, 3% sultanas, modified potato starch, breadcrumbs (wheat flour, water, salt, yeast), salt, acidity regulator: citric acid, cinnamon, thickeners: sodium alginate, calcium alginate, glucose syrup.'
        },
        {
            'id': 'E6wgL2xxNMKHzS49brqv',
            'name': 'The Best Rhubarb & Custard Yoghurt',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Yogurt (milk), Rhubarb (12%), Whipping Cream (milk) (11%), Sugar, Cornflour, Flavourings, Colour (Carotenes), Vanilla Powder.'
        },
        {
            'id': 'E99XhqZJEHnDoWW8qD8U',
            'name': 'Honeycomb Ice Cream',
            'brand': 'Mackie\'s Of Scotland',
            'serving_size_g': 100.0,
            'ingredients': 'Whole milk 58%, whipping cream 18%, sugar, honeycomb 7% (sugar, glucose syrup, sodium bicarbonate), milk solids, glycerine, emulsifier (mono - and diglycerides of fatty acids), stabilisers (sodium alginate and guar gum).'
        },
        {
            'id': 'E9WhibXZBTj7MunDOcy2',
            'name': 'Batts Medium Peri Peri Sauce',
            'brand': 'Batts',
            'serving_size_g': 100.0,
            'ingredients': '11% onion purée, 4% lemon purée, sunflower oil, ground spices (cayenne chilli pepper, African bird\'s eye chilli, paprika), 2.5% green chilli, garlic purée, salt, stabilisers: xanthan gum, propane-1,2-diol alginate, antioxidant: ascorbic acid, preservative: potassium sorbate, rosemary extract.'
        },
        {
            'id': 'EA5BGJIJBj9Au36VkUAx',
            'name': 'Takis Fuego',
            'brand': 'Bimbo',
            'serving_size_g': 100.0,
            'ingredients': 'Pre-Cooked Cornflour, Palm Fat, Chilli and Lime Flavour Seasoning [Maltodextrin, Salt, Flavour Enhancers (Monosodium Glutamate, Potassium Chloride, Disodium Inosinate, Disodium Guanylate), Flavouring, Cornstarch, Acidity Regulator (Citric Acid), Sugar, Colours (Paprika Extract, Beetroot Red Concentrate), Stabiliser (Gum Arabic), Antioxidant (Tocopherol-Rich Extract)], Sunflower Oil.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 85\n")

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

    updated = update_batch85(db_path)

    print(f"✨ BATCH 85 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1511 + updated} products cleaned")

    # Check if we hit the 1525 milestone
    total = 1511 + updated
    if total >= 1525:
        print("\n🎉🎉 1525 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
