#!/usr/bin/env python3
"""
Export barcode data from database to CSV
"""

import sqlite3
import csv

def export_barcodes():
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    csv_path = "/Users/aaronkeen/Desktop/barcode_export.csv"
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all products with barcodes
    cursor.execute("""
        SELECT id, name, brand, barcode, ingredients, serving_size,
               energy_kcal_100g, fat_100g, carbs_100g, sugar_100g, protein_100g, salt_100g
        FROM products 
        WHERE barcode IS NOT NULL AND LENGTH(barcode) > 0
        ORDER BY id
    """)
    
    results = cursor.fetchall()
    
    # Write to CSV
    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = [
            'id', 'name', 'brand', 'barcode', 'ingredients', 'serving_size',
            'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in results:
            writer.writerow({
                'id': row[0],
                'name': row[1],
                'brand': row[2],
                'barcode': row[3],
                'ingredients': row[4],
                'serving_size': row[5],
                'energy_kcal_100g': row[6],
                'fat_100g': row[7],
                'carbs_100g': row[8],
                'sugar_100g': row[9],
                'protein_100g': row[10],
                'salt_100g': row[11]
            })
    
    conn.close()
    
    print(f"📄 Exported {len(results)} products with barcodes to: {csv_path}")
    return len(results)

if __name__ == "__main__":
    export_barcodes()