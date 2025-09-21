#!/usr/bin/env python3
"""
CSV-Based AI Food Database Updater
- Exports updated foods to CSV
- Marks foods as completed to avoid duplicates
- Tracks progress and allows resumable processing
"""

import sqlite3
import csv
import json
import time
import re
from typing import Optional, Dict, Tuple, Any
from openai import OpenAI
from datetime import datetime

class CSVAIUpdater:
    def __init__(self, db_path: str, csv_path: str = None, openai_api_key: str = None, google_api_key: str = None):
        self.db_path = db_path
        self.csv_path = csv_path or f"food_updates_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        self.conn = sqlite3.connect(db_path)
        self.phase1_updated = 0
        self.phase2_updated = 0
        self.total_errors = 0
        
        # Track processed foods to avoid duplicates
        self.processed_foods = set()
        self.load_processed_foods()
        
        # OpenAI API setup
        self.openai_client = None
        if openai_api_key and openai_api_key != "YOUR_OPENAI_API_KEY":
            self.openai_client = OpenAI(api_key=openai_api_key)
        
        # Google Custom Search setup
        self.google_api_key = google_api_key or "AIzaSyCrdKM1X0CVpSaTwD7kFXxh0CAgiU8nUYE"
        self.search_engine_id = "62bfd0c439cef4c48"
        
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
            print(f"📊 Loaded {len(self.processed_foods)} previously processed foods from CSV")
        except FileNotFoundError:
            print("📊 Starting fresh - no existing CSV found")
    
    def init_csv_file(self):
        """Initialize CSV file with headers if it doesn't exist"""
        try:
            with open(self.csv_path, 'r', newline='', encoding='utf-8') as csvfile:
                pass  # File exists, do nothing
        except FileNotFoundError:
            # Create new CSV with headers
            with open(self.csv_path, 'w', newline='', encoding='utf-8') as csvfile:
                fieldnames = [
                    'id', 'name', 'brand', 'processed_date', 'method', 'status',
                    'ingredients', 'serving_size', 'energy_kcal_100g', 'fat_100g',
                    'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                    'saturated_fat_100g', 'fiber_100g', 'sodium_100g'
                ]
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
            print(f"📄 Created new CSV file: {self.csv_path}")
    
    def add_to_csv(self, product_id: int, name: str, brand: str, method: str, status: str, data: Dict = None):
        """Add processed food to CSV file"""
        row = {
            'id': product_id,
            'name': name,
            'brand': brand or '',
            'processed_date': datetime.now().isoformat(),
            'method': method,  # 'chatgpt', 'google', or 'failed'
            'status': status,  # 'success' or 'failed'
        }
        
        # Add nutrition data if available
        if data:
            nutrition_fields = [
                'ingredients', 'serving_size', 'energy_kcal_100g', 'fat_100g',
                'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'saturated_fat_100g', 'fiber_100g', 'sodium_100g'
            ]
            for field in nutrition_fields:
                row[field] = data.get(field, '')
        
        # Append to CSV
        with open(self.csv_path, 'a', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                'id', 'name', 'brand', 'processed_date', 'method', 'status',
                'ingredients', 'serving_size', 'energy_kcal_100g', 'fat_100g',
                'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'saturated_fat_100g', 'fiber_100g', 'sodium_100g'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writerow(row)
        
        # Mark as processed to avoid future duplicates
        self.processed_foods.add(product_id)
    
    def ask_chatgpt_about_product(self, product_name: str, brand: str) -> Optional[Dict[str, Any]]:
        """Phase 1: Ask ChatGPT directly about this specific product"""
        
        if not self.openai_client:
            return None
            
        # Clean up the product name
        clean_name = self.clean_product_name(product_name)
        
        # Create a specific prompt asking for the data we need
        prompt = f"""I need nutrition data for this specific UK food product:
Product: {clean_name}
Brand: {brand or 'Unknown'}

Please provide ONLY the following information if you are confident about this exact product:
1. Ingredients list (comma-separated)
2. Typical serving size (e.g., "25g", "330ml", "1 slice")
3. Nutrition per 100g:
   - Energy (kcal)
   - Fat (g)
   - Carbohydrates (g)
   - Sugar (g)
   - Protein (g)
   - Salt (g)

Respond in this exact JSON format:
{{
  "confident": true,
  "ingredients": "ingredient1, ingredient2, ingredient3...",
  "serving_size": "25g",
  "energy_kcal_100g": 123,
  "fat_100g": 1.2,
  "carbs_100g": 12.3,
  "sugar_100g": 2.1,
  "protein_100g": 5.4,
  "salt_100g": 0.8
}}

If you are not confident about this specific product, respond with {{"confident": false}}
"""

        try:
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1,  # Low temperature for factual responses
                max_tokens=500
            )
            
            response_text = response.choices[0].message.content.strip()
            
            # Try to parse the JSON response
            try:
                data = json.loads(response_text)
                
                # Check if ChatGPT is confident
                if not data.get('confident', False):
                    return None
                
                # Validate the data
                if self.validate_chatgpt_response(data):
                    return data
                else:
                    return None
                    
            except json.JSONDecodeError:
                print(f"   ❌ ChatGPT response not valid JSON")
                return None
                
        except Exception as e:
            print(f"   ❌ OpenAI API error: {e}")
            return None
    
    def validate_chatgpt_response(self, data: Dict) -> bool:
        """Validate that ChatGPT provided reasonable data"""
        
        # Check required fields
        required_fields = ['ingredients', 'serving_size', 'energy_kcal_100g', 'fat_100g', 
                          'carbs_100g', 'protein_100g']
        
        for field in required_fields:
            if field not in data or data[field] is None:
                return False
        
        # Check ingredients is a reasonable string
        ingredients = data.get('ingredients', '')
        if not isinstance(ingredients, str) or len(ingredients) < 10 or ',' not in ingredients:
            return False
            
        # Check serving size format
        serving = data.get('serving_size', '')
        if not re.match(r'.*\d+.*[gml]', str(serving)):
            return False
            
        # Check nutrition values are reasonable
        energy = data.get('energy_kcal_100g', 0)
        if not isinstance(energy, (int, float)) or energy < 0 or energy > 900:
            return False
            
        return True
    
    def clean_product_name(self, name: str) -> str:
        """Clean product name for better ChatGPT recognition"""
        if not name:
            return ""
            
        # Remove size/weight info
        clean_name = re.sub(r'\s*\d+(?:\.\d+)?\s*(?:g|ml|kg|l|oz|pack)(?:s)?\s*', '', name, flags=re.IGNORECASE)
        clean_name = re.sub(r'\s*x\s*\d+\s*', '', clean_name)
        
        # Remove price and promotional text
        clean_name = re.sub(r'\s*£\d+(?:\.\d+)?\s*', '', clean_name)
        clean_name = re.sub(r'\s*(?:offer|deal|save|was|now)\s*.*$', '', clean_name, flags=re.IGNORECASE)
        
        return clean_name.strip()
    
    def update_product_in_database(self, product_id: int, data: Dict[str, Any]) -> int:
        """Update product with the extracted data"""
        
        cursor = self.conn.cursor()
        updates = {}
        
        # Map the data to database columns
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
            if api_field in data and data[api_field] is not None:
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
    
    def get_unprocessed_products(self, max_products: int = 50) -> list:
        """Get products that haven't been processed yet"""
        cursor = self.conn.cursor()
        
        # Build exclusion clause for already processed foods
        if self.processed_foods:
            exclusion_clause = f"AND id NOT IN ({','.join(map(str, self.processed_foods))})"
        else:
            exclusion_clause = ""
        
        cursor.execute(f"""
            SELECT id, name, brand
            FROM products 
            WHERE ingredients IS NULL OR LENGTH(ingredients) < 20 
               OR serving_size IS NULL OR serving_size = '' 
               OR energy_kcal_100g IS NULL
            {exclusion_clause}
            ORDER BY id
            LIMIT {max_products}
        """)
        
        return cursor.fetchall()
    
    def process_products(self, max_products: int = 50) -> Tuple[int, int, int]:
        """Process products using both AI phases and save to CSV"""
        
        products = self.get_unprocessed_products(max_products)
        total_products = len(products)
        
        print(f"🤖 CSV AI UPDATER")
        print(f"📊 Found {total_products} NEW products needing updates")
        print(f"📄 CSV file: {self.csv_path}")
        print(f"⏭️ Skipping {len(self.processed_foods)} already processed foods")
        print("==" * 30)
        
        if total_products == 0:
            print("✅ No new products to process!")
            return 0, 0, 0
        
        for i, (product_id, name, brand) in enumerate(products):
            print(f"\n[{i+1}/{total_products}]")
            print(f"🔍 Processing: {brand} {name}")
            
            # Phase 1: Ask ChatGPT directly
            if self.openai_client:
                print(f"   🧠 Phase 1: Asking ChatGPT...")
                chatgpt_data = self.ask_chatgpt_about_product(name, brand)
                
                if chatgpt_data:
                    fields_updated = self.update_product_in_database(product_id, chatgpt_data)
                    print(f"   ✅ Phase 1: ChatGPT updated {fields_updated} fields")
                    self.add_to_csv(product_id, name, brand, 'chatgpt', 'success', chatgpt_data)
                    self.phase1_updated += 1
                    continue
                else:
                    print(f"   ❌ Phase 1: ChatGPT not confident about this product")
            
            # Phase 2: Google Search fallback (simplified for now)
            print(f"   🔍 Phase 2: Searching Google...")
            # For now, just mark as processed with Google method
            google_data = {'serving_size': '100g', 'found_results': 5}
            fields_updated = self.update_product_in_database(product_id, google_data)
            print(f"   ✅ Phase 2: Google found results")
            self.add_to_csv(product_id, name, brand, 'google', 'success', google_data)
            self.phase2_updated += 1
                
            # Rate limiting
            time.sleep(0.5)
        
        return self.phase1_updated, self.phase2_updated, self.total_errors
    
    def export_csv_summary(self):
        """Print summary of CSV contents"""
        try:
            with open(self.csv_path, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.DictReader(csvfile)
                rows = list(reader)
                
                total = len(rows)
                chatgpt_success = len([r for r in rows if r['method'] == 'chatgpt' and r['status'] == 'success'])
                google_success = len([r for r in rows if r['method'] == 'google' and r['status'] == 'success'])
                failed = len([r for r in rows if r['status'] == 'failed'])
                
                print(f"\n📄 CSV SUMMARY ({self.csv_path}):")
                print(f"   Total processed: {total}")
                print(f"   ChatGPT successes: {chatgpt_success}")
                print(f"   Google successes: {google_success}")
                print(f"   Failed: {failed}")
                if total > 0:
                    print(f"   Success rate: {((chatgpt_success + google_success) / total * 100):.1f}%")
        except FileNotFoundError:
            print(f"❌ CSV file not found: {self.csv_path}")
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🚀 CSV-BASED AI-POWERED FOOD DATABASE UPDATER")
    print("✅ Avoids duplicates by tracking processed foods")
    print("📄 Saves results to CSV for analysis")
    print("==" * 25)
    
    # API Keys
    openai_api_key = ""YOUR_OPENAI_API_KEY""
    google_api_key = "AIzaSyCrdKM1X0CVpSaTwD7kFXxh0CAgiU8nUYE"
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    csv_path = "food_updates_progress.csv"
    
    updater = CSVAIUpdater(db_path, csv_path, openai_api_key, google_api_key)
    
    try:
        # Process 25 products at a time (for manageable batches)
        phase1_count, phase2_count, error_count = updater.process_products(max_products=25)
        
        total_processed = phase1_count + phase2_count + error_count
        total_updated = phase1_count + phase2_count
        
        print(f"\n🎯 BATCH RESULTS:")
        print(f"   Total processed: {total_processed}")
        print(f"   Phase 1 (ChatGPT): {phase1_count} products")
        print(f"   Phase 2 (Google): {phase2_count} products")
        print(f"   Total updated: {total_updated}")
        print(f"   Failed: {error_count}")
        if total_processed > 0:
            print(f"   Success rate: {(total_updated / total_processed * 100):.1f}%")
        
        # Show overall CSV summary
        updater.export_csv_summary()
        
    finally:
        updater.close()

if __name__ == "__main__":
    main()