#!/usr/bin/env python3
"""
Batch 57: Clean ingredients for 25 products
Progress: 811 -> 836 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch57(db_path: str):
    """Update batch 57 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '3AMvU6qOC6StIHao4CGk',
            'name': 'Pitted Queen Olives',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Queen Green Olives, Water, Salt, Acidity Regulator (Lactic Acid).'
        },
        {
            'id': '3AbomxBjsvZKtEhdPmHw',
            'name': 'Parma Ham',
            'brand': 'Aldi',
            'serving_size_g': 13.0,
            'ingredients': 'Pork Leg, Salt.'
        },
        {
            'id': '3BDMDegHBnf0cxF2MPZu',
            'name': 'Peanut M&ms',
            'brand': 'M&ms',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Peanuts, Cocoa Mass, Full Cream Milk Powder, Cocoa Butter, Starch, Palm Fat, Skimmed Milk Powder, Glucose Syrup, Stabilizer (Gum Arabic), Emulsifier (Soya Lecithin), Shea Fat, Whey Permeate (Milk), Milk Fat, Dextrin, Glazing Agent (Carnauba Wax), Palm Kernel Oil, Colours (Carmine, E133, E170, E100, E160a), Salt, Flavouring.'
        },
        {
            'id': '3BE02KMLQBBctg08dxUp',
            'name': 'Tesco Millionaire Bites 22pk',
            'brand': 'Tesco',
            'serving_size_g': 12.0,
            'ingredients': 'Caramel (47%) (Condensed Skimmed Milk, Palm Oil, Glucose Syrup, Invert Sugar Syrup, Sugar, Water, Emulsifier (Soya Lecithins), Gelling Agent (Pectin)), Milk Chocolate (14%) (Sugar, Cocoa Butter, Cocoa Mass, Dried Skimmed Milk, Milk Fat, Milk Sugar, Emulsifier (Soya Lecithins)), Palm Oil, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Wholemeal Wheat Flour, Sugar, Palm Kernel Oil, Oat Flour, Coconut Oil, Invert Sugar Syrup, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Salt, Rapeseed Oil.'
        },
        {
            'id': '3BmBGngYjSZKCIuCtvIV',
            'name': 'Silverskin Onions',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Silverskin Onions, Water, Spirit Vinegar, Acetic Acid, Salt, Sugar (contains Sulphites), Barley Malt Extract, Sweetener (Sodium Saccharin), Preservative (Sodium Metabisulphite).'
        },
        {
            'id': '3BtpdcyvEJc32A5sEwln',
            'name': 'Apricot Wheats',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Wholewheat (72%), Sugar, Reconstituted Apricot Purée (8%), Humectant (Glycerol - Vegetable), Glucose Syrup, Dried Apricot (2%), Thickener (Maltodextrin), Acids (Malic Acid, Citric Acid), Gelling Agent (Pectin), Acidity Regulator (Trisodium Citrate), Flavouring.'
        },
        {
            'id': '3CG8uSkBBCPz8AMqF9Pw',
            'name': 'Chicken And Ham Paste',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken 42%, Ham with Added Water 25% (Pork 87%, Water, Salt, Antioxidant (Sodium Ascorbate)), Water, Modified Starch, Salt, Dried Egg, Emulsifier (E471), Stabilizer (E450), Preservative (E250).'
        },
        {
            'id': '3CXTUL11TCJWswAIOxNn',
            'name': 'Smooth Brussels Pâté',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork Liver (34%), Water, Pork Fat (20%), Pork (6.0%), Pork Rind, Salt, Tapioca Starch, Sugar, Dried Onions, Emulsifier (Citric Acid Esters of Mono and Diglycerides of Fatty Acids), Potato Fibre, Flavouring, Tomato Powder, Acidity Regulators (Sodium Acetates, Citric Acid), Pork Protein, Antioxidant (Ascorbic Acid), Brandy, Spices, Preservative (Sodium Nitrite).'
        },
        {
            'id': '3ELCw74YRqQfYoGy3Tkh',
            'name': 'Bluffalo Notzarella',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Soya Milk (Water, Soya Beans), Coconut Oil, Tapioca Flour, Sea Salt, Kappa Carrageenan (Derived from Seaweed), Nutritional Yeast, Lactic Acid.'
        },
        {
            'id': '3FPpnzATMp1hJqhSPKIf',
            'name': 'No Chorizo Tortellini',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Durum Wheat Semolina, Water, Onion, Sun Dried Tomato (7%), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sunflower Oil, Chilli, Coconut Oil, Potato Flakes, Modified Potato Starch, Modified Tapioca Starch, Extra Virgin Olive Oil (0.5%), Garlic Purée, Parsley, Basil, Nutritional Yeast Flakes, Thyme, Yeast, Salt, Sea Salt, Smoked Paprika, Smoked Torula Yeast, Bamboo Fibre, Black Pepper, Glucose Syrup, Red Chilli, Yeast Extract, Chicory Inulin, Sugar, Flavourings, Carrot Juice, Colour (Beta-Carotene), Tomato, Rapeseed Oil, Lovage.'
        },
        {
            'id': '3HAopaeMeOncS37UQXgr',
            'name': 'Hula Hoops BBQ Beef Flavour',
            'brand': 'Hula Hoops',
            'serving_size_g': 34.0,
            'ingredients': 'Potato (Potato Starch & Dried Potato), Sunflower Oil (24%), Rice Flour, Barbecue Flavour (Salt, Rice Flour, Dried Yeast Extract, Dried Whey, Dried Onion, Potassium Chloride, Sugar, Natural Flavourings, Dried Tomato, Colour (Paprika Extract), Maize Flour, Natural Flavouring (contains Potassium Chloride, Salt, Maltodextrin, Dried Onion)), Salt.'
        },
        {
            'id': '3IKoRN2DhFtHOfYm0Qos',
            'name': '25g Protein Pouch',
            'brand': 'Getpro',
            'serving_size_g': 200.0,
            'ingredients': 'Quark (Milk) 51%, Yoghurt (Milk) 40%, Forest Fruits 6.1% (Blackberry 2.9%, Strawberry 1.4%, Blueberry 0.8%, Blackcurrant 0.4%, Lingonberry 0.4%, Raspberry 0.2%), Natural Flavouring, Sweeteners (Acesulfame K, Sucralose), Lemon Juice Concentrate, Tapioca Starch, Fruit and Vegetable Concentrates (Carrot, Blueberry), Milk Minerals Concentrate, Thickener (Pectin).'
        },
        {
            'id': '3IYb9oJtp8onN0SBMM7g',
            'name': 'Organic Falafels Bio',
            'brand': 'Florentin',
            'serving_size_g': 100.0,
            'ingredients': 'Soaked Chickpeas 70%, Onions 12%, Parsley 10%, Water, Sea Salt, Garlic, Cumin, Sunflower Oil, Thickener (Xanthan Gum, Guar Gum), Nutritional Acid (Lactic Acid (Made from Sugar Cane)).'
        },
        {
            'id': '3Iu7XQxkB8KcHgKJoRPF',
            'name': 'Irresistible Hot And Spicy Chorizo',
            'brand': 'Co-op',
            'serving_size_g': 56.0,
            'ingredients': 'Pork, Paprika, Salt, Garlic, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Extracts of Rosemary).'
        },
        {
            'id': '3K6mO5XPJ5L4AeDvxt7f',
            'name': 'Super Nutty Granola',
            'brand': 'Tesco Finest',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes, Spelt (Wheat) Flakes, Sugar, Barley Flakes, Almonds (6%), Honey, Hazelnut (5%), Rapeseed Oil, Cashew Nut (2%), Brazil Nut Slices (1%), Pecan Nut Pieces (1%), Sugar Syrup Powder, Salt, Flavouring.'
        },
        {
            'id': '3EGHp9oru4oHQav0Nda4',
            'name': 'Giannis Salted Caramel Ice Cream',
            'brand': 'Giannis',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Coconut Oil, Salted Caramel Sauce (8%) (Water, Glucose-Fructose Syrup, Sugar, Whey Powder (Milk), Skimmed Milk Powder, Salt, Burnt Sugar, Thickener (Pectins), Stabilizer (Sodium Alginate), Flavoring), Glucose Syrup, Whey Powder (Milk), Skimmed Milk Powder, White and Dark Chocolate Flavored Curls (2%) (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Lactose (Milk), Whey Powder (Milk), Lemon Concentrate, Safflower Concentrate, Emulsifier (Lecithins (Sunflower)), Natural Vanilla Flavoring, Plant Extracts (Radish Concentrate, Apple Concentrate, Blackcurrant Concentrate), Flavoring), Emulsifier (Mono- and Diglycerides of Fatty Acids), Burnt Sugar, Thickeners (Locust Bean Gum, Guar Gum), Salt, Flavoring, Flavoring (contains Milk).'
        },
        {
            'id': '3MK5Jwbn5Dqzg2U4T3Co',
            'name': 'Black Cherry Conserve',
            'brand': 'Wilkin Sons Ltd',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Black Cherries, Acidity Regulator (Citric Acid), Gelling Agent (Citrus Pectin).'
        },
        {
            'id': '3MVX16f9rbiRYqcYRyBa',
            'name': 'Chicken Noodle Dry Packet Soup',
            'brand': 'Unilever',
            'serving_size_g': 225.0,
            'ingredients': 'Pasta (Durum Wheat Semolina, Wheat Semolina) 65%, Salt, Potato Starch, Yeast Extract, Flavourings (contain Celery), Chicken 3%, Chicken Fat 2.5%, Toasted Onion Powder, Potassium Chloride, Sugar, Palm Oil, Spices (Celery Seeds, Turmeric, Pepper), Parsley, Antioxidants (Extracts of Rosemary, Alpha-Tocopherol, Ascorbyl Palmitate).'
        },
        {
            'id': '3MlLRxm3ClfiSpTKMQfr',
            'name': 'Crunchy Mandelmus',
            'brand': 'Koro',
            'serving_size_g': 100.0,
            'ingredients': '85% Almond Kernels, 15% Almond Pieces.'
        },
        {
            'id': '3MsboHWKNC3zVoxd3qPz',
            'name': 'Pret Marvellous Milk Chocolate',
            'brand': 'Pret A Manger',
            'serving_size_g': 100.0,
            'ingredients': 'Cane Sugar, Cocoa Butter, Milk Powder, Cocoa Mass, Emulsifier (Soya Lecithin).'
        },
        {
            'id': '3N08lJgmgTv3oqCdiIzp',
            'name': 'Cookies And Cream Milkshake',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Water, Cream (Milk) (10%), Syrup (Maltodextrin, Sugar, Lactose, Cookie Pieces (25%) (Sugar, Cocoa Powder, Glucose Syrup, Wheat Starch, Powder (Milk), Sunflower Oil, Corn Flour, Humectant), Salt), Milk Protein, Stabilisers (Locust Bean Gum, Guar), Natural Flavouring, Natural Vanilla Extract.'
        },
        {
            'id': '3N5Ldafx8qFiLwJAEcYo',
            'name': 'Tesco Summer Edition 4 Pineapple Coconut & Lime Lollies',
            'brand': 'Tesco',
            'serving_size_g': 74.0,
            'ingredients': 'Pineapple Juice (69%), Coconut Milk (17%), Sugar, Lime Juice (3%).'
        },
        {
            'id': '3NpLFNn6RWJK7KkgGa8f',
            'name': 'Butter Fudge',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Butter (Milk) (12%), Glucose Syrup, Whole Milk Powder, Invert Sugar (Sugar, Glucose-Fructose Syrup, Water, Acidity Regulator (Citric Acid)), Sea Salt, Emulsifier (Sunflower Lecithins).'
        },
        {
            'id': '3ObwIs801ziMiEIInAwB',
            'name': 'Strawberry Yoghurt Flakes',
            'brand': 'Fruit Bowl',
            'serving_size_g': 18.0,
            'ingredients': 'Yogurt Flavoured Coating (60%) (Sugar, Palm Fat, Whey Powder (Milk), Rice Flour, Yogurt Powder (Milk) (3%), Emulsifier (Sunflower Lecithins), Glazing Agent (Shellac, Gum Arabic)), Fruit Flakes (40%) (Concentrated Apple Purée, Fructose-Glucose Syrup, Strawberry Purée, Sugar, Gluten Free Wheat Fibre, Palm Fat, Gelling Agent (Pectin), Concentrated Aronia Juice, Acidity Regulator (Malic Acid), Natural Flavouring).'
        },
        {
            'id': '3OtYyxlysCT1Xc2HNHrZ',
            'name': 'Minis Ice Creams',
            'brand': 'Alsi',
            'serving_size_g': 100.0,
            'ingredients': 'Milk Chocolate Covered Ice Cream Lolly: Reconstituted Skimmed Milk, Milk Chocolate (34%) (Sugar, Cocoa Mass, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods. Milk Chocolate Covered Ice Cream Lolly with Chopped Almonds: Reconstituted Skimmed Milk, Milk Chocolate (33%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Cocoa Mass, Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Chopped Almonds (5%), Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods. White Chocolate Covered Ice Cream Lolly: Reconstituted Skimmed Milk, White Chocolate (34%) (Sugar, Cocoa Butter, Skimmed Milk Powder, Clarified Butter (Milk), Coconut Fat, Emulsifiers (Polyglycerol Polyricinoleate, Lecithins (Sunflower)), Vanilla Extract), Whey Protein Concentrate (Milk), Coconut Oil, Glucose-Fructose Syrup, Sugar, Inulin, Emulsifier (Mono-and Diglycerides of Fatty Acids), Stabilisers (Carob Gum, Guar Gum), Vegetable Extract (Carrot Concentrate), Vanilla Extract, Ground Vanilla Pods.'
        }
    ]

    current_timestamp = int(datetime.now().timestamp())

    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (
            product['ingredients'],
            product['serving_size_g'],
            current_timestamp,
            product['id']
        ))

        print(f"✅ {product['brand']} - {product['name']}")
        print(f"   Serving: {product['serving_size_g']}g\n")

    conn.commit()
    conn.close()

    return len(clean_data)

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    print("🧹 CLEANING INGREDIENTS - BATCH 57\n")

    cleaned_count = update_batch57(db_path)

    # Calculate total progress
    previous_total = 811  # From batch 56
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 57 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 825 and previous_total < 825:
        print(f"\n🎉 825 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 12.8% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
