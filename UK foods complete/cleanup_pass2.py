#!/usr/bin/env python3
"""
Second pass cleanup - fix remaining OCR artifacts
"""

import pandas as pd
import re

print("Running second pass cleanup...")

df = pd.read_csv('/Users/aaronkeen/Downloads/UK foods complete/uk_foods_cleaned.csv')
original = len(df)

fixes = 0

# Fix doubled letters at word boundaries (OCR artifacts)
double_patterns = [
    (r'\bCCocoa\b', 'Cocoa'),
    (r'\bCCookies\b', 'Cookies'),
    (r'\bEEmulsifier', 'Emulsifier'),
    (r'\bWWater\b', 'Water'),
    (r'\bSSOYA\b', 'SOYA'),
    (r'\bMMILK\b', 'MILK'),
    (r'\bwwheat\b', 'wheat'),
    (r'wheat flourr', 'Wheat Flour'),
    (r'Wheat flourr', 'Wheat Flour'),
    (r'\bflourr\b', 'flour'),
]

# Apply to name and ingredients
for col in ['name', 'ingredients']:
    if col in df.columns:
        for pattern, replacement in double_patterns:
            mask = df[col].str.contains(pattern, case=False, na=False, regex=True)
            if mask.any():
                df.loc[mask, col] = df.loc[mask, col].str.replace(pattern, replacement, regex=True)
                fixes += mask.sum()

# Remove products where name is mostly numbers or very short
df = df[df['name'].str.len() > 2]
df = df[~df['name'].str.match(r'^[\d\s\.\,]+$', na=False)]

# Clean up any empty allergens
if 'allergens' in df.columns:
    df['allergens'] = df['allergens'].replace('', pd.NA)
    df['allergens'] = df['allergens'].str.replace(r',\s*$', '', regex=True)
    df['allergens'] = df['allergens'].str.replace(r'^\s*,', '', regex=True)

df = df.reset_index(drop=True)
df.to_csv('/Users/aaronkeen/Downloads/UK foods complete/uk_foods_cleaned.csv', index=False)

print(f"Second pass complete: {fixes} additional fixes")
print(f"Original: {original}, Final: {len(df)}")
