#!/usr/bin/env python3
"""
Strict AI Data Fixer - NO GUESSING ALLOWED
Rejects responses that contain guessing language or vague information
"""

import sqlite3
import json
import time
import re
import csv
from typing import Optional, Dict
from openai import OpenAI
from datetime import datetime

class StrictAIFixer:
    def __init__(self, db_path: str, csv_path: str = None, openai_api_key: str = None):
        self.db_path = db_path
        self.csv_path = csv_path or f"/Users/aaronkeen/Desktop/strict_ai_fixed_data_1000.csv"
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
                'id', 'original_name', 'original_brand', 'processed_date', 'status', 'rejection_reason',
                'corrected_name', 'corrected_brand', 'ingredients', 'serving_size', 
                'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
                'sugar_per_serving', 'protein_per_serving', 'salt_per_serving',
                'chatgpt_response'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
        print(f"📄 Created CSV file: {self.csv_path}")
    
    def is_guess_response(self, response_text: str) -> tuple[bool, str]:
        """Check if the response contains guessing language - returns (is_guess, reason)"""
        
        # Convert to lowercase for checking
        text_lower = response_text.lower()
        
        # Guessing indicators
        guess_phrases = [
            'typically', 'usually', 'generally', 'approximate', 'estimated', 
            'would include', 'would contain', 'would typically', 'would usually',
            'might include', 'might contain', 'could include', 'could contain',
            'likely', 'probably', 'should be', 'tends to', 'may vary',
            'standard', 'common', 'basic', 'generic', 'similar products',
            'this type of product', 'products like this', 'similar items',
            "don't have exact", "don't have specific", "not specific",
            'exact list should be obtained', 'check the product packaging',
            'consult the packaging', 'refer to the package', 'see packaging'
        ]
        
        for phrase in guess_phrases:
            if phrase in text_lower:
                return True, f"Contains guessing language: '{phrase}'"
        
        # Check for vague ingredient lists
        if 'ingredients:' in text_lower:
            ingredients_section = text_lower.split('ingredients:')[1].split('\n')[0]
            if any(word in ingredients_section for word in ['etc', 'among others', 'and more', 'various']):
                return True, "Vague ingredient list with 'etc' or similar"
        
        # Check for disclaimer language
        disclaimer_phrases = [
            'values can vary', 'may vary', 'approximate values', 'estimates',
            'for reference only', 'should be verified', 'check packaging'
        ]
        
        for phrase in disclaimer_phrases:
            if phrase in text_lower:
                return True, f"Contains disclaimer indicating uncertainty: '{phrase}'"
        
        return False, ""
    
    def fix_food_data(self, product_name: str, brand: str) -> Optional[Dict]:
        """Ultra-strict prompt with guess rejection"""
        
        if not self.openai_client:
            return None
            
        # Much more strict prompt
        prompt = f"""I need EXACT nutrition data for this specific UK product. DO NOT GUESS.

Product: {product_name}
Brand: {brand}

CRITICAL RULES:
1. Only provide data if you have EXACT knowledge of this specific product
2. DO NOT use words like: typically, usually, approximately, estimated, would, might, could, likely, probably
3. DO NOT provide generic data for similar products
4. DO NOT suggest checking packaging or getting exact information elsewhere
5. If you don't have reliable data, say EXACTLY: "I don't have reliable data for this specific product"

Required format IF you have exact data:
Name: [exact name]
Brand: [exact brand] 
Ingredients: [complete exact ingredient list]
Serving size: [exact serving size]
Per 100g - Calories: [exact number], Fat: [exact], Carbs: [exact], Sugar: [exact], Protein: [exact], Salt: [exact]
Per serving - Calories: [exact number], Fat: [exact], Carbs: [exact], Sugar: [exact], Protein: [exact], Salt: [exact]"""

        try:
            print(f"   🔍 Strict check: {brand} {product_name}")
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.1,  # Lower temperature for less creativity
                max_tokens=500   # Shorter responses
            )
            
            response_text = response.choices[0].message.content.strip()
            
            # First check if it's an "I don't know" response
            if "don't have reliable data" in response_text.lower():
                print(f"   ❌ ChatGPT honestly doesn't know this product")
                return {'status': 'honest_failure', 'chatgpt_response': response_text}
            
            # Check for guessing language
            is_guess, guess_reason = self.is_guess_response(response_text)
            if is_guess:
                print(f"   🚫 REJECTED: {guess_reason}")
                return {'status': 'rejected_guess', 'rejection_reason': guess_reason, 'chatgpt_response': response_text}
            
            # Parse the response if it passes strict validation
            extracted_data = self.parse_simple_response(response_text)
            
            if extracted_data:
                # Clean up the response text for CSV
                clean_response = response_text.replace('\n', ' | ').replace('\r', ' | ')
                if len(clean_response) > 500:
                    clean_response = clean_response[:500] + "..."
                extracted_data['chatgpt_response'] = clean_response
                extracted_data['status'] = 'success'
                print(f"   ✅ VALIDATED: Real data extracted")
                return extracted_data
            
            return {'status': 'parse_failed', 'chatgpt_response': response_text}
                
        except Exception as e:
            print(f"   ❌ API error: {e}")
            return None
    
    def parse_simple_response(self, response_text: str) -> Optional[Dict]:
        """Parse the response format with stricter validation"""
        
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
            
            # Extract ingredients
            ing_match = re.search(r'Ingredients:\s*(.+?)(?:\n|Per|$)', response_text, re.IGNORECASE | re.DOTALL)
            if ing_match:
                ingredients = ing_match.group(1).strip()
                # Reject vague ingredient lists
                if not any(word in ingredients.lower() for word in ['etc', 'among others', 'and more', 'various', 'typically']):
                    data['ingredients'] = ingredients
            
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
            
            # Require minimum data quality
            required_fields = ['corrected_name', 'ingredients', 'energy_kcal_100g']
            if all(field in data for field in required_fields):
                print(f"   ✅ Extracted {len(data)} validated data fields")
                return data
            else:
                print(f"   ❌ Missing required fields")
                return None
                
        except Exception as e:
            print(f"   ❌ Error parsing response: {e}")
            return None
    
    def add_to_csv(self, product_id: int, original_name: str, original_brand: str, result: Dict):
        """Add processed food to CSV file"""
        
        row = {
            'id': product_id,
            'original_name': original_name,
            'original_brand': original_brand or '',
            'processed_date': datetime.now().isoformat(),
            'status': result.get('status', 'failed'),
            'rejection_reason': result.get('rejection_reason', ''),
        }
        
        # Add nutrition data if available
        if result.get('status') == 'success':
            for field in ['corrected_name', 'corrected_brand', 'ingredients', 'serving_size',
                         'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                         'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
                         'sugar_per_serving', 'protein_per_serving', 'salt_per_serving']:
                row[field] = result.get(field, '')
        
        # Always add the raw response for analysis
        row['chatgpt_response'] = result.get('chatgpt_response', '')
        
        # Append to CSV
        with open(self.csv_path, 'a', newline='', encoding='utf-8') as csvfile:
            fieldnames = [
                'id', 'original_name', 'original_brand', 'processed_date', 'status', 'rejection_reason',
                'corrected_name', 'corrected_brand', 'ingredients', 'serving_size', 
                'energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g',
                'energy_kcal_per_serving', 'fat_per_serving', 'carbs_per_serving', 
                'sugar_per_serving', 'protein_per_serving', 'salt_per_serving',
                'chatgpt_response'
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writerow(row)
    
    def update_database(self, product_id: int, data: Dict) -> int:
        """Update database with corrected data (only if validated)"""
        
        if data.get('status') != 'success':
            return 0
            
        cursor = self.conn.cursor()
        updates = {}
        
        # Map data to database columns
        field_mapping = {
            'corrected_name': 'name',
            'corrected_brand': 'brand',
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
        """Process products with strict validation"""
        
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
        
        print(f"🚫 STRICT AI DATA FIXER")
        print(f"📊 Found {total_products} products to validate")
        print(f"📄 CSV file: {self.csv_path}")
        print("=" * 50)
        
        if total_products == 0:
            print("✅ No products to process!")
            return
        
        guess_rejections = 0
        honest_failures = 0
        
        for i, (product_id, name, brand) in enumerate(products):
            print(f"\n[{i+1}/{total_products}] Validating ID {product_id}: {brand} {name}")
            
            # Ask ChatGPT with strict validation
            result = self.fix_food_data(name, brand)
            
            if result:
                status = result.get('status', 'failed')
                
                if status == 'success':
                    # Update database only with validated data
                    fields_updated = self.update_database(product_id, result)
                    print(f"   ✅ VALIDATED SUCCESS: Updated {fields_updated} database fields")
                    self.successes += 1
                elif status == 'rejected_guess':
                    print(f"   🚫 GUESS REJECTED: {result.get('rejection_reason', 'Unknown')}")
                    guess_rejections += 1
                elif status == 'honest_failure':
                    print(f"   ❌ HONEST FAILURE: ChatGPT doesn't know this product")
                    honest_failures += 1
                else:
                    print(f"   ❌ OTHER FAILURE: {status}")
                    self.failures += 1
                
                # Add to CSV regardless of status
                self.add_to_csv(product_id, name, brand, result)
            else:
                print(f"   ❌ API FAILED: No response")
                self.add_to_csv(product_id, name, brand, {'status': 'api_failed'})
                self.failures += 1
                
            # Rate limiting
            time.sleep(2)
        
        # Final results
        total_processed = self.successes + self.failures + guess_rejections + honest_failures
        print(f"\n🎯 STRICT VALIDATION RESULTS:")
        print(f"   Total processed: {total_processed}")
        print(f"   ✅ Validated successes: {self.successes}")
        print(f"   🚫 Guess rejections: {guess_rejections}")
        print(f"   ❌ Honest failures: {honest_failures}")
        print(f"   💥 Other failures: {self.failures}")
        if total_processed > 0:
            print(f"   📊 Real data rate: {(self.successes / total_processed * 100):.1f}%")
            print(f"   🚫 Guess rejection rate: {(guess_rejections / total_processed * 100):.1f}%")
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🚫 STRICT AI DATA FIXER")
    print("✅ NO GUESSING - Only validated data or honest failures")
    print("=" * 60)
    
    # API Key
    openai_api_key = ""YOUR_OPENAI_API_KEY""
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    
    fixer = StrictAIFixer(db_path, openai_api_key=openai_api_key)
    
    try:
        # Process 100 products with strict validation
        fixer.process_products(max_products=100)
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()