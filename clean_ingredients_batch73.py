#!/usr/bin/env python3
"""
Batch 73: Clean ingredients for 25 products
Progress: 1211 -> 1236 products cleaned
"""

import sqlite3
from datetime import datetime

def update_batch73(db_path: str):
    """Update batch 73 of products with cleaned ingredients"""

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Clean product data
    clean_data = [
        {
            'id': '8aCiunKba8GUcoswL7gn',
            'name': 'Dubai Style Chocolate',
            'brand': 'Lindt',
            'serving_size_g': 29.0,
            'ingredients': 'Whole Milk Chocolate (Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Lactose, Skimmed Milk Powder, Emulsifier (Soya Lecithin), Barley Malt Extract, Flavouring), Pistachio Paste with Shredded Pastry Filling 26% (Pistachios 45%, Sugar, Anhydrous Milk Fat, Shredded Pastry 10% (Wheat Flour, Water, Corn Starch, Sunflower Oil, Salt), Cocoa Butter, Whole Milk Powder, Almonds, Skimmed Milk Powder, Hazelnuts, Salt, Emulsifier (Soya Lecithin), Invert Sugar Syrup, Flavourings).'
        },
        {
            'id': '8aH9eXqyRI8MmPye8upl',
            'name': 'Seeded Bread',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Mixed Seeds 14% (Sunflower Seeds, Golden Linseeds, Brown Linseeds, Millet, Poppy Seeds, Pumpkin Seeds), Wheat Fibre, Yeast, Wheat Protein, Salt, Malted Barley Flour, Spirit Vinegar, Vegetable Oils and Fat (Rapeseed Oil, Palm Fat, Palm Oil), Emulsifier (Mono-and Diacetyl Tartaric Acid Esters of Mono - and Diglycerides of Fatty Acids), Preservative (Calcium Propionate), Soya Flour, Flour Treatment Agent (Ascorbic Acid).'
        },
        {
            'id': '8aI7P56IxjNLgYvPObyp',
            'name': 'Apricot Jam',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose-Fructose Syrup, Sugar, Apricots, Acidity Regulators (Citric Acid, Sodium Citrates), Gelling Agent (Pectins).'
        },
        {
            'id': '8ah4MMTEpbc9Zquw1Ybx',
            'name': 'High Protein Flame Baked Flatbreads',
            'brand': 'Aldi',
            'serving_size_g': 80.0,
            'ingredients': 'Wheat Flour (Calcium Carbonate, Niacin, Iron, Thiamin), Water, Wheat Gluten, Rapeseed Oil, Pea Protein (4.5%), Wheat Protein (3%), Spirit Vinegar, Yeast, Emulsifier (Mono - and Diglycerides of Fatty Acids), Stabiliser (Carboxymethyl Cellulose), Preservatives (Potassium Sorbate, Calcium Propionate), Raising Agents (Diphosphates, Sodium Carbonates, Calcium Phosphates), Salt, Wheat Starch, Acidity Regulator (Citric Acid).'
        },
        {
            'id': '8av1wsjm1Ix9zZQnveEK',
            'name': 'Protein 22 Chocolate Brownie',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'White Chocolate with Sweetener 23.3% (Maltitol, Cocoa Butter, Whole Milk Powder, Emulsifier (Soya Lecithin), Vanilla 0.2%), Milk Protein, Caramel Flavored Layer 18.3% (Bulking Agent (Polydextrose), Soya Oil, Skimmed Milk Powder, Xylitol, Emulsifier (Soya Lecithin), Flavors, Salt), Hydrolyzed Wheat Gluten, Humectant (Glycerol), Soya Protein, Soya Oil, Banana 0.7%, Salt, Flavors, Sunflower Oil, Sweetener (Sucralose), Coloring Agent (Beta Carotene).'
        },
        {
            'id': '8b0g5dPb6C2fv7pSmidp',
            'name': 'Cheese & Broccoli Quiche',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Broccoli 13%, Skimmed Milk, Egg, Tomato 10%, Water, Vegetable Oil (Palm, Rapeseed), Vegetarian Extra Mature Cheddar Cheese (Milk) 5%, Single Cream (Milk), Fromage Frais (Milk), Maize Flour, Vegetarian Red Leicester Cheese (Milk) 2% (contains Colour (Annatto Norbixin)), Modified Maize Starch, Cornflour, Onion, Dextrose, Sugar, Tomato Purée, Garlic Purée, Salt, Smoked Paprika, Oregano, Thyme, Black Pepper, White Pepper, Nutmeg.'
        },
        {
            'id': '8csTFwfW2J3GKzh2X6GA',
            'name': 'Pumpkin Seeds',
            'brand': 'Aldi',
            'serving_size_g': 30.0,
            'ingredients': 'Pumpkin Seeds.'
        },
        {
            'id': '8ebPeilhTwsmoSTeqmSl',
            'name': 'Unsmoked Back Bacon',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (87%), Water, Salt, Preservatives (Sodium Nitrite, Potassium Nitrate), Antioxidant (Sodium Ascorbate).'
        },
        {
            'id': '8f1dHTs7Urdvd7y97gHn',
            'name': 'Operetta',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Roasted Chopped Hazelnuts, Vegetable Fats (Palm, Sunflower, Palm Kernel) in varying proportions, Roasted Whole Hazelnuts, Wheat Flour (contains Gluten), Cocoa Butter, Cocoa Mass, Dried Whole Milk, Hazelnut Paste, Fat Reduced Cocoa Powder, Dried Skimmed Milk, Dried Whey (Milk), Lactose (Milk), Emulsifier (Soya Lecithin, Sunflower Lecithin), Flavourings, Dried Free Range Egg, Caramelised Sugar Syrup, Raising Agent (Sodium Bicarbonate), Salt.'
        },
        {
            'id': '8fQxZerlcxALVta4H4D6',
            'name': 'Slimming World Diet Cola Chicken',
            'brand': 'Iceland',
            'serving_size_g': 100.0,
            'ingredients': 'Chicken Chunks (25%) (Chicken Breast (99%), Tapioca Starch, Salt), Water, Roasted Red Pepper (10%), Roasted Yellow Pepper (8%), Passata, Sugar Snap Peas (5%), Tomato Paste, Flavoured Syrup (Water, Colour (Sulphite Ammonia Caramel), Caffeine, Acid (Phosphoric Acid), Acidity Regulator (Sodium Citrates), Sweeteners (Acesulfame K, Sucralose), Preservative (Sodium Benzoate)), Garlic Purée, Dark Soy Sauce (Soy Sauce (Water, Soya Beans, Roasted Wheat, Salt), Sugar, Water, Salt, Tamarind Paste, Onion Powder, Barley Malt Extract, Garlic Powder, Ground Ginger, Lemon Juice, Clove Powder, Chilli Powder), Chicken Bouillon (Salt, Yeast Extract, Potato Starch, Flavouring, Chicken Stock (Dried Chicken Meat, Onion Powder, Carrot Extract, Leek Extract), Dried Sage, White Pepper, Dried Lovage), Salt, Herbs, Seaweed Granules.'
        },
        {
            'id': '8fXP499XBp6WLDjA9OXe',
            'name': 'Lemon & Coriander Cous Cous',
            'brand': 'Bramwells',
            'serving_size_g': 130.0,
            'ingredients': 'Cous Cous (90%) (Durum Wheat Semolina), Maize Maltodextrin, Flavourings, Rapeseed Oil and/or Sunflower Oil, Coriander (1%), Salt, Lemon Juice (0.5%), Lemon Peel, Colour (Curcumin Extract), Celery Seeds, Whey (Milk), Emulsifier (Lecithins (Soya)).'
        },
        {
            'id': '8ZGcBokQxIyNLWWiXIFt',
            'name': 'Milk Chocolate',
            'brand': 'Godiva',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Butter Oil, Natural Vanilla Flavouring, Emulsifier (Soya Lecithin).'
        },
        {
            'id': '8gMp0d2Q4h3PWL2bS6S2',
            'name': 'Sparkling Apple And Mango',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Water, Citric Acid, Malic Acid, Flavourings, Acidity Regulator (Sodium Citrates), Preservative (Potassium Sorbate), Sweeteners (Sucralose, Acesulfame K).'
        },
        {
            'id': '8h8rJa7YOIuzTbs4a4lf',
            'name': 'Digestives Dark Chocolate',
            'brand': 'McVitie\'s',
            'serving_size_g': 16.6,
            'ingredients': 'Wheat Flour 35%, Dark Chocolate 30% (Sugar, Cocoa Mass, Vegetable Fats, Butter Oil (Milk), Cocoa Butter, Emulsifiers (Soy Lecithin, E476), Natural Flavouring), Palm Oil, Wholemeal Wheat Flour 8%, Sugar, Glucose-Fructose Syrup, Acidity Regulator (E296), Raising Agents (E500ii, E503ii), Salt.'
        },
        {
            'id': '8hYrpI34Xv7EELvE62Kt',
            'name': 'Spaghetti',
            'brand': 'Cucina',
            'serving_size_g': 216.0,
            'ingredients': 'Durum Wheat Semolina, Water.'
        },
        {
            'id': '8i3RtdsSzdP8Cfo9Ab3g',
            'name': 'Happy Hippo Cocoa',
            'brand': 'Ferrero Scandinavia AB',
            'serving_size_g': 20.7,
            'ingredients': 'Sugar, Vegetable Fats (Palm, Shea), Wheat Flour, Milk Powder (7.5%), Fat-Reduced Cocoa Powder (5%), Skimmed Milk Powder (4.5%), Hazelnuts, Whey Powder (Milk), Chocolate (Sugar, Cocoa Mass, Cocoa Butter, Emulsifier (Lecithins (Soya)), Vanillin), Wheat Starch, Emulsifier (Lecithins (Soya)), Sunflower Oil, Whey Proteins (Milk), Raising Agents (Ammonium Bicarbonate, Sodium Bicarbonate), Salt, Vanillin.'
        },
        {
            'id': '8i7FI6GueyRnbs1Sp5WH',
            'name': 'Red Pesto',
            'brand': 'Morrisons',
            'serving_size_g': 48.0,
            'ingredients': 'Reconstituted Tomato Purée, Sunflower Oil, Partially Rehydrated Sundried Tomatoes (8%), Grana Padano Cheese (6%) (Cheese (Milk), Preservative (Egg Lysozyme)), Basil (6%), Red Pepper, Pecorino Romano Cheese (2%) (Sheep\'s Milk), Pine Kernels, Cashew Nuts, Acidity Regulator (Citric Acid), Salt.'
        },
        {
            'id': '8iDxRR0wTw8FU40hAn3Y',
            'name': 'Carlis Thin Crust Stonebaked Pizza',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Spiced Cooked Chicken Breast 12% (Chicken Breast, Tapioca Starch, Dextrose, Salt, Rapeseed Oil, Paprika Powder), Mozzarella Cheese 12% (Milk), Sugar, Red Onion 5%, Red Pepper Purée, Red Pepper 3%, Yellow Pepper 3%, Rapeseed Oil, Spring Onion 1.5%, Spirit Vinegar, Yeast, Salt, Garlic, Chilli Powder, Dextrose, Potato Starch.'
        },
        {
            'id': '8iTZvm4RYjVN8SyPOrQ2',
            'name': 'Dark Chocolate 70%',
            'brand': 'Tony\'s Chocolonely',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Sugar, Cocoa Butter, Fat Reduced Cocoa Powder, Emulsifier (Soya Lecithin).'
        },
        {
            'id': '8il0I11bwRpgz5pyLYzP',
            'name': 'Coconut Oil Alternative To Garlic And Herbs Soft Cheese',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Coconut Oil (24%), Tapioca Starch, Modified Potato Starch, Salt, Gram Flour, Maize Starch, Sugar, Tricalcium Citrate, Flavourings, Modified Maize Starch, Acidity Regulators (Citric Acid, Lactic Acid, Sodium Lactate), Thickeners (Carrageenan, Guar Gum), Garlic, Parsley, Garlic Powder, Spirit Vinegar, Soya Protein Concentrate, Chive, Basil Leaf.'
        },
        {
            'id': '8ioETnOaSAdn00cpyOzZ',
            'name': 'Golden Chicken And Grain Salas',
            'brand': 'M&S',
            'serving_size_g': 280.0,
            'ingredients': 'Cos Lettuce, Turmeric Yogurt Dressing (16%) (Greek Style Yogurt (Milk), Maple Syrup, Lemon Juice, Water, Ginger, Roasted Garlic Purée, Vegetable Oil (Sunflower/Rapeseed), Salt, Coriander, Chicory Fibre, Citrus Fibre, Oat Fibre, Curry Powder (Coriander Seeds, Turmeric, Fenugreek Seeds, Cumin Seeds, Ground Black Pepper, Salt, Dried Chillies, Dried Garlic, Dried Ginger, Caraway Seeds, Dried Onions), Turmeric, Ground Black Pepper), Cooked Chicken (15%), Cooked Quinoa (12%) (Water, Quinoa Seeds), Cooked Rice (7%) (Water, Red Rice, Wild Rice), Tomatoes, Cooked Chickpeas (5%) (Chickpeas, Water), Cucumber, Lime Infused Red Onions (Red Onions, Lime), Cumin Seeds, Fennel Seeds, Dried Ginger, Dill Seeds, Cloves, Cornflour, Red Chillies, Rapeseed Oil.'
        },
        {
            'id': '8ip3UjvxxWqEiJklVT2F',
            'name': 'Supreme Jaffa Cakes Raspberry',
            'brand': 'E Wedel',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Glucose-Fructose Syrup, Dark Chocolate 15% (Sugar, Cocoa Mass, Cocoa Butter, Emulsifiers (Soya Lecithins, E476), Flavouring), Wheat Flour, Pasteurized Egg Mass, Humectant (Glycerol), Wheat Starch, Gelling Agent (Pectins), Emulsifiers (E471, E475), Concentrated Raspberry Juice (0.3%), Acidity Regulators (Citric Acid, Trisodium Citrate, Malic Acid), Rapeseed Oil, Raising Agent (Ammonium Hydrogen Carbonate), Concentrated Black Carrot Juice, Salt, Flavourings, Colour (Beta-Carotene).'
        },
        {
            'id': '8jFitMT1gOPzx9Btp872',
            'name': 'Oatcakes',
            'brand': 'M&S',
            'serving_size_g': 12.5,
            'ingredients': 'Oatmeal (76%), Wheatflour (with Wheatflour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Palm Oil, Sugar, Sea Salt, Raising Agent (Sodium Bicarbonate), Dried Skimmed Milk.'
        },
        {
            'id': '8mAgw81y38TZvDYzMqsa',
            'name': 'Dark Chocolate Single Origin Peru 80%',
            'brand': 'Waitrose',
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Cane Sugar, Cocoa Butter, Emulsifier (Soya Lecithin).'
        },
        {
            'id': '8mAhRQ0JdqYu15LsNTiW',
            'name': 'Kellog Crunchy NUT Granola',
            'brand': 'Kellogg\'s',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Oats (52%), Sugar, Sustainable Palm Oil, Wheat Flour, Caramelised Hazelnuts (6%) (Hazelnuts, Sugar, Antioxidants (E464, E306)), Hazelnut Flavoured Cereal Pieces (Crisp Rice (Rice Flour, Wheat Flour, Sugar, Malted Wheat Flour, Milk Whey Powder, Salt, Rapeseed Oil, Emulsifier (E471)), Sugar, Natural Flavouring), Salt, Molasses, Dried Coconut, Barley Malt Extract.'
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

    print("🧹 CLEANING INGREDIENTS - BATCH 73\n")

    cleaned_count = update_batch73(db_path)

    # Calculate total progress
    previous_total = 1211  # From batch 72
    total_cleaned = previous_total + cleaned_count

    print(f"✨ BATCH 73 COMPLETE: {cleaned_count} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} products cleaned")

    # Check for milestones
    if total_cleaned >= 1225 and previous_total < 1225:
        print(f"\n🎉 1225 MILESTONE ACHIEVED! 🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"💪 Over 19.0% progress through the messy ingredients!")

    remaining = 6448 - total_cleaned
    print(f"🎯 Approximately {remaining} products with messy ingredients remaining")
