#!/usr/bin/env python3
"""
Clean ingredients for batch 82 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch82(db_path: str):
    """Update batch 82 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 82: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'CbaCSJx1jHnhUBTn2aXp',
            'name': 'Cocoa Vanilla Oat Boost',
            'brand': 'Graze',
            'serving_size_g': 100.0,
            'ingredients': 'Oats (38%), chicory root fibre, vegetable oil (palm), sunflower seeds, golden syrup, cocoa powder (3.6%), liquid sugar, chocolate mass, sugar, cocoa butter, fat-reduced cocoa powder, emulsifier: soya lecithin, humectant: palm fat, modified starch, soya flour, starch, natural vanilla flavouring, sea salt, soya lecithin, citrus fibre, stabiliser: xanthan gum, molasses.'
        },
        {
            'id': 'CbyY32f0xFSNFDCbECHZ',
            'name': 'Falafels',
            'brand': 'Sainsbury\'s Plant Pioneers',
            'serving_size_g': 100.0,
            'ingredients': 'Chickpeas 37%, Onion 15%, Water, Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Wheat Gluten, Parsley, Dried Onion, Coriander Leaf, Sugar, Coriander Powder, Cumin Powder, Salt, Garlic Purée, Raising Agents (Ammonium Hydrogen Carbonate, Disodium Diphosphate, Sodium Carbonate), Black Pepper, Wheat Starch.'
        },
        {
            'id': 'Cd5e3aOZ5IpxUQN5889X',
            'name': 'Aero Peppermint Mint',
            'brand': 'Nestlé',
            'serving_size_g': 27.0,
            'ingredients': 'Sugar, vegetable fats (palm, shea), whey powder from milk, dried milk powder, cocoa butter, butterfat, whole milk, cocoa mass, skimmed milk powder, emulsifiers (E442, E476, soya lecithins, sunflower lecithins), flavourings, colour (curcumin).'
        },
        {
            'id': 'CdJaLNzwiyuPrY7KWuL7',
            'name': 'Milk Chocolate Hazelnut, Caramelised Cashew & Pistachio',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa butter, cane sugar, milk powder, cocoa mass, hazelnuts 6%, caramelised cashews 5% (cashew nuts, cane sugar), pistachio nuts 3%, milk fat, salt, vanilla extract.'
        },
        {
            'id': 'CdL2boCOWDdVeCp5y9RX',
            'name': 'Pumpkin Spice Cake',
            'brand': 'Sainsbury\'s Taste The Difference',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Cream Cheese Buttercream (21%) (Sugar, Butter (Cows\' Milk), Full Fat Soft Cheese (Cows\' Milk), Pasteurised Lemon Juice, Cornflour), Pasteurised Egg, Rapeseed Oil, Light Brown Sugar, Pumpkin Purée (11%), Sugar, Humectant: Vegetable Glycerine; Dried Glucose Syrup, Partially Inverted Sugar Syrup, Lemon Juice, Ground Spices (Nutmeg, Cinnamon, Coriander Seed, Ginger, Caraway, Clove), Raising Agents: Sodium Bicarbonate, Disodium Diphosphate; Cornflour, Palm Oil, Molasses.'
        },
        {
            'id': 'CdXFni8lMH3GEb2FhEDU',
            'name': 'Tesco Scottish Shortbread Assortment Tin',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour [Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin], Butter (Milk) (32%), Sugar, Cornflour, Salt.'
        },
        {
            'id': 'CdbFFtn4U4l3PWFFOa2q',
            'name': 'Bulgur Wheat',
            'brand': 'Asda',
            'serving_size_g': 80.0,
            'ingredients': 'Bulgur Wheat.'
        },
        {
            'id': 'Ce6eehLfI82NXIJavJZN',
            'name': 'Cinnamon Rolls',
            'brand': 'Just Roll',
            'serving_size_g': 100.0,
            'ingredients': 'Dough (76%): Wheat flour, margarine (vegetable fats and oils (palm, rapeseed), water, emulsifier (mono - and - diglycerides of fatty acids), salt, acid (citric acid)), water, sugar, wheat gluten, dextrose, raising agents (glucono-delta-lactone, potassium carbonates, diphosphates), ethyl alcohol, salt, thickener (xanthan gum), flavouring, stabiliser (magnesium chloride), colour (carotenes), flour treatment agent (ascorbic acid). Cinnamon preparation (15%): Sugar, sunflower oil, corn starch, cinnamon (5%), fat-reduced cocoa powder, emulsifier (lecithins). Icing sugar (9%): Powdered sugar.'
        },
        {
            'id': 'CeJW3CjnsRFLtFV7WCjq',
            'name': 'Pouring Cream',
            'brand': 'Baileys',
            'serving_size_g': 30.0,
            'ingredients': 'Double cream (milk) (64%), skimmed milk (19%), alcohol, sugar, original irish cream liqueur (milk) (2%), flavouring, colour (plain caramel), emulsifier (mono-and diglycerides of fatty acids), acidity regulator (citrate), milk protein, stabiliser (pectin).'
        },
        {
            'id': 'CeeBLy5XqeVxZUTd96r6',
            'name': 'Baklava',
            'brand': 'Deluxe',
            'serving_size_g': 100.0,
            'ingredients': 'Filo Pastry (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Glucose Syrup, Rapeseed Oil, Salt, Clarified Butter (Milk), Maize Starch), Invert Sugar Syrup, Cashew Nuts (Ranging from 13% to 26% across varieties), Butter Blend (Rapeseed Oil, Clarified Butter (Milk)), Sugar, Dark Chocolate (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier (Soya Lecithin, Sorbitan Tristearate), Natural Vanilla Flavouring), Milk Chocolate (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Whey Powder (Milk), Emulsifier (Soya Lecithin, Polyglycerol Polyricinoleate), Natural Vanilla Flavouring), Mixed Nuts (Walnut, Macadamia, Almond, Pistachio), Cocoa Powder, Flavouring.'
        },
        {
            'id': 'CfFNWLYXGEKnq4R95hY4',
            'name': 'Potato Scones',
            'brand': 'Aldi',
            'serving_size_g': 40.0,
            'ingredients': 'RECONSTITUTED DRIED POTATO (78%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Salt, Preservative: Potassium Sorbate; Wheat Gluten.'
        },
        {
            'id': 'CfYWjkxUUpCcLXKuq2tx',
            'name': 'Dark Seville Orange Marmalade',
            'brand': 'Specially Selected',
            'serving_size_g': 15.0,
            'ingredients': 'Sugar, Orange, Gelling Agent: Pectins; Acid: Citric Acid; Colour: Plain Caramel; Acidity Regulator: Sodium Citrate.'
        },
        {
            'id': 'ChXnMbmaHYF6ypN3Zdfi',
            'name': 'Curry Sauce',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Rice flour, ground fenugreek, ground cumin, mustard powder, salt, ground ginger, ground black pepper, tomato puree from concentrate, modified maize starch, creamed coconut (2%), curry powder (ground coriander, paprika, chilli powder, ground nutmeg, ground fennel), sultanas (1.5%), rapeseed oil, sugar, salt, acidity regulator: lactic acid, onion powder, chilli powder, ground turmeric, dried garlic, sweetener: sodium saccharin.'
        },
        {
            'id': 'Chs1bOmzMXneUXPSgJJX',
            'name': 'Serrano Ham Slices',
            'brand': 'Dulano',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Sugar, Preservatives: Sodium Nitrite, Potassium Nitrate; Antioxidant: Sodium Ascorbate.'
        },
        {
            'id': 'Cj1IdnofSED8ukwFGvOh',
            'name': 'Classic Italian Recipe Kit Tagliatelle Carbonara',
            'brand': 'Rana',
            'serving_size_g': 408.0,
            'ingredients': 'Fresh egg pasta (durum wheat semolina, eggs 18%, water). Carbonara sauce: Water, cream (from milk) 17%, smoked bacon 8.5% (pork meat, salt, natural flavourings), starches (from corn and potato), corn fibre, onion, skimmed milk powder, natural flavourings (contain wheat), salt, grated cheese (from milk) 0.5%, egg yolk 0.5%, black pepper 0.1%, turmeric. P.D.O. Parmigiano Reggiano cheese 7g (milk, salt, rennet).'
        },
        {
            'id': 'Cj6P6kIt73GnJRCWxMDt',
            'name': 'Extra Velouté Blanc',
            'brand': 'Lindt',
            'serving_size_g': 10.0,
            'ingredients': 'Sugar, cocoa butter, whole milk powder, lactose, emulsifier: soy lecithin, natural aroma of Madagascar vanilla, bourbon vanilla extract.'
        },
        {
            'id': 'CkrfrPTEV0dZxO4TxcU7',
            'name': 'Garlic Mushroom Wood Fried Pizza',
            'brand': 'Sainsbury\'s Taste The Difference',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour, Water, Mozzarella Cheese, Chestnut Mushroom, Mascarpone Cheese, Tomato Purée, Cows\' Milk, Onion, Semolina, Rapeseed Oil, Whipped Cream, Truffle Flavoured Oil, Salt, Olive Oil, Flat Leaf Parsley, Lemon Juice, Extra Virgin Olive Oil, Mushroom, Cornflour, Regato Cheese, Yeast, Garlic Purée, Parsley, Garlic, Wheat Flour, Black Pepper, Wheat Starch, Butter, Gelling Agent: Pectin, Maize Starch, Carrot, Truffle, Flavouring, Black Olive, Thyme, Concentrated Lemon Juice, White Pepper, Malted Wheat Flour, Wheat Gluten, Chilli, Muscovado Sugar.'
        },
        {
            'id': 'CmWKF9dVlfMFIO83LvC2',
            'name': 'Nature\'s Strawberries',
            'brand': 'Tru Fru',
            'serving_size_g': 100.0,
            'ingredients': 'Strawberries, milk chocolate (sugar, cocoa butter, whole milk powder, cocoa mass, emulsifier: soya lecithin, natural flavouring), white chocolate (sugar, cocoa butter, whole milk powder, skim milk powder, emulsifier: soya lecithin, natural flavouring).'
        },
        {
            'id': 'CnkFwpaQSsU0eKLVF7SE',
            'name': 'Free Range Egg Mayonnaise Sandwich',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Free range hard-boiled egg (48%), wheat flour (calcium carbonate, iron, niacin, thiamin), water, rapeseed oil, pasteurised free range egg yolk, salt, spirit vinegar, yeast, emulsifiers (mono- and di-glycerides fatty acids, mono- and di-acetyl tartaric acid esters of mono- and di-glycerides of fatty acids), wheat gluten, soya flour, white pepper, sugar, palm oil, flour treatment agent (ascorbic acid).'
        },
        {
            'id': 'CpFRMN4MRvTuZ7d927Sv',
            'name': 'Cafe Iced Caramel',
            'brand': 'Cafe',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk (70%), Coffee (Water, Coffee Powder) (27%), Milk Protein (2.2%), Stabilisers (Cellulose, Cellulose Gum), Natural Flavourings, Acidity Regulator (Sodium Phosphates), Caramelised Sugar Powder, Sweeteners (Sucralose, Acesulfame Potassium).'
        },
        {
            'id': 'Cpki6wzHgT83GyY1o0mg',
            'name': 'Spice Infusion Cous Cous',
            'brand': 'Bramwells',
            'serving_size_g': 130.0,
            'ingredients': 'COUS COUS (86%) (Durum Wheat Semolina), VEGETABLES (6%) (Onion, Carrot, Tomato), Salt, Rapeseed and/or Sunflower Oil, Sunflower Seeds, Yeast Extract, Spinach Powder, Cumin, Carrot Extract Powder, Flavourings (contains Wheat), Turmeric, Garlic Powder, Coriander Seeds, Parsley, Cayenne Pepper, Paprika, Salt, Fenugreek Seeds, Coriander, Celery Seeds, Cinnamon, Cloves, Whey (Milk), Emulsifier: Lecithins (Soya).'
        },
        {
            'id': 'CqFkK2MCbIGiZZZ2XaId',
            'name': 'High Protein Passion Fruit, Mango & Papaya',
            'brand': 'Milbona',
            'serving_size_g': 200.0,
            'ingredients': '90% Yogurt (Milk), Sugar, 1% Passion Fruit Juice, Water, 1% Mango Purée, 1% Papaya, Natural Flavourings, Maize Starch, Concentrated Lemon Juice, Safflower Concentrate.'
        },
        {
            'id': 'CqPgz3berQjw0QeoUq1k',
            'name': 'Creamy Chicken Soup',
            'brand': 'Chef Select',
            'serving_size_g': 100.0,
            'ingredients': 'Water, chicken, cream, vegetables, wheat flour, salt, spices, herbs, flavourings.'
        },
        {
            'id': 'CqYCxNy9YosoRuod4yan',
            'name': 'Swedish Meatballs Wrap (hot)',
            'brand': 'Pret A Manger',
            'serving_size_g': 240.0,
            'ingredients': 'Meatballs (38%) (Pork, Onion, Tomato Paste, Red Pepper, Paprika, Garlic Purée, Parsley, Salt, Black Pepper, Thyme, Rosemary, Sage, Flavouring), Kibbled Rye Wrap (Wheat flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), Water, Malted Rye Flakes (Rye), Rapeseed Oil, humectant (Glycerol), raising agents (Diphosphates, Sodium Bicarbonate), Dried Fermented Wheat Flour, Wheat Flour (Wheat Flour, Calcium Carbonate, Niacin, Iron, Thiamin), emulsifier (Mono - and Diglycerides of Fatty Acids), Salt, acidity regulator (Citric Acid), Wheat Starch, flour treatment agent (L-Cysteine)), Grevé Cheese (Milk), Chipotle Ketchup (Red Pepper, Muscovado Sugar, Red Wine Vinegar, Onion, Chipotle Peppers in Adobo Sauce (Chipotle Pepper, Water, Tomato Paste, Salt, Sugar, Onion, acidity regulator (Acetic Acid)), Vegetable Oil (Sunflower Oil and Rapeseed Oil), Tomato Paste, Maize Starch, Water, Garlic, Salt, Black Pepper, Cayenne Pepper), Red Tapenade (Cherry Tomato, Semi-Dried Red Pepper, Rapeseed Oil, Tomato Concentrate, Sugar, Salt, Concentrated Lemon Juice, Garlic, Parsley, Chive, Basil, Basil Flavouring), Red Onion, Seasoning (Sea Salt, Black Pepper, Rapeseed Oil).'
        },
        {
            'id': 'CrHZ3y9fV1cpXuVVzI88',
            'name': 'Chocolate Orange',
            'brand': 'Terry\'s',
            'serving_size_g': 29.0,
            'ingredients': 'Sugar, cocoa mass, cocoa butter, skimmed milk powder, whey powder from milk, vegetable fats (palm, shea), milk fat, emulsifiers (soya lecithins, E476), orange oil, flavouring.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 82\n")

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

    updated = update_batch82(db_path)

    print(f"✨ BATCH 82 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1436 + updated} products cleaned")

    # Check if we hit the 1450 milestone
    total = 1436 + updated
    if total >= 1450:
        print("\n🎉🎉 1450 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
