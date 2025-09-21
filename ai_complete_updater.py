#!/usr/bin/env python3
"""
AI-Powered Complete Food Data Updater
Fetches ingredients, nutrition facts, AND serving sizes from online UK sources
Automatically calculates per-serving AND per-100g nutrition values
"""

import sqlite3
import requests
import json
import time
import re
from typing import Optional, Dict, Tuple, Any

class AICompleteUpdater:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.updated_count = 0
        self.error_count = 0
        
    def search_product_data(self, product_name: str, brand: str) -> Dict[str, str]:
        """Search multiple UK retailers for complete product data"""
        
        results = {
            'tesco': '',
            'sainsburys': '',
            'asda': '',
            'general': ''
        }
        
        query_base = f'"{brand}" "{product_name}" UK'
        
        # Search Tesco
        try:
            tesco_query = f'site:tesco.com {query_base} nutrition ingredients'
            tesco_url = f"https://api.duckduckgo.com/?q={tesco_query}&format=json&no_html=1"
            response = requests.get(tesco_url, timeout=10)
            data = response.json()
            
            if data.get('Results'):
                for result in data['Results'][:2]:
                    if 'tesco.com' in result.get('FirstURL', ''):
                        results['tesco'] += result.get('Text', '') + " "
        except:
            pass
        
        # Search Sainsbury's  
        try:
            sainsburys_query = f'site:sainsburys.co.uk {query_base} nutrition ingredients'
            sainsburys_url = f"https://api.duckduckgo.com/?q={sainsburys_query}&format=json&no_html=1"
            response = requests.get(sainsburys_url, timeout=10)
            data = response.json()
            
            if data.get('Results'):
                for result in data['Results'][:2]:
                    if 'sainsburys.co.uk' in result.get('FirstURL', ''):
                        results['sainsburys'] += result.get('Text', '') + " "
        except:
            pass
            
        # Search ASDA
        try:
            asda_query = f'site:asda.com {query_base} nutrition ingredients'
            asda_url = f"https://api.duckduckgo.com/?q={asda_query}&format=json&no_html=1"
            response = requests.get(asda_url, timeout=10)
            data = response.json()
            
            if data.get('Results'):
                for result in data['Results'][:2]:
                    if 'asda.com' in result.get('FirstURL', ''):
                        results['asda'] += result.get('Text', '') + " "
        except:
            pass
        
        # General search
        try:
            general_query = f'{query_base} nutrition facts ingredients serving size UK'
            general_url = f"https://api.duckduckgo.com/?q={general_query}&format=json&no_html=1"
            response = requests.get(general_url, timeout=10)
            data = response.json()
            
            if data.get('Abstract'):
                results['general'] += data['Abstract'] + " "
            if data.get('RelatedTopics'):
                for topic in data['RelatedTopics'][:3]:
                    if isinstance(topic, dict) and 'Text' in topic:
                        results['general'] += topic['Text'] + " "
        except:
            pass
        
        return results
    
    def extract_ingredients(self, web_data: Dict[str, str]) -> Optional[str]:
        """Extract ingredients from web search results"""
        
        all_text = " ".join(web_data.values())
        
        # Look for ingredient patterns
        ingredient_patterns = [
            r'[Ii]ngredients?:?\s*([^.]+(?:\.[^.]*)*)',
            r'[Cc]ontains?:?\s*([^.]+(?:\.[^.]*)*)',
            r'[Mm]ade with:?\s*([^.]+(?:\.[^.]*)*)',
        ]
        
        for pattern in ingredient_patterns:
            match = re.search(pattern, all_text)
            if match:
                ingredients = match.group(1).strip()
                ingredients = self.clean_text(ingredients)
                
                if self.validate_ingredients(ingredients):
                    return ingredients
        
        return None
    
    def extract_serving_size(self, web_data: Dict[str, str]) -> Optional[str]:
        """Extract serving size from web search results"""
        
        all_text = " ".join(web_data.values())
        
        # Look for serving size patterns
        serving_patterns = [
            r'[Ss]erving size:?\s*([^.]+)',
            r'[Pp]er serving:?\s*\(([^)]+)\)',
            r'[Ss]erves?\s*(\d+)',
            r'(\d+(?:\.\d+)?(?:g|ml))\s*pack',
            r'(\d+(?:\.\d+)?(?:g|ml))\s*(?:can|bottle|bag)',
        ]
        
        for pattern in serving_patterns:
            match = re.search(pattern, all_text)
            if match:
                serving = match.group(1).strip()
                serving = self.clean_text(serving)
                
                if self.validate_serving_size(serving):
                    return serving
        
        return None
    
    def extract_nutrition_facts(self, web_data: Dict[str, str]) -> Dict[str, Optional[float]]:
        """Extract nutrition facts from web search results"""
        
        all_text = " ".join(web_data.values())
        
        nutrition = {
            'energy_kcal': None,
            'fat': None,
            'saturated_fat': None,
            'carbs': None,
            'sugars': None,
            'fiber': None,
            'protein': None,
            'salt': None
        }
        
        # Look for nutrition patterns
        patterns = {
            'energy_kcal': [r'(\d+(?:\.\d+)?)\s*kcal', r'(\d+(?:\.\d+)?)\s*calories'],
            'fat': [r'[Ff]at:?\s*(\d+(?:\.\d+)?)g', r'[Tt]otal fat:?\s*(\d+(?:\.\d+)?)g'],
            'saturated_fat': [r'[Ss]aturated fat:?\s*(\d+(?:\.\d+)?)g', r'[Ss]aturates:?\s*(\d+(?:\.\d+)?)g'],
            'carbs': [r'[Cc]arbohydrates?:?\s*(\d+(?:\.\d+)?)g', r'[Cc]arbs:?\s*(\d+(?:\.\d+)?)g'],
            'sugars': [r'[Ss]ugars?:?\s*(\d+(?:\.\d+)?)g'],
            'fiber': [r'[Ff]ib(?:er|re):?\s*(\d+(?:\.\d+)?)g'],
            'protein': [r'[Pp]rotein:?\s*(\d+(?:\.\d+)?)g'],
            'salt': [r'[Ss]alt:?\s*(\d+(?:\.\d+)?)g', r'[Ss]odium:?\s*(\d+(?:\.\d+)?)mg']
        }
        
        for nutrient, nutrient_patterns in patterns.items():
            for pattern in nutrient_patterns:
                match = re.search(pattern, all_text)
                if match:
                    value = float(match.group(1))
                    # Convert sodium mg to salt g
                    if 'sodium' in pattern and 'mg' in pattern:
                        value = value * 2.5 / 1000  # Convert sodium mg to salt g
                    nutrition[nutrient] = value
                    break
        
        return nutrition
    
    def calculate_conversions(self, serving_size: str, nutrition_per_100g: Dict[str, Optional[float]]) -> Dict[str, Optional[float]]:
        """Calculate per-serving nutrition from per-100g values"""
        
        # Extract numeric value and unit from serving size
        match = re.search(r'(\d+(?:\.\d+)?)\s*(g|ml)', serving_size.lower())
        if not match:
            return {}
        
        serving_amount = float(match.group(1))
        unit = match.group(2)
        
        # Calculate multiplier (assume 1ml = 1g for liquids)
        multiplier = serving_amount / 100
        
        # Convert nutrition values
        per_serving = {}
        for nutrient, value in nutrition_per_100g.items():
            if value is not None:
                per_serving[f"{nutrient}_per_serving"] = round(value * multiplier, 2)
        
        return per_serving
    
    def clean_text(self, text: str) -> str:
        """Clean up extracted text"""
        if not text:
            return ""
        
        # Remove common prefixes and suffixes
        text = re.sub(r'^(ingredients?:?\s*|contains?:?\s*|made with:?\s*)', '', text, flags=re.IGNORECASE)
        text = text.strip(' .,;:')
        
        return text
    
    def validate_ingredients(self, ingredients: str) -> bool:
        """Validate ingredient list"""
        if not ingredients or len(ingredients) < 15:
            return False
        
        # Should have commas
        if ',' not in ingredients:
            return False
            
        # Should not contain obvious non-food words
        bad_words = ['website', 'click', 'buy', 'price', '£', '$', 'delivery']
        if any(word in ingredients.lower() for word in bad_words):
            return False
            
        return True
    
    def validate_serving_size(self, serving: str) -> bool:
        """Validate serving size"""
        if not serving or len(serving) < 2:
            return False
            
        # Should contain numbers and units
        if not re.search(r'\d+(?:\.\d+)?\s*(?:g|ml|slice|piece|biscuit)', serving.lower()):
            return False
            
        return True
    
    def update_product_complete(self, product_id: int, name: str, brand: str, current_data: Dict[str, Any]) -> bool:
        """Update complete product data: ingredients, serving size, and nutrition"""
        
        print(f"🔍 Searching complete data for: {brand} {name}")
        
        # Search for product data
        web_data = self.search_product_data(name, brand or "")
        
        if not any(web_data.values()):
            print(f"❌ No web data found")
            self.error_count += 1
            return False
        
        # Extract data
        ingredients = self.extract_ingredients(web_data)
        serving_size = self.extract_serving_size(web_data)
        nutrition_facts = self.extract_nutrition_facts(web_data)
        
        # Prepare update data
        updates = {}
        
        if ingredients and (not current_data.get('ingredients') or len(current_data.get('ingredients', '')) < 20):
            updates['ingredients'] = ingredients
            print(f"   ✅ Found ingredients: {ingredients[:60]}...")
        
        if serving_size and not current_data.get('serving_size'):
            updates['serving_size'] = serving_size
            print(f"   ✅ Found serving size: {serving_size}")
            
            # Calculate per-serving nutrition if we have per-100g data
            per_serving = self.calculate_conversions(serving_size, {
                'energy_kcal': current_data.get('energy_kcal_100g'),
                'fat': current_data.get('fat_100g'),
                'carbs': current_data.get('carbs_100g'),
                'protein': current_data.get('protein_100g'),
                'salt': current_data.get('salt_100g'),
                'fiber': current_data.get('fiber_100g'),
                'sugars': current_data.get('sugar_100g')
            })
            updates.update(per_serving)
        
        # Add nutrition facts (per 100g)
        for nutrient, value in nutrition_facts.items():
            if value is not None and not current_data.get(f'{nutrient}_100g'):
                updates[f'{nutrient}_100g'] = value
                print(f"   ✅ Found {nutrient}: {value}")
        
        # Apply updates
        if updates:
            cursor = self.conn.cursor()
            
            # Build UPDATE query
            set_clauses = []
            values = []
            for column, value in updates.items():
                set_clauses.append(f"{column} = ?")
                values.append(value)
            
            query = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = ?"
            values.append(product_id)
            
            cursor.execute(query, values)
            self.conn.commit()
            
            print(f"   ✅ Updated {len(updates)} fields")
            self.updated_count += 1
            return True
        else:
            print(f"   ❌ No new data to update")
            self.error_count += 1
            return False
    
    def update_products_batch(self, batch_size: int = 10, max_products: int = 50) -> Tuple[int, int]:
        """Update complete data for multiple products"""
        
        cursor = self.conn.cursor()
        
        # Get products that need updating
        cursor.execute(f"""
            SELECT id, name, brand, ingredients, serving_size, 
                   energy_kcal_100g, fat_100g, carbs_100g, protein_100g, salt_100g, fiber_100g, sugar_100g
            FROM products 
            WHERE brand IN ('Tesco', 'ASDA', 'Sainsbury''s', 'Walkers', 'Marks & Spencer')
              AND (ingredients IS NULL OR LENGTH(ingredients) < 20 OR serving_size IS NULL OR serving_size = '')
            ORDER BY RANDOM()
            LIMIT {max_products}
        """)
        
        products = cursor.fetchall()
        
        print(f"🤖 AI COMPLETE UPDATER - Processing {len(products)} products")
        print("=" * 60)
        
        for i, row in enumerate(products):
            product_id = row[0]
            name = row[1]
            brand = row[2]
            
            current_data = {
                'ingredients': row[3],
                'serving_size': row[4],
                'energy_kcal_100g': row[5],
                'fat_100g': row[6],
                'carbs_100g': row[7],
                'protein_100g': row[8],
                'salt_100g': row[9],
                'fiber_100g': row[10],
                'sugar_100g': row[11]
            }
            
            print(f"\n[{i+1}/{len(products)}] {brand} - {name}")
            
            success = self.update_product_complete(product_id, name, brand or "", current_data)
            
            # Rate limiting
            time.sleep(1)
            
            # Batch checkpoint
            if (i + 1) % batch_size == 0:
                print(f"\n📊 Checkpoint: {self.updated_count} updated, {self.error_count} failed")
                time.sleep(15)
        
        return self.updated_count, self.error_count
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🤖 AI-POWERED COMPLETE FOOD DATA UPDATER")
    print("=" * 50)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    updater = AICompleteUpdater(db_path)
    
    try:
        # Update 5 products as a test
        updated, errors = updater.update_products_batch(batch_size=5, max_products=5)
        
        print(f"\n🎯 FINAL RESULTS:")
        print(f"   Products updated: {updated}")
        print(f"   Products failed: {errors}")
        print(f"   Success rate: {(updated / (updated + errors) * 100):.1f}%" if (updated + errors) > 0 else "0%")
        
    finally:
        updater.close()

if __name__ == "__main__":
    main()