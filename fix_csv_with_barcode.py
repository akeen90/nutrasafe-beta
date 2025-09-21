#!/usr/bin/env python3
"""
Fix the existing CSV to include barcode column
"""

import csv
import os

def fix_csv_with_barcode():
    old_csv = "/Users/aaronkeen/Desktop/simple_ai_fixed_data_1000.csv"
    new_csv = "/Users/aaronkeen/Desktop/simple_ai_fixed_data_1000_with_barcode.csv"
    
    # Read the old CSV
    rows = []
    with open(old_csv, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            rows.append(row)
    
    # Write new CSV with barcode column
    with open(new_csv, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'id', 'original_name', 'original_brand', 'processed_date', 'status',
            'corrected_name', 'corrected_brand', 'barcode', 'ingredients', 'serving_size', 
            'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
            'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
            'sugar_per_serving', 'protein_per_serving', 'salt_per_serving',
            'chatgpt_response'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in rows:
            # Add empty barcode field for existing rows
            row['barcode'] = ''
            writer.writerow(row)
    
    print(f"✅ Created new CSV with barcode column: {new_csv}")
    print(f"📊 Processed {len(rows)} existing rows")
    
    # Replace the old CSV with the new one
    os.replace(new_csv, old_csv)
    print(f"✅ Updated original CSV file with barcode column")

if __name__ == "__main__":
    fix_csv_with_barcode()