#!/usr/bin/env python3
"""
Clean ingredients for batch 80 of messy products
"""

import sqlite3
from datetime import datetime

def update_batch80(db_path: str):
    """Update batch 80 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Batch 80: Products with cleaned ingredients
    clean_data = [
        {
            'id': 'BhvFyLdj4cnB1O8Z9DPl',
            'name': 'Original RYE Crispbread',
            'brand': 'Rivercote',
            'serving_size_g': 100.0,
            'ingredients': 'Wholegrain Rye Flour, Rye Flour, Salt.'
        },
        {
            'id': 'BjGDOx1zMHUkgqol41BO',
            'name': 'Delicious BAR',
            'brand': 'Nutrend',
            'serving_size_g': 50.0,
            'ingredients': 'Milk, chocolate 22% (sweetener maltitol, cocoa butter, cocoa mass, dried milk, cocoa, emulsifier sunflower lecithin), protein mixture (milk proteins, soy protein isolate), humectant glycerine, collagen peptides, peanuts 9%, polydextrose, sunflower oil, dried skimmed milk, oligofructose, vegetable fat (palm kernel, palm, shea), emulsifier rapeseed lecithin, water, flavouring, sodium chloride, emulsifier sodium citrate, colours E 150c and E 160b, sweetener sucralose.'
        },
        {
            'id': 'BkG2yfU2DtyasSh0TMrO',
            'name': 'Mummy Meegz M\'z Gems Vegan',
            'brand': 'Mummy Meegz',
            'serving_size_g': 40.0,
            'ingredients': 'Sugar, cocoa butter, dried rice syrup, cocoa mass, almond paste, rice starch, concentrate (radish, carrot, spirulina), glazing agents (gum arabic, carnauba wax), emulsifier (sunflower lecithin), vanilla natural flavouring and colouring (riboflavin).'
        },
        {
            'id': 'BkVnfq2ZNU1Kj8BuWaIq',
            'name': 'Auntie Bessie',
            'brand': 'Aunt Bessies',
            'serving_size_g': 75.0,
            'ingredients': 'Wheat flour, jam 29% (glucose fructose syrup, apple puree concentrate, plum puree concentrate, apricot puree concentrate, acidity regulators: citric acid, trisodium citrate, gelling agent: pectin, elderberry juice concentrate, natural flavouring), water, palm oil, sugar, chicory fibre, whey powder (milk), raising agents (disodium diphosphate, sodium bicarbonate, calcium carbonate), niacin, iron, thiamin, calcium sulphate.'
        },
        {
            'id': 'Bkix1rYFgOi14bCtzAWw',
            'name': '6 Premium Pork Sausages',
            'brand': 'Black Farmer',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (90%), Water, Potato Starch, Salt, Dextrose, Spices (Pepper, Nutmeg), Herbs (Sage, Parsley), Stabiliser (Triphosphates), Preservative (Sodium Sulphite), Antioxidant (Ascorbic Acid), Spice Extracts, Acidity Regulator (Citric Acid), Sage Extract.'
        },
        {
            'id': 'Bl6mgplXpY7MUAPA842F',
            'name': 'Indien',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'ONION BHAJE: ONION 76%, Gram Flour, Cottonseed Oil, Rice Flour, Garlic, Coriander Leaf, Salt, Ginger, Lemon Juice, Raising Agent: Sodium Carbonates; Cumin Seed Powder, Green Chilli, Turmeric Powder, Chilli Powder, Ground Green Cardamom, Ground Cloves, Ground Black Cardamom, Ground Coriander, Ground Cinnamon, Ground Mace, Ground Bay Leaves. VEGETABLE PAKORA: POTATO 31%, CABBAGE 22%, Gram Flour, ONION 12%, SPINACH 9%, Cottonseed Oil, GREEN PEAS 6%, Cumin Seed Powder, Salt, Red Chilli Powder, Turmeric Powder, Coriander Powder, Ground Green Cardamom, Raising Agent: Sodium Carbonates; Ground Cloves, Ground Black Cardamom, Ground Coriander, Ground Cinnamon, Ground Mace, Ground Bay Leaves. VEGETABLE SAMOSA: Wheat Flour, POTATO 25%, CARROT 22%, Cottonseed Oil, Onion, GREEN PEAS 3%, Garlic, Salt, Coriander Leaf, Ginger, Corn Starch, Lemon Juice, Fully Refined Soybean Oil, Fennel Seeds, Cumin Seeds, Sugar, Ground Green Cardamom, Cumin Seed Powder, Chilli Powder, Star Anise Powder, Ground Cloves, Ground Black Cardamom, Turmeric Powder, Ground Coriander, Ground Cinnamon, Ground Mace, Ground Bay Leaves.'
        },
        {
            'id': 'BleBG5Ok9Tt0TRkJZPb3',
            'name': 'Karmelki Twarde Kawowe O Smaku Espresso',
            'brand': 'Candy Land',
            'serving_size_g': 5.0,
            'ingredients': 'Sugar, glucose syrup, coffee extract 2%, evaporated milk, butter (from milk), unhydrogenated palm fat, salt, aroma, emulsifier: lecithins (from soybeans).'
        },
        {
            'id': 'Bm9YKjSuErhxSSHjeANX',
            'name': 'Super Toastie Extra Thick Sliced White',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified wheat flour (wheat flour, iron, thiamin, nicotinic acid, calcium carbonate), Water, Salt, Yeast, Soya flour, Preservative (calcium propionate), Emulsifier (mono - and diacetyltartaric acid esters of mono - and diglycerides of fatty acids), Flour treatment agent (ascorbic acid), Folic acid.'
        },
        {
            'id': 'Bn4zlI5pGzDohkFQ6S1j',
            'name': 'Free From Chocolate Chip Cookies',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Gluten Free Oat Flour, Chocolate Chips (18%) (Cocoa Mass, Sugar, Cocoa Butter, Emulsifier: Sunflower Lecithin), Sugar, Palm Oil, Margarine (Palm Fat, Rapeseed Oil, Water, Palm Oil, Salt, Emulsifier: Mono- and Diglycerides of Fatty Acids), Tapioca Flour, Rice Flour, Partially Inverted Sugar Syrup, Raising Agents: Sodium Bicarbonate, Ammonium Bicarbonate; Stabiliser: Xanthan Gum; Flavouring.'
        },
        {
            'id': 'Bo0wU2a2gptUbrWRhxw0',
            'name': 'MAIN Apple & Cinnamon Bircher With Greek Style Yog',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 190.0,
            'ingredients': 'Water, Reduced Fat Greek Style Yogurt (27%) (Cows\' Milk), Apple & Cinnamon Sauce (21%) (Apple, Water, Sugar, Cornflour, Apple Purée, Lemon Juice, Cinnamon Powder, Flavouring, Gelling Agent: Pectin), Oat Flakes (19%), Concentrated Apple Juice.'
        },
        {
            'id': 'Bo6zQJzH4cuE3QjCg7Bj',
            'name': 'Chewy Bites',
            'brand': 'Chewits',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, glucose syrup, vegetable fats (palm, coconut), humectant (sorbitol), maltodextrin, acids (citric acid, lactic acid), natural flavouring, emulsifier (sucrose esters of fatty acids), fruit juice from concentrate (apple, lemon, strawberry, orange, pineapple, peach), salt, acidity regulator (sodium lactate), colour (carmine).'
        },
        {
            'id': 'BoKAOPXd8PJJTdDDuAVj',
            'name': 'Dark Rye & Sunflower Bread',
            'brand': 'Tesco',
            'serving_size_g': 40.0,
            'ingredients': 'Water, Sunflower Seeds (8%), Rye Flour (5%), Wheat Gluten, Yeast, Fat, Salt, Emulsifier (Mono- and Di-Acetyl Tartaric Acid Esters of Mono- and Di-Glycerides of Fatty Acids), Caramelised Sugar, Fermented Wheat.'
        },
        {
            'id': 'BotpxDRC74D60t59w6Q3',
            'name': 'Triple Chocolate Cookies',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'BELGIAN DARK CHOCOLATE CHUNKS (22%) (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier: Lecithins (Soya); Flavouring), Wheat Flour (Wheat Flour, Wheat Gluten, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Margarine (Rapeseed Oil, Palm Oil, Water, Salt, Flavouring, Emulsifier: Polyglycerol Esters of Fatty Acids; Colours: Annatto Bixin, Curcumin), BELGIAN WHITE CHOCOLATE CHUNKS (7%) (Sugar, Whole Milk Powder, Cocoa Butter, Skimmed Milk Powder, Emulsifier: Lecithins (Soya); Flavouring), Water, FAT REDUCED COCOA POWDER (3%), Invert Sugar Syrup, Humectant: Glycerol; Whey Powder (Milk), Egg Powder, Rapeseed Oil, Palm Oil, Glucose, Dextrose, Buttermilk, Flavourings, Raising Agents: Sodium Carbonates, Diphosphates; Salt.'
        },
        {
            'id': 'BpAzN0h7CkQUGmcDAyBP',
            'name': '16 Crumbed Ham Slice',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Pork 86%, Water, Salt, Gluten Free Breadcrumbs (Rice Flour, Cornflour, Salt, Dextrose), Rapeseed Oil, Colours (Curcumin, Paprika Extract), Stabilisers (Potassium Triphosphate, Sodium Triphosphate, Tetrapotassium Diphosphate), Mineral Sea Salt, Pork Gelatine, Honey, Antioxidant (Sodium Ascorbate), Brown Sugar, Preservative (Sodium Nitrite), Caramelised Sugar Syrup.'
        },
        {
            'id': 'BrAbZ3cMJULi8wNRNx0p',
            'name': 'Standard Raisin Crispy',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat flour, raisins (18%), sugar, currants (5%), oat flour, glucose-fructose syrup, rapeseed oil, glucose syrup, humectant (glycerol), palm oil, inulin, dried skimmed milk, rice flour, wheat bran, concentrated apple purée, raising agents (sodium bicarbonate, disodium diphosphate, ammonium bicarbonate), salt, dextrose, invert sugar syrup, oatmeal, whey powder (milk), gelling agent (pectin), emulsifier (rapeseed lecithins), flavouring, coconut, citric acid.'
        },
        {
            'id': 'BrCxZsCh7oO4EeCgN6jV',
            'name': 'Mediterranean Cous Cous',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '85% Dried Cous Cous (Durum Wheat Semolina), 5% Tomato Powder, Dried Tomato, Flavourings (contain Barley), Palm Oil, Dried Onion, Sugar, Dried Black Olives, Salt, Dried Herbs (Chives, Parsley, Basil), Dried Garlic, Colour: Paprika Extract; Acid: Citric Acid.'
        },
        {
            'id': 'BsIutW6vGBIDXEgTLfgu',
            'name': 'Skyr Yogurt Vanilla',
            'brand': 'Milbona',
            'serving_size_g': 150.0,
            'ingredients': 'Fat Free Yogurt (Milk), Water, Modified Maize Starch, Concentrated Lemon Juice, Vanilla Extract, Thickeners: Pectins, Xanthan Gum; Acidity Regulators: Calcium Citrates, Citric Acid; Natural Cream Flavouring (contains Milk), Ground Vanilla Pods, Sweeteners: Aspartame, Acesulfame K.'
        },
        {
            'id': 'BsMV2ynFt0orR2vk08wp',
            'name': 'Dark Chocolate Coated Mini Rice Cakes',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Dark chocolate (60%) (sugar, cocoa mass, cocoa butter, emulsifier (soya lecithins), flavouring), Rice (40%).'
        },
        {
            'id': 'BtSbh4dFTkDqQyc0yVvM',
            'name': 'Del Monte Ketchup',
            'brand': 'Del Monte',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes, Spirit Vinegar, Sugar (19%), Modified Maize Starch, Salt (1.5%), Natural Spice Flavouring.'
        },
        {
            'id': 'BwkvGns3j2joRuLNedUM',
            'name': 'British Outdoor Bred Pulled Wiltshire Ham Hock',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'British Ham Hock, Curing Salt (Salt, Preservative: Sodium Nitrite, Potassium Nitrate).'
        },
        {
            'id': 'BwqUgLY8NUlJFuZTzoml',
            'name': 'Organisation Lightly Salted Rice Crackers',
            'brand': 'Snack Organisation',
            'serving_size_g': 25.0,
            'ingredients': 'Rice (91%), sugar, rice bran oil (contains antioxidant: soy tocopherols), salt (1.5%), soy sauce powder (soy, rice, salt), flavour enhancers: disodium guanylate, disodium inosinate, antioxidant: soy tocopherol, soy sauce flavour.'
        },
        {
            'id': 'BxjpZSQBqUhpR6Cr09E5',
            'name': 'Tiramisu Dessert',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Tiramisu dessert made with sponge fingers and coffee sauce, topped with mascarpone and marsala wine mousse and cocoa dusting.'
        },
        {
            'id': 'BymNo8f2abUSy0cTKiuF',
            'name': 'Huel Black Edition Powder - Chocolate',
            'brand': 'Huel',
            'serving_size_g': 90.0,
            'ingredients': 'Pea Protein, Ground Flaxseed, Brown Rice Protein, Tapioca Flour, Cocoa Powder (6.5%), Sunflower Oil Powder, Organic Coconut Sugar, Natural Flavourings, Micronutrient Blend (Potassium Citrate, Potassium Chloride, Corn Starch, Calcium Carbonate, Vitamin C (as L-Ascorbic Acid), Niacin (as Niacinamide), Lutein, Pantothenic Acid (as Calcium-D-Pantothenate), Lycopene, Vitamin B6 (as Pyridoxine Hydrochloride), Riboflavin, Vitamin A (as Retinyl Acetate), Vitamin B1 (as Thiamin Mononitrate), Zeaxanthin, Vitamin K2 (as Menaquinone-7), L-Methylfolate, Potassium Iodide, Vitamin D2 (as Ergocalciferol), Plant-Derived Vitamin D3 (as Cholecalciferol), Vitamin B12 (as Cyanocobalamin)), Medium-Chain Triglyceride Powder (from Coconut), Stabiliser: Xanthan Gum, Sea Salt, Sweetener: Steviol Glycosides, Green Tea Powder, Kombucha Powder, Bacillus Coagulans.'
        },
        {
            'id': 'C1CyDrudMtEI55PWruNW',
            'name': 'Ridged',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Oat flakes, sugar, rapeseed oil, pumpkin seeds, freeze dried fruits (2.5%) (blackcurrants, cranberry slices, blueberries), almonds (1.5%), honey (1%), sunflower seeds, flavouring.'
        },
        {
            'id': 'C1T6LZHIEvJxZKq8ibwN',
            'name': 'Reduced Fat Tikka Masala Curry Sauce',
            'brand': 'Sharwood\'s',
            'serving_size_g': 105.0,
            'ingredients': 'Tomatoes (33%), water, fat free yoghurt (0.6%)(milk), double cream (6%) (milk), modified maize starch, sugar, onion, ginger purée, garlic purée, ground cumin, ground coriander seed, desiccated coconut (1%), coriander, salt, ground spices, concentrated lemon juice, acidity regulator (lactic acid), colour (paprika extract).'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    updated_count = 0

    print("🧹 CLEANING INGREDIENTS - BATCH 80\n")

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

    updated = update_batch80(db_path)

    print(f"✨ BATCH 80 COMPLETE: {updated} products cleaned")
    print(f"📊 TOTAL PROGRESS: {1386 + updated} products cleaned")

    # Check if we hit the 1400 milestone
    total = 1386 + updated
    if total >= 1400:
        print("\n🎉🎉 1400 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total} products cleaned!")
        print(f"💪 Over {round((total/6448)*100, 1)}% progress through the messy ingredients!")
        print(f"🎯 Approximately {6448 - total} products with messy ingredients remaining")
