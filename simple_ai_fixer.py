#!/usr/bin/env python3
"""
Simple AI Data Fixer - Let ChatGPT do what it does best
Just tell it to fix the data from reputable sources
"""

import sqlite3
import json
import time
import re
import csv
from typing import Optional, Dict
from openai import OpenAI
from datetime import datetime

class SimpleAIFixer:
    def __init__(self, db_path: str, csv_path: str = None, openai_api_key: str = None):
        self.db_path = db_path
        self.csv_path = csv_path or f"/Users/aaronkeen/Desktop/simple_ai_fixed_data_1000.csv"
        self.conn = sqlite3.connect(db_path)
        self.successes = 0
        self.failures = 0
        
        # OpenAI API setup
        self.openai_client = None
        if openai_api_key:
            self.openai_client = OpenAI(api_key=openai_api_key)
            
        # Initialize CSV file
        self.init_csv_file()
    
    def init_csv_file(self):
        """Initialize CSV file"""
        with open(self.csv_path, 'w', newline='', encoding='utf-8') as csvfile:
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
        print(f"📄 Created CSV file: {self.csv_path}")
    
    def fix_food_data(self, product_name: str, brand: str) -> Optional[Dict]:
        """Simple prompt - just ask ChatGPT to fix the data"""
        
        if not self.openai_client:
            return None
            
        # Strict prompt - NO GUESSING ALLOWED
        prompt = f"""Find EXACT nutrition data for this food product from reputable sources:

Product: {product_name}
Brand: {brand}

CRITICAL RULES:
- ONLY provide data if you have EXACT, VERIFIED information from reputable sources
- If you don't have exact ingredients, say "I cannot find exact ingredient information"
- If you don't have exact nutrition data, say "I cannot find verified nutrition information"
- DO NOT guess, estimate, or say "typically", "usually", "approximately", etc.
- DO NOT provide generic/similar product data
- BE HONEST if you can't find the specific product

If you have exact verified data, provide it in this format:
Name: [exact corrected name]
Brand: [exact corrected brand] 
Barcode: [exact barcode/EAN number if available]
Ingredients: [exact ingredient list from official source]
Serving size: [exact serving size]
Per 100g - Calories: [exact kcal], Fat: [exact g], Carbs: [exact g], Sugar: [exact g], Protein: [exact g], Salt: [exact g]
Per serving - Calories: [exact kcal], Fat: [exact g], Carbs: [exact g], Sugar: [exact g], Protein: [exact g], Salt: [exact g]

If you cannot find exact verified information, just say: "I cannot find verified information for this specific product."

        try:
            print(f"   🤖 Asking ChatGPT to fix the data...")
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1,
                max_tokens=600
            )
            
            response_text = response.choices[0].message.content.strip()
            print(f"   📝 ChatGPT response received")
            
            # Parse the response
            extracted_data = self.parse_simple_response(response_text)
            
            if extracted_data:
                # Clean up the response text for CSV - remove newlines and limit length
                clean_response = response_text.replace('\n', ' | ').replace('\r', ' | ')
                if len(clean_response) > 500:
                    clean_response = clean_response[:500] + "..."
                extracted_data['chatgpt_response'] = clean_response
                return extracted_data
            
            return None
                
        except Exception as e:
            print(f"   ❌ API error: {e}")
            return None
    
    def parse_simple_response(self, response_text: str) -> Optional[Dict]:
        """Parse the simple response format"""
        
        try:
            data = {}
            
            # Extract corrected name
            name_match = re.search(r'Name:\s*(.+?)(?:\n|$)', response_text, re.IGNORECASE)
            if name_match:
                data['corrected_name'] = name_match.group(1).strip()
            
            # Extract corrected brand
            brand_match = re.search(r'Brand:\s*(.+?)(?:\n|$)', response_text, re.IGNORECASE)
            if brand_match:
                data['corrected_brand'] = brand_match.group(1).strip()
            
            # Extract barcode
            barcode_match = re.search(r'Barcode:\s*(.+?)(?:\n|$)', response_text, re.IGNORECASE)
            if barcode_match:
                data['barcode'] = barcode_match.group(1).strip()
            
            # Extract ingredients
            ing_match = re.search(r'Ingredients:\s*(.+?)(?:\n|Per|$)', response_text, re.IGNORECASE | re.DOTALL)
            if ing_match:
                data['ingredients'] = ing_match.group(1).strip()
            
            # Extract serving size
            serving_match = re.search(r'Serving size:\s*(.+?)(?:\n|$)', response_text, re.IGNORECASE)
            if serving_match:
                data['serving_size'] = serving_match.group(1).strip()
            
            # Extract per 100g nutrition
            per_100g_match = re.search(r'Per 100g.*?Calories:\s*(\d+(?:\.\d+)?)', response_text, re.IGNORECASE | re.DOTALL)
            if per_100g_match:
                data['energy_kcal_100g'] = float(per_100g_match.group(1))
            
            # Extract more 100g values
            patterns_100g = {
                'fat_100g': r'Per 100g.*?Fat:\s*(\d+(?:\.\d+)?)',
                'carbs_100g': r'Per 100g.*?Carbs:\s*(\d+(?:\.\d+)?)', 
                'sugar_100g': r'Per 100g.*?Sugar:\s*(\d+(?:\.\d+)?)',
                'protein_100g': r'Per 100g.*?Protein:\s*(\d+(?:\.\d+)?)',
                'salt_100g': r'Per 100g.*?Salt:\s*(\d+(?:\.\d+)?)'
            }
            
            for field, pattern in patterns_100g.items():
                match = re.search(pattern, response_text, re.IGNORECASE | re.DOTALL)
                if match:
                    data[field] = float(match.group(1))
            
            # Extract per serving nutrition
            per_serving_match = re.search(r'Per serving.*?Calories:\s*(\d+(?:\.\d+)?)', response_text, re.IGNORECASE | re.DOTALL)
            if per_serving_match:
                data['energy_kcal_per_serving'] = float(per_serving_match.group(1))
            
            patterns_serving = {
                'fat_per_serving': r'Per serving.*?Fat:\s*(\d+(?:\.\d+)?)',
                'carbs_per_serving': r'Per serving.*?Carbs:\s*(\d+(?:\.\d+)?)',
                'sugar_per_serving': r'Per serving.*?Sugar:\s*(\d+(?:\.\d+)?)', 
                'protein_per_serving': r'Per serving.*?Protein:\s*(\d+(?:\.\d+)?)',
                'salt_per_serving': r'Per serving.*?Salt:\s*(\d+(?:\.\d+)?)'
            }
            
            for field, pattern in patterns_serving.items():
                match = re.search(pattern, response_text, re.IGNORECASE | re.DOTALL)
                if match:
                    data[field] = float(match.group(1))
            
            # Check if we got meaningful data
            if len(data) > 2:  # More than just the response text
                print(f"   ✅ Extracted {len(data)} data fields")
                return data
            else:
                print(f"   ❌ No meaningful data extracted")
                return None
                
        except Exception as e:
            print(f"   ❌ Error parsing response: {e}")
            return None
    
    def add_to_csv(self, product_id: int, original_name: str, original_brand: str, status: str, data: Dict = None):
        """Add processed food to CSV file"""
        
        row = {
            'id': product_id,
            'original_name': original_name,
            'original_brand': original_brand or '',
            'processed_date': datetime.now().isoformat(),
            'status': status,
        }
        
        # Add extracted data if available
        if data:
            for field in ['corrected_name', 'corrected_brand', 'barcode', 'ingredients', 'serving_size',
                         'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                         'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
                         'sugar_per_serving', 'protein_per_serving', 'salt_per_serving', 'chatgpt_response']:
                row[field] = data.get(field, '')
        
        # Append to CSV
        with open(self.csv_path, 'a', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                'id', 'original_name', 'original_brand', 'processed_date', 'status',
                'corrected_name', 'corrected_brand', 'barcode', 'ingredients', 'serving_size', 
                'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
                'sugar_per_serving', 'protein_per_serving', 'salt_per_serving',
                'chatgpt_response'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writerow(row)
    
    def update_database(self, product_id: int, data: Dict) -> int:
        """Update database with corrected data"""
        
        cursor = self.conn.cursor()
        updates = {}
        
        # Map data to database columns
        field_mapping = {
            'corrected_name': 'name',
            'corrected_brand': 'brand',
            'barcode': 'barcode',
            'ingredients': 'ingredients',
            'serving_size': 'serving_size',
            'energy_kcal_100g': 'energy_kcal_100g',
            'fat_100g': 'fat_100g',
            'carbs_100g': 'carbs_100g',
            'sugar_100g': 'sugar_100g',
            'protein_100g': 'protein_100g',
            'salt_100g': 'salt_100g'
        }
        
        # Build update query
        for api_field, db_field in field_mapping.items():
            if api_field in data and data[api_field] is not None and data[api_field] != '':
                updates[db_field] = data[api_field]
        
        if not updates:
            return 0
            
        # Execute update
        set_clauses = [f"{col} = ?" for col in updates.keys()]
        values = list(updates.values()) + [product_id]
        
        query = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = ?"
        cursor.execute(query, values)
        self.conn.commit()
        
        return len(updates)
    
    def process_products(self, max_products: int = 10):
        """Process products with simple AI fixing"""
        
        cursor = self.conn.cursor()
        
        # Get products that need fixing
        cursor.execute(f"""
            SELECT id, name, brand
            FROM products 
            WHERE (ingredients IS NULL OR LENGTH(ingredients) < 20 
               OR serving_size IS NULL OR serving_size = '' 
               OR energy_kcal_100g IS NULL)
            ORDER BY id
            LIMIT {max_products}
        """)
        
        products = cursor.fetchall()
        total_products = len(products)
        
        print(f"🤖 SIMPLE AI DATA FIXER")
        print(f"📊 Found {total_products} products to fix")
        print(f"📄 CSV file: {self.csv_path}")
        print("=" * 50)
        
        if total_products == 0:
            print("✅ No products to fix!")
            return
        
        for i, (product_id, name, brand) in enumerate(products):
            print(f"\\n[{i+1}/{total_products}] Fixing ID {product_id}: {brand} {name}")
            
            # Ask ChatGPT to fix the data
            fixed_data = self.fix_food_data(name, brand)
            
            if fixed_data:
                # Update database
                fields_updated = self.update_database(product_id, fixed_data)
                print(f"   ✅ SUCCESS: Updated {fields_updated} database fields")
                
                # Add to CSV
                self.add_to_csv(product_id, name, brand, 'success', fixed_data)
                self.successes += 1
            else:
                print(f"   ❌ FAILED: Could not fix data")
                self.add_to_csv(product_id, name, brand, 'failed')
                self.failures += 1
                
            # Rate limiting
            time.sleep(2)
        
        # Final results
        total_processed = self.successes + self.failures
        print(f"\\n🎯 FINAL RESULTS:")
        print(f"   Total processed: {total_processed}")
        print(f"   Successes: {self.successes}")
        print(f"   Failures: {self.failures}")
        if total_processed > 0:
            print(f"   Success rate: {(self.successes / total_processed * 100):.1f}%")
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🤖 SIMPLE AI DATA FIXER")
    print("✅ Let ChatGPT do what it does best - fix data from reputable sources")
    print("=" * 60)
    
    # API Key
    openai_api_key = ""YOUR_OPENAI_API_KEY""
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    
    fixer = SimpleAIFixer(db_path, openai_api_key=openai_api_key)
    
    try:
        # Process 1000 products
        fixer.process_products(max_products=1000)
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()