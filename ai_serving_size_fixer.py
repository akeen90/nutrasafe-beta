#!/usr/bin/env python3
"""
AI-Powered Serving Size Fixer
Uses web search + AI to get accurate UK serving sizes for food products
"""

import sqlite3
import requests
import json
import time
import re
from typing import Optional, Dict, Tuple

class AIServingSizeFixer:
    def __init__(self, db_path: str, api_key: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.api_key = api_key
        self.fixed_count = 0
        self.error_count = 0
        
    def search_web(self, query: str) -> str:
        """Search web for product information"""
        try:
            # Using DuckDuckGo Instant Answer API (free)
            url = f"https://api.duckduckgo.com/?q={query}&format=json&no_html=1&skip_disambig=1"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            # Get abstract or related topics
            result = ""
            if data.get('Abstract'):
                result += data['Abstract'] + " "
            if data.get('RelatedTopics'):
                for topic in data['RelatedTopics'][:3]:
                    if isinstance(topic, dict) and 'Text' in topic:
                        result += topic['Text'] + " "
            
            return result.strip()
        except:
            return ""
    
    def ask_ai_for_serving_size(self, product_name: str, brand: str, web_info: str) -> Optional[str]:
        """Use AI to determine serving size from product info"""
        
        prompt = f"""Based on the following UK food product information, determine the most accurate typical serving size.

Product: {product_name}
Brand: {brand}
Web Information: {web_info}

Please provide ONLY the serving size in this exact format:
- For drinks: "330ml" or "500ml" etc.
- For solid foods: "30g" or "1 biscuit (25g)" or "1/2 pizza (150g)" etc.
- For bread: "1 slice (36g)" or "2 slices (72g)" etc.

Consider UK retail standards. If you cannot determine from the information, respond with "UNKNOWN".

Serving size:"""

        try:
            # Using OpenAI API (you'll need to replace with your preferred AI API)
            headers = {
                'Authorization': f'Bearer {self.api_key}',
                'Content-Type': 'application/json'
            }
            
            data = {
                'model': 'gpt-3.5-turbo',
                'messages': [{'role': 'user', 'content': prompt}],
                'max_tokens': 50,
                'temperature': 0.1
            }
            
            response = requests.post(
                'https://api.openai.com/v1/chat/completions',
                headers=headers,
                json=data,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                serving_size = result['choices'][0]['message']['content'].strip()
                
                # Clean up the response
                serving_size = serving_size.replace('Serving size:', '').strip()
                
                if serving_size == "UNKNOWN" or not serving_size:
                    return None
                    
                return serving_size
            else:
                return None
                
        except Exception as e:
            print(f"AI API error: {e}")
            return None
    
    def fix_product_serving_size(self, product_id: int, name: str, brand: str, current_serving: str) -> bool:
        """Fix serving size for a single product"""
        
        # Skip if serving size looks already correct
        if self.is_serving_size_reasonable(current_serving, name):
            return False
        
        # Create search query
        search_query = f"{brand} {name} UK serving size nutrition"
        
        # Get web information
        print(f"🔍 Searching: {search_query[:50]}...")
        web_info = self.search_web(search_query)
        
        if not web_info:
            # Try simpler search
            search_query = f"{name} serving size UK"
            web_info = self.search_web(search_query)
        
        # Ask AI for serving size
        if web_info:
            print(f"🤖 Asking AI for serving size...")
            ai_serving_size = self.ask_ai_for_serving_size(name, brand or "", web_info)
            
            if ai_serving_size:
                # Update database
                cursor = self.conn.cursor()
                cursor.execute(
                    "UPDATE products SET serving_size = ? WHERE id = ?",
                    (ai_serving_size, product_id)
                )
                self.conn.commit()
                
                print(f"✅ Updated: {name} → {ai_serving_size}")
                self.fixed_count += 1
                return True
        
        self.error_count += 1
        return False
    
    def is_serving_size_reasonable(self, serving_size: str, product_name: str) -> bool:
        """Check if serving size looks reasonable"""
        if not serving_size:
            return False
        
        # Check for obvious errors
        suspicious_patterns = [
            r'330ml.*cookie',  # ml for solid food
            r'330ml.*chocolate',
            r'330ml.*biscuit',
            r'100g.*water',    # grams for liquids
            r'100g.*juice',
            r'100g.*cola',
            r'800g.*slice',    # Whole loaf as serving
            r'1000g',          # 1kg servings
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, f"{serving_size} {product_name}", re.IGNORECASE):
                return False
        
        # If it has reasonable patterns, likely OK
        reasonable_patterns = [
            r'\d+ml',          # Has ml for liquids
            r'\d+g',           # Has grams
            r'\d+\s*slice',    # Slice portions
            r'\d+\s*biscuit',  # Biscuit portions
            r'\d+\s*piece',    # Piece portions
        ]
        
        for pattern in reasonable_patterns:
            if re.search(pattern, serving_size, re.IGNORECASE):
                return True
        
        return False
    
    def fix_database_batch(self, batch_size: int = 10, max_products: int = 100) -> Tuple[int, int]:
        """Fix serving sizes in batches with rate limiting"""
        
        cursor = self.conn.cursor()
        
        # Get products with questionable serving sizes
        cursor.execute(f"""
            SELECT id, name, brand, serving_size 
            FROM products 
            WHERE serving_size LIKE '%330ml%' 
               OR serving_size LIKE '%100g%'
               OR serving_size LIKE '%800g%'
               OR serving_size LIKE '%1000g%'
               OR serving_size IS NULL
               OR serving_size = ''
            ORDER BY RANDOM()
            LIMIT {max_products}
        """)
        
        products = cursor.fetchall()
        
        print(f"🚀 AI SERVING SIZE FIXER - Processing {len(products)} products")
        print("=" * 60)
        
        for i, (product_id, name, brand, current_serving) in enumerate(products):
            print(f"\n[{i+1}/{len(products)}] {name} ({brand})")
            print(f"Current: {current_serving}")
            
            success = self.fix_product_serving_size(product_id, name, brand or "", current_serving or "")
            
            # Rate limiting - be nice to APIs
            time.sleep(2)
            
            # Batch checkpoint
            if (i + 1) % batch_size == 0:
                print(f"\n📊 Checkpoint: {self.fixed_count} fixed, {self.error_count} errors")
                time.sleep(5)  # Longer pause between batches
        
        return self.fixed_count, self.error_count
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🤖 AI-POWERED SERVING SIZE FIXER")
    print("=" * 50)
    
    # Using environment variable or Claude's access
    API_KEY = ""YOUR_OPENAI_API_KEY""  # We'll use Claude's web search instead
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    fixer = AIServingSizeFixer(db_path, API_KEY)
    
    try:
        # Fix 50 products as a test
        fixed, errors = fixer.fix_database_batch(batch_size=10, max_products=50)
        
        print(f"\n🎯 FINAL RESULTS:")
        print(f"   Fixed: {fixed}")
        print(f"   Errors: {errors}")
        print(f"   Success rate: {(fixed / (fixed + errors) * 100):.1f}%")
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()