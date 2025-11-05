#!/usr/bin/env python3
"""
Clean ingredients batch 32 - BREAKING THE 300 MILESTONE!
"""

import sqlite3
from datetime import datetime

def update_batch32(db_path: str):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("🧹 CLEANING INGREDIENTS - BATCH 32 (300 MILESTONE!)\\n")

    clean_data = [
        {
            'id': 'eMxs1yKaffPtm2lwstq7',
            'name': 'Lincolnshire Pork Chipolata Sausages',
            'brand': 'Deluxe',
            'serving_size_g': 46.0,
            'ingredients': 'British Pork (90%), Water, Rice Flour, Parsley, Chickpea Flour, Salt, Dried Sage, Dried Parsley, Dried Thyme, Stabiliser (Diphosphates), Maize Starch, Preservative (Sodium Metabisulphite), White Pepper, Black Pepper, Nutmeg, Mace, Dextrose. Filled into Calcium Alginate Casings. Contains Pork, Sulphites.'
        },
        {
            'id': 'tXr48CMvCNR9pIO4Wg9h',
            'name': 'Mini Brioche Bun',
            'brand': 'St. Pierre',
            'serving_size_g': 20.0,
            'ingredients': 'Wheat Flour, Egg, Sugar, Rapeseed Oil, Concentrated Butter (Milk), Yeast, Dried Skimmed Milk, Wheat Gluten, Salt, Flavouring, Milk Proteins, Toasted Malted Rye Flour, Emulsifier (Mono- and Diglycerides of Fatty Acids), Deactivated Yeast, Colour (Beta-Carotene). Contains Cereals Containing Gluten, Eggs, Milk, Rye, Wheat. May Contain Sesame Seeds.'
        },
        {
            'id': 'xjSIDzna0ytEIuRWZAPu',
            'name': 'Dark Chocolate With 70% Cocoa From Ghana',
            'brand': "Mackie's Of Scotland",
            'serving_size_g': 100.0,
            'ingredients': 'Cocoa Mass, Sugar, Emulsifier (Soya Lecithin), Vanilla Extract. Contains Soybeans. May Contain Milk, Nuts, Peanuts.'
        },
        {
            'id': 'HjXOH287ODAoQGUNH2iE',
            'name': 'Frusli Juicy Blueberries Chewy Cereal Bars',
            'brand': 'Jordans',
            'serving_size_g': 100.0,
            'ingredients': 'British Wholegrain Oat Flakes (34%), Fruit Pieces (Blueberry Infused Diced Cranberries (12%) (Sugar, Cranberries, Blueberry Juice, Grape Juice Concentrate), Raisins (7%), Dried Sweetened Blueberries (1.5%) (Blueberries, Sugar), Fruit Purée Pieces (1%) (Concentrated Apple Purée, Concentrated Apple Juice, Concentrated Blueberry Purée, Citrus Fibre, Gelling Agent (Pectin), Concentrates (Carrot, Blueberry), Natural Flavouring)), Glucose Syrup, Wholegrain Oat Flour, Sugar, Honey, Vegetable Oil (Rapeseed and Sunflower in Varying Proportion), Rice Flour, Natural Flavouring, Chopped Roasted Hazelnuts. Contains Cereals Containing Gluten, Nuts, Oats.'
        },
        {
            'id': 'G55WrlM5RpjPD7PPVm2I',
            'name': 'Dry Cured Honey Roast Ham',
            'brand': 'Farmfoods',
            'serving_size_g': 100.0,
            'ingredients': 'Pork, Salt, Honey, White Sugar, Stabilisers (Diphosphates, Triphosphates), Brown Sugar, Smoke Flavouring, Antioxidant (Sodium Ascorbate), Preservative (Sodium Nitrite). Made with 100g of Raw Pork per 100g of Finished Product. Contains Pork.'
        },
        {
            'id': 'l2Ylhj7WC1wxLPKN8GVX',
            'name': 'Cheese & Onion Dip',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Medium Fat Hard Cheese (Milk) (23%), Red Leicester Cheese (with Colour (Beta Carotene)) (Milk) (12%), White Onion (10%), Rapeseed Oil, Cornflour, Pasteurised Egg Yolk, Spirit Vinegar, Sugar, Salt, Lemon Juice from Concentrate, Chive. Contains Eggs, Milk.'
        },
        {
            'id': 'iYFazJvWWNKXee5lXnbg',
            'name': 'Creamy Garlic Chicken Kievs',
            'brand': 'Moy Park',
            'serving_size_g': 117.0,
            'ingredients': 'Chicken Breast (64%), Breadcrumb (Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Yeast, Salt), Butter (Milk), Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Rapeseed Oil, Wheat Starch, Wheat Gluten, Roast Garlic Purée, Garlic Purée, Parsley, Salt, Sugar, White Pepper, Concentrated Lemon Juice, Sunflower Oil, Yeast, Flavouring. Contains Cereals Containing Gluten, Milk, Wheat.'
        },
        {
            'id': 'lfgR3Vl3dbUgSE09vgII',
            'name': 'Lime And Yuzu Mojito',
            'brand': 'Belvoir Farm',
            'serving_size_g': 100.0,
            'ingredients': 'Carbonated Spring Water, Sugar, Fresh Lime Juice (5%), Lime Juice from Concentrate (4%), Yuzu Juice, Mint Extract.'
        },
        {
            'id': 'R5ZFCwtHSkpKf0CWzF6h',
            'name': 'Cherry Bakewell',
            'brand': "Sainsbury's",
            'serving_size_g': 40.0,
            'ingredients': 'Fortified Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Sugar, Vegetable Oils (Palm, Rapeseed, Palm Kernel, Palm Stearin), Glucose Syrup, Plum and Raspberry Jam (9%) (Glucose-Fructose Syrup, Plum Purée (32%), Sugar, Raspberry Purée (3.0%), Gelling Agent (Pectin), Acid (Citric Acid), Acidity Regulator (Sodium Citrate), Preservative (Potassium Sorbate), Colour (Anthocyanins), Flavouring), Glacé Cherries (5%) (Cherries, Glucose-Fructose Syrup, Sugar, Acid (Citric Acid), Colour (Anthocyanins)), Skimmed Milk Powder, Whey Powder (Milk), Dried Egg White, Flavouring, Dextrose, Emulsifiers (Sorbitan Monostearate, Polysorbate 60, Mono- and Diglycerides of Fatty Acids), Raising Agents (Disodium Diphosphate, Sodium Bicarbonate), Ground Almond, Salt, Humectant (Vegetable Glycerine), Preservative (Potassium Sorbate). Contains Cereals Containing Gluten, Eggs, Milk, Nuts, Wheat.'
        },
        {
            'id': 'MiCJtZFgYPFideWyMTmP',
            'name': 'Mushy Processed Peas',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Dehydrated Processed Peas (95%), Water, Sugar, Salt, Colour (Copper Complexes of Chlorophyllins, Carotenes).'
        },
        {
            'id': 'KV3LQoylvib5pcCDOaJR',
            'name': 'Marshmallow Mateys Cereal',
            'brand': 'Generic',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Grain Oat Flour, Sugar, Marshmallows (18%) (Sugar, Modified Corn Starch, Corn Syrup, Dextrose, Gelatin, Artificial Flavouring, Colours (Tartrazine (E102), Sunset Yellow (E110), Brilliant Blue (E133), Allura Red (E129))), Corn Syrup, Wheat Starch, Salt, Antioxidant (Calcium Carbonate (E170)), Acidity Regulator (Trisodium Phosphate (E339iii)), Vitamins (Thiamin Mononitrate (B1), Riboflavin (B2), Niacin (B3), Pantothenic Acid (B5), Pyridoxine Hydrochloride (B6), Folic Acid, Vitamin B12, Vitamin A, Vitamin C), Iron (Ferric Orthophosphate), Zinc (Zinc Oxide). Contains Cereals Containing Gluten, Oats, Wheat.'
        },
        {
            'id': 'wdLYJ2jq3WVqZIXjhD7d',
            'name': 'Cheerios Vanilla Os',
            'brand': 'Cheerios',
            'serving_size_g': 100.0,
            'ingredients': 'Whole Grain Oat Flour (31.5%), Whole Grain Wheat (31.5%), Whole Grain Barley Flour (19.0%), Fructo-Oligosaccharides, Wheat Starch, Sugar, Whole Grain Maize Flour (2.2%), Whole Grain Rice Flour (2.2%), Sunflower Oil, Calcium Carbonate, Salt, Flavourings, Antioxidant (Tocopherols), Vitamins (Iron, Vitamin C, Niacin, Pantothenic Acid, Folic Acid, Vitamin B6, Riboflavin, Vitamin D). Contains Barley, Cereals Containing Gluten, Oats, Wheat.'
        },
        {
            'id': 'Aauj8Zb6y78QMejO9SBv',
            'name': 'Sliced Chorizo',
            'brand': 'Co-op',
            'serving_size_g': 100.0,
            'ingredients': 'Pork (87%), Salt, Lactose (Milk), Paprika (1%), Dextrose, Sugar, Smoked Paprika, Milk Protein, Garlic, Paprika Extract, Acidity Regulator (Sodium Citrate), Antioxidants (Sodium Erythorbate, Extracts of Rosemary), Preservatives (Sodium Nitrite, Potassium Nitrate), Black Pepper, Oregano. Contains Milk, Pork.'
        },
        {
            'id': '83gjGOTBYfBwjA0xRm1d',
            'name': 'Cherries And Berries Squash',
            'brand': 'Tesco',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Apple Juice from Concentrate (32%), Cherry Juice from Concentrate (4%), Citric Acid, Strawberry Juice from Concentrate (2%), Raspberry Juice from Concentrate (2%), Acidity Regulator (Sodium Citrate), Malic Acid, Sweeteners (Sucralose, Acesulfame K), Flavourings, Colour (Anthocyanins), Preservatives (Potassium Sorbate, Sodium Metabisulphite). Contains Sulphites.'
        },
        {
            'id': 'rrrLOaZwUjus6MFALONT',
            'name': 'Granary Loaf',
            'brand': 'M&S',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour (Wheat Flour, Calcium Carbonate, Iron, Niacin, Thiamin), Water, Malted Wheat Flakes (12%) (Contains Quinoa), Sprouted Barley Grains (7%), Barley Grains, Sourdough (Water, Barley Flour, Quinoa, Starter Culture), Salt, Yeast, Malted Barley Flour, Dried Wheat Gluten, Vinegar, Palm Oil, Soya Flour, Wheat Germ, Caramelised Sugar, Rapeseed Oil, Flour Treatment Agent (Ascorbic Acid), Rye Flour. Contains Barley, Cereals Containing Gluten, Rye, Soybeans, Wheat. May Contain Nuts, Peanuts, Sesame.'
        },
        {
            'id': 'e0679NBRP5RWe9LO7OZa',
            'name': 'Cookie Chocolate',
            'brand': 'Generic',
            'serving_size_g': 30.0,
            'ingredients': 'Sugar, Whole Milk Powder, Cocoa Butter, Cocoa Mass, Cookie Pieces (7.78%) (Wheat Flour, Butter (Milk), Sugar, Salt), Dark Chocolate Pieces (6.11%) (Cocoa Mass, Sugar, Cocoa Butter, Cocoa Powder, Emulsifier (Soy Lecithin)), Emulsifier (Soy Lecithin). Contains Cereals Containing Gluten, Milk, Soybeans, Wheat. May Contain Eggs, Nuts, Peanuts.'
        },
        {
            'id': 'RbQ4BUDUZ1VJ6LXLOMI6',
            'name': 'Vegan No Duck & Hoisin Wrap',
            'brand': 'Boots',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Wrap (Fortified Wheat Flour, Water, Vegetable Oils (Palm, Rapeseed), Raising Agents, Sugar, Acidity Regulator, Salt), Seasoned Wheat Gluten and Soya Protein Pieces (21%) (Soya Protein, Wheat Gluten, Salt, Soya Bean Oil, Flavouring, Stock Powder (Yeast Extract, Chicory Extract, Salt, Sunflower Oil, Carrot Extract, Onion Powder, Tomato Powder), Yeast Extract, Black Pepper, Onion Powder), Vegan Hoisin Sauce (10%) (Water, Sugar, Brown Sugar, Dark Fermented Bean Paste (Fermented Soya Beans, Water, Salt, Fortified Wheat Flour), Concentrated Plum Juice, Cornflour, Rapeseed Oil, Soya Sauce), Cucumber, Lettuce, Spring Onion. Contains Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'zkRkTsOsiekVEl0ZdyHv',
            'name': 'Isey Skyr Baked Apples',
            'brand': 'Isey Skyr',
            'serving_size_g': 170.0,
            'ingredients': 'Skimmed Milk, Water, Apples (8%), Maize Starch, Flavours, Thickener (Pectin), Caramelised Sugar Syrup (0.1%), Sweeteners (Sucralose, Acesulfame K), Skyr Cultures. Contains Milk.'
        },
        {
            'id': 'EQ0D3orttlJQi6SoRRf0',
            'name': 'Fine Egg Noodles',
            'brand': 'Blue Dragon',
            'serving_size_g': 100.0,
            'ingredients': 'Wheat Flour, Water, Egg Yolk Powder (1%), Salt, Raising Agents (Sodium Hydrogen Carbonate, Potassium Hydrogen Carbonate). Contains Cereals Containing Gluten, Eggs, Wheat. May Contain Soya, Peanuts, Nuts.'
        },
        {
            'id': 'e5MwJLA0Yw1nm1MsCwGw',
            'name': 'Chip Shop Curry Sauce Pots',
            'brand': 'Bisto',
            'serving_size_g': 90.0,
            'ingredients': 'Water, Modified Maize Starch, Maltodextrin, Salt, Sugar, Onion Powder, Rapeseed Oil, Flavourings (Contain Celery), Tomato Powder, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Ground Spices (Paprika, Cumin, Turmeric, Black Pepper, Chilli, Cayenne Pepper), Tomato Paste, Wheat Flour (with added Calcium, Iron, Niacin, Thiamin), Emulsifier (Soya Lecithin), Garlic Powder, Colour (Ammonia Caramel), Yeast Extract (Contains Barley). Contains Barley, Celery, Cereals Containing Gluten, Soybeans, Wheat.'
        },
        {
            'id': 'P5Zk1lXHdHXIePVfqDtX',
            'name': 'Stonebaked Thin BBQ Meat Feast Pizza',
            'brand': 'Tesco',
            'serving_size_g': 160.0,
            'ingredients': 'Wheat Flour, Tomato Purée, Mozzarella Full Fat Soft Cheese (15%) (Milk), Water, Pepperoni (5%) (Pork, Pork Fat, Salt, Dextrose, Spices, Garlic Powder, Red Pepper Extract, Antioxidants (Extracts of Rosemary, Sodium Ascorbate), Pepper Extract, Ginger Extract, Preservative (Sodium Nitrite)), Formed Ham (5%) (Pork, Salt, Dextrose, Sugar, Antioxidants (Sodium Ascorbate, Extracts of Rosemary), Preservative (Sodium Nitrite)), Meatballs (5%) (Pork, Water, Wheat Flour, Salt, Dextrose, Spices, Sugar, Tomato, Antioxidants (Ascorbic Acid, Extracts of Rosemary), Onion Powder, Rosemary, Garlic Powder, Pepper Extract, Coriander Extract, Cardamom Extract, Yeast, Rapeseed Oil), Sugar, Spirit Vinegar, Plum, Rapeseed Oil, Glucose-Fructose Syrup, Yeast, Dextrose, Salt, Caramelised Sugar, Mustard Seed, Wheat Starch, Potato Starch, Pea Starch, Spices, Smoked Maltodextrin, Onion Powder, Dried Herbs, Dried Garlic, Cinnamon, Sunflower Oil. Contains Cereals Containing Gluten, Milk, Mustard, Pork, Wheat.'
        },
        {
            'id': 'Ns6kXZQi5KM8Cojd93Uj',
            'name': 'Vegetable Gravy',
            'brand': 'Bisto',
            'serving_size_g': 100.0,
            'ingredients': 'Potato Starch, Dried Glucose Syrup, Salt, Rapeseed Oil, Flavourings (Contain Celery), Maltodextrin, Flavour Enhancers (Monosodium Glutamate, Disodium 5-Ribonucleotides), Roasted Carrot Juice Concentrate Powder, Ground Bay Leaf, Ground Black Pepper, Colour (Ammonia Caramel), Sugar, Garlic Powder, Emulsifier (Soya Lecithin), Ground Thyme, Onion Oil, Rosemary Extract. Contains Celery, Soybeans. May Contain Cereals Containing Gluten, Wheat.'
        },
        {
            'id': 'sLUVXia6rb8atRyE9LcB',
            'name': 'Mixed Fruit',
            'brand': 'Asda',
            'serving_size_g': 100.0,
            'ingredients': 'Mixed Vine Fruits (86%) (Sultanas (50%), Currants (18%), Raisins (18%), Cotton Seed Oil, Sunflower Oil), Candied Citrus Peels (14%) (Orange Peel, Glucose-Fructose Syrup, Lemon Peel, Sugar, Acidity Regulator (Citric Acid), Preservatives (Sulphur Dioxide, Potassium Sorbate)). Contains Sulphites.'
        },
        {
            'id': 'zOeCthyqGcq5zsRX2M5n',
            'name': 'Tangfastics',
            'brand': 'Haribo',
            'serving_size_g': 100.0,
            'ingredients': 'Glucose Syrup, Sugar, Gelatine, Dextrose, Acids (Citric Acid, Malic Acid), Acidity Regulators (Calcium Citrates, Sodium Hydrogen Malate), Caramelised Sugar Syrup, Fruit and Plant Concentrates (Apple, Aronia, Blackcurrant, Carrot, Elderberry, Grape, Hibiscus, Kiwi, Lemon, Mango, Orange, Passion Fruit, Safflower, Spirulina), Flavouring, Elderberry Extract, Glazing Agent (Carnauba Wax).'
        },
        {
            'id': 'Mksvql3aR1tUMUh0mgCV',
            'name': 'Taste The Difference Kashmiri Style Chicken Korma',
            'brand': "Sainsbury's",
            'serving_size_g': 400.0,
            'ingredients': 'Cooked Saffron Pilau Rice (Water, Basmati Rice, Onion, Skimmed Milk, Rapeseed Oil, Mint, Lemon Juice, Salt, Cardamom, Turmeric, Cardamom Pod, Mace, Saffron), Chargrilled Marinated Chicken (20%) (Chicken Breast, Low Fat Yogurt (Milk), Cornflour, Coriander Leaf, Rapeseed Oil, Ginger Purée, Garlic Purée, Paprika, Turmeric, Salt, Coriander, Cumin, Cinnamon, Clove, Colour (Paprika Extract), White Pepper, Chilli Powder, Bay Leaf), Onion, 16% Fat Cream (Milk), Low Fat Yogurt (Milk), Water, Coconut Extract, Cashew Nut, Rapeseed Oil, Ginger Purée, Garlic Purée, Butter (Milk), Sugar, Pistachio Nuts, Almond Flakes, Desiccated Coconut, Coriander Leaf, Salt, Cumin, Turmeric, Green Chilli Purée, Coriander, Cardamom, Mace, Cinnamon, Chilli Powder, Ginger Powder, White Pepper, Paprika, Clove, Nutmeg, Bay Leaf. Contains Milk, Nuts.'
        },
        {
            'id': 'ZMGyNYp2rZzaVYUyPxqO',
            'name': 'Fresh Custard',
            'brand': "Sainsbury's",
            'serving_size_g': 100.0,
            'ingredients': 'British Milk, Water, Sugar, Thickener (Modified Maize Starch), British Cream (Milk) (3.5%), Flavouring, Stabiliser (Tara Gum), Colour (Carotenes). Contains Milk.'
        },
        {
            'id': 'WhoM5BQtxDqVe4QCnLD1',
            'name': 'Peppermint Cream',
            'brand': 'Cadbury',
            'serving_size_g': 100.0,
            'ingredients': 'Sugar, Cocoa Mass, Glucose Syrup, Humectant (Glycerol), Vegetable Fats (Palm, Shea), Emulsifiers (Soya Lecithin, E476), Flavouring. Chocolate Contains Vegetable Fats in Addition to Cocoa Butter. Contains Soybeans. May Contain Nuts, Wheat, Milk.'
        },
        {
            'id': '62JHXPU80GLzbEan0ynv',
            'name': 'Peach Greens Superfood Powder',
            'brand': 'Free Soul',
            'serving_size_g': 100.0,
            'ingredients': 'Natural Flavourings, Acid (Citric Acid), Sweetener (Steviol Glycosides from Stevia), Flaxseed Powder, Spinach Powder, Apple Powder, Apple Fibre Powder, Alfalfa Powder, Broccoli Powder, Spirulina Powder, Wheatgrass Powder, Kale Powder, Chlorella Powder, KSM-66 Organic Ashwagandha Powder (12:1), Barley Grass Powder, Lucuma Powder, Moringa Leaf Powder, Green Tea (Camellia Sinensis) Extract (25:1), Pineapple Fruit Powder, Red Beetroot Powder, Fennel Seed Extract (24:1), Maca Powder, Actazin Standardised Green Kiwi Fruit Powder, Livaux Gold Kiwi Fruit Powder. Contains Barley, Cereals Containing Gluten.'
        },
        {
            'id': 'LglwlbWvkhdEGPhkgw6b',
            'name': 'Summer Fruits Squash',
            'brand': 'Morrisons',
            'serving_size_g': 100.0,
            'ingredients': 'Water, Fruit Juices from Concentrates (20%) (Apple, Strawberry, Raspberry), Acid (Citric Acid), Acidity Regulator (Sodium Citrates), Flavouring, Sweeteners (Acesulfame K, Sucralose), Preservatives (Potassium Sorbate, Sodium Metabisulphite), Fruit and Vegetable Concentrates (Black Carrot, Hibiscus), Antioxidant (Ascorbic Acid). Contains Sulphites.'
        },
        {
            'id': 'D9ghpMQVn7XvIRJzdJ9w',
            'name': 'White Chocolate Salted Peanut Protein Bar',
            'brand': 'Grenade',
            'serving_size_g': 35.0,
            'ingredients': 'White Chocolate with Sweetener (31%) (Sweetener (Maltitol), Cocoa Butter, Whole Milk Powder, Emulsifier (Lecithins (Soy)), Natural Flavouring), Protein Blend (Calcium Caseinate (Milk), Whey Protein Isolate (Milk)), Humectant (Glycerol), Bovine Collagen Hydrolysate, Roasted Peanut Pieces (7%), Water, Dietary Fibre (Polydextrose), Palm Fat, Peanut Paste (2.3%), Flavouring, Salt, Sweetener (Sucralose). Contains Milk, Peanuts, Soybeans.'
        }
    ]

    updates_made = 0
    for product in clean_data:
        cursor.execute("""
            UPDATE foods
            SET ingredients = ?, serving_size_g = ?, updated_at = ?
            WHERE id = ?
        """, (product['ingredients'], product['serving_size_g'],
              int(datetime.now().timestamp()), product['id']))

        if cursor.rowcount > 0:
            print(f"✅ {product['brand']} - {product['name']}")
            print(f"   Serving: {product['serving_size_g']}g\\n")
            updates_made += 1

    conn.commit()
    conn.close()

    total_cleaned = 271 + updates_made

    print(f"✨ BATCH 32 COMPLETE: {updates_made} products cleaned")
    print(f"📊 TOTAL PROGRESS: {total_cleaned} / 681")

    if total_cleaned >= 300:
        print(f"\\n🎉🎉🎉 300 MILESTONE ACHIEVED! 🎉🎉🎉")
        print(f"🎯 {total_cleaned} products cleaned!")
        print(f"🚀 Next milestone: {350 - total_cleaned} products until 350!\\n")
    else:
        remaining_to_300 = 300 - total_cleaned
        print(f"🎯 Next milestone: {remaining_to_300} products until 300!\\n")

if __name__ == "__main__":
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    update_batch32(db_path)
