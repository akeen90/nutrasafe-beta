#!/usr/bin/env python3
"""
Smart UK Food Database Serving Size Fixer
Fixes missing serving sizes for 17,476+ products using intelligent pattern matching
"""

import sqlite3
import re
from typing import Dict, Optional, Tuple

class ServingSizeFixer:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.fixed_count = 0
        self.total_processed = 0
        
    def get_serving_size_rules(self) -> Dict[str, str]:
        """Comprehensive UK product serving size rules based on food patterns"""
        return {
            # Beverages - specific volumes
            'coca cola|coke|pepsi|sprite|fanta': '330ml',
            'ribena|cordial|squash': '250ml',
            'energy drink|red bull|monster': '250ml',
            'orange juice|apple juice|cranberry juice': '200ml',
            'smoothie': '250ml',
            'tassimo|coffee pod|latte|cappuccino': '200ml',
            'wine': '125ml',
            'beer|lager|ale': '330ml',
            'spirits|vodka|gin|whisky|rum': '25ml',
            
            # Chocolate & Confectionery
            'mars bar|snickers|bounty|twix|kitkat|kit kat': '45g',
            'dairy milk|galaxy|quality street': '45g',
            'toblerone': '50g',
            'haribo|gummy|jelly sweets': '30g',
            'chocolate chip cookies|digestives': '2 biscuits (25g)',
            'after eight|mint chocolates': '5 pieces (25g)',
            
            # Crisps & Snacks
            'walkers|pringles|cheese and onion|ready salted': '25g',
            'doritos|tortilla chips': '30g',
            'nuts|almonds|cashews|peanuts': '30g',
            'pretzels': '25g',
            'popcorn': '20g',
            
            # Breakfast Items
            'cornflakes|rice krispies|special k|fruit & fibre': '30g',
            'porridge oats|oats': '40g',
            'muesli|granola': '45g',
            'toast|bread slice': '1 slice (36g)',
            'croissant': '1 croissant (65g)',
            'bagel': '1 bagel (85g)',
            
            # Dairy
            'milk': '200ml',
            'yogurt|yoghurt': '125g',
            'cheese': '30g',
            'butter': '10g',
            
            # Ready Meals & Meat
            'chicken kiev|chicken kyiv': '1 piece (125g)',
            'pizza': '1/2 pizza (150g)',
            'lasagne|lasagna': '1 portion (400g)',
            'curry': '1 portion (350g)',
            'fish fingers': '3 fingers (84g)',
            'sausages': '2 sausages (80g)',
            'bacon': '2 rashers (60g)',
            'chicken breast': '1 breast (150g)',
            
            # Condiments & Spreads
            'peanut butter|jam|honey|nutella': '15g',
            'ketchup|brown sauce|mayo': '15g',
            'mango chutney|pickle': '15g',
            'gravy|bisto': '1 serving (125ml)',
            'stock cube|bouillon': '1 cube (10g)',
            
            # Baking & Ingredients
            'flour': '100g',
            'sugar': '1 tsp (4g)',
            'vanilla extract': '1 tsp (5ml)',
            'baking powder': '1 tsp (4g)',
            'cooking chocolate': '25g',
            
            # Noodles & Pasta
            'noodles|instant noodles': '1 pack (85g)',
            'pasta|spaghetti|penne': '75g',
            'rice': '75g',
            
            # Protein Supplements
            'protein powder|whey|impact protein': '30g',
            'protein bar': '1 bar (60g)',
            
            # Frozen Foods
            'ice cream': '60ml',
            'frozen peas|sweetcorn': '80g',
            'fish cake': '1 cake (85g)',
            
            # Fruit & Vegetables
            'banana': '1 medium (118g)',
            'apple': '1 medium (180g)',
            'orange': '1 medium (154g)',
            'potato': '1 medium (150g)',
            'tomato': '1 medium (123g)',
        }
    
    def extract_weight_from_name(self, food_name: str) -> Optional[str]:
        """Extract serving size from product name (e.g., '85g', '500ml')"""
        # Look for patterns like "85g", "500ml", "1.5l", "2kg"
        weight_patterns = [
            r'(\d+(?:\.\d+)?)\s*g(?:\s|$)',  # grams
            r'(\d+(?:\.\d+)?)\s*kg(?:\s|$)', # kilograms
            r'(\d+(?:\.\d+)?)\s*ml(?:\s|$)', # milliliters
            r'(\d+(?:\.\d+)?)\s*l(?:\s|$)',  # liters
            r'(\d+(?:\.\d+)?)\s*oz(?:\s|$)', # ounces
        ]
        
        for pattern in weight_patterns:
            match = re.search(pattern, food_name.lower())
            if match:
                value = match.group(1)
                if 'kg' in pattern:
                    return f"{int(float(value) * 1000)}g"
                elif 'l' in pattern and 'ml' not in pattern:
                    return f"{int(float(value) * 1000)}ml"
                elif 'oz' in pattern:
                    return f"{int(float(value) * 28.35)}g"  # Convert oz to grams
                else:
                    unit = pattern.split('\\')[1].replace('s*', '').replace('(?:', '').replace('\\s|$)', '')
                    return f"{value}{unit}"
        
        return None
    
    def get_category_default(self, category: str) -> Optional[str]:
        """Get default serving size based on category"""
        if not category:
            return None
            
        category_lower = category.lower()
        
        category_defaults = {
            'beverages': '250ml',
            'chocolate': '45g',
            'biscuits': '2 biscuits (25g)',
            'crisps': '25g',
            'cereal': '30g',
            'yogurt': '125g',
            'cheese': '30g',
            'bread': '1 slice (36g)',
            'meat': '100g',
            'pasta': '75g',
            'rice': '75g',
            'sauce': '15g',
            'soup': '250ml',
            'ice cream': '60ml',
        }
        
        for key, serving in category_defaults.items():
            if key in category_lower:
                return serving
                
        return None
    
    def infer_serving_size(self, food_name: str, category: str) -> Optional[str]:
        """Smart serving size inference using multiple strategies"""
        
        # Strategy 1: Extract from product name
        extracted = self.extract_weight_from_name(food_name)
        if extracted:
            return extracted
            
        # Strategy 2: Pattern matching rules
        rules = self.get_serving_size_rules()
        food_lower = food_name.lower()
        
        for pattern, serving in rules.items():
            # Use word boundary matching for better accuracy
            pattern_words = pattern.split('|')
            for word in pattern_words:
                if re.search(r'\b' + re.escape(word) + r'\b', food_lower):
                    return serving
                    
        # Strategy 3: Category-based defaults
        category_default = self.get_category_default(category)
        if category_default:
            return category_default
            
        # Strategy 4: Fallback based on food type hints
        if any(word in food_lower for word in ['drink', 'juice', 'soda', 'cola']):
            return '330ml'
        elif any(word in food_lower for word in ['bar', 'chocolate']):
            return '45g'
        elif any(word in food_lower for word in ['crisp', 'chip']):
            return '25g'
        elif any(word in food_lower for word in ['cereal', 'flakes']):
            return '30g'
            
        return None
    
    def fix_serving_sizes(self, batch_size: int = 1000) -> Tuple[int, int]:
        """Process and fix serving sizes in batches"""
        
        cursor = self.conn.cursor()
        
        # Get all products with missing serving sizes
        cursor.execute("""
            SELECT id, food_name, category 
            FROM uk_foods 
            WHERE serving_size IS NULL OR serving_size = ''
        """)
        
        products = cursor.fetchall()
        total_to_fix = len(products)
        print(f"🔧 Found {total_to_fix} products with missing serving sizes")
        
        updates = []
        
        for i, (product_id, food_name, category) in enumerate(products):
            self.total_processed += 1
            
            # Infer serving size
            serving_size = self.infer_serving_size(food_name, category or '')
            
            if serving_size:
                updates.append((serving_size, product_id))
                self.fixed_count += 1
                
                if len(updates) >= batch_size:
                    self._apply_batch_updates(updates)
                    updates = []
                    print(f"✅ Processed {i+1}/{total_to_fix} products, fixed {self.fixed_count} so far")
        
        # Apply remaining updates
        if updates:
            self._apply_batch_updates(updates)
            
        print(f"🎉 COMPLETE: Fixed {self.fixed_count} out of {self.total_processed} products")
        return self.fixed_count, self.total_processed
    
    def _apply_batch_updates(self, updates):
        """Apply batch of serving size updates"""
        cursor = self.conn.cursor()
        cursor.executemany("""
            UPDATE uk_foods 
            SET serving_size = ? 
            WHERE id = ?
        """, updates)
        self.conn.commit()
    
    def verify_fixes(self) -> Dict[str, int]:
        """Verify the fixes by checking remaining issues"""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            SELECT COUNT(*) FROM uk_foods 
            WHERE serving_size IS NULL OR serving_size = ''
        """)
        remaining_empty = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM uk_foods")
        total_products = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM uk_foods 
            WHERE serving_size IS NOT NULL AND serving_size != ''
        """)
        products_with_serving = cursor.fetchone()[0]
        
        return {
            'total_products': total_products,
            'products_with_serving': products_with_serving,
            'remaining_empty': remaining_empty,
            'completion_percentage': round((products_with_serving / total_products) * 100, 1)
        }
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🚀 STARTING UK FOOD DATABASE SERVING SIZE FIXER")
    print("=" * 60)
    
    db_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/uk_foods_local.db"
    fixer = ServingSizeFixer(db_path)
    
    try:
        # Initial stats
        initial_stats = fixer.verify_fixes()
        print(f"📊 INITIAL STATS:")
        print(f"   Total products: {initial_stats['total_products']}")
        print(f"   With serving sizes: {initial_stats['products_with_serving']}")
        print(f"   Missing serving sizes: {initial_stats['remaining_empty']}")
        print(f"   Completion: {initial_stats['completion_percentage']}%")
        print()
        
        # Fix serving sizes
        fixed, processed = fixer.fix_serving_sizes()
        
        # Final stats
        final_stats = fixer.verify_fixes()
        print()
        print(f"📈 FINAL RESULTS:")
        print(f"   Products processed: {processed}")
        print(f"   Serving sizes fixed: {fixed}")
        print(f"   Remaining unfixed: {final_stats['remaining_empty']}")
        print(f"   New completion rate: {final_stats['completion_percentage']}%")
        print(f"   Improvement: +{final_stats['completion_percentage'] - initial_stats['completion_percentage']}%")
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()