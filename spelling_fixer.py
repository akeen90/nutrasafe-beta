#!/usr/bin/env python3
"""
UK Food Database Spelling Fixer
Fixes common spelling mistakes in product names and brands
"""

import sqlite3
import re
from typing import Dict, List, Tuple

class SpellingFixer:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.fixed_count = 0
        
    def get_spelling_corrections(self) -> Dict[str, str]:
        """Comprehensive UK food spelling corrections"""
        return {
            # Common misspellings
            'choclate': 'chocolate',
            'chocalate': 'chocolate',
            'chocolte': 'chocolate',
            'chocholate': 'chocolate',
            
            # Fruits & Vegetables
            'bannana': 'banana',
            'banna': 'banana',
            'bananna': 'banana',
            'straberry': 'strawberry',
            'strawbery': 'strawberry',
            'strowberry': 'strawberry',
            'rasberry': 'raspberry',
            'raspbery': 'raspberry',
            'blackbery': 'blackberry',
            'blueberrys': 'blueberries',
            'strawberrys': 'strawberries',
            'rasberries': 'raspberries',
            'tomatoe': 'tomato',
            'tomatos': 'tomatoes',
            'potatoe': 'potato',
            'potatos': 'potatoes',
            'avacado': 'avocado',
            'avacados': 'avocados',
            'brocoli': 'broccoli',
            'cabage': 'cabbage',
            'caulliflower': 'cauliflower',
            'cauli flower': 'cauliflower',
            'peppar': 'pepper',
            'pepers': 'peppers',
            'onyon': 'onion',
            'onyons': 'onions',
            
            # Dairy & Proteins
            'yoghurt': 'yogurt',  # Or keep yoghurt if UK preference
            'yougart': 'yogurt',
            'youghurt': 'yogurt',
            'cheeze': 'cheese',
            'chease': 'cheese',
            'checken': 'chicken',
            'chiken': 'chicken',
            'chickn': 'chicken',
            'beaf': 'beef',
            'mutton': 'lamb',  # If preferred
            'prok': 'pork',
            'samon': 'salmon',
            'salomon': 'salmon',
            'mackrel': 'mackerel',
            'makrel': 'mackerel',
            'tunafish': 'tuna',
            'tuna fish': 'tuna',
            
            # Grains & Breads
            'bred': 'bread',
            'biscuit': 'biscuit',  # Keep correct
            'biscut': 'biscuit',
            'biskuit': 'biscuit',
            'cracker': 'cracker',
            'crakers': 'crackers',
            'crackers': 'crackers',
            'cerial': 'cereal',
            'cerael': 'cereal',
            'oatmeel': 'oatmeal',
            'oat meal': 'oatmeal',
            'porrige': 'porridge',
            'poridge': 'porridge',
            'musley': 'muesli',
            'museli': 'muesli',
            'granolla': 'granola',
            'granolla': 'granola',
            
            # Seasonings & Flavors
            'flavour': 'flavour',  # Keep UK spelling
            'flavor': 'flavour',   # Convert US to UK
            'flavoured': 'flavoured',
            'flavored': 'flavoured',
            'vannila': 'vanilla',
            'vanila': 'vanilla',
            'vanila': 'vanilla',
            'cinammon': 'cinnamon',
            'cinamon': 'cinnamon',
            'cinnammon': 'cinnamon',
            'organo': 'oregano',
            'origano': 'oregano',
            'basill': 'basil',
            'parsly': 'parsley',
            'parsely': 'parsley',
            'corriander': 'coriander',
            'corianda': 'coriander',
            
            # Cooking Terms
            'bakd': 'baked',
            'bakt': 'baked',
            'grild': 'grilled',
            'griled': 'grilled',
            'roastd': 'roasted',
            'rosted': 'roasted',
            'fryd': 'fried',
            'fride': 'fried',
            'steamd': 'steamed',
            'steemed': 'steamed',
            'boild': 'boiled',
            'boyled': 'boiled',
            
            # Snacks & Treats
            'crisps': 'crisps',  # Keep UK term
            'chips': 'crisps',   # Convert US to UK for packaged snacks
            'biscits': 'biscuits',
            'biscuts': 'biscuits',
            'cookys': 'cookies',
            'cookees': 'cookies',
            'icecream': 'ice cream',
            'ice-cream': 'ice cream',
            'chocalte': 'chocolate',
            'chocholate': 'chocolate',
            
            # Common UK Brand Misspellings
            'walkers': 'Walkers',
            'tesco': 'Tesco',
            'asda': 'ASDA',
            'morrisons': 'Morrisons',
            'waitrose': 'Waitrose',
            'marks & spencer': 'Marks & Spencer',
            'm&s': 'M&S',
            'cadbury': 'Cadbury',
            'nestle': 'Nestlé',
            'heinz': 'Heinz',
            'charlie binghams': "Charlie Bigham's",
            
            # Measurements & Common Terms
            'orgnic': 'organic',
            'organc': 'organic',
            'organik': 'organic',
            'fre range': 'free range',
            'freerange': 'free range',
            'free-range': 'free range',
            'wholewheat': 'wholemeal',  # UK preference
            'whole wheat': 'wholemeal',
            'wholegrain': 'wholegrain',
            'whole grain': 'wholegrain',
            'sugarfree': 'sugar free',
            'sugar-free': 'sugar free',
            'fatfree': 'fat free',
            'fat-free': 'fat free',
            'low-fat': 'low fat',
            'lowfat': 'low fat',
            'reduced fat': 'reduced fat',
            'reducd fat': 'reduced fat',
            'extra virgin': 'extra virgin',
            'extravirgin': 'extra virgin',
        }
    
    def get_word_boundaries_corrections(self) -> List[Tuple[str, str]]:
        """Word boundary corrections using regex patterns"""
        return [
            (r'\bchoclate\b', 'chocolate'),
            (r'\bchocalate\b', 'chocolate'),
            (r'\bbannana\b', 'banana'),
            (r'\bstraberry\b', 'strawberry'),
            (r'\brasberry\b', 'raspberry'),
            (r'\btomatoe\b', 'tomato'),
            (r'\bpotatoe\b', 'potato'),
            (r'\bavacado\b', 'avocado'),
            (r'\bbrocoli\b', 'broccoli'),
            (r'\bcaulliflower\b', 'cauliflower'),
            (r'\byoghurt\b', 'yogurt'),  # Convert to standard
            (r'\bchecken\b', 'chicken'),
            (r'\bchiken\b', 'chicken'),
            (r'\bbeaf\b', 'beef'),
            (r'\bsamon\b', 'salmon'),
            (r'\bmackrel\b', 'mackerel'),
            (r'\bcerial\b', 'cereal'),
            (r'\bporrige\b', 'porridge'),
            (r'\bmusley\b', 'muesli'),
            (r'\bvannila\b', 'vanilla'),
            (r'\bcinammon\b', 'cinnamon'),
            (r'\borgano\b', 'oregano'),
            (r'\bparsly\b', 'parsley'),
            (r'\bcorriander\b', 'coriander'),
            (r'\bflavor\b', 'flavour'),  # US to UK
            (r'\bflavored\b', 'flavoured'),
            (r'\borganc\b', 'organic'),
            (r'\borgnic\b', 'organic'),
            (r'\bwholewheat\b', 'wholemeal'),
            (r'\bwhole wheat\b', 'wholemeal'),
        ]
    
    def fix_spelling_in_text(self, text: str) -> Tuple[str, bool]:
        """Fix spelling in a given text, return (fixed_text, was_changed)"""
        if not text:
            return text, False
            
        original_text = text
        
        # Apply word boundary corrections first (more precise)
        word_corrections = self.get_word_boundaries_corrections()
        for pattern, replacement in word_corrections:
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
        
        # Apply simple string replacements
        corrections = self.get_spelling_corrections()
        for mistake, correction in corrections.items():
            # Case-insensitive replacement but preserve original case pattern
            if mistake.lower() in text.lower():
                # Find all occurrences with different cases
                pattern = re.escape(mistake)
                matches = re.finditer(pattern, text, re.IGNORECASE)
                
                for match in reversed(list(matches)):  # Reverse to maintain positions
                    original_word = match.group()
                    
                    # Preserve case pattern
                    if original_word.isupper():
                        replacement = correction.upper()
                    elif original_word.istitle():
                        replacement = correction.title()
                    elif original_word.islower():
                        replacement = correction.lower()
                    else:
                        replacement = correction
                    
                    text = text[:match.start()] + replacement + text[match.end():]
        
        return text, text != original_text
    
    def fix_all_spelling(self) -> Tuple[int, int]:
        """Fix spelling in all product names and brands"""
        cursor = self.conn.cursor()
        
        # Get all products
        cursor.execute("SELECT id, name, brand FROM products")
        products = cursor.fetchall()
        
        total_products = len(products)
        updates = []
        
        print(f"🔤 Checking spelling in {total_products} products...")
        
        for i, (product_id, name, brand) in enumerate(products):
            name_fixed = name
            brand_fixed = brand
            name_changed = False
            brand_changed = False
            
            # Fix name spelling
            if name:
                name_fixed, name_changed = self.fix_spelling_in_text(name)
            
            # Fix brand spelling
            if brand:
                brand_fixed, brand_changed = self.fix_spelling_in_text(brand)
            
            # If anything changed, add to updates
            if name_changed or brand_changed:
                updates.append((name_fixed, brand_fixed, product_id))
                self.fixed_count += 1
                
                if self.fixed_count <= 10:  # Show first 10 examples
                    changes = []
                    if name_changed:
                        changes.append(f"'{name}' → '{name_fixed}'")
                    if brand_changed:
                        changes.append(f"Brand: '{brand}' → '{brand_fixed}'")
                    print(f"   ✏️  {' | '.join(changes)}")
            
            # Progress update
            if i % 5000 == 0 and i > 0:
                print(f"   📊 Progress: {i}/{total_products} checked, {self.fixed_count} fixed so far")
        
        # Apply updates
        if updates:
            cursor.executemany("""
                UPDATE products 
                SET name = ?, brand = ?
                WHERE id = ?
            """, updates)
            self.conn.commit()
            
        print(f"✅ Fixed spelling in {self.fixed_count} products")
        return self.fixed_count, total_products
    
    def find_potential_duplicates(self) -> List[Tuple[str, int]]:
        """Find products that might be duplicates after spelling fixes"""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            SELECT name, brand, COUNT(*) as count
            FROM products 
            WHERE name IS NOT NULL
            GROUP BY LOWER(name), LOWER(COALESCE(brand, ''))
            HAVING count > 1
            ORDER BY count DESC
            LIMIT 20
        """)
        
        duplicates = cursor.fetchall()
        return [(f"{name} ({brand})", count) for name, brand, count in duplicates]
    
    def get_statistics(self) -> Dict:
        """Get spelling fix statistics"""
        cursor = self.conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM products")
        total = cursor.fetchone()[0]
        
        # Check for remaining common misspellings
        remaining_issues = []
        common_mistakes = ['choclate', 'bannana', 'straberry', 'tomatoe', 'potatoe']
        
        for mistake in common_mistakes:
            cursor.execute(f"SELECT COUNT(*) FROM products WHERE name LIKE '%{mistake}%'")
            count = cursor.fetchone()[0]
            if count > 0:
                remaining_issues.append((mistake, count))
        
        return {
            'total_products': total,
            'spelling_fixes': self.fixed_count,
            'remaining_issues': remaining_issues
        }
    
    def close(self):
        """Close database connection"""
        self.conn.close()

def main():
    print("🔤 UK FOOD DATABASE SPELLING FIXER")
    print("=" * 50)
    
    db_path = "/Users/aaronkeen/Documents/Food database/Tesco/uk_foods.db"
    fixer = SpellingFixer(db_path)
    
    try:
        # Fix all spelling
        fixed, total = fixer.fix_all_spelling()
        print()
        
        # Check for potential duplicates
        duplicates = fixer.find_potential_duplicates()
        if duplicates:
            print("🔍 POTENTIAL DUPLICATES FOUND (after spelling fixes):")
            for duplicate, count in duplicates[:10]:
                print(f"   {count}x: {duplicate}")
            print()
        
        # Final statistics
        stats = fixer.get_statistics()
        print(f"📊 FINAL RESULTS:")
        print(f"   Total products: {stats['total_products']}")
        print(f"   Spelling fixes applied: {stats['spelling_fixes']}")
        
        if stats['remaining_issues']:
            print(f"   Remaining spelling issues:")
            for mistake, count in stats['remaining_issues']:
                print(f"     - '{mistake}': {count} occurrences")
        else:
            print(f"   ✅ No common spelling mistakes found!")
        
    finally:
        fixer.close()

if __name__ == "__main__":
    main()