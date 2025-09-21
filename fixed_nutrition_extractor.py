#!/usr/bin/env python3
"""
Fixed Nutrition Data Extractor
Addresses the core issue: getting real nutrition data instead of placeholders
Focus on simple, working ChatGPT prompts with better error handling
"""

import sqlite3
import json
import time
import re
import csv
from typing import Optional, Dict
from openai import OpenAI
from datetime import datetime

class FixedNutritionExtractor:
    def __init__(self, db_path: str, csv_path: str = None, openai_api_key: str = None):
        self.db_path = db_path
        self.csv_path = csv_path or f"fixed_nutrition_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        self.conn = sqlite3.connect(db_path)
        self.successes = 0
        self.failures = 0
        
        # Track processed foods to avoid duplicates
        self.processed_foods = set()
        self.load_processed_foods()
        
        # OpenAI API setup
        self.openai_client = None
        if openai_api_key and openai_api_key != "YOUR_OPENAI_API_KEY":
            self.openai_client = OpenAI(api_key=openai_api_key)
            
        # Initialize CSV file
        self.init_csv_file()
    
    def load_processed_foods(self):
        """Load already processed food IDs from existing CSV"""
        try:
            with open(self.csv_path, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                for row in reader:
                    if row.get('id'):
                        self.processed_foods.add(int(row['id']))
            print(f"📊 Loaded {len(self.processed_foods)} previously processed foods")
        except FileNotFoundError:
            print("📊 Starting fresh - no existing CSV found")
    
    def init_csv_file(self):
        """Initialize CSV file with essential headers"""
        try:
            with open(self.csv_path, 'r', newline='', encoding='utf-8') as csvfile:
                pass  # File exists
        except FileNotFoundError:
            with open(self.csv_path, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = [
                    'id', 'name', 'brand', 'processed_date', 'status',
                    'ingredients', 'serving_size', 'energy_kcal_100g', 
                    'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                    'chatgpt_raw_response', 'extraction_notes'
                ]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
            print(f"📄 Created CSV file: {self.csv_path}")
    
    def ask_chatgpt_simple(self, product_name: str, brand: str) -> Optional[Dict]:
        """Simplified ChatGPT approach - just ask for basic nutrition facts"""
        
        if not self.openai_client:
            return None
            
        # Much simpler, more direct prompt
        brand_text = f" by {brand}" if brand else ""
        prompt = f"""Please provide basic nutrition information for the UK food product: {product_name}{brand_text}

If you know this product, provide these facts per 100g:
- Calories (kcal)
- Fat (g)
- Carbs (g) 
- Sugar (g)
- Protein (g)
- Salt (g)
- Main ingredients (just the first 3-5)
- Typical serving size

If you don't know this exact product, just say "I don't have reliable data for this specific product."

Format your response as simple bullet points, not JSON."""

        try:
            print(f"   🧠 Asking ChatGPT about: {brand} {product_name}")
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
                max_tokens=400
            )
            
            response_text = response.choices[0].message.content.strip()
            print(f"   📝 ChatGPT response: {response_text[:100]}...")
            
            # Try to extract data from the text response
            if "don't have reliable data" in response_text.lower() or "don't know" in response_text.lower():
                print(f"   ❌ ChatGPT doesn't know this product")
                return None
            
            # Parse the bullet point response
            extracted_data = self.parse_chatgpt_text_response(response_text, product_name, brand)
            
            if extracted_data:
                # Add the raw response for debugging
                extracted_data['chatgpt_raw_response'] = response_text
                return extracted_data
            
            return None
                
        except Exception as e:
            print(f"   ❌ OpenAI API error: {e}")
            return None
    
    def parse_chatgpt_text_response(self, response_text: str, product_name: str, brand: str) -> Optional[Dict]:
        """Parse ChatGPT's text response to extract nutrition data"""
        
        try:
            data = {}
            
            # Extract calories/energy
            cal_match = re.search(r'calories?\s*[:\-]?\s*(\d+(?:\.\d+)?)', response_text, re.IGNORECASE)
            if cal_match:
                data['energy_kcal_100g'] = float(cal_match.group(1))
            
            # Extract fat
            fat_match = re.search(r'fat\s*[:\-]?\s*(\d+(?:\.\d+)?)g?', response_text, re.IGNORECASE)
            if fat_match:
                data['fat_100g'] = float(fat_match.group(1))
            
            # Extract carbs
            carb_match = re.search(r'carb(?:s|ohydrates?)?\s*[:\-]?\s*(\d+(?:\.\d+)?)g?', response_text, re.IGNORECASE)
            if carb_match:
                data['carbs_100g'] = float(carb_match.group(1))
            
            # Extract sugar  
            sugar_match = re.search(r'sugar\s*[:\-]?\s*(\d+(?:\.\d+)?)g?', response_text, re.IGNORECASE)
            if sugar_match:
                data['sugar_100g'] = float(sugar_match.group(1))
            
            # Extract protein
            protein_match = re.search(r'protein\s*[:\-]?\s*(\d+(?:\.\d+)?)g?', response_text, re.IGNORECASE)
            if protein_match:
                data['protein_100g'] = float(protein_match.group(1))
            
            # Extract salt
            salt_match = re.search(r'salt\s*[:\-]?\s*(\d+(?:\.\d+)?)g?', response_text, re.IGNORECASE)
            if salt_match:
                data['salt_100g'] = float(salt_match.group(1))
            
            # Extract serving size
            serving_patterns = [
                r'serving size?\s*[:\-]?\s*([^\\n,]+?)(?:\\n|$)',
                r'typical serving\s*[:\-]?\s*([^\\n,]+?)(?:\\n|$)',
                r'per serving\s*[:\-]?\s*([^\\n,]+?)(?:\\n|$)'
            ]
            
            for pattern in serving_patterns:
                serving_match = re.search(pattern, response_text, re.IGNORECASE)
                if serving_match:
                    serving_text = serving_match.group(1).strip()
                    # Clean up the serving size
                    serving_text = re.sub(r'[^\w\s\d\.]', '', serving_text)
                    if serving_text and len(serving_text) < 50:
                        data['serving_size'] = serving_text
                    break
            
            # Extract basic ingredients
            ingredient_patterns = [
                r'ingredients?\s*[:\-]\s*([^\\n]+?)(?:\\n|$)',
                r'main ingredients?\s*[:\-]\s*([^\\n]+?)(?:\\n|$)',
                r'contains?\s*[:\-]\s*([^\\n]+?)(?:\\n|$)'
            ]
            
            for pattern in ingredient_patterns:
                ing_match = re.search(pattern, response_text, re.IGNORECASE)
                if ing_match:
                    ingredients_text = ing_match.group(1).strip()
                    if ingredients_text and len(ingredients_text) > 5:
                        data['ingredients'] = ingredients_text
                    break
            
            # Validate we got some meaningful data
            nutrition_fields = ['energy_kcal_100g', 'fat_100g', 'carbs_100g', 'protein_100g']
            if any(field in data for field in nutrition_fields):
                print(f"   ✅ Extracted {len(data)} data fields")
                return data
            else:
                print(f"   ❌ No meaningful nutrition data extracted")
                return None
                
        except Exception as e:
            print(f"   ❌ Error parsing response: {e}")
            return None
    
    def add_to_csv(self, product_id: int, name: str, brand: str, status: str, data: Dict = None):
        """Add processed food to CSV file"""
        
        row = {
            'id': product_id,
            'name': name,
            'brand': brand or '',
            'processed_date': datetime.now().isoformat(),
            'status': status,  # 'success' or 'failed'
        }
        
        # Add nutrition data if available
        if data:
            nutrition_fields = [
                'ingredients', 'serving_size', 'energy_kcal_100g', 'fat_100g',
                'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'chatgpt_raw_response', 'extraction_notes'
            ]
            for field in nutrition_fields:
                row[field] = data.get(field, '')
        
        # Append to CSV
        with open(self.csv_path, 'a', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                'id', 'name', 'brand', 'processed_date', 'status',
                'ingredients', 'serving_size', 'energy_kcal_100g', 
                'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'chatgpt_raw_response', 'extraction_notes'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writerow(row)
        
        # Mark as processed
        self.processed_foods.add(product_id)
    
    def update_database(self, product_id: int, data: Dict) -> int:
        """Update database with nutrition data"""
        
        cursor = self.conn.cursor()
        updates = {}
        
        # Map data to database columns
        field_mapping = {
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
    
    def get_unprocessed_products(self, max_products: int = 10) -> list:
        """Get products that need nutrition data"""
        cursor = self.conn.cursor()
        
        # Build exclusion clause
        if self.processed_foods:
            exclusion_clause = f"AND id NOT IN ({','.join(map(str, self.processed_foods))})"
        else:
            exclusion_clause = ""
        
        cursor.execute(f"""
            SELECT id, name, brand
            FROM products 
            WHERE (ingredients IS NULL OR LENGTH(ingredients) < 20 
               OR serving_size IS NULL OR serving_size = '' 
               OR energy_kcal_100g IS NULL)
            {exclusion_clause}
            ORDER BY id
            LIMIT {max_products}
        """)
        
        return cursor.fetchall()
    
    def process_products(self, max_products: int = 10):
        """Process products with simplified approach"""
        
        products = self.get_unprocessed_products(max_products)
        total_products = len(products)
        
        print(f"🔧 FIXED NUTRITION EXTRACTOR")
        print(f"📊 Found {total_products} products needing nutrition data")
        print(f"📄 CSV file: {self.csv_path}")
        print("=" * 60)
        
        if total_products == 0:
            print("✅ No new products to process!")
            return
        
        for i, (product_id, name, brand) in enumerate(products):
            print(f"\\n[{i+1}/{total_products}] Processing ID {product_id}: {brand} {name}")
            
            # Try simple ChatGPT approach
            chatgpt_data = self.ask_chatgpt_simple(name, brand)
            
            if chatgpt_data:
                # Update database
                fields_updated = self.update_database(product_id, chatgpt_data)
                print(f"   ✅ SUCCESS: Updated {fields_updated} database fields")
                
                # Add to CSV
                self.add_to_csv(product_id, name, brand, 'success', chatgpt_data)
                self.successes += 1
            else:
                print(f"   ❌ FAILED: No nutrition data extracted")
                self.add_to_csv(product_id, name, brand, 'failed', {'extraction_notes': 'ChatGPT had no reliable data'})
                self.failures += 1
                
            # Rate limiting
            time.sleep(2)  # Longer delay for quality responses
        
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
    print("🔧 FIXED NUTRITION DATA EXTRACTOR")
    print("✅ Simplified approach to get REAL nutrition data")
    print("🎯 Focus on working ChatGPT prompts, not complex JSON")
    print("=" * 50)
    
    # API Key
    openai_api_key = ""YOUR_OPENAI_API_KEY""
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    csv_path = "/Users/aaronkeen/Desktop/nutrition_data_100_foods.csv"
    
    extractor = FixedNutritionExtractor(db_path, csv_path, openai_api_key)
    
    try:
        # Process 100 products as requested
        extractor.process_products(max_products=100)
        
    finally:
        extractor.close()

if __name__ == "__main__":
    main()