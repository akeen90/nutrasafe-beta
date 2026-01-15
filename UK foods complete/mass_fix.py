#!/usr/bin/env python3
"""
UK Foods Database Mass Fix Script
Automatically fixes all identified issues from the 15-agent verification
"""

import pandas as pd
import re
import numpy as np
from datetime import datetime

print("=" * 60)
print("UK FOODS DATABASE MASS FIX")
print("=" * 60)

# Load the database
df = pd.read_csv('/Users/aaronkeen/Downloads/UK foods complete/uk_foods_cleaned.csv')
original_count = len(df)
print(f"\nLoaded {original_count} products")

fixes_made = {
    'spelling': 0,
    'allergen': 0,
    'category': 0,
    'nutrition': 0,
    'brand': 0,
    'deleted': 0,
    'ingredients': 0
}

# ============================================================
# 1. SPELLING FIXES - Common OCR and spelling errors
# ============================================================
print("\n[1/7] Fixing spelling errors...")

spelling_fixes = {
    # Product name fixes
    'Chocolatees': 'Chocolates',
    'Califlower': 'Cauliflower',
    'Couliflower': 'Cauliflower',
    'Yogourt': 'Yogurt',
    'Yogurg': 'Yogurt',
    'Hazenuts': 'Hazelnuts',
    'Sheperds': "Shepherd's",
    'Dekight': 'Delight',
    'Salade': 'Salad',
    'Maroccan': 'Moroccan',
    'Quinona': 'Quinoa',
    'Cornfalkes': 'Cornflakes',
    'Jerkey': 'Jerky',
    'Yotkshires': 'Yorkshires',
    'Crakers': 'Crackers',
    'Batteted': 'Battered',
    'Chesse': 'Cheese',
    'Stong': 'Strong',
    'Firy': 'Fiery',
    'Tomoto': 'Tomato',
    'Marshmellow': 'Marshmallow',
    'Peppemint': 'Peppermint',
    'Proten': 'Protein',
    'Ptotein': 'Protein',
    'Gliten': 'Gluten',
    'Tricoloure': 'Tricolore',
    'Bibrant': 'Vibrant',
    'Sekection': 'Selection',
    'Frut&nut': 'Fruit & Nut',
    'Fusisli': 'Fusilli',
    'Aparagus': 'Asparagus',
    'Cookied': 'Cookies',
    'Chcicken': 'Chicken',
    'Chickens Nuggets': 'Chicken Nuggets',
    'Moca': 'Mocha',
    'Cocolate': 'Chocolate',
    'Puzza': 'Pizza',
    'Snacke': 'Snack',
    'Withe': 'White',
    'Pewrwla': 'Pretzels',
    'Lental': 'Lentil',
    'Tomatoy': 'Tomato',
    'Ookies': 'Cookies',
    'Whitte': 'White',
    'Tune': 'Tuna',
    'RICR': 'RICE',
    'Cajun Spiced RICR': 'Cajun Spiced Rice',
    'Refried Bens': 'Refried Beans',
    'Gouda Chesse': 'Gouda Cheese',
    'Pub Chesse': 'Pub Cheese',
    'Salt And Paper': 'Salt And Pepper',
}

# Apply spelling fixes to product names
for wrong, correct in spelling_fixes.items():
    mask = df['name'].str.contains(wrong, case=False, na=False)
    if mask.any():
        df.loc[mask, 'name'] = df.loc[mask, 'name'].str.replace(wrong, correct, case=False, regex=False)
        fixes_made['spelling'] += mask.sum()

