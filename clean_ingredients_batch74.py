#!/usr/bin/env python3
"""
Batch 74: Clean ingredients for 25 products
Progress: 1236 -> 1261 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch74(db_path: str):
    """Update batch 74 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '8xftf2OJNZ0L4k24WYyM',
            'name': 'Meadow Flower Light',
            'brand': 'Aldi',
            'serving_size_g': 10.0,
            'ingredients': 'Vegetable Oils in Varying Proportions (49%) (Palm and Palm Kernel Oil, Rapeseed Oil), Buttermilk (40%), Water, Salt (1.5%), Acid (Lactic Acid), Colour (Carotenes), Flavouring.'
        },
        {
            'id': '8y38fJYugvJQOjO1yx3e',
            'name': 'Milka Chocolate Hazelnuts',
            'brand': 'Milka',
            'serving_size_g': 16.7,
            'ingredients': 'Sugar, Cocoa Butter, Cocoa Mass, Skimmed Milk Powder, Hazelnut Pieces (9%), Whey Powder (from Milk), Milk Fat, Emulsifier (Soya Lecithins), Hazelnut Paste, Flavouring.'
        },
        {
            'id': '8yJVGV5JkozPWl5at14H',
            'name': 'Chocolate Strands',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Mass, Cocoa Powder, Emulsifier (Soya Lecithins).'
        },
        {
            'id': '8ygnlktaXBlJFJCJz5vs',
            'name': 'Salmon Fillets',
            'brand': 'Aldi',
            'serving_size_g': 90.0,
            'ingredients': 'Atlantic Salmon (Fish) 91%, Sweet Chilli Sauce (Sugar, Water, Red Chilli Puree (Red Bell Pepper, Salt, Chilli Peppers), Red Chilli Pepper, Salt, Red Wine Vinegar, Red Bell Pepper, Garlic, Onion, Red Chilli Powder, Paprika Powder, Garlic Powder, Ginger Powder, Turmeric Powder, Cumin Powder, Ground Lemongrass, Black Pepper, Coriander Leaf, Ginger Puree, Sunflower Oil, Flavouring, Salt).'
        },
        {
            'id': '8tesmzOdPseAarjRW0q8',
            'name': '6.9 10% Of An Adult\'s Reference Intake! Typical Va',
            'brand': 'Mr Kipling',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour with Added Calcium, Iron, Niacin, Thiamin, Sugar, Vegetable Oils (Palm, Rapeseed), Glucose Syrup, Strawberry Flavoured Jam (Glucose-Fructose Syrup, Strawberry Purée, Sugar, Acid (Citric Acid), Gelling Agent (Pectin), Flavouring, Acidity Regulator (Sodium Citrates), Colour (Anthocyanins), Preservative (Potassium Sorbate)), Icing Sugar, Red Sugar Decorations (Sugar, Wheat Starch, Glucose Syrup, Fruit and Vegetable Concentrates (Blackcurrant, Lemon, Radish, Safflower), Coconut Oil), Humectant (Vegetable Glycerine), Skimmed Milk Powder, Whey Powder (Milk), Dried Egg White, Dextrose, Emulsifiers (Sorbitan Monostearate, Polysorbate 60, Mono - and Diglycerides of Fatty Acids), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Flavourings, Preservatives (Potassium Sorbate, Sulphur Dioxide), Colour (Carmine).'
        },
        {
            'id': '900IYVgGm0WXs3sy0k25',
            'name': 'Chicken Popstars Southern Fried',
            'brand': 'Birds Eye',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Breast (60%), Coating (Wheat Flour, Water, Cornflour, Rice Flour, Salt, Yeast Extract, Spices, Raising Agent (Sodium Bicarbonate), Rapeseed Oil).'
        },
        {
            'id': '91ZviBUMUIGYr2xsFiaV',
            'name': 'Scrambled Oggs',
            'brand': 'Alternative Foods London Ltd',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Sunflower Oil, Chickpea Protein, Maize Starch, Thickener (Methyl Cellulose), Nutritional Yeast (Dried Inactive Yeast), Emulsifier (Sunflower Lecithin), Acid (Lactic Acid), Firming Agent (Calcium Lactate, Calcium Carbonate), Sugar, Gelling Agent (Gellan Gum), Acidity Regulator (Sodium Citrate), Natural Flavouring, Black Pepper, Maltodextrin, Black Salt, Colour (Beta-Carotene).'
        },
        {
            'id': '9224OAg3JgtIcVXlRhLC',
            'name': 'Homestyle Chips',
            'brand': 'Harvest Basket',
            'serving_size_g': 100.0,
            'ingredients': '91% Potatoes, 5% Seasoned Coating (Flour (Wheat, Rice), Wheat Starch, Salt, Yeast Extract, Dextrose, Spice Extracts, Raising Agents (Diphosphates, Sodium Carbonates), Thickener (Xanthan Gum), Antioxidant (Extracts of Rosemary)), 4% Sunflower Oil.'
        },
        {
            'id': '92UiNBrBlM8hpG55IPNr',
            'name': 'Porchetta Toscana',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Ground Black Pepper, Garlic, Wild Fennel Flowers, Rosemary, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite), Cinnamon, Nutmeg, Star Anise, Ground Coriander, Cloves, Caraway Seeds.'
        },
        {
            'id': '92y02YUPeGClq2LtI06q',
            'name': 'Victoria Sponge Slice Gluten Free',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Icing (20%) (Icing Sugar, Palm Oil, Water, Rapeseed Oil, Coconut Oil, Humectant (Glycerol), Flavouring, Emulsifier (Mono - and Diglycerides of Fatty Acids)), Sugar, Potato Starch, Egg, Strawberry Jam (16%) (Sugar, Strawberries, Glucose-Fructose Syrup, Acidity Regulators (Citric Acid, Sodium Citrates), Gelling Agent (Pectins), Firming Agent (Calcium Chloride)), Rapeseed Oil, Humectant (Glycerol), Invert Sugar Syrup, Raising Agents (Diphosphates, Sodium Carbonates), Thickener (Xanthan Gum), Emulsifier (Sodium Stearoyl-2-Lactylate), Preservative (Potassium Sorbate).'
        },
        {
            'id': '93uiFuLXNc0TEucVNVSW',
            'name': 'Jelly Buttons',
            'brand': 'Tangerine Confectionery Ltd',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose Syrup, Water, Cornflour, Beef Gelatine, Spirulina Concentrate, Flavouring, Fruit and Vegetable Concentrates (Radish, Blackcurrant, Carrot), Colour (Chlorophylls).'
        },
        {
            'id': '958TBpKHId16irS2dZa7',
            'name': 'Gin & Candle',
            'brand': 'Walkers',
            'serving_size_g': 25.0,
            'ingredients': 'Potato Flakes, Starch, Rapeseed Oil, Salt, Malt Vinegar Seasoning (Sugar, Emulsifier (Sunflower Lecithin), Sunflower Oil, Colour (Annatto), Malt Vinegar Seasoning (Flavourings (contains Barley), Vinegar Extract, Acid (Citric Acid), Sea Salt, Lactose from Milk, Potassium Chloride, Salt, Colour (Paprika Extract))).'
        },
        {
            'id': '95Vey1BAJR2dQOXM9zPI',
            'name': 'Mixed Bean Salad In Water',
            'brand': 'Essential Waitrose',
            'serving_size_g': 270.0,
            'ingredients': 'Water, Borlotti Beans, Pinto Beans, Black Eyed Beans, Chickpeas, Haricot Beans, Lima Beans, Great Northern Beans, Cannellini Beans, Flageolet Beans, Antioxidant (Ascorbic Acid), Firming Agent (Calcium Chloride).'
        },
        {
            'id': '95X1Lidge367ucQOOmQi',
            'name': 'Organic Stock Paste Chicken &rosemary',
            'brand': 'Kallo',
            'serving_size_g': 100.0,
            'ingredients': 'Sea Salt, Potato Starch, Sunflower Oil, Sustainable Palm Fat, Sugar, Chicken Fat (6.5%), Agave Fibre, Natural Flavouring, Yeast Extract, Chicken (1%), Herbs and Spices (Turmeric, Rosemary, Parsley, Black Pepper), Onion.'
        },
        {
            'id': '96N8uUwWzFmCvHQ3fU72',
            'name': 'Simply... Fat Free Natural Yogurt',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': 'Skimmed Milk, Yogurt Cultures.'
        },
        {
            'id': '96pME2k0lSCh8uOmkwmj',
            'name': 'Spaghetti In Rich Tomato Sauce',
            'brand': 'Lidl',
            'serving_size_g': 100.0,
            'ingredients': '47% Spaghetti Cuts (Durum Wheat Semolina, Water), 29% Tomato Purée, Water, Sugar, Modified Maize Starch, Salt, Onion Powder, Ground Paprika, Potato Flour, Acidity Regulator (Citric Acid), Flavourings, Colour (Paprika Extract).'
        },
        {
            'id': '97WHGfh32TxwRSqt984y',
            'name': 'Roasted Salted Cashews',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Cashew Nut Halves, Peanut Oil, Salt.'
        },
        {
            'id': '97oEBy6xsmWepY7n9HLc',
            'name': 'Breaded Chicken Steaks',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken (62%), Water, Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Wheat Starch, Salt, Pea Fibre, Yeast, Yeast Extract, Sugar, Garlic Powder, Onion Powder, Paprika, Dextrose, Sage, White Pepper.'
        },
        {
            'id': '982j1OSZ8XqZb4fom2zX',
            'name': 'Seeded Batch',
            'brand': 'Hovis',
            'serving_size_g': 50.0,
            'ingredients': 'Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Water, Seed Mix (10%) (Contains Brown Linseed, Toasted Brown Linseed, Toasted Sunflower Seeds, Millet Seed, Golden Linseed, Poppy Seed), Yeast, Soya Flour, Wheat Protein, Malted Barley Flour, Salt, Granulated Sugar, Barley Flour, Vegetable Proteins, Preservative (E282), Rapeseed Oil, Caramelised Sugar, Barley Fibre, Emulsifier (E472e), Dextrose, Maltodextrin, Starch, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '98hYCOQKPVKGFnuhBV47',
            'name': 'Spanish Chorizo De Navarra',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Smoked Paprika, Salt, Garlic, Corn Dextrose, Antioxidants (Oregano Extract, Rosemary Extract), Preservatives (Sodium Nitrite, Potassium Nitrate).'
        },
        {
            'id': '99eBH8mTSgvIMCvhwMJj',
            'name': 'Free From Brown Sliced Loaf',
            'brand': 'Morrisons',
            'serving_size_g': 41.0,
            'ingredients': 'Water, Tapioca Starch, Rice Flour, Bamboo Fibre, Maize Starch, Potato Starch, Rapeseed Oil, Humectant (Glycerol), Psyllium Husk Powder, Brown Rice Flour, Sugar, Potato Flakes, Thickeners (Hydroxypropyl Methyl Cellulose, Xanthan Gum), Dried Egg White, Salt, Yeast, Preservatives (Calcium Propionate, Sorbic Acid), Fat Reduced Cocoa Powder, Cornflour, Caramelised Sugar, Flavouring.'
        },
        {
            'id': '9AK5Wjb0Z2JSDB5s3S0B',
            'name': 'GF Choco Pops',
            'brand': 'M&S',
            'serving_size_g': 30.0,
            'ingredients': 'Brown Rice Flour (78%), Sugar, Cocoa (3%), Salt, Rice Bran Extract.'
        },
        {
            'id': '9At655Utar2JhaMchk8k',
            'name': 'Ready TO COOK Herby BABY Potatoes Use By 24 AUG 38',
            'brand': 'Oaklands',
            'serving_size_g': 100.0,
            'ingredients': '95% Whole Baby Potatoes, 3% Salted Butter (Butter (Milk), Sea Salt), 1.9% Rapeseed Oil, 0.1% Herbs (Parsley, Spearmint).'
        },
        {
            'id': '9C5YYXD0MX3tMG2YBkkj',
            'name': 'Dairy Free Milky Way',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Butter, Cocoa Mass, Ground Tiger Nuts, Chicory Fibre, Rice Syrup Powder, Emulsifier (Sunflower Lecithin), Natural Vanilla Flavouring.'
        },
        {
            'id': '9Ci9urcYxmoo6fGIo2Ct',
            'name': 'Sweet And Sour Sauce',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Water, 27% Sugar, White Rice Vinegar, 4% Tomato Paste, Modified Maize Starch, 2.5% Concentrated Pineapple Juice, 2% Pineapple, 2% Ginger Purée, Salt, Acidity Regulator (Citric Acid), Colour (Paprika Extract).'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 74\n")

    cleaned_count = update_batch74(db_path)

    # Calculate total progress
    previous_total = 1236  # From batch 73
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 74 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1250 and previous_total < 1250:
        print(f"\n🎉🎉 1250 MILESTONE ACHIEVED! 🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 19.4% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
