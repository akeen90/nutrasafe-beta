#!/usr/bin/env python3
"""
GPT Knowledge-Based Food Updater
Uses ChatGPT's existing knowledge to fill in missing ingredients, serving sizes, and nutrition data
for common UK food products without any web scraping
"""

import sqlite3
import re
from typing import Optional, Dict, Tuple, List

class GPTKnowledgeUpdater:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.updated_count = 0
        self.error_count = 0
        
    def get_gpt_food_knowledge(self) -> Dict[str, Dict]:
        """
        Built-in knowledge base of common UK foods with ingredients, serving sizes, and nutrition
        This represents what ChatGPT already knows about common food products
        """
        
        return {
            # Beverages - Soft Drinks
            'coca cola': {
                'ingredients': 'Carbonated Water, Sugar, Colour (Caramel E150d), Acid (Phosphoric Acid), Natural Flavourings including Caffeine',
                'serving_size': '330ml',
                'energy_kcal_100g': 42,
                'fat_100g': 0,
                'carbs_100g': 10.6,
                'sugar_100g': 10.6,
                'protein_100g': 0,
                'salt_100g': 0
            },
            'pepsi': {
                'ingredients': 'Carbonated Water, Sugar, Colour (Caramel E150d), Acid (Phosphoric Acid), Natural Flavouring including Caffeine',
                'serving_size': '330ml',
                'energy_kcal_100g': 43,
                'fat_100g': 0,
                'carbs_100g': 11,
                'sugar_100g': 11,
                'protein_100g': 0,
                'salt_100g': 0.02
            },
            'sprite': {
                'ingredients': 'Carbonated Water, Sugar, Acid (Citric Acid), Natural Lemon and Lime Flavourings, Sweeteners (Acesulfame K, Aspartame)',
                'serving_size': '330ml',
                'energy_kcal_100g': 18,
                'fat_100g': 0,
                'carbs_100g': 4.5,
                'sugar_100g': 4.5,
                'protein_100g': 0,
                'salt_100g': 0.03
            },
            'fanta orange': {
                'ingredients': 'Carbonated Water, Sugar, Orange Juice from Concentrate (4%), Citric Acid, Natural Orange Flavouring, Preservative (Potassium Sorbate)',
                'serving_size': '330ml',
                'energy_kcal_100g': 38,
                'fat_100g': 0,
                'carbs_100g': 9.3,
                'sugar_100g': 9.3,
                'protein_100g': 0,
                'salt_100g': 0.01
            },
            
            # Chocolate & Confectionery
            'dairy milk': {
                'ingredients': 'Milk Chocolate, Sugar, Cocoa Butter, Milk Powder, Cocoa Mass, Vegetable Fats (Palm, Shea), Emulsifiers (E442, E476), Flavourings',
                'serving_size': '45g',
                'energy_kcal_100g': 534,
                'fat_100g': 30,
                'carbs_100g': 57,
                'sugar_100g': 56,
                'protein_100g': 7.3,
                'salt_100g': 0.24
            },
            'kit kat': {
                'ingredients': 'Sugar, Wheat Flour, Cocoa Butter, Milk Powder, Cocoa Mass, Lactose and Protein from Whey, Palm Fat, Emulsifier (Lecithins), Raising Agent (Sodium Bicarbonate), Salt, Natural Vanilla Flavouring',
                'serving_size': '45g',
                'energy_kcal_100g': 518,
                'fat_100g': 25,
                'carbs_100g': 62,
                'sugar_100g': 47,
                'protein_100g': 7,
                'salt_100g': 0.18
            },
            'mars bar': {
                'ingredients': 'Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose, Milk Fat, Palm Fat, Salt, Egg White Powder, Milk Protein, Natural Vanilla Extract',
                'serving_size': '51g',
                'energy_kcal_100g': 449,
                'fat_100g': 17,
                'carbs_100g': 68,
                'sugar_100g': 59,
                'protein_100g': 4.6,
                'salt_100g': 0.5
            },
            'snickers': {
                'ingredients': 'Milk Chocolate (Sugar, Cocoa Butter, Chocolate, Skimmed Milk Powder, Lactose, Milk Fat, Salt, Artificial Flavour), Peanuts, Corn Syrup, Sugar, Palm Oil, Skimmed Milk Powder, Lactose, Salt, Egg Whites, Artificial Flavour',
                'serving_size': '48g',
                'energy_kcal_100g': 488,
                'fat_100g': 24,
                'carbs_100g': 56,
                'sugar_100g': 48,
                'protein_100g': 9,
                'salt_100g': 0.5
            },
            'twix': {
                'ingredients': 'Milk Chocolate (Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey, Palm Fat, Milk Fat, Emulsifier (Soya Lecithin), Natural Vanilla Extract), Caramel (Glucose Syrup, Sugar, Sweetened Condensed Skimmed Milk, Vegetable Fat (Palm), Lactose and Protein from Whey, Salt, Emulsifier (Mono- and Diglycerides of Fatty Acids), Natural Vanilla Extract), Wheat Flour',
                'serving_size': '50g',
                'energy_kcal_100g': 495,
                'fat_100g': 24,
                'carbs_100g': 64,
                'sugar_100g': 49,
                'protein_100g': 5.7,
                'salt_100g': 0.33
            },
            
            # Crisps & Snacks
            'walkers ready salted': {
                'ingredients': 'Potatoes, Sunflower Oil, Salt',
                'serving_size': '25g',
                'energy_kcal_100g': 533,
                'fat_100g': 34,
                'carbs_100g': 50,
                'sugar_100g': 0.5,
                'protein_100g': 6.6,
                'salt_100g': 1.3
            },
            'walkers cheese and onion': {
                'ingredients': 'Potatoes, Sunflower Oil, Cheese & Onion Flavour (Lactose (from Milk), Salt, Dried Onion, Cheese Powder (from Milk), Potassium Chloride, Sugar, Dried Garlic, Citric Acid)',
                'serving_size': '25g',
                'energy_kcal_100g': 533,
                'fat_100g': 34,
                'carbs_100g': 50,
                'sugar_100g': 2.8,
                'protein_100g': 6,
                'salt_100g': 1.8
            },
            'walkers salt and vinegar': {
                'ingredients': 'Potatoes, Sunflower Oil, Salt & Vinegar Flavour (Lactose (from Milk), Salt, Sodium Diacetate, Citric Acid, Malic Acid, Yeast Extract Powder)',
                'serving_size': '25g',
                'energy_kcal_100g': 533,
                'fat_100g': 34,
                'carbs_100g': 50,
                'sugar_100g': 1.2,
                'protein_100g': 6,
                'salt_100g': 2.3
            },
            
            # Cereals
            'cornflakes': {
                'ingredients': 'Maize, Salt, Sugar, Barley Malt Extract, Vitamins (Niacin, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin B12), Iron',
                'serving_size': '30g',
                'energy_kcal_100g': 378,
                'fat_100g': 0.9,
                'carbs_100g': 84,
                'sugar_100g': 8,
                'protein_100g': 7,
                'salt_100g': 1.3
            },
            'weetabix': {
                'ingredients': 'Wholemeal Wheat (95%), Malted Barley Extract, Sugar, Salt, Niacin, Iron, Riboflavin (B2), Thiamin (B1), Folic Acid',
                'serving_size': '2 biscuits (38g)',
                'energy_kcal_100g': 362,
                'fat_100g': 2.2,
                'carbs_100g': 69,
                'sugar_100g': 4.4,
                'protein_100g': 12,
                'salt_100g': 0.27
            },
            'rice krispies': {
                'ingredients': 'Rice, Sugar, Salt, Barley Malt Extract, Vitamins (Niacin, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin B12), Iron',
                'serving_size': '30g',
                'energy_kcal_100g': 387,
                'fat_100g': 1,
                'carbs_100g': 87,
                'sugar_100g': 10,
                'protein_100g': 6,
                'salt_100g': 1.3
            },
            
            # Biscuits
            'digestive biscuits': {
                'ingredients': 'Wheat Flour, Vegetable Oil (Palm), Wholemeal Wheat Flour, Sugar, Partially Inverted Sugar Syrup, Raising Agents (Sodium Bicarbonate, Malic Acid), Salt',
                'serving_size': '2 biscuits (25g)',
                'energy_kcal_100g': 471,
                'fat_100g': 20.9,
                'carbs_100g': 62.1,
                'sugar_100g': 16.4,
                'protein_100g': 7.1,
                'salt_100g': 1.2
            },
            'hobnobs': {
                'ingredients': 'Rolled Oats (31%), Wheat Flour, Vegetable Oil (Sustainable Palm), Sugar, Partially Inverted Sugar Syrup, Raising Agents (Sodium Bicarbonate, Ammonium Bicarbonate), Salt',
                'serving_size': '2 biscuits (27g)',
                'energy_kcal_100g': 466,
                'fat_100g': 19.3,
                'carbs_100g': 64.5,
                'sugar_100g': 21.6,
                'protein_100g': 6.7,
                'salt_100g': 0.87
            },
            
            # Yogurts
            'greek yogurt': {
                'ingredients': 'Yogurt (Milk), Live Yogurt Cultures (L. bulgaricus, S. thermophilus)',
                'serving_size': '125g',
                'energy_kcal_100g': 97,
                'fat_100g': 5,
                'carbs_100g': 4,
                'sugar_100g': 4,
                'protein_100g': 9,
                'salt_100g': 0.1
            },
            'natural yogurt': {
                'ingredients': 'Yogurt (Milk), Live Yogurt Cultures (L. bulgaricus, S. thermophilus)',
                'serving_size': '125g',
                'energy_kcal_100g': 61,
                'fat_100g': 3.25,
                'carbs_100g': 4.7,
                'sugar_100g': 4.7,
                'protein_100g': 3.5,
                'salt_100g': 0.05
            },

            # More Beverages
            '7up': {
                'ingredients': 'Carbonated Water, Sugar, Citric Acid, Natural Lemon and Lime Flavouring, Sodium Citrate',
                'serving_size': '330ml',
                'energy_kcal_100g': 40,
                'fat_100g': 0,
                'carbs_100g': 10,
                'sugar_100g': 10,
                'protein_100g': 0,
                'salt_100g': 0.01
            },
            'dr pepper': {
                'ingredients': 'Carbonated Water, Sugar, Colour (Caramel E150d), Phosphoric Acid, Flavourings, Preservative (Potassium Sorbate), Caffeine',
                'serving_size': '330ml',
                'energy_kcal_100g': 41,
                'fat_100g': 0,
                'carbs_100g': 10.3,
                'sugar_100g': 10.3,
                'protein_100g': 0,
                'salt_100g': 0.01
            },
            'irn bru': {
                'ingredients': 'Carbonated Water, Sugar, Acid (Citric Acid), Flavourings, Preservative (E211), Caffeine, Colours (Sunset Yellow FCF, Ponceau 4R)',
                'serving_size': '330ml',
                'energy_kcal_100g': 34,
                'fat_100g': 0,
                'carbs_100g': 8.5,
                'sugar_100g': 8.5,
                'protein_100g': 0,
                'salt_100g': 0.02
            },
            'ribena': {
                'ingredients': 'Water, Sugar, Blackcurrant Juice from Concentrate (10%), Citric Acid, Natural Flavouring, Vitamin C',
                'serving_size': '250ml',
                'energy_kcal_100g': 46,
                'fat_100g': 0,
                'carbs_100g': 11.5,
                'sugar_100g': 11.5,
                'protein_100g': 0,
                'salt_100g': 0
            },
            'orange juice': {
                'ingredients': 'Orange Juice from Concentrate, Vitamin C',
                'serving_size': '200ml',
                'energy_kcal_100g': 45,
                'fat_100g': 0.1,
                'carbs_100g': 10.4,
                'sugar_100g': 10.4,
                'protein_100g': 0.8,
                'salt_100g': 0
            },
            'apple juice': {
                'ingredients': 'Apple Juice from Concentrate, Vitamin C',
                'serving_size': '200ml',
                'energy_kcal_100g': 46,
                'fat_100g': 0.1,
                'carbs_100g': 11.3,
                'sugar_100g': 11.3,
                'protein_100g': 0.1,
                'salt_100g': 0
            },

            # More Chocolate & Confectionery
            'bounty': {
                'ingredients': 'Milk Chocolate (Sugar, Cocoa Butter, Dried Skimmed Milk, Cocoa Mass, Lactose, Milk Fat, Emulsifiers (Soya Lecithin, E476), Vanilla Extract), Coconut (21%), Sugar, Glucose Syrup, Humectant (Glycerol), Salt, Emulsifier (Mono- and Diglycerides of Fatty Acids), Natural Vanilla Flavouring',
                'serving_size': '57g',
                'energy_kcal_100g': 473,
                'fat_100g': 25,
                'carbs_100g': 57,
                'sugar_100g': 50,
                'protein_100g': 4.1,
                'salt_100g': 0.23
            },
            'aero': {
                'ingredients': 'Sugar, Dried Skimmed Milk, Cocoa Butter, Cocoa Mass, Vegetable Fats (Palm, Shea), Lactose and Protein from Whey (Milk), Milk Fat, Emulsifier (Lecithins)',
                'serving_size': '36g',
                'energy_kcal_100g': 535,
                'fat_100g': 31,
                'carbs_100g': 56,
                'sugar_100g': 55,
                'protein_100g': 7,
                'salt_100g': 0.16
            },
            'toblerone': {
                'ingredients': 'Sugar, Cocoa Mass, Cocoa Butter, Milk Powder, Honey (3%), Milk Fat, Almonds (1.6%), Emulsifier (Lecithin), Egg White, Flavouring',
                'serving_size': '35g',
                'energy_kcal_100g': 534,
                'fat_100g': 30,
                'carbs_100g': 59,
                'sugar_100g': 57,
                'protein_100g': 4.9,
                'salt_100g': 0.08
            },
            'galaxy': {
                'ingredients': 'Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose and Protein from Whey, Palm Fat, Milk Fat, Emulsifiers (Soya Lecithin, E476), Vanilla Extract',
                'serving_size': '42g',
                'energy_kcal_100g': 544,
                'fat_100g': 32,
                'carbs_100g': 56,
                'sugar_100g': 55,
                'protein_100g': 6.5,
                'salt_100g': 0.19
            },
            'maltesers': {
                'ingredients': 'Sugar, Cocoa Butter, Skimmed Milk Powder, Cocoa Mass, Lactose, Milk Fat, Wheat Flour, Palm Fat, Milk Serum Powder, Emulsifiers (Soya Lecithin, E476), Barley Malt Extract, Salt, Raising Agent (E341), Natural Vanilla Extract',
                'serving_size': '37g',
                'energy_kcal_100g': 492,
                'fat_100g': 22,
                'carbs_100g': 68,
                'sugar_100g': 59,
                'protein_100g': 6,
                'salt_100g': 0.3
            },
            'haribo': {
                'ingredients': 'Glucose Syrup, Sugar, Gelatine, Dextrose, Fruit Juice from Concentrate (Apple, Strawberry, Raspberry, Orange, Lemon, Pineapple), Citric Acid, Fruit and Plant Concentrates, Flavouring, Glazing Agent (Beeswax, Carnauba Wax), Invert Sugar Syrup',
                'serving_size': '30g',
                'energy_kcal_100g': 343,
                'fat_100g': 0.5,
                'carbs_100g': 77,
                'sugar_100g': 46,
                'protein_100g': 6.9,
                'salt_100g': 0.07
            },

            # More Crisps & Snacks  
            'pringles': {
                'ingredients': 'Dehydrated Potatoes, Vegetable Oils (Sunflower, Palm, Corn), Rice Flour, Wheat Starch, Corn Flour, Emulsifier (E471), Salt, Colour (Annatto)',
                'serving_size': '25g',
                'energy_kcal_100g': 534,
                'fat_100g': 35,
                'carbs_100g': 49,
                'sugar_100g': 2.2,
                'protein_100g': 4,
                'salt_100g': 1.3
            },
            'walkers prawn cocktail': {
                'ingredients': 'Potatoes, Sunflower Oil, Prawn Cocktail Flavour (Lactose (from Milk), Sugar, Flavour Enhancer (Monosodium Glutamate), Salt, Acid (Citric Acid), Potassium Chloride, Dried Yeast, Colours (Paprika Extract, Beetroot Red), Flavourings)',
                'serving_size': '25g',
                'energy_kcal_100g': 533,
                'fat_100g': 34,
                'carbs_100g': 50,
                'sugar_100g': 3.1,
                'protein_100g': 6,
                'salt_100g': 1.4
            },
            'walkers roast chicken': {
                'ingredients': 'Potatoes, Sunflower Oil, Roast Chicken Flavour (Flavour Enhancer (Monosodium Glutamate), Salt, Sugar, Chicken Powder, Dried Yeast Extract, Acid (Citric Acid), Spice Extracts (Turmeric, Paprika, White Pepper, Cardamom, Ginger), Dried Herbs (Sage, Thyme), Flavouring)',
                'serving_size': '25g',
                'energy_kcal_100g': 533,
                'fat_100g': 34,
                'carbs_100g': 50,
                'sugar_100g': 2.5,
                'protein_100g': 6,
                'salt_100g': 1.6
            },
            'doritos': {
                'ingredients': 'Corn, Vegetable Oils (Corn, Sunflower, Rapeseed), Nacho Cheese Flavour (Whey Powder (from Milk), Salt, Lactose (from Milk), Sugar, Flavour Enhancers (Monosodium Glutamate, Disodium 5-ribonucleotide), Cheese Powder (from Milk), Onion Powder, Garlic Powder, Colours (Paprika Extract, Annatto), Acid (Citric Acid), Milk Proteins)',
                'serving_size': '30g',
                'energy_kcal_100g': 498,
                'fat_100g': 26,
                'carbs_100g': 60,
                'sugar_100g': 2.7,
                'protein_100g': 7,
                'salt_100g': 1.8
            },

            # More Cereals
            'cheerios': {
                'ingredients': 'Wholegrain Oat Flour (70%), Sugar, Oat Flour, Salt, Calcium Carbonate, Colour (Carotenes), Vitamins (Niacin, Riboflavin, Vitamin B6, Thiamin, Folic Acid, Vitamin B12), Iron',
                'serving_size': '30g',
                'energy_kcal_100g': 367,
                'fat_100g': 4,
                'carbs_100g': 73,
                'sugar_100g': 22,
                'protein_100g': 7,
                'salt_100g': 1.2
            },
            'shreddies': {
                'ingredients': 'Wholemeal Wheat (99%), Sugar, Salt, Vitamins (Niacin, Riboflavin, Vitamin B6, Thiamin, Folic Acid, Vitamin B12), Iron',
                'serving_size': '40g',
                'energy_kcal_100g': 360,
                'fat_100g': 2,
                'carbs_100g': 70,
                'sugar_100g': 4.5,
                'protein_100g': 11,
                'salt_100g': 0.23
            },
            'bran flakes': {
                'ingredients': 'Wholegrain Wheat (89%), Wheat Bran, Sugar, Barley Malt Extract, Salt, Vitamins (Niacin, Riboflavin, Vitamin B6, Thiamin, Folic Acid, Vitamin B12), Iron',
                'serving_size': '30g',
                'energy_kcal_100g': 320,
                'fat_100g': 2,
                'carbs_100g': 67,
                'sugar_100g': 22,
                'protein_100g': 10,
                'salt_100g': 1.3
            },
            'coco pops': {
                'ingredients': 'Rice, Sugar, Fat Reduced Cocoa Powder, Salt, Cocoa, Flavouring, Niacin, Iron, Vitamin B6, Riboflavin, Thiamin, Folic Acid, Vitamin B12',
                'serving_size': '30g',
                'energy_kcal_100g': 380,
                'fat_100g': 2.5,
                'carbs_100g': 84,
                'sugar_100g': 35,
                'protein_100g': 4.2,
                'salt_100g': 0.13
            },

            # Bread Products
            'hovis bread': {
                'ingredients': 'Wholemeal Wheat Flour, Water, Yeast, Salt, Wheat Gluten, Soya Flour, Emulsifiers (E472e, E481), Flour Treatment Agent (Ascorbic Acid)',
                'serving_size': '1 slice (36g)',
                'energy_kcal_100g': 217,
                'fat_100g': 2.5,
                'carbs_100g': 37,
                'sugar_100g': 3,
                'protein_100g': 9,
                'salt_100g': 0.98
            },
            'warburtons bread': {
                'ingredients': 'Wheat Flour, Water, Yeast, Salt, Wheat Gluten, Soya Flour, Emulsifiers (E472e, E481), Flour Treatment Agent (Ascorbic Acid), Sugar',
                'serving_size': '1 slice (36g)',
                'energy_kcal_100g': 265,
                'fat_100g': 3.2,
                'carbs_100g': 47,
                'sugar_100g': 3,
                'protein_100g': 9.4,
                'salt_100g': 1.1
            },

            # Ready Meals
            'birds eye fish fingers': {
                'ingredients': 'Cod (58%), Breadcrumbs (Wheat Flour, Water, Salt, Yeast), Rapeseed Oil, Wheat Flour, Water, Salt',
                'serving_size': '4 fingers (112g)',
                'energy_kcal_100g': 233,
                'fat_100g': 12,
                'carbs_100g': 15,
                'sugar_100g': 1,
                'protein_100g': 17,
                'salt_100g': 0.9
            },
            'mccain chips': {
                'ingredients': 'Potatoes, Sunflower Oil',
                'serving_size': '100g',
                'energy_kcal_100g': 142,
                'fat_100g': 4.2,
                'carbs_100g': 23,
                'sugar_100g': 0.3,
                'protein_100g': 2.8,
                'salt_100g': 0.05
            },

            # Dairy Products
            'philadelphia cream cheese': {
                'ingredients': 'Pasteurised Milk and Cream, Salt, Cheese Culture, Carob Bean Gum',
                'serving_size': '30g',
                'energy_kcal_100g': 250,
                'fat_100g': 24,
                'carbs_100g': 4,
                'sugar_100g': 4,
                'protein_100g': 5.6,
                'salt_100g': 0.8
            },
            'lurpak butter': {
                'ingredients': 'Butter (Cream, Salt), Lactic Acid Culture',
                'serving_size': '10g',
                'energy_kcal_100g': 735,
                'fat_100g': 81,
                'carbs_100g': 0.6,
                'sugar_100g': 0.6,
                'protein_100g': 0.7,
                'salt_100g': 1.2
            },

            # Breakfast Items
            'nutella': {
                'ingredients': 'Sugar, Palm Oil, Hazelnuts (13%), Skimmed Milk Powder (8.7%), Fat-Reduced Cocoa (7.4%), Emulsifier: Lecithins (Soya), Vanillin',
                'serving_size': '15g',
                'energy_kcal_100g': 539,
                'fat_100g': 30.9,
                'carbs_100g': 57.5,
                'sugar_100g': 56.3,
                'protein_100g': 6.3,
                'salt_100g': 0.107
            },
            'marmite': {
                'ingredients': 'Yeast Extract, Salt, Vegetable Extract, Niacin, Thiamin, Riboflavin, Folic Acid, Vitamin B12',
                'serving_size': '4g',
                'energy_kcal_100g': 274,
                'fat_100g': 0.9,
                'carbs_100g': 24,
                'sugar_100g': 1,
                'protein_100g': 39,
                'salt_100g': 10.9
            },

            # Tea & Coffee
            'pg tips tea': {
                'ingredients': 'Black Tea',
                'serving_size': '1 cup (240ml)',
                'energy_kcal_100g': 1,
                'fat_100g': 0,
                'carbs_100g': 0.3,
                'sugar_100g': 0,
                'protein_100g': 0,
                'salt_100g': 0.003
            },
            'nescafe coffee': {
                'ingredients': 'Coffee',
                'serving_size': '1 cup (240ml)',
                'energy_kcal_100g': 2,
                'fat_100g': 0,
                'carbs_100g': 0.3,
                'sugar_100g': 0,
                'protein_100g': 0.1,
                'salt_100g': 0.002
            },

            # Ice Cream
            'ben jerrys': {
                'ingredients': 'Cream, Skim Milk, Liquid Sugar (Sugar, Water), Water, Sugar, Egg Yolks, Butter, Vanilla Extract, Guar Gum, Carrageenan',
                'serving_size': '100ml',
                'energy_kcal_100g': 250,
                'fat_100g': 14,
                'carbs_100g': 26,
                'sugar_100g': 23,
                'protein_100g': 4,
                'salt_100g': 0.13
            },
            'haagen dazs': {
                'ingredients': 'Cream, Skim Milk, Sugar, Egg Yolk, Vanilla Extract',
                'serving_size': '100ml',
                'energy_kcal_100g': 244,
                'fat_100g': 15,
                'carbs_100g': 21,
                'sugar_100g': 21,
                'protein_100g': 4.4,
                'salt_100g': 0.1
            }
        }
    
    def find_matching_products(self, knowledge_base: Dict[str, Dict]) -> List[Tuple]:
        """Find products in database that match our knowledge base"""
        cursor = self.conn.cursor()
        
        matching_products = []
        
        for food_key, food_data in knowledge_base.items():
            # Look for products that contain this food name
            search_terms = food_key.split(' ')
            
            # Build flexible search query
            conditions = []
            params = []
            
            for term in search_terms:
                conditions.append("(LOWER(name) LIKE ? OR LOWER(brand) LIKE ?)")
                params.extend([f'%{term}%', f'%{term}%'])
            
            query = f"""
                SELECT id, name, brand, ingredients, serving_size,
                       energy_kcal_100g, fat_100g, carbs_100g, sugar_100g, protein_100g, salt_100g
                FROM products 
                WHERE ({' AND '.join(conditions)})
                  AND (ingredients IS NULL OR LENGTH(ingredients) < 20 OR serving_size IS NULL OR serving_size = '')
                LIMIT 10
            """
            
            cursor.execute(query, params)
            results = cursor.fetchall()
            
            for result in results:
                matching_products.append((food_key, food_data, result))
        
        return matching_products
    
    def calculate_per_serving_nutrition(self, serving_size: str, nutrition_100g: Dict[str, float]) -> Dict[str, float]:
        """Calculate per-serving nutrition from per-100g values"""
        
        # Extract numeric value from serving size
        match = re.search(r'(\d+(?:\.\d+)?)', serving_size)
        if not match:
            return {}
        
        serving_amount = float(match.group(1))
        
        # Assume grams if no unit specified, or if it's ml (1ml ≈ 1g for most foods)
        multiplier = serving_amount / 100
        
        per_serving = {}
        for nutrient, value in nutrition_100g.items():
            if value is not None:
                # Use the correct column names from smart_database_fixer
                column_name = f"{nutrient.replace('energy_kcal', 'calories')}_per_serving"
                per_serving[column_name] = round(value * multiplier, 2)
        
        return per_serving
    
    def update_product_with_knowledge(self, food_key: str, food_data: Dict, product_row: Tuple) -> bool:
        """Update a single product with GPT knowledge"""
        
        product_id = product_row[0]
        product_name = product_row[1]
        product_brand = product_row[2]
        current_ingredients = product_row[3]
        current_serving = product_row[4]
        
        print(f"🤖 Updating: {product_brand} {product_name}")
        
        updates = {}
        
        # Update ingredients if missing or poor quality
        if not current_ingredients or len(current_ingredients) < 20:
            updates['ingredients'] = food_data['ingredients']
            print(f"   ✅ Added ingredients: {food_data['ingredients'][:60]}...")
        
        # Update serving size if missing
        if not current_serving or current_serving == '':
            updates['serving_size'] = food_data['serving_size']
            print(f"   ✅ Added serving size: {food_data['serving_size']}")
        
        # Update nutrition data (per 100g)
        nutrition_fields = ['energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g']
        
        for field in nutrition_fields:
            current_value = product_row[nutrition_fields.index(field) + 5]  # Offset for other fields
            if current_value is None and field.replace('_100g', '') in food_data:
                updates[field] = food_data[field.replace('_100g', '')]
                print(f"   ✅ Added {field}: {food_data[field.replace('_100g', '')]}")
        
        # Calculate per-serving nutrition
        if 'serving_size' in updates or current_serving:
            serving_to_use = updates.get('serving_size', current_serving)
            nutrition_per_100g = {
                'energy_kcal': updates.get('energy_kcal_100g', product_row[5]),
                'fat': updates.get('fat_100g', product_row[6]),
                'carbs': updates.get('carbs_100g', product_row[7]),
                'sugar': updates.get('sugar_100g', product_row[8]),
                'protein': updates.get('protein_100g', product_row[9]),
                'salt': updates.get('salt_100g', product_row[10])
            }
            
            per_serving = self.calculate_per_serving_nutrition(serving_to_use, nutrition_per_100g)
            # Map to correct column names 
            for key, value in per_serving.items():
                correct_key = key.replace('energy_kcal_per_serving', 'calories_per_serving')
                if correct_key != key:
                    updates[correct_key] = value
                else:
                    updates[key] = value
            
            if per_serving:
                print(f"   ✅ Calculated per-serving nutrition")
        
        # Apply updates to database
        if updates:
            cursor = self.conn.cursor()
            
            # Build UPDATE query
            set_clauses = []
            values = []
            for column, value in updates.items():
                set_clauses.append(f"{column} = ?")
                values.append(value)
            
            query = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = ?"
            values.append(product_id)
            
            cursor.execute(query, values)
            self.conn.commit()
            
            print(f"   ✅ Updated {len(updates)} fields")
            self.updated_count += 1
            return True
        else:
            print(f"   ❌ No updates needed")
            self.error_count += 1
            return False
    
    def update_with_gpt_knowledge(self, max_products: int = 100) -> Tuple[int, int]:
        """Update products using GPT's built-in knowledge"""
        
        knowledge_base = self.get_gpt_food_knowledge()
        matching_products = self.find_matching_products(knowledge_base)
        
        print(f"🤖 GPT KNOWLEDGE UPDATER - Found {len(matching_products)} potential matches")
        print("=" * 70)
        
        processed = 0
        for food_key, food_data, product_row in matching_products[:max_products]:
            
            print(f"\n[{processed + 1}] Matching '{food_key}' knowledge to product:")
            success = self.update_product_with_knowledge(food_key, food_data, product_row)
            
            processed += 1
            
            if processed >= max_products:
                break
        
        return self.updated_count, self.error_count
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🤖 GPT KNOWLEDGE-BASED FOOD UPDATER")
    print("=" * 50)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    updater = GPTKnowledgeUpdater(db_path)
    
    try:
        # Update products using GPT knowledge
        updated, errors = updater.update_with_gpt_knowledge(max_products=1000)
        
        print(f"\n🎯 FINAL RESULTS:")
        print(f"   Products updated: {updated}")
        print(f"   Products skipped: {errors}")
        print(f"   Success rate: {(updated / (updated + errors) * 100):.1f}%" if (updated + errors) > 0 else "0%")
        
    finally:
        updater.close()

if __name__ == "__main__":
    main()