# Fix common ingredient spelling errors
ingredient_fixes = {
    'Wheatflour': 'Wheat Flour',
    'sWheatflour': 'Wheat Flour',
    'Whear Flour': 'Wheat Flour',
    'Wheat Floor': 'Wheat Flour',
    'wheat flou': 'wheat flour',
    'Comflour': 'Cornflour',
    'Com starch': 'Corn starch',
    'Coca mass': 'Cocoa mass',
    'Cocna Mass': 'Cocoa Mass',
    'Cone Butter': 'Cocoa Butter',
    'Ocoa butter': 'Cocoa butter',
    'Palm kernell': 'Palm kernel',
    'Palm Uil': 'Palm Oil',
    'Rapeseed oll': 'Rapeseed oil',
    'Sunfliwer': 'Sunflower',
    'Sunfiower': 'Sunflower',
    'Sunfever oil': 'Sunflower oil',
    'sunhower': 'sunflower',
    'Leclans': 'Lecithins',
    'Leothies': 'Lecithins',
    'Ecithins': 'Lecithins',
    'Lecithincitin': 'Lecithin',
    'Mulsifier': 'Emulsifier',
    'Emuisitier': 'Emulsifier',
    'Emulsfiee': 'Emulsifier',
    'Emusher': 'Emulsifier',
    'Endisiner': 'Emulsifier',
    'Ravourings': 'Flavourings',
    'Flavol ring': 'Flavouring',
    'favouring': 'flavouring',
    'Havouring': 'Flavouring',
    'falvor': 'flavour',
    'Naturafflavouring': 'Natural flavouring',
    'Caicium': 'Calcium',
    'Codrum Bicarbonate': 'Sodium Bicarbonate',
    'Potarsium': 'Potassium',
    'Acitity': 'Acidity',
    'Acldity': 'Acidity',
    'Adity Regulator': 'Acidity Regulator',
    'Carrageenarc': 'Carrageenan',
    'Carrageenar': 'Carrageenan',
    'Kapthar Gurg': 'Xanthan Gum',
    'Canthan gum': 'Xanthan gum',
    'Cellulose Qum': 'Cellulose Gum',
    'geletine': 'gelatine',
    'hidrogenated': 'hydrogenated',
    'Parika': 'Paprika',
    'Caretenes': 'Carotenes',
    'Eta Carotene': 'Beta Carotene',
    'Moditied': 'Modified',
    'tacopherols': 'tocopherols',
    'Broccolli': 'Broccoli',
    'Mater': 'Water',
    'Vater': 'Water',
    'Ater': 'Water',
    'viamin': 'vitamin',
    'Vtamin': 'Vitamin',
    'Naicin': 'Niacin',
    'bluebarry': 'blueberry',
    'Peonuts': 'Peanuts',
    'Hazlenut': 'Hazelnut',
    'Hazeunuts': 'Hazelnuts',
    'mazelnots': 'hazelnuts',
    'anillin': 'vanillin',
    'valla extract': 'vanilla extract',
    'Ganic vanilla': 'Organic vanilla',
}

if 'ingredients' in df.columns:
    for wrong, correct in ingredient_fixes.items():
        mask = df['ingredients'].str.contains(wrong, case=False, na=False)
        if mask.any():
            df.loc[mask, 'ingredients'] = df.loc[mask, 'ingredients'].str.replace(wrong, correct, case=False, regex=False)
            fixes_made['ingredients'] += mask.sum()

print(f"   Fixed {fixes_made['spelling']} product names")
print(f"   Fixed {fixes_made['ingredients']} ingredient entries")

# ============================================================
# 2. FIX ALLERGEN ISSUES
# ============================================================
print("\n[2/7] Fixing allergen issues...")

# Remove invalid allergens (not EU regulatory allergens)
invalid_allergens = ['Pork', 'Beef', 'Chicken', 'Turkey', 'Apple', 'Orange', 'Peach',
                     'Banana', 'Kiwi', 'None', 'Breadcrumb', 'Gelatin', 'Mycoprotein',
                     'Rapeseed Oil', 'Crickets', 'Insects']

if 'allergens' in df.columns:
    for invalid in invalid_allergens:
        mask = df['allergens'].str.contains(invalid, case=False, na=False)
        if mask.any():
            # Remove the invalid allergen from the string
            df.loc[mask, 'allergens'] = df.loc[mask, 'allergens'].str.replace(
                rf',?\s*{invalid}\s*,?', ',', case=False, regex=True
            )
            fixes_made['allergen'] += mask.sum()

    # Clean up allergen formatting (remove double commas, leading/trailing commas)
    df['allergens'] = df['allergens'].str.replace(r',\s*,', ',', regex=True)
    df['allergens'] = df['allergens'].str.strip(', ')

# Fix gluten-free products that incorrectly list Wheat/Gluten allergens
gluten_free_patterns = ['gluten free', 'gluten-free', 'free from gluten', 'gf ', ' gf']
for pattern in gluten_free_patterns:
    mask = (df['name'].str.contains(pattern, case=False, na=False) &
            df['allergens'].str.contains('Wheat|Gluten', case=False, na=False))
    if mask.any():
        df.loc[mask, 'allergens'] = df.loc[mask, 'allergens'].str.replace(
            r'Wheat,?\s*|Gluten,?\s*', '', case=False, regex=True
        )
        fixes_made['allergen'] += mask.sum()

# Fix vegan products that incorrectly list Milk allergen
vegan_patterns = ['vegan', 'plant-based', 'plant based', 'dairy free', 'dairy-free']
for pattern in vegan_patterns:
    mask = (df['name'].str.contains(pattern, case=False, na=False) &
            df['allergens'].str.contains(r'\bMilk\b', case=False, na=False, regex=True))
    if mask.any():
        df.loc[mask, 'allergens'] = df.loc[mask, 'allergens'].str.replace(
            r'\bMilk\b,?\s*', '', case=False, regex=True
        )
        fixes_made['allergen'] += mask.sum()

