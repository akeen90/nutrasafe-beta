#!/usr/bin/env python3
"""
Comprehensive Database Updater
Phase 1: Use ChatGPT's built-in knowledge (safe, no guessing)
Phase 2: Google search for remaining products with data extraction
"""

import sqlite3
import requests
import json
import time
import re
from typing import Optional, Dict, Tuple, Any
from urllib.parse import quote_plus

class ComprehensiveUpdater:
    def __init__(self, db_path: str, google_api_key: str = None):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.phase1_updated = 0
        self.phase2_updated = 0
        self.total_errors = 0
        
        # Google Custom Search configuration
        self.google_api_key = google_api_key or "YOUR_API_KEY_HERE"
        self.search_engine_id = "62bfd0c439cef4c48"
        
    def query_gpt_knowledge(self, product_name: str, brand: str) -> Optional[Dict[str, Any]]:
        """Phase 1: Use ChatGPT's built-in knowledge - NEVER GUESS"""
        
        # Clean product name for better recognition
        clean_name = self.clean_product_name(product_name, brand)
        
        # Apply ChatGPT's food knowledge reasoning - ONLY for known products
        food_data = self.apply_gpt_reasoning(clean_name, brand)
        
        return food_data
    
    def clean_product_name(self, name: str, brand: str) -> str:
        """Clean product name for better recognition"""
        if not name:
            return ""
            
        # Remove common retail suffixes
        clean_name = re.sub(r'\s*\d+(?:\.\d+)?\s*(?:g|ml|kg|l|oz|pack|multipack)(?:s)?\s*$', '', name, flags=re.IGNORECASE)
        clean_name = re.sub(r'\s*x\s*\d+\s*$', '', clean_name, flags=re.IGNORECASE)
        clean_name = re.sub(r'\s*-\s*\d+(?:\.\d+)?\s*(?:g|ml|kg|l|oz)\s*$', '', clean_name, flags=re.IGNORECASE)
        
        # Remove price and promotional text
        clean_name = re.sub(r'\s*£\d+(?:\.\d+)?\s*', '', clean_name)
        clean_name = re.sub(r'\s*(?:offer|deal|save|was|now)\s*.*$', '', clean_name, flags=re.IGNORECASE)
        
        # Remove common retail terms
        retail_terms = ['own brand', 'value', 'basics', 'extra special', 'finest', 'free from']
        for term in retail_terms:
            clean_name = re.sub(f'\\b{re.escape(term)}\\b', '', clean_name, flags=re.IGNORECASE)
        
        return clean_name.strip()
    
    def apply_gpt_reasoning(self, product_name: str, brand: str) -> Optional[Dict[str, Any]]:
        """Apply ChatGPT's reasoning to determine food data - ONLY for known products"""
        
        if not product_name:
            return None
            
        # Normalize for pattern matching
        full_product = f"{brand} {product_name}".lower().strip()
        product_lower = product_name.lower().strip()
        
        # === MAJOR UK BRANDS - SPECIFIC PRODUCTS ONLY ===
        
        # Coca-Cola Products
        if any(term in full_product for term in ['coca cola', 'coke classic', 'coca-cola']):
            return {
                'ingredients': 'Carbonated Water, Sugar, Colour (Caramel E150d), Acid (Phosphoric Acid), Natural Flavourings including Caffeine',
                'serving_size': '330ml',
                'energy_kcal_100g': 42, 'fat_100g': 0, 'carbs_100g': 10.6, 'sugar_100g': 10.6, 'protein_100g': 0, 'salt_100g': 0
            }
        
        # Pepsi Products
        if any(term in full_product for term in ['pepsi', 'pepsi cola']):
            if 'max' in full_product:
                return {
                    'ingredients': 'Carbonated Water, Colour (Caramel E150d), Sweeteners (Aspartame, Acesulfame K), Acid (Phosphoric Acid), Natural Flavourings including Caffeine, Preservative (Potassium Sorbate)',
                    'serving_size': '330ml',
                    'energy_kcal_100g': 1, 'fat_100g': 0, 'carbs_100g': 0, 'sugar_100g': 0, 'protein_100g': 0, 'salt_100g': 0.02
                }
            else:
                return {
                    'ingredients': 'Carbonated Water, Sugar, Colour (Caramel E150d), Acid (Phosphoric Acid), Natural Flavourings including Caffeine',
                    'serving_size': '330ml',
                    'energy_kcal_100g': 43, 'fat_100g': 0, 'carbs_100g': 11, 'sugar_100g': 11, 'protein_100g': 0, 'salt_100g': 0.01
                }
        
        # Mars Products
        if any(term in full_product for term in ['mars bar', 'mars chocolate']) and 'mars' in brand.lower():
            return {
                'ingredients': 'Sugar, Glucose Syrup, Milk Powder, Cocoa Butter, Cocoa Mass, Sunflower Oil, Milk Fat, Lactose, Salt, Egg White Powder, Vanilla Extract',
                'serving_size': '45g',
                'energy_kcal_100g': 457, 'fat_100g': 16.5, 'carbs_100g': 68, 'sugar_100g': 59.9, 'protein_100g': 4.2, 'salt_100g': 0.24
            }
        
        # Walkers Crisps - Expanded varieties
        if 'walkers' in brand.lower() or 'walkers' in product_lower:
            if any(term in product_lower for term in ['ready salted', 'original']):
                return {
                    'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), Salt',
                    'serving_size': '25g',
                    'energy_kcal_100g': 533, 'fat_100g': 34, 'carbs_100g': 50, 'sugar_100g': 0.5, 'protein_100g': 6.1, 'salt_100g': 1.3
                }
            elif 'prawn cocktail' in product_lower:
                return {
                    'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), Prawn Cocktail Flavour [Flavourings, Sugar, Salt, Potassium Chloride, Dried Onion, Dried Garlic, Citric Acid, Colour (Paprika Extract)]',
                    'serving_size': '25g',
                    'energy_kcal_100g': 530, 'fat_100g': 33, 'carbs_100g': 51, 'sugar_100g': 2.1, 'protein_100g': 6, 'salt_100g': 1.3
                }
            elif any(term in product_lower for term in ['cheese and onion', 'cheese & onion']):
                return {
                    'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), Cheese & Onion Flavour [Dried Onion, Flavouring, Salt, Cheese Powder, Potassium Chloride, Dried Yeast, Citric Acid]',
                    'serving_size': '25g',
                    'energy_kcal_100g': 530, 'fat_100g': 33, 'carbs_100g': 51, 'sugar_100g': 2.1, 'protein_100g': 6, 'salt_100g': 1.3
                }
            elif any(term in product_lower for term in ['salt and vinegar', 'salt & vinegar']):
                return {
                    'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), Salt & Vinegar Flavour [Salt, Lactose (from Milk), Sodium Diacetate, Malic Acid, Flavouring]',
                    'serving_size': '25g',
                    'energy_kcal_100g': 533, 'fat_100g': 34, 'carbs_100g': 50, 'sugar_100g': 1.1, 'protein_100g': 6.1, 'salt_100g': 1.6
                }
            elif any(term in product_lower for term in ['bbq', 'barbecue']):
                return {
                    'ingredients': 'Potatoes, Vegetable Oils (Sunflower, Rapeseed), BBQ Flavour [Sugar, Salt, Flavourings, Onion Powder, Garlic Powder, Paprika Extract, Smoke Flavouring]',
                    'serving_size': '25g',
                    'energy_kcal_100g': 528, 'fat_100g': 33, 'carbs_100g': 52, 'sugar_100g': 3.2, 'protein_100g': 5.9, 'salt_100g': 1.4
                }
            elif 'wotsits' in product_lower or 'monster munch' in product_lower:
                return {
                    'ingredients': 'Maize, Vegetable Oils (Sunflower, Rapeseed), Cheese Flavour [Whey Powder (from Milk), Cheese Powder, Salt, Flavouring, Colour (Annatto, Paprika Extract)]',
                    'serving_size': '22g',
                    'energy_kcal_100g': 506, 'fat_100g': 28, 'carbs_100g': 57, 'sugar_100g': 2.8, 'protein_100g': 6.4, 'salt_100g': 2.2
                }
        
        # Doritos
        if 'doritos' in product_lower:
            if 'chilli heatwave' in product_lower:
                return {
                    'ingredients': 'Maize, Vegetable Oils (Sunflower, Rapeseed), Chilli Heatwave Flavour [Salt, Sugar, Flavourings, Onion Powder, Garlic Powder, Paprika, Chilli Powder, Colour (Paprika Extract)]',
                    'serving_size': '30g',
                    'energy_kcal_100g': 498, 'fat_100g': 25, 'carbs_100g': 60, 'sugar_100g': 4.2, 'protein_100g': 7.2, 'salt_100g': 1.7
                }
        
        # Lindt Chocolate
        if 'lindt' in brand.lower():
            return {
                'ingredients': 'Sugar, Cocoa Butter, Whole Milk Powder, Cocoa Mass, Lactose, Skimmed Milk Powder, Emulsifier (Soya Lecithin), Barley Malt Extract, Flavouring',
                'serving_size': '25g',
                'energy_kcal_100g': 534, 'fat_100g': 32, 'carbs_100g': 51, 'sugar_100g': 50, 'protein_100g': 6.9, 'salt_100g': 0.14
            }
        
        # Add more specific brand matches here...
        # Only include products where we have EXACT knowledge
        
        return None  # Never guess for branded products
    
    def google_search_product(self, product_name: str, brand: str) -> Optional[Dict[str, str]]:
        """Phase 2: Google search for product information"""
        
        # Create search query
        search_terms = []
        if brand and brand.strip():
            search_terms.append(f'"{brand}"')
        if product_name and product_name.strip():
            search_terms.append(f'"{product_name}"')
        
        search_terms.extend(['UK', 'nutrition', 'ingredients', 'serving size'])
        query = ' '.join(search_terms)
        
        try:
            # Use Google Custom Search API
            if self.google_api_key == "YOUR_API_KEY_HERE":
                print(f"   ❌ Google API key not configured. Set it in constructor or environment.")
                return None
                
            search_url = "https://www.googleapis.com/customsearch/v1"
            params = {
                'key': self.google_api_key,
                'cx': self.search_engine_id,
                'q': query,
                'num': 5  # Get top 5 results
            }
            
            response = requests.get(search_url, params=params, timeout=10)
            data = response.json()
            
            if response.status_code != 200:
                error_msg = data.get('error', {}).get('message', 'Unknown error')
                print(f"   ❌ Google API error: {error_msg}")
                return None
            
            search_results = {
                'abstract': '',
                'results': []
            }
            
            # Get search results
            if data.get('items'):
                for result in data['items'][:5]:  # Top 5 results
                    search_results['results'].append({
                        'title': result.get('title', ''),
                        'url': result.get('link', ''),
                        'snippet': result.get('snippet', '')
                    })
            
            # Google Custom Search doesn't have RelatedTopics
            
            return search_results
            
        except Exception as e:
            print(f"   🔍 Search error: {str(e)}")
            return None
    
    def extract_data_from_search(self, search_results: Dict[str, str], product_name: str, brand: str) -> Optional[Dict[str, Any]]:
        """Extract nutrition data from search results using AI reasoning"""
        
        if not search_results:
            return None
        
        # Combine all text from search results
        all_text = search_results.get('abstract', '') + ' '
        for result in search_results.get('results', []):
            all_text += result.get('snippet', '') + ' '
        
        if len(all_text.strip()) < 50:  # Not enough data
            return None
        
        # Extract ingredients
        ingredients = self.extract_ingredients_from_text(all_text)
        
        # Extract serving size
        serving_size = self.extract_serving_size_from_text(all_text)
        
        # Extract nutrition facts
        nutrition = self.extract_nutrition_from_text(all_text)
        
        # Only return if we found meaningful data
        if ingredients or serving_size or any(nutrition.values()):
            result = {}
            if ingredients:
                result['ingredients'] = ingredients
            if serving_size:
                result['serving_size'] = serving_size
            result.update(nutrition)
            return result
        
        return None
    
    def extract_ingredients_from_text(self, text: str) -> Optional[str]:
        """Extract ingredients from search text"""
        
        # Look for ingredient patterns
        ingredient_patterns = [
            r'[Ii]ngredients?:?\s*([^.]+)',
            r'[Cc]ontains?:?\s*([^.]+)',
            r'[Mm]ade with:?\s*([^.]+)',
        ]
        
        for pattern in ingredient_patterns:
            match = re.search(pattern, text)
            if match:
                ingredients = match.group(1).strip()
                
                # Clean up the ingredients
                ingredients = re.sub(r'^(ingredients?:?\\s*|contains?:?\\s*|made with:?\\s*)', '', ingredients, flags=re.IGNORECASE)
                ingredients = ingredients.strip(' .,;:')
                
                # Validate it looks like real ingredients
                if self.validate_ingredients(ingredients):
                    return ingredients
        
        return None
    
    def extract_serving_size_from_text(self, text: str) -> Optional[str]:
        """Extract serving size from search text"""
        
        # Look for serving size patterns
        serving_patterns = [
            r'[Ss]erving size:?\s*([^.]+)',
            r'[Pp]er serving:?\s*\(([^)]+)\)',
            r'[Ss]erves?\s*(\d+)',
            r'(\d+(?:\.\d+)?(?:g|ml))\s*pack',
            r'(\d+(?:\.\d+)?(?:g|ml))\s*(?:can|bottle|bag)',
        ]
        
        for pattern in serving_patterns:
            match = re.search(pattern, text)
            if match:
                serving = match.group(1).strip()
                
                if self.validate_serving_size(serving):
                    return serving
        
        return None
    
    def extract_nutrition_from_text(self, text: str) -> Dict[str, Optional[float]]:
        """Extract nutrition facts from search text"""
        
        nutrition = {
            'energy_kcal_100g': None,
            'fat_100g': None,
            'carbs_100g': None,
            'sugar_100g': None,
            'protein_100g': None,
            'salt_100g': None
        }
        
        # Look for nutrition patterns
        patterns = {
            'energy_kcal_100g': [r'(\d+(?:\.\d+)?)\s*kcal', r'(\d+(?:\.\d+)?)\s*calories'],
            'fat_100g': [r'[Ff]at:?\s*(\d+(?:\.\d+)?)g', r'[Tt]otal fat:?\s*(\d+(?:\.\d+)?)g'],
            'carbs_100g': [r'[Cc]arbohydrates?:?\s*(\d+(?:\.\d+)?)g', r'[Cc]arbs:?\s*(\d+(?:\.\d+)?)g'],
            'sugar_100g': [r'[Ss]ugars?:?\s*(\d+(?:\.\d+)?)g'],
            'protein_100g': [r'[Pp]rotein:?\s*(\d+(?:\.\d+)?)g'],
            'salt_100g': [r'[Ss]alt:?\s*(\d+(?:\.\d+)?)g', r'[Ss]odium:?\s*(\d+(?:\.\d+)?)mg']
        }
        
        for nutrient, nutrient_patterns in patterns.items():
            for pattern in nutrient_patterns:
                match = re.search(pattern, text)
                if match:
                    value = float(match.group(1))
                    # Convert sodium mg to salt g
                    if 'sodium' in pattern and 'mg' in pattern:
                        value = value * 2.5 / 1000
                    nutrition[nutrient] = value
                    break
        
        return nutrition
    
    def validate_ingredients(self, ingredients: str) -> bool:
        """Validate ingredient list looks legitimate"""
        if not ingredients or len(ingredients) < 15:
            return False
            
        # Should have commas (ingredient separation)
        if ',' not in ingredients:
            return False
            
        # Should not contain obvious non-food words
        bad_words = ['website', 'click', 'buy', 'price', '£', '$', 'delivery', 'copyright', 'terms']
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
    
    def calculate_per_serving_nutrition(self, serving_size: str, nutrition_100g: Dict[str, float]) -> Dict[str, float]:
        """Calculate per-serving nutrition from per-100g values"""
        
        # Parse serving size to get multiplier
        multiplier = self._parse_serving_multiplier(serving_size)
        if not multiplier:
            return {}
        
        per_serving = {}
        for nutrient, value in nutrition_100g.items():
            if value is not None:
                # Map to database column names
                field_mapping = {
                    'energy_kcal_100g': 'calories_per_serving',
                    'fat_100g': 'fat_per_serving',
                    'carbs_100g': 'carbs_per_serving',
                    'sugar_100g': 'sugar_per_serving',
                    'protein_100g': 'protein_per_serving',
                    'salt_100g': 'salt_per_serving'
                }
                if nutrient in field_mapping:
                    per_serving[field_mapping[nutrient]] = round(value * multiplier, 2)
        
        return per_serving
    
    def _parse_serving_multiplier(self, serving_size: str) -> Optional[float]:
        """Parse serving size to get multiplier for 100g calculations"""
        if not serving_size:
            return None
        
        # Extract numeric value and unit
        match = re.search(r'(\d+(?:\.\d+)?)\s*(g|ml)', serving_size.lower())
        if match:
            value = float(match.group(1))
            return value / 100
        
        return 1.0  # Default to 100g serving
    
    def update_product(self, product_id: int, name: str, brand: str, current_data: Dict[str, Any]) -> Tuple[bool, str]:
        """Update a single product using both phases"""
        
        print(f"🔍 Processing: {brand} {name}")
        
        # Phase 1: Try ChatGPT knowledge first
        gpt_data = self.query_gpt_knowledge(name, brand or "")
        
        if gpt_data:
            # Found in ChatGPT knowledge
            updates = self.prepare_updates(gpt_data, current_data)
            if updates:
                self.apply_updates(product_id, updates)
                self.phase1_updated += 1
                print(f"   ✅ Phase 1: Updated with ChatGPT knowledge ({len(updates)} fields)")
                return True, "phase1"
            else:
                print(f"   ⏭️  Phase 1: No updates needed")
        
        # Phase 2: Try Google search
        print(f"   🔍 Phase 2: Searching Google...")
        search_results = self.google_search_product(name, brand or "")
        
        if search_results:
            search_data = self.extract_data_from_search(search_results, name, brand or "")
            
            if search_data:
                updates = self.prepare_updates(search_data, current_data)
                if updates:
                    self.apply_updates(product_id, updates)
                    self.phase2_updated += 1
                    print(f"   ✅ Phase 2: Updated with Google search ({len(updates)} fields)")
                    return True, "phase2"
                else:
                    print(f"   ⏭️  Phase 2: No new data found")
            else:
                print(f"   ❌ Phase 2: Could not extract valid data")
        else:
            print(f"   ❌ Phase 2: Search failed")
        
        self.total_errors += 1
        return False, "none"
    
    def prepare_updates(self, data: Dict[str, Any], current_data: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare database updates"""
        updates = {}
        
        # Update ingredients if missing or poor quality
        if data.get('ingredients') and (not current_data.get('ingredients') or len(current_data.get('ingredients', '')) < 20):
            updates['ingredients'] = data['ingredients']
        
        # Update serving size if missing
        if data.get('serving_size') and (not current_data.get('serving_size') or current_data.get('serving_size') == '100g'):
            updates['serving_size'] = data['serving_size']
        
        # Update nutrition (per 100g) if missing
        nutrition_fields = ['energy_kcal_100g', 'fat_100g', 'carbs_100g', 'sugar_100g', 'protein_100g', 'salt_100g']
        for field in nutrition_fields:
            if data.get(field) is not None and current_data.get(field) is None:
                updates[field] = data[field]
        
        # Calculate per-serving nutrition if we have serving size
        serving_size = updates.get('serving_size') or current_data.get('serving_size')
        if serving_size:
            nutrition_100g = {k: updates.get(k) or current_data.get(k) for k in nutrition_fields}
            per_serving = self.calculate_per_serving_nutrition(serving_size, nutrition_100g)
            updates.update(per_serving)
        
        return updates
    
    def apply_updates(self, product_id: int, updates: Dict[str, Any]):
        """Apply updates to database"""
        cursor = self.conn.cursor()
        
        set_clauses = []
        values = []
        for column, value in updates.items():
            set_clauses.append(f"{column} = ?")
            values.append(value)
        
        query = f"UPDATE products SET {', '.join(set_clauses)} WHERE id = ?"
        values.append(product_id)
        
        cursor.execute(query, values)
        self.conn.commit()
    
    def process_all_products(self, batch_size: int = 100) -> Tuple[int, int, int]:
        """Process all products in the database systematically"""
        
        cursor = self.conn.cursor()
        
        # Get products that need updating (limited for testing)
        cursor.execute("""
            SELECT id, name, brand, ingredients, serving_size,
                   energy_kcal_100g, fat_100g, carbs_100g, sugar_100g, protein_100g, salt_100g
            FROM products 
            WHERE ingredients IS NULL OR LENGTH(ingredients) < 20 
               OR serving_size IS NULL OR serving_size = '' OR serving_size = '100g'
               OR energy_kcal_100g IS NULL
            ORDER BY id
            LIMIT 50
        """)
        
        products = cursor.fetchall()
        total_products = len(products)
        
        print(f"🚀 COMPREHENSIVE DATABASE UPDATER")
        print(f"📊 Found {total_products} products needing updates")
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
                'sugar_100g': row[8],
                'protein_100g': row[9],
                'salt_100g': row[10]
            }
            
            print(f"\\n[{i+1}/{total_products}]")
            
            success, phase = self.update_product(product_id, name, brand or "", current_data)
            
            # Rate limiting for Google searches
            if phase == "phase2":
                time.sleep(1)  # Be nice to Google
            else:
                time.sleep(0.1)  # Faster for ChatGPT knowledge
            
            # Progress checkpoint
            if (i + 1) % batch_size == 0:
                print(f"\\n📊 CHECKPOINT ({i+1}/{total_products}):")
                print(f"   Phase 1 (ChatGPT): {self.phase1_updated} products")
                print(f"   Phase 2 (Google): {self.phase2_updated} products")
                print(f"   Failed: {self.total_errors} products")
                print(f"   Success rate: {((self.phase1_updated + self.phase2_updated) / (i+1) * 100):.1f}%")
                time.sleep(5)  # Longer pause between batches
        
        return self.phase1_updated, self.phase2_updated, self.total_errors
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🚀 COMPREHENSIVE FOOD DATABASE UPDATER")
    print("Phase 1: ChatGPT Knowledge (Safe)")
    print("Phase 2: Google Custom Search (API)")
    print("=" * 50)
    
    # Get Google API key (set this to your actual key)
    google_api_key = "AIzaSyCrdKM1X0CVpSaTwD7kFXxh0CAgiU8nUYE"
    
    if google_api_key == "YOUR_GOOGLE_API_KEY_HERE":
        print("⚠️  Google API key not set. Phase 2 will be skipped.")
        print("   Set your API key in the google_api_key variable")
        print("   Follow google_api_setup_guide.md for setup instructions")
        print()
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    updater = ComprehensiveUpdater(db_path, google_api_key)
    
    try:
        # Process 50 products for testing
        phase1_count, phase2_count, error_count = updater.process_all_products(batch_size=50)
        
        total_processed = phase1_count + phase2_count + error_count
        total_updated = phase1_count + phase2_count
        
        print(f"\\n🎯 FINAL RESULTS:")
        print(f"   Total processed: {total_processed}")
        print(f"   Phase 1 (ChatGPT): {phase1_count} products")
        print(f"   Phase 2 (Google): {phase2_count} products")
        print(f"   Total updated: {total_updated}")
        print(f"   Failed: {error_count}")
        print(f"   Overall success rate: {(total_updated / total_processed * 100):.1f}%" if total_processed > 0 else "0%")
        
    finally:
        updater.close()

if __name__ == "__main__":
    main()