#!/usr/bin/env python3
"""
Brand Name Cleaner for UK Food Database
Fixes the corrupted brand names and moves product descriptors to product names
"""

import sqlite3
import re
from typing import Dict, Tuple

class BrandCleaner:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.fixes_applied = 0
        
        # Brand name fixes
        self.brand_fixes = {
            # Sainsbury's variations
            "Sainsbury'S's": "Sainsbury's",
            "Sainsbury'S's, By Sainsbury'S's": "Sainsbury's",
            "By Sainsbury'S's": "Sainsbury's",
            "Sainsbury'S's'S": "Sainsbury's",
            
            # Tesco variations
            "Tescos": "Tesco",
            
            # M&S variations
            "Cook With M & S, Marks & Spencer": "Marks & Spencer",
            "M & S": "Marks & Spencer",
            "M&S": "Marks & Spencer",
            
            # ASDA variations
            "ASDA": "ASDA",
            
            # Walkers variations
            "Walker Heinz": "Walkers",
            
            # Other brands
            "Corale, Aldi": "ALDI",
            "Tetley, American Power Products Inc.": "Tetley",
            "Lord Nelson": "Lord Nelson"
        }
        
        # Product descriptors that should be in product name, not brand
        self.descriptor_patterns = [
            r"Taste the Difference",
            r"Cook With",
            r"Be Good to Yourself", 
            r"Eat Well",
            r"Premium",
            r"Finest",
            r"Value",
            r"Organic",
            r"Free From",
            r"Simply",
            r"Extra Special"
        ]
    
    def clean_brand_name(self, brand: str, product_name: str) -> Tuple[str, str]:
        """Clean brand name and move descriptors to product name"""
        if not brand:
            return brand, product_name
        
        # Apply direct brand fixes
        if brand in self.brand_fixes:
            new_brand = self.brand_fixes[brand]
            return new_brand, product_name
        
        # Extract main brand and descriptors
        cleaned_brand = brand
        product_additions = []
        
        # Check for descriptors in brand that should be in product
        for pattern in self.descriptor_patterns:
            if re.search(pattern, brand, re.IGNORECASE):
                # Extract the descriptor
                match = re.search(f"({pattern})", brand, re.IGNORECASE)
                if match:
                    descriptor = match.group(1)
                    product_additions.append(descriptor)
                    cleaned_brand = re.sub(pattern, "", cleaned_brand, flags=re.IGNORECASE).strip()
        
        # Clean up the brand further
        cleaned_brand = re.sub(r',\s*$', '', cleaned_brand)  # Remove trailing commas
        cleaned_brand = re.sub(r'^\s*,', '', cleaned_brand)  # Remove leading commas
        cleaned_brand = cleaned_brand.strip()
        
        # Add descriptors to product name
        if product_additions:
            new_product_name = " ".join(product_additions) + " " + product_name
            return cleaned_brand, new_product_name.strip()
        
        return cleaned_brand, product_name
    
    def fix_all_brands(self):
        """Fix all brand names in the database"""
        cursor = self.conn.cursor()
        
        # Get all products with their current brand and name
        cursor.execute("SELECT id, name, brand FROM products WHERE brand IS NOT NULL AND brand != ''")
        products = cursor.fetchall()
        
        print(f"🧹 BRAND CLEANER")
        print(f"📊 Found {len(products)} products with brands to check")
        print("=" * 50)
        
        for product_id, name, brand in products:
            original_brand = brand
            cleaned_brand, updated_name = self.clean_brand_name(brand, name)
            
            if cleaned_brand != original_brand or updated_name != name:
                # Update the database
                cursor.execute(
                    "UPDATE products SET brand = ?, name = ? WHERE id = ?",
                    (cleaned_brand, updated_name, product_id)
                )
                
                print(f"✅ Fixed ID {product_id}:")
                print(f"   Brand: '{original_brand}' → '{cleaned_brand}'")
                if updated_name != name:
                    print(f"   Name:  '{name}' → '{updated_name}'")
                
                self.fixes_applied += 1
        
        self.conn.commit()
        print(f"\n🎯 RESULTS:")
        print(f"   Total fixes applied: {self.fixes_applied}")
        print(f"   Database updated successfully")
    
    def show_brand_stats(self):
        """Show current brand distribution"""
        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT brand, COUNT(*) as count 
            FROM products 
            WHERE brand IS NOT NULL AND brand != '' 
            GROUP BY brand 
            ORDER BY count DESC 
            LIMIT 20
        """)
        
        results = cursor.fetchall()
        print(f"\n📊 TOP 20 BRANDS AFTER CLEANING:")
        for brand, count in results:
            print(f"   {brand}: {count} products")
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🧹 UK FOOD DATABASE BRAND CLEANER")
    print("Fixes corrupted brand names and moves descriptors to product names")
    print("=" * 60)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    cleaner = BrandCleaner(db_path)
    
    try:
        # Show current problems
        print("🔍 BEFORE CLEANING:")
        cleaner.show_brand_stats()
        
        # Fix the brands
        cleaner.fix_all_brands()
        
        # Show results
        print("🔍 AFTER CLEANING:")
        cleaner.show_brand_stats()
        
    finally:
        cleaner.close()

if __name__ == "__main__":
    main()