# Standardize allergen names
allergen_standardization = {
    'Soybeans': 'Soya',
    'Soybeans,': 'Soya,',
    'Tree Nuts': 'Nuts',
    'Sulphur-Dioxide-And-Sulphites': 'Sulphites',
}

for old, new in allergen_standardization.items():
    df['allergens'] = df['allergens'].str.replace(old, new, case=False, regex=False)

# Clean up allergen formatting
df['allergens'] = df['allergens'].str.replace(r',\s*,', ',', regex=True)
df['allergens'] = df['allergens'].str.strip(', ')
df['allergens'] = df['allergens'].replace('', np.nan)

print(f"   Fixed {fixes_made['allergen']} allergen entries")

# ============================================================
# 3. FIX CATEGORY ISSUES
# ============================================================
print("\n[3/7] Fixing category issues...")

# Category translations and fixes
category_fixes = {
    'Przekaski, Slodkie przekaski': 'Snacks, Sweet snacks',
    'Przekski, Sodkie przekski': 'Snacks, Sweet snacks',
    'Plantaardige levensmiddelen en dranken': 'Plant-based foods and beverages',
    'Salzige Snacks': 'Salty snacks',
    'Comidas preparadas': 'Prepared meals',
    'es:Nutricion-deportiva': 'Sports nutrition',
    'Da:Crackers': 'Crackers',
    'Hr:Cokolade': 'Chocolate',
    'th:Spain': 'Snacks',
    'Fiocchi di mais': 'Corn flakes',
    'Undefined': '',
    'Null': '',
    'H': '',
    'Po Mm Mm': '',
    '105': '',
    'Ener': 'Energy drinks',
    'Froz': 'Frozen foods',
    'Brad': 'Bread',
    'Cips': 'Crisps',
}

if 'category' in df.columns:
    for old_cat, new_cat in category_fixes.items():
        mask = df['category'] == old_cat
        if mask.any():
            df.loc[mask, 'category'] = new_cat
            fixes_made['category'] += mask.sum()

# Fix products in wrong categories based on keywords
# Meat products in "Plant-based foods"
meat_keywords = ['beef', 'pork', 'chicken', 'ham', 'bacon', 'sausage', 'lamb', 'turkey']
for keyword in meat_keywords:
    mask = (df['name'].str.contains(keyword, case=False, na=False) &
            df['category'].str.contains('Plant-based', case=False, na=False))
    if mask.any():
        df.loc[mask, 'category'] = 'Meats and their products'
        fixes_made['category'] += mask.sum()

print(f"   Fixed {fixes_made['category']} category entries")

# ============================================================
# 4. FIX NUTRITION ANOMALIES
# ============================================================
print("\n[4/7] Fixing nutrition anomalies...")

# Convert nutrition columns to numeric
nutrition_cols = ['calories', 'protein', 'carbs', 'fat', 'saturated_fat', 'fiber', 'sugar', 'sodium']
for col in nutrition_cols:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='coerce')

# Fix obvious decimal place errors
# Fiber > 50g is likely 10x error
if 'fiber' in df.columns:
    mask = df['fiber'] > 50
    if mask.any():
        df.loc[mask, 'fiber'] = df.loc[mask, 'fiber'] / 10
        fixes_made['nutrition'] += mask.sum()

# Calories < 5 for actual food products (not drinks) is likely an error
if 'calories' in df.columns:
    mask = (df['calories'] < 5) & (df['calories'] > 0) & (~df['name'].str.contains('water|tea|coffee|diet|zero', case=False, na=False))
    if mask.any():
        # Likely missing a decimal place - multiply by 100
        df.loc[mask, 'calories'] = df.loc[mask, 'calories'] * 100
        fixes_made['nutrition'] += mask.sum()

# Sodium > 10g is likely in wrong units (should be /1000)
if 'sodium' in df.columns:
    mask = df['sodium'] > 10
    if mask.any():
        df.loc[mask, 'sodium'] = df.loc[mask, 'sodium'] / 10
        fixes_made['nutrition'] += mask.sum()

print(f"   Fixed {fixes_made['nutrition']} nutrition entries")

# ============================================================
# 5. FIX BRAND ISSUES
# ============================================================
print("\n[5/7] Fixing brand issues...")

