#!/usr/bin/env python3
"""
Smart Database Fixer - Fix serving sizes and missing data using intelligent analysis
Works with existing data without external dependencies
"""

import sqlite3
import re
from typing import Dict, Optional, Tuple

class SmartDatabaseFixer:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.fixed_count = 0
        
        # Add serving_size column if it doesn't exist
        self._add_missing_columns()
        
    def _add_missing_columns(self):
        """Add serving_size column if it doesn't exist"""
        cursor = self.conn.cursor()
        try:
            cursor.execute("ALTER TABLE products ADD COLUMN serving_size TEXT")
            self.conn.commit()
            print("✅ Added serving_size column")
        except sqlite3.OperationalError:
            pass
    
    def extract_serving_from_name(self, name: str) -> Optional[str]:
        """Extract serving size from product name"""
        if not name:
            return None
            
        name_lower = name.lower()
        
        # Look for weight/volume patterns
        patterns = [
            (r'(\d+(?:\.\d+)?)\s*ml\b', 'ml'),
            (r'(\d+(?:\.\d+)?)\s*l\b', 'l'),
            (r'(\d+(?:\.\d+)?)\s*g\b', 'g'),
            (r'(\d+(?:\.\d+)?)\s*kg\b', 'kg'),
            (r'(\d+(?:\.\d+)?)\s*oz\b', 'oz'),
        ]
        
        for pattern, unit in patterns:
            match = re.search(pattern, name_lower)
            if match:
                value = match.group(1)
                
                # Convert to standard units
                if unit == 'l':
                    return f"{int(float(value) * 1000)}ml"
                elif unit == 'kg':
                    return f"{int(float(value) * 1000)}g"
                elif unit == 'oz':
                    return f"{int(float(value) * 28.35)}g"
                else:
                    return f"{value}{unit}"
        
        return None
    
    def infer_serving_from_category(self, name: str, brand: str, category: str) -> str:
        """Infer serving size based on product type"""
        
        product_text = f"{name} {brand} {category}".lower()
        
        # Comprehensive UK serving size rules
        serving_rules = [
            # Beverages
            (['cola', 'pepsi', 'sprite', 'fanta', 'energy drink', 'soft drink'], '330ml'),
            (['wine'], '125ml'),
            (['beer', 'lager', 'ale'], '330ml'),
            (['spirits', 'vodka', 'gin', 'whisky', 'rum'], '25ml'),
            (['juice', 'smoothie'], '200ml'),
            (['coffee', 'latte', 'cappuccino'], '200ml'),
            (['cordial', 'squash'], '250ml'),
            
            # Confectionery & Snacks
            (['chocolate bar', 'mars', 'snickers', 'bounty', 'twix', 'kit kat', 'dairy milk'], '45g'),
            (['crisps', 'walkers', 'pringles'], '25g'),
            (['nuts', 'almonds', 'peanuts', 'cashews'], '30g'),
            (['sweets', 'gummy', 'haribo'], '30g'),
            
            # Breakfast & Cereals
            (['cereal', 'cornflakes', 'rice krispies', 'special k'], '30g'),
            (['porridge', 'oats'], '40g'),
            (['muesli', 'granola'], '45g'),
            (['toast', 'bread'], '1 slice (36g)'),
            (['bagel'], '1 bagel (85g)'),
            (['croissant'], '1 croissant (65g)'),
            
            # Dairy
            (['milk'], '200ml'),
            (['yogurt', 'yoghurt'], '125g'),
            (['cheese'], '30g'),
            (['butter'], '10g'),
            
            # Ready Meals
            (['pizza'], '1/2 pizza (150g)'),
            (['pasta'], '75g'),
            (['rice'], '75g'),
            (['curry'], '1 portion (350g)'),
            (['soup'], '250ml'),
            (['baked beans'], '415g'),
            
            # Meat & Fish
            (['chicken breast'], '1 breast (150g)'),
            (['salmon', 'fish'], '100g'),
            (['sausages'], '2 sausages (80g)'),
            (['bacon'], '2 rashers (60g)'),
            
            # Condiments & Spreads
            (['jam', 'honey', 'nutella', 'peanut butter'], '15g'),
            (['ketchup', 'sauce', 'mayo'], '15g'),
            (['stock cube'], '1 cube (10g)'),
        ]
        
        # Find matching rule
        for keywords, serving in serving_rules:
            if any(keyword in product_text for keyword in keywords):
                return serving
        
        # Default fallback
        return '100g'
    
    def fix_serving_sizes(self) -> Tuple[int, int]:
        """Fix all missing serving sizes"""
        cursor = self.conn.cursor()
        
        # Get products without serving sizes
        cursor.execute("""
            SELECT id, name, brand, categories 
            FROM products 
            WHERE serving_size IS NULL OR serving_size = ''
        """)
        
        products = cursor.fetchall()
        total_products = len(products)
        
        print(f"🔧 Found {total_products} products without serving sizes")
        
        updates = []
        
        for i, (product_id, name, brand, category) in enumerate(products):
            # Try to extract from name first
            serving_size = self.extract_serving_from_name(name or '')
            
            # If not found, infer from category/type
            if not serving_size:
                serving_size = self.infer_serving_from_category(
                    name or '', brand or '', category or ''
                )
            
            if serving_size:
                updates.append((serving_size, product_id))
                self.fixed_count += 1
                
                # Show progress for large datasets
                if i % 1000 == 0 and i > 0:
                    print(f"   📊 Progress: {i}/{total_products} processed")
        
        # Apply all updates
        if updates:
            cursor.executemany("""
                UPDATE products 
                SET serving_size = ? 
                WHERE id = ?
            """, updates)
            self.conn.commit()
            
        print(f"✅ Fixed serving sizes for {self.fixed_count} products")
        return self.fixed_count, total_products
    
    def calculate_per_serving_nutrition(self) -> int:
        """Calculate per-serving nutrition from per-100g data"""
        cursor = self.conn.cursor()
        
        # Add per-serving columns if they don't exist
        serving_columns = [
            'calories_per_serving', 'fat_per_serving', 'carbs_per_serving',
            'protein_per_serving', 'salt_per_serving', 'fiber_per_serving', 'sugar_per_serving'
        ]
        
        for column in serving_columns:
            try:
                cursor.execute(f"ALTER TABLE products ADD COLUMN {column} REAL")
            except sqlite3.OperationalError:
                pass
        
        self.conn.commit()
        
        # Get products with both nutrition and serving size data
        cursor.execute("""
            SELECT id, serving_size, 
                   energy_kcal_100g, fat_100g, carbs_100g, protein_100g, 
                   salt_100g, fiber_100g, sugar_100g
            FROM products 
            WHERE serving_size IS NOT NULL 
              AND serving_size != ''
              AND energy_kcal_100g IS NOT NULL
        """)
        
        products = cursor.fetchall()
        calculated_count = 0
        
        for row in products:
            product_id = row[0]
            serving_size = row[1]
            nutrition_100g = row[2:9]
            
            # Parse serving size to get multiplier
            multiplier = self._parse_serving_multiplier(serving_size)
            
            if multiplier:
                # Calculate per-serving values
                per_serving = []
                for value in nutrition_100g:
                    if value is not None:
                        per_serving.append(round(value * multiplier, 2))
                    else:
                        per_serving.append(None)
                
                # Update database
                cursor.execute("""
                    UPDATE products SET
                        calories_per_serving = ?,
                        fat_per_serving = ?,
                        carbs_per_serving = ?,
                        protein_per_serving = ?,
                        salt_per_serving = ?,
                        fiber_per_serving = ?,
                        sugar_per_serving = ?
                    WHERE id = ?
                """, per_serving + [product_id])
                
                calculated_count += 1
        
        self.conn.commit()
        print(f"✅ Calculated per-serving nutrition for {calculated_count} products")
        return calculated_count
    
    def _parse_serving_multiplier(self, serving_size: str) -> Optional[float]:
        """Parse serving size to get multiplier for 100g"""
        if not serving_size:
            return None
            
        # Extract numeric value and unit
        match = re.search(r'(\d+(?:\.\d+)?)\s*(g|ml)', serving_size.lower())
        if match:
            value = float(match.group(1))
            unit = match.group(2)
            
            # For weight, simple division by 100
            if unit == 'g':
                return value / 100
            # For liquids, assume 1ml = 1g (approximation)
            elif unit == 'ml':
                return value / 100
        
        # Default to 1.0 for unknown formats
        return 1.0
    
    def get_statistics(self) -> Dict:
        """Get database statistics"""
        cursor = self.conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM products")
        total = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM products 
            WHERE serving_size IS NOT NULL AND serving_size != ''
        """)
        with_serving = cursor.fetchone()[0]
        
        cursor.execute("""
            SELECT COUNT(*) FROM products 
            WHERE energy_kcal_100g IS NOT NULL
        """)
        with_nutrition = cursor.fetchone()[0]
        
        return {
            'total_products': total,
            'with_serving_size': with_serving,
            'with_nutrition': with_nutrition,
            'serving_percentage': round((with_serving / total) * 100, 1),
            'nutrition_percentage': round((with_nutrition / total) * 100, 1)
        }
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🛠️  SMART DATABASE FIXER")
    print("=" * 50)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    fixer = SmartDatabaseFixer(db_path)
    
    try:
        # Initial stats
        initial_stats = fixer.get_statistics()
        print(f"📊 INITIAL STATS:")
        print(f"   Total products: {initial_stats['total_products']}")
        print(f"   With serving sizes: {initial_stats['with_serving_size']} ({initial_stats['serving_percentage']}%)")
        print(f"   With nutrition: {initial_stats['with_nutrition']} ({initial_stats['nutrition_percentage']}%)")
        print()
        
        # Fix serving sizes
        fixed, total = fixer.fix_serving_sizes()
        print()
        
        # Calculate per-serving nutrition
        calculated = fixer.calculate_per_serving_nutrition()
        print()
        
        # Final stats
        final_stats = fixer.get_statistics()
        print(f"📈 FINAL RESULTS:")
        print(f"   Serving sizes fixed: {fixed}")
        print(f"   Per-serving nutrition calculated: {calculated}")
        print(f"   Final serving size coverage: {final_stats['serving_percentage']}%")
        print(f"   Improvement: +{final_stats['serving_percentage'] - initial_stats['serving_percentage']:.1f}%")
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()