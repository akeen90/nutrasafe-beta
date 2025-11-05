#!/usr/bin/env python3
"""
Batch 61: Clean ingredients for 25 products
Progress: 911 -> 936 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch61(db_path: str):
    """Update batch 61 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '58a4LIpdMIUvZSz2ToC0',
            'name': 'Fusilli Pasta',
            'brand': 'Tesco',
            'serving_size_g': 170.0,
            'ingredients': 'Durum Wheat Semolina.'
        },
        {
            'id': '59A0kFEL00SJ2xllmCuF',
            'name': 'Free From Gluten Penne',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Yellow Cornflour, Rice Flour, White Cornflour, Emulsifier (Mono - and Diglycerides of Fatty Acids).'
        },
        {
            'id': '59kClPhgmNvZiaqIhnUK',
            'name': 'Belgium Chocolate Biomel',
            'brand': 'Biomel',
            'serving_size_g': 100.0,
            'ingredients': 'Coconut Milk (Purified Water, Pressed Coconut), Raw Cane Sugar, Cacao, Gellan Gum, Guar Gum, Sea Salt, Vitamins (B6, D), Calcium, Live Active Cultures.'
        },
        {
            'id': '5AIjG3t2iAkSuNlkcFzA',
            'name': 'Diet Pineapple & Grapefruit',
            'brand': 'M&S',
            'serving_size_g': 500.0,
            'ingredients': 'Carbonated Water, Pineapple Juice from Concentrate (3%), Grapefruit Juice from Concentrate (2%), Comminuted Lemon from Concentrate (1%), Flavourings, Acid (Citric Acid), Preservatives (E202, E242), Sweetener (Steviol Glycosides from Stevia), Acidity Regulator (E331), Antioxidant (Ascorbic Acid), Colour (Carotenes).'
        },
        {
            'id': '5AJ31mwQwrOUuyWd8rfL',
            'name': 'Spring Water',
            'brand': 'Rubicon',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Spring Water 97%, Fruit Juices from Concentrate (Raspberry 1.5%, Black Cherry 1%), Acid (Citric Acid), Natural Flavourings, Natural Raspberry Flavouring, Black Carrot Concentrate, Preservative (Potassium Sorbate), Sweetener (Sucralose), Acidity Regulator (Trisodium Citrate), Green Tea Extract, Vitamins (Niacin, B6, B12).'
        },
        {
            'id': '5AU1me6K7gM8KvEkL5tB',
            'name': 'Mild & Melting Grated Mozzarella & Cheddar',
            'brand': 'Co-op',
            'serving_size_g': 30.0,
            'ingredients': 'Vegetarian Mozzarella (Milk), Cheddar Cheese (Milk), Anti-caking Agent (Potato Starch).'
        },
        {
            'id': '5Adwx9pDxznl1MCFDKPg',
            'name': 'Cheese Savouries',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin (B3), Thiamin (B1)), Palm Oil, Cheese Powder (Milk) 10%, Sunflower Oil, Dried Autolysed Yeast, Sugar, Glucose Syrup, Barley Malt Extract, Raising Agents (Ammonium Carbonates, Sodium Carbonates), Salt, Whey Powder (Milk), Lactic Acid, Flavourings.'
        },
        {
            'id': '5AeaLxScv0trzqWPP7IM',
            'name': 'Giant Moroccan Style Couscous',
            'brand': 'Sainsbury\'s',
            'serving_size_g': 50.0,
            'ingredients': 'Couscous 81% (Wheat Flour), Dried Apricot 4% (Dried Apricot, Rice Flour, Preservative (Sulphur Dioxide)), Raisins (Raisins, Sunflower Oil), Dried Tomato, Flavourings (contains Barley), Dried Green Pepper, Palm Oil, Sugar, Ground Spices (Cumin, Coriander, Pepper, Cinnamon, Chilli), Salt, Garlic Powder, Maltodextrin, Cumin Seeds, Dried Coriander, Colour (Curcumin), Ground Oregano.'
        },
        {
            'id': '5B5MhQx1rP4l3A1o1Gkj',
            'name': 'Mackerel Fillets In Olive Oil',
            'brand': 'Lidl',
            'serving_size_g': 42.5,
            'ingredients': '68% Mackerel Fillets, 28% Olive Oil, Salt.'
        },
        {
            'id': '5BraZKyezWayvXljsM7X',
            'name': 'Spinach & Carrot Veggie Bakes',
            'brand': 'Cauldron',
            'serving_size_g': 50.0,
            'ingredients': 'Spinach (25%), Carrots (24%), Restructured and Rehydrated Soy Flour, Sunflower Oil, Wheat Gluten, Tapioca and Pea Starch, Breadcrumb (Wheat Flour, Yeast, Salt), Potato Flake, Rice Flour, Soy Protein Isolate, Onion, Pea Fibre, Sugar, Salt, Potassium Chloride, Preservative (Potassium Sorbate), Dried Garlic, Spirit Vinegar, Natural Flavourings, Black Pepper.'
        },
        {
            'id': '5Coq2BUm48AOCrqsFP5M',
            'name': 'Italian Mascarpone',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cream (Milk), Milk, Acidity Regulator (Citric Acid).'
        },
        {
            'id': '5CwRMoMMljd7moK6vhLp',
            'name': 'Toastie',
            'brand': 'Kingsmill',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (with Calcium, Iron, Niacin (B3), and Thiamin), Water, Yeast, Salt, Vegetable Fats (Palm, Rapeseed), Flour Treatment Agent (Ascorbic Acid (Vitamin C)).'
        },
        {
            'id': '5CxUB8nd4YXbLcHAdF4e',
            'name': 'Tomato Ketchup Smokey Bacon Flavour',
            'brand': 'Heinz',
            'serving_size_g': 100.0,
            'ingredients': 'Tomatoes (148g per 100g Tomato Ketchup), Spirit Vinegar, Sugar, Salt, Flavourings, Smoke Flavouring, Spice and Herb Extracts (contain Celery), Spice.'
        },
        {
            'id': '5FLJRpPd5SwjWuumhKL2',
            'name': 'Heinz Tomato Ketchup Imp',
            'brand': 'Heinz',
            'serving_size_g': 15.0,
            'ingredients': 'Tomatoes (200g per 100g Tomato Ketchup), Spirit Vinegar, Lemon Juice from Concentrate, Potassium Chloride, Acid (Malic Acid), Citrus Fibre, Spice and Herb Extracts (contain Celery), Sweetener (Sucralose).'
        },
        {
            'id': '5FZEzLO4rMb7uQmpAjuo',
            'name': 'Smoky Barbecue',
            'brand': 'Graze',
            'serving_size_g': 100.0,
            'ingredients': 'Barbecue Coated Peas (40%) (Green Peas (53%), Corn Starch, Waxy Corn Starch, Sugar, High Oleic Sunflower Oil, Barbecue Flavouring (3%) (Sugar, Salt, Maltodextrin, Yeast Extract, Onion Powder, Garlic Powder, Tomato Powder, Sweet Chilli Powder, Natural Flavouring, Spices, Acidity Regulator (Citric Acid), Colour (Paprika Extract)), Salt), Chilli Corn (33%) (Corn, Sunflower Oil, Chilli Seasoning (2%) (Maltodextrin, Onion Powder, Garlic Powder, Paprika Powder, Pepper Powder, Cayenne Pepper, Tomato, Salt), Salt, Paprika Oil), Corn Chips (27%) (Corn, Sunflower Oil).'
        },
        {
            'id': '5FqE05xtrr1kaF40jIAZ',
            'name': 'Meat Free Bisto Gravy',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Dried Glucose Syrup, Salt, Rapeseed Oil, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Mushroom Stock (2.5%) (Mushroom Concentrate, Rapeseed Oil, Glucose Syrup, Salt, Flavourings), Colour (Ammonia Caramel), Sugar, Onion Powder, Potassium Chloride, Emulsifier (Soya Lecithin), Black Pepper Extract, Onion Oil, Rosemary Extract.'
        },
        {
            'id': '5G49wT2nUqzRUSIhcevx',
            'name': 'Gravy Granules For Chicken',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Palm Oil, Salt, Maltodextrin, Colour (Plain Caramel), Flavourings, Dried Onion, Caster Sugar, Sage, Caramelised Sugar, Emulsifier (Rapeseed Lecithins).'
        },
        {
            'id': '5GGZwCqcg2z4yTqh3UkX',
            'name': 'Lightly Salted Rice Cakes',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Brown Rice, Salt (0.3%).'
        },
        {
            'id': '5GWJpbktQ2mHRT4MAV2F',
            'name': 'Diced Beetroot',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Diced Beetroot, Water, Sugar, Acetic Acid, Spirit Vinegar, Salt, Preservative (Potassium Sorbate), Sweetener (Saccharins).'
        },
        {
            'id': '5Gdx8PY1OfaWpbuGlhs5',
            'name': 'Chicken Tikka',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Chicken Breast 45% (Chicken Breast 98%, Salt), Mayonnaise (Water, Rapeseed Oil, Cornflour, Pasteurised Egg Yolk, Spirit Vinegar, Sugar, Salt, Lemon Juice from Concentrate), Tikka Sauce 1% (Water, Dextrose, Spirit Vinegar, Spices (Cumin, Coriander, Cayenne Pepper, Turmeric), Sugar, Cornflour, Onion Powder, Garlic Powder, Parsley, Colour (Paprika Extract), Concentrated Lemon Juice, Coriander Extract), White Onions, Curry Paste (Rapeseed Oil, Water, Salt, Coriander, Cumin, Tomato Paste, Sugar, Paprika, Fenugreek, Cayenne Pepper, Turmeric, Mustard Seeds, Gram Flour, Cinnamon, Acidity Regulator (Citric Acid), Cardamom, Cloves, Preservative (Potassium Sorbate)).'
        },
        {
            'id': '5HXUPYTPRNv41SvdzYpu',
            'name': 'Snackrite Salt And Vinegar Pringles',
            'brand': 'Snackrite',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Potato, High Oleic Sunflower Oil (34%), Potato Starch, Natural Flavouring, Salt, Emulsifier (Mono-and Diglycerides of Fatty Acids), Paprika Extract, Sweet Whey Powder (Milk), Fructose, Turmeric Extract, Spirit Vinegar Extract Powder.'
        },
        {
            'id': '5JRiXeSGOj5ha4aosItV',
            'name': 'French Fries',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potato (89%), Sunflower Oil, Modified Potato Starch, Rice Flour, Salt, Dextrose, Maltodextrin, Colours (Curcumin, Paprika Extract), Raising Agents (Diphosphates, Sodium Carbonates), Thickener (Xanthan Gum).'
        },
        {
            'id': '5JjDir9OghStuK4wGhMI',
            'name': 'West Indian Original Hot Pepper Sauce',
            'brand': 'Encona',
            'serving_size_g': 100.0,
            'ingredients': 'Habanero Mash (64%) (Habanero Peppers, Scotch Bonnet Peppers, Salt, Acid (Acetic Acid)), Water, Acid (Acetic Acid), Salt, Onion Powder, Mustard, Modified Maize Starch (E1414), Stabiliser (Xanthan Gum).'
        },
        {
            'id': '5K3Euk40dsIQ390mbbLf',
            'name': 'Jelly Mix/pick N Mix',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Beef Gelatine, Pork Gelatine, Dextrose, Fruit Juices from Concentrate (2%) (Grape, Pear, Pineapple, Peach), Corn Starch, Acid (Citric Acid), Modified Potato Starch, Fruit and Vegetable Concentrates (Carrot, Safflower, Apple, Spirulina).'
        },
        {
            'id': '5KAFSe2Va45f6rtXL1Sa',
            'name': 'Tofoo Burger',
            'brand': 'The Tofoo Co',
            'serving_size_g': 93.0,
            'ingredients': 'Tofu 46% (Water, Soya Beans, Nigari), Sweet Potato 11%, Red Pepper, Sweetcorn, Black Beans 7%, Tomato Puree, Green Jalapeno Chilli 3.7%, Coriander, Stabilizer (Methyl Cellulose), Garlic Puree, Smoked Paprika, Salt, Lime Juice Concentrate, Ground Cumin, Oregano, Chilli Flakes.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 61\n")

    cleaned_count = update_batch61(db_path)

    # Calculate total progress
    previous_total = 911  # From batch 60
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 61 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 925 and previous_total < 925:
        print(f"\n🎉 925 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 14.3% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