# Brand standardization
brand_fixes = {
    "Welch'S": "Welch's",
    "Reese'S": "Reese's",
    "Campbell'S": "Campbell's",
    "Paterson'S": "Paterson's",
    "Patterson'S": "Paterson's",
    "Burton'S": "Burton's",
    "Sainsburry'S": "Sainsbury's",
    "Moreisons": "Morrisons",
    "M & S": "M&S",
    "Tesso": "Tesco",
    "Del Monter": "Del Monte",
    "Alsi": "Aldi",
    "Pepperidge Farms": "Pepperidge Farm",
    "Dempsters": "Dempster's",
    "Croats & Mollica": "Crosta & Mollica",
    "Anthon Beeg": "Anthon Berg",
    "Nil Mor": "Nib Mor",
    "Loaker": "Loacker",
    "Sammills": "Sam Mills",
    "Sulpice Choloat": "Sulpice Chocolat",
    "Johnsof": "Johnson",
    "Sharpcheddar": "Kraft",
    "Null": "",
    "400G": "",
}

if 'brand' in df.columns:
    for old_brand, new_brand in brand_fixes.items():
        mask = df['brand'] == old_brand
        if mask.any():
            df.loc[mask, 'brand'] = new_brand
            fixes_made['brand'] += mask.sum()

    # Remove emojis from brand names
    df['brand'] = df['brand'].str.replace(r'[^\x00-\x7F]+', '', regex=True)
    df['brand'] = df['brand'].str.strip()

print(f"   Fixed {fixes_made['brand']} brand entries")

# ============================================================
# 6. DELETE SEVERELY CORRUPTED PRODUCTS
# ============================================================
print("\n[6/7] Removing severely corrupted entries...")

# Products to delete based on criteria:
delete_mask = pd.Series([False] * len(df))

# 1. Products with completely garbled names (more than 50% non-alpha characters)
def is_garbled(text):
    if pd.isna(text) or len(str(text)) < 3:
        return False
    text = str(text)
    alpha_count = sum(c.isalpha() or c.isspace() for c in text)
    return alpha_count / len(text) < 0.4

delete_mask |= df['name'].apply(is_garbled)

# 2. Products with names that are clearly OCR garbage
garbage_patterns = [
    r'^[0-9\s\.\,]+$',  # Only numbers
    r'^\d+\.\d+g\s+\d+',  # Nutrition data as name
    r'EET BABY RANS',
    r'Ree Kam UTEN',
    r'PICO TIC.*DRI Dys',
    r'Urine \+ GINS',
    r'^Unknown$',
    r'^\s*$',
]

for pattern in garbage_patterns:
    delete_mask |= df['name'].str.contains(pattern, case=False, na=False, regex=True)

# 3. Products where ingredients are completely unreadable (very short or all numbers)
if 'ingredients' in df.columns:
    def ingredients_corrupted(text):
        if pd.isna(text):
            return False
        text = str(text)
        if len(text) < 10:
            return False
        # Check if mostly numbers/symbols
        alpha_count = sum(c.isalpha() for c in text)
        return alpha_count / len(text) < 0.3

    # Don't delete just for corrupted ingredients - too aggressive
    # delete_mask |= df['ingredients'].apply(ingredients_corrupted)

# Count deletions
deletion_count = delete_mask.sum()
fixes_made['deleted'] = deletion_count

# Remove the corrupted entries
df = df[~delete_mask].copy()

print(f"   Deleted {deletion_count} corrupted entries")

# ============================================================
# 7. FINAL CLEANUP
# ============================================================
print("\n[7/7] Final cleanup...")

# Remove any rows where name is empty or NaN
df = df[df['name'].notna() & (df['name'].str.strip() != '')]

# Clean up whitespace in all string columns
string_cols = df.select_dtypes(include=['object']).columns
for col in string_cols:
    df[col] = df[col].str.strip()

# Reset index
df = df.reset_index(drop=True)

# Save the fixed database
output_path = '/Users/aaronkeen/Downloads/UK foods complete/uk_foods_cleaned.csv'
df.to_csv(output_path, index=False)

final_count = len(df)

# ============================================================
# SUMMARY
# ============================================================
print("\n" + "=" * 60)
print("MASS FIX COMPLETE")
print("=" * 60)
print(f"\nOriginal products: {original_count}")
print(f"Final products: {final_count}")
print(f"Products removed: {original_count - final_count}")
print(f"\nFixes by category:")
print(f"   Spelling fixes: {fixes_made['spelling']}")
print(f"   Ingredient fixes: {fixes_made['ingredients']}")
print(f"   Allergen fixes: {fixes_made['allergen']}")
print(f"   Category fixes: {fixes_made['category']}")
print(f"   Nutrition fixes: {fixes_made['nutrition']}")
print(f"   Brand fixes: {fixes_made['brand']}")
print(f"   Deleted entries: {fixes_made['deleted']}")
print(f"\nTotal fixes: {sum(fixes_made.values())}")
print(f"\nSaved to: {output_path}")
