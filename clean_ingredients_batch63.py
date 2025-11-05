#!/usr/bin/env python3
"""
Batch 63: Clean ingredients for 25 products
Progress: 961 -> 986 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch63(db_path: str):
    """Update batch 63 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '5tpRMJ1bzuZ3AGUxErIH',
            'name': 'Nuts & Seeds Muesli',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Oat Flakes, Toasted Wheat Flakes, Chopped Dates (Rice Flour), Wheat Flakes, Barley Flakes, Mixed Nuts (5%) (Cashew Nut, Hazelnut, Almond), Pumpkin Seeds (2.5%), Sunflower Seeds (2.5%), Dried Apricots (Dried Apricots, Preservative (Sulphur Dioxide)), Dried Apple, Coconut.'
        },
        {
            'id': '5txqd7EsJ6jdW1QDPY9T',
            'name': 'Chicken Korma With Pilau Rice',
            'brand': 'Aldi',
            'serving_size_g': 100.0,
            'ingredients': 'Cooked Pilau Rice 43% (Water, Basmati Rice 43%, Rapeseed Oil, Cumin Seed, Ground Turmeric, Green Cardamom Pod, Whole Cloves), Water, Cooked Chicken Breast Pieces 15% (Chicken, Corn Starch), Onion, Coconut 3.5%, Rapeseed Oil, Chicken Mince, Low-Fat Yogurt (Milk), 16% Fat Cream 1.5% (Milk), Tomato Purée, Sugar, Modified Maize Starch, Desiccated Coconut, Whey Powder (Milk), Coriander Leaf, Salt, Garlic Purée, Ginger Purée, Ground Coriander, Ground Cumin, Ground Cardamom, Ground Turmeric, Green Chili Purée, Chili Powder, Ground Cinnamon, Ground Black Pepper, Ground Ginger, Ground Fennel, Paprika, Ground Green Cardamom, Ground Clove, Spice Extracts, Ground Bay Leaf.'
        },
        {
            'id': '5tybD2vjBOKoxy260DZQ',
            'name': 'Free From',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Tapioca Starch, Rice Flour, Bamboo Fibre, Potato Starch, Humectant (Glycerol - Vegetable), Rapeseed Oil, Egg White Powder, Psyllium Husk Powder, Cornflour, Thickeners (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Sugar, Yeast, Salt, Preservatives (Calcium Propionate, Sorbic Acid), Quinoa Flour, Emulsifier (Mono - and Diglycerides of Fatty Acids - Vegetable).'
        },
        {
            'id': '5u9VSFOZwDX2B5G1SZXF',
            'name': 'Medium Tikka Curry Powder',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Coriander Seed, Paprika, Cumin Seed, Onion Powder, Salt, Coriander Leaf, Garlic Powder, Fenugreek, Cinnamon, Ginger, Chilli Powder, Black Pepper, Cardamom, Clove.'
        },
        {
            'id': '5uUTDTyShboGlIy4jrXa',
            'name': 'Asda Beef Bourguignon',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Beef (47%), Chantenay Carrots (12%), Mushrooms (12%), Cabernet Sauvignon (8%) (Cabernet Sauvignon, Preservative (Sulphur Dioxide)), Smoked Dry-Cured Bacon Lardons (6%) (Pork Belly (96%), Salt, Sugar, Preservatives (Sodium Nitrite, Sodium Nitrate), Antioxidant (Sodium Ascorbate)), Silverskin Onions (4%), Water, Redcurrant Jelly (Sugar, Water, Redcurrant Juice from Concentrate, Gelling Agent (Pectins)), Beef Bouillon (Beef Stock, Tomato Purée, Onions, Carrots, Onions, Yeast Extract, Tomato Paste, Beef Dripping), Unsalted Butter (Milk), Cornflour (contains Sulphites), Brown Sugar (contains Sulphites), Black Pepper, Garlic Purée, Salt, Caramelised Sugar Syrup, Bay Leaves, Porcini Mushroom Powder.'
        },
        {
            'id': '5vrgCC0rAuF04OBSPvzv',
            'name': 'Potato Croquettes',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '67% Potatoes, 20% Cheese Flavoured Filling (19.6% Processed Cheese Food Preparation (Raclette Semi-hard Cheese (Milk), Water, Cheese Mix (Soft Cheese (Milk), Semi-hard Cheese (Milk), Hard Cheese (Milk)), Butter (Milk), Whey Powder (Milk), Emulsifying Salts (Diphosphates, Triphosphates), Modified Maize Starch, Maize Starch)), 6% Sunflower Oil, Potato Flakes (Dried Potatoes), Spices, Maize Starch, Salt, Dextrose, Milk Protein, Spices.'
        },
        {
            'id': '5wsyOVcuMuuuiwLs5YwM',
            'name': 'Ggy',
            'brand': 'M Ghee\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Gluten, with Calcium Carbonate, Iron, Niacin (B3) and Thiamine (B1)), Water, Yeast, Rye Flour, Salt, Emulsifiers (E472e, E471), Soya Flour, Vegetable Oil (Rapeseed), Flour Treatment Agents (E300, E920).'
        },
        {
            'id': '5qcX61mR33Co2WDD5MpI',
            'name': 'Plain Flour',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour.'
        },
        {
            'id': '5wz4nrSubESt8zrFMJdo',
            'name': 'Ready Salted',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Potatoes, Sunflower Oil, Salt.'
        },
        {
            'id': '5xYxsnt92JpjbuycMvqB',
            'name': 'Blueberry Whole Grain Oat Bar',
            'brand': 'Stoats',
            'serving_size_g': 42.0,
            'ingredients': 'Wholegrain Oats 48%, Rapeseed Oil, Soluble Fibre (Oligofructose), Sultanas (Sultanas, Sunflower Oil), Unsalted Butter.'
        },
        {
            'id': '5xjbfq5qqtZ7Z61C52ZW',
            'name': 'Mayonnaise Light',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Rapeseed Oil, Spirit Vinegar, Modified Maize Starch, Pasteurised Free Range Whole Egg, Sugar, Salt, Pasteurised Free Range Egg Yolk, Maize Starch, Thickeners (Xanthan Gum, Guar Gum), Preservative (Potassium Sorbate), Concentrated Lemon Juice, Mustard Seeds, Spices.'
        },
        {
            'id': '5yCNxsmZzojRwk0WPtZb',
            'name': 'Special Toffee Original',
            'brand': 'Thorntons',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Sweetened Condensed Milk (Whole Milk, Sugar, Lactose (Milk)), Palm Fat, Butter (Milk), Rapeseed Oil, Brown Sugar (Sugar, Molasses), Invert Sugar Syrup, Salt, Sea Salt, Flavouring, Emulsifier (E471).'
        },
        {
            'id': '5zJjzNANWXD5CZbRke94',
            'name': 'Crystal Noodles Sesame Glaze',
            'brand': 'Itsu',
            'serving_size_g': 100.0,
            'ingredients': 'Crystal Noodles 52% (Pea Starch, Water, Mung Bean Starch), Broth Paste 47% (Soy Sauce (Water, Soya Beans, Wheat, Salt, Alcohol), Soya Stock (Maltodextrin, Natural Flavouring, Yeast Extract, Salt), Tahini Paste (Sesame) 20%, Dried Onion, Sesame Oil 11%, Mirin (Fermented Rice, Water, Maltose, Alcohol), Yeast Extract, Sugar, Rapeseed Oil, Ginger Puree, Chilli Puree, Paprika, Garlic Puree, Black Sugar, Pepper, Leek).'
        },
        {
            'id': '602OditIm6lhI86f7KJd',
            'name': 'Season And Shake Mediterranean Chicken',
            'brand': 'Unilever',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Tomato Powder (21%), Salt, Potato Flakes (12%), Sugar, Yeast Extract, Onion Powder (3%), Garlic (3%), Paprika (3%), Flavourings, Basil, Cayenne Pepper, Oregano, Pepper, Rosemary, Bay Leaves.'
        },
        {
            'id': '60SI3KKqIakUYdnZ0gJo',
            'name': 'Chocolate Milk',
            'brand': 'Chocomel',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sugar, Cashew Nut 3.2%, Cocoa Powder 1.7%, Cocoa Butter 0.7%, Pea Protein 0.3%, Fructose, Salt, Flavour, Calcium Carbonate, Acidity Regulators (Dipotassium Phosphate, Sodium Citrate), Stabilisers (Cellulose, Cellulose Gum, Gellan Gum).'
        },
        {
            'id': '616lJt0jr95aAqFewexM',
            'name': 'Gianni\'s Recipe Lollies Cherry Cola',
            'brand': 'Gianni\'s',
            'serving_size_g': 70.0,
            'ingredients': 'Water, Sugar, Glucose Syrup, Fruit Juices from Concentrate (3%) (Lemon, Sour Cherry), Colours (Anthocyanins, Plain Caramel, Beetroot Red), Acids (Malic Acid, Citric Acid), Stabiliser (Guar Gum), Flavourings.'
        },
        {
            'id': '6194ysyMeVZ2ef0D4RAU',
            'name': 'Thin Rice Noodles',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Rice.'
        },
        {
            'id': '61PQpB8m13DT3q2TjXYw',
            'name': 'Egg Noodles Singapore Curry',
            'brand': 'Naked Noodle',
            'serving_size_g': 100.0,
            'ingredients': 'Dried Egg Noodles (71%) (Soft Wheat, Durum Wheat Semolina, Egg, Salt, Acidity Regulator (Potassium Carbonate)), Potato Starch, Maltodextrin, Flavourings, Sugar, Dried Carrot (2.3%), Garlic Powder, Curry Powder (1.4%) (Coriander, Turmeric, Salt, Allspice, Ginger, Fenugreek, Garlic Powder, Black Pepper, Cumin, Red Pepper, Bay), Dried Spring Onion (1.3%), Dried Onion, Onion Powder, Chinese Five Spice (0.5%) (Salt, Star Anise, Sugar, Onion Powder, Garlic Powder, Black Pepper, Cinnamon, Clove, Fennel Seed, Ginger, Chilli Powder), Dried Coriander, Mushroom Extract Powder, Ground Turmeric, Palm Oil, Colour (Curcumin).'
        },
        {
            'id': '61VReqB39C2xE2Ohv6Y0',
            'name': 'Fruit Creations Strawberry & Watermelon',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Fruit Juices from Concentrate (Apple 18%, Watermelon 1%, Strawberry 1%), Acids (Citric Acid, Malic Acid), Natural Strawberry Flavouring with other Natural Flavourings, Acidity Regulator (Sodium Citrate), Preservatives (Potassium Sorbate, Sodium Metabisulphite), Sweeteners (Sucralose, Acesulfame K), Carrot and Hibiscus Concentrate, Stabiliser (Cellulose Gum).'
        },
        {
            'id': '62WOiCdlUu5yW7AfVXN0',
            'name': 'Tomato Ketchup 50% Less Sugar And Salt',
            'brand': 'Heinz',
            'serving_size_g': 15.0,
            'ingredients': 'Tomatoes (174g per 100g Tomato Ketchup), Spirit Vinegar, Sugar, Salt, Spice and Herb Extracts (contain Celery), Sweetener (Steviol Glycosides), Spice.'
        },
        {
            'id': '632OhqpoFofUhpqmv0BP',
            'name': 'Dark Chocolate Nuts & Sea Salt',
            'brand': 'Kind Thins',
            'serving_size_g': 19.0,
            'ingredients': 'Almond Pieces, Dark Chocolate (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Soya Lecithin), Natural Flavouring), Peanut Pieces, Glucose Syrup, Chicory Root Fibre, Brown Rice Crisps (Brown Rice Flour, Honey, Sea Salt), Honey, Sugar, Cocoa Mass, Sunflower Oil, Sea Salt, Emulsifier (Soya Lecithin), Antioxidant (Tocopherol-Rich Extract).'
        },
        {
            'id': '632a3npC8Sgek6NnUfLR',
            'name': 'Bramwells Maple Flavour Glaze American Style Seasoning',
            'brand': 'Bramwells',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Brown Sugar, Modified Maize Starch, Salt, Maize Starch, Acids (Sodium Acetates, Citric Acid), Colours (Plain Caramel, Curcumin, Paprika Extract), Dried Garlic 3%, Dried Onion 3%, Dried Tomato 2%, Thickener (Guar Gum), Yeast Extract, Flavourings, Dried Parsley, Hickory Smoked High Oleic Sunflower Oil, Smoke Flavouring.'
        },
        {
            'id': '63hj5Q4PMtaJaq5dfWCp',
            'name': 'Dubai Style Chocolate',
            'brand': 'L\'amour Costco',
            'serving_size_g': 15.5,
            'ingredients': 'Milk Chocolate (Sugar, Cacao Butter, Cacao Mass, Whole Milk Powder, Skimmed Milk Powder, Whey Powder (Milk), Emulsifier (Sunflower Lecithin), Artificial Flavouring (Vanillin)), Filling (Pistachio (19%), Crispy Kadayıf Crumbles (8%) (Wheat Flour, Water), Sugar, Vegetable Oil (Palm Oil), Skimmed Milk Powder, Whey Powder (Milk), Butter, Emulsifier (Sunflower Lecithin)).'
        },
        {
            'id': '657IzoZ6aVR9FNufIrrc',
            'name': 'Banana Milk',
            'brand': 'Yazoo',
            'serving_size_g': 100.0,
            'ingredients': 'Semi Skimmed Milk, Skimmed Milk, Sugar, Banana Juice from Concentrate (1%), Stabiliser (Gellan Gum), Natural Flavouring, Colour (Carotenes).'
        },
        {
            'id': '66Yvwfy9IUDcstr2mjMs',
            'name': 'Red Cabbage & Apple',
            'brand': 'Tesco',
            'serving_size_g': 138.0,
            'ingredients': 'Red Cabbage (76%), Onion, Apple (13%), Redcurrant Jelly (Glucose-Fructose Syrup, Concentrated Redcurrant Juice, Gelling Agent (Pectins), Acidity Regulators (Citric Acid, Sodium Citrate)), Red Wine, Muscovado Sugar, Butter (Milk), Red Wine Vinegar, Cornflour, Salt, Black Pepper, Cinnamon Powder, Clove Powder.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 63\n")

    cleaned_count = update_batch63(db_path)

    # Calculate total progress
    previous_total = 961  # From batch 62
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 63 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 975 and previous_total < 975:
        print(f"\n🎉 975 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 15.1% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
