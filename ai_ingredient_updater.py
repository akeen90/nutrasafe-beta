#!/usr/bin/env python3
"""
AI-Powered Ingredient Updater
Fetches complete ingredient lists from online UK retail sources
Updates missing/incomplete ingredient data using web search + AI
"""

import sqlite3
import requests
import json
import time
import re
from typing import Optional, Dict, Tuple

class AIIngredientUpdater:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.updated_count = 0
        self.error_count = 0
        
    def search_tesco_ingredients(self, product_name: str, brand: str) -> Optional[str]:
        """Search Tesco website for ingredient information"""
        query = f"{brand} {product_name} ingredients UK"
        try:
            # Using DuckDuckGo to search specifically for Tesco product pages
            search_url = f"https://api.duckduckgo.com/?q=site:tesco.com {query}&format=json&no_html=1"
            response = requests.get(search_url, timeout=10)
            data = response.json()
            
            # Look for Tesco product pages
            result_text = ""
            if data.get('Results'):
                for result in data['Results'][:2]:
                    if 'tesco.com' in result.get('FirstURL', ''):
                        result_text += result.get('Text', '') + " "
            
            return result_text.strip()
        except:
            return None
    
    def search_sainsburys_ingredients(self, product_name: str, brand: str) -> Optional[str]:
        """Search Sainsbury's website for ingredient information"""
        query = f"{brand} {product_name} ingredients UK"
        try:
            search_url = f"https://api.duckduckgo.com/?q=site:sainsburys.co.uk {query}&format=json&no_html=1"
            response = requests.get(search_url, timeout=10)
            data = response.json()
            
            result_text = ""
            if data.get('Results'):
                for result in data['Results'][:2]:
                    if 'sainsburys.co.uk' in result.get('FirstURL', ''):
                        result_text += result.get('Text', '') + " "
            
            return result_text.strip()
        except:
            return None
    
    def search_general_ingredients(self, product_name: str, brand: str) -> Optional[str]:
        """General web search for UK ingredient information"""
        query = f'"{brand}" "{product_name}" ingredients UK nutrition facts'
        try:
            search_url = f"https://api.duckduckgo.com/?q={query}&format=json&no_html=1"
            response = requests.get(search_url, timeout=10)
            data = response.json()
            
            result_text = ""
            if data.get('Abstract'):
                result_text += data['Abstract'] + " "
            if data.get('RelatedTopics'):
                for topic in data['RelatedTopics'][:3]:
                    if isinstance(topic, dict) and 'Text' in topic:
                        result_text += topic['Text'] + " "
            
            return result_text.strip()
        except:
            return None
    
    def extract_ingredients_with_ai(self, product_name: str, brand: str, web_info: str) -> Optional[str]:
        """Use AI reasoning to extract clean ingredient list"""
        
        if not web_info or len(web_info) < 20:
            return None
            
        # Look for ingredient patterns in the web info
        ingredient_patterns = [
            r'[Ii]ngredients?:?\s*([^.]+(?:\.[^.]*)*)',
            r'[Cc]ontains?:?\s*([^.]+(?:\.[^.]*)*)',
            r'[Mm]ade with:?\s*([^.]+(?:\.[^.]*)*)',
        ]
        
        for pattern in ingredient_patterns:
            match = re.search(pattern, web_info)
            if match:
                ingredients = match.group(1).strip()
                
                # Clean up the ingredients
                ingredients = self.clean_ingredient_text(ingredients)
                
                # Validate it looks like real ingredients
                if self.validate_ingredients(ingredients):
                    return ingredients
        
        # Try to find ingredient-like text
        sentences = web_info.split('.')
        for sentence in sentences:
            if self.looks_like_ingredients(sentence):
                cleaned = self.clean_ingredient_text(sentence)
                if self.validate_ingredients(cleaned):
                    return cleaned
        
        return None
    
    def clean_ingredient_text(self, text: str) -> str:
        """Clean up ingredient text"""
        if not text:
            return ""
            
        # Remove common prefixes
        text = re.sub(r'^(ingredients?:?\s*|contains?:?\s*|made with:?\s*)', '', text, flags=re.IGNORECASE)
        
        # Remove trailing punctuation and clean up
        text = text.strip(' .,;:')
        
        # Remove obvious non-ingredient text
        stop_phrases = [
            'nutritional information', 'per 100g', 'energy', 'calories',
            'allergy advice', 'storage', 'produced in', 'packed in'
        ]
        
        for phrase in stop_phrases:
            if phrase.lower() in text.lower():
                # Split and keep the part before the stop phrase
                parts = re.split(phrase, text, flags=re.IGNORECASE)
                text = parts[0].strip(' .,;:')
        
        return text
    
    def looks_like_ingredients(self, text: str) -> bool:
        """Check if text looks like an ingredient list"""
        if not text or len(text) < 10:
            return False
            
        text_lower = text.lower()
        
        # Ingredient keywords
        ingredient_keywords = [
            'flour', 'sugar', 'salt', 'oil', 'water', 'milk', 'egg', 'butter',
            'wheat', 'corn', 'rice', 'potato', 'tomato', 'onion', 'garlic',
            'preservative', 'flavour', 'colour', 'stabiliser', 'emulsifier'
        ]
        
        # Count how many ingredient words we find
        keyword_count = sum(1 for keyword in ingredient_keywords if keyword in text_lower)
        
        # Look for percentage indicators
        has_percentages = bool(re.search(r'\d+%', text))
        
        # Look for comma-separated structure
        has_commas = text.count(',') >= 2
        
        return keyword_count >= 2 or (keyword_count >= 1 and (has_percentages or has_commas))
    
    def validate_ingredients(self, ingredients: str) -> bool:
        """Validate ingredient list looks legitimate"""
        if not ingredients or len(ingredients) < 15:
            return False
            
        # Should have commas (ingredient separation)
        if ',' not in ingredients:
            return False
            
        # Should not be all caps or all lowercase
        if ingredients.isupper() or ingredients.islower():
            return False
            
        # Should not contain obvious non-food words
        bad_words = ['website', 'click', 'buy', 'price', '£', '$', 'delivery']
        if any(word in ingredients.lower() for word in bad_words):
            return False
            
        return True
    
    def update_product_ingredients(self, product_id: int, name: str, brand: str, current_ingredients: str) -> bool:
        """Update ingredients for a single product"""
        
        # Skip if already has good ingredients
        if current_ingredients and len(current_ingredients) > 50 and self.validate_ingredients(current_ingredients):
            return False
        
        print(f"🔍 Searching ingredients for: {brand} {name}")
        
        # Try multiple search strategies
        search_results = []
        
        # Search Tesco
        tesco_info = self.search_tesco_ingredients(name, brand or "")
        if tesco_info:
            search_results.append(tesco_info)
        
        # Search Sainsbury's
        sainsburys_info = self.search_sainsburys_ingredients(name, brand or "")
        if sainsburys_info:
            search_results.append(sainsburys_info)
        
        # General search
        general_info = self.search_general_ingredients(name, brand or "")
        if general_info:
            search_results.append(general_info)
        
        # Process search results with AI
        for web_info in search_results:
            ingredients = self.extract_ingredients_with_ai(name, brand or "", web_info)
            if ingredients:
                # Update database
                cursor = self.conn.cursor()
                cursor.execute(
                    "UPDATE products SET ingredients = ? WHERE id = ?",
                    (ingredients, product_id)
                )
                self.conn.commit()
                
                print(f"✅ Updated: {ingredients[:80]}...")
                self.updated_count += 1
                return True
        
        print(f"❌ No ingredients found")
        self.error_count += 1
        return False
    
    def update_missing_ingredients(self, batch_size: int = 20, max_products: int = 100) -> Tuple[int, int]:
        """Update ingredients for products with missing data"""
        
        cursor = self.conn.cursor()
        
        # Get products with missing or poor ingredient data
        cursor.execute(f"""
            SELECT id, name, brand, ingredients 
            FROM products 
            WHERE (ingredients IS NULL OR LENGTH(ingredients) < 20)
              AND brand IN ('Tesco', 'ASDA', 'Sainsbury''s', 'Walkers', 'Marks & Spencer')
            ORDER BY RANDOM()
            LIMIT {max_products}
        """)
        
        products = cursor.fetchall()
        
        print(f"🤖 AI INGREDIENT UPDATER - Processing {len(products)} products")
        print("=" * 60)
        
        for i, (product_id, name, brand, current_ingredients) in enumerate(products):
            print(f"\n[{i+1}/{len(products)}] {brand} - {name}")
            
            success = self.update_product_ingredients(product_id, name, brand or "", current_ingredients or "")
            
            # Rate limiting - be nice to APIs
            time.sleep(1)
            
            # Batch checkpoint
            if (i + 1) % batch_size == 0:
                print(f"\n📊 Checkpoint: {self.updated_count} updated, {self.error_count} failed")
                time.sleep(10)  # Longer pause between batches
        
        return self.updated_count, self.error_count
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🤖 AI-POWERED INGREDIENT UPDATER")
    print("=" * 50)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    updater = AIIngredientUpdater(db_path)
    
    try:
        # Update 5 products as a test
        updated, errors = updater.update_missing_ingredients(batch_size=5, max_products=5)
        
        print(f"\n🎯 FINAL RESULTS:")
        print(f"   Updated: {updated}")
        print(f"   Failed: {errors}")
        print(f"   Success rate: {(updated / (updated + errors) * 100):.1f}%" if (updated + errors) > 0 else "0%")
        
    finally:
        updater.close()

if __name__ == "__main__":
    main()