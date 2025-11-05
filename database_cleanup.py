#!/usr/bin/env python3
"""
Comprehensive Food Database Cleanup Script
Fixes duplicates, serving sizes, ingredients, and validates nutrition data
"""

import sqlite3
import re
from datetime import datetime
from typing import Dict, List, Tuple
import shutil

class DatabaseCleaner:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.backup_path = db_path.replace('.db', f'_backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.db')
        self.conn = None
        self.cursor = None
        self.stats = {
            'duplicates_removed': 0,
            'serving_sizes_fixed': 0,
            'ingredients_cleaned': 0,
            'names_corrected': 0,
            'nutrition_validated': 0
        }

    def backup_database(self):
        """Create a backup before making changes"""
        print(f"Creating backup: {self.backup_path}")
        shutil.copy2(self.db_path, self.backup_path)
        print("✅ Backup created successfully")

    def connect(self):
        """Connect to the database"""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.commit()
            self.conn.close()

    def fix_serving_sizes(self):
        """Fix invalid serving sizes (0g or NULL)"""
        print("\n📊 Fixing invalid serving sizes...")

        # Get foods with invalid serving sizes
        self.cursor.execute("""
            SELECT id, name, brand, serving_description, serving_size_g
            FROM foods
            WHERE serving_size_g = 0 OR serving_size_g IS NULL
        """)

        invalid_foods = self.cursor.fetchall()
        fixed_count = 0

        for food in invalid_foods:
            food_id = food['id']
            serving_desc = food['serving_description'] or ''

            # Try to extract serving size from description
            serving_size = self._extract_serving_size(serving_desc)

            if serving_size:
                self.cursor.execute("""
                    UPDATE foods
                    SET serving_size_g = ?, updated_at = ?
                    WHERE id = ?
                """, (serving_size, int(datetime.now().timestamp()), food_id))
                fixed_count += 1
            else:
                # Default to 100g if we can't determine
                self.cursor.execute("""
                    UPDATE foods
                    SET serving_size_g = 100, updated_at = ?
                    WHERE id = ?
                """, (int(datetime.now().timestamp()), food_id))
                fixed_count += 1

        self.stats['serving_sizes_fixed'] = fixed_count
        print(f"✅ Fixed {fixed_count} serving sizes")

    def _extract_serving_size(self, description: str) -> float:
        """Extract serving size in grams from description"""
        if not description:
            return 100.0

        description = description.lower()

        # Pattern: "330ml", "250 ml", "100g", "50 g"
        ml_match = re.search(r'(\d+\.?\d*)\s*ml', description)
        if ml_match:
            return float(ml_match.group(1))  # Assume 1ml = 1g for liquids

        g_match = re.search(r'(\d+\.?\d*)\s*g(?:ram)?s?', description)
        if g_match:
            return float(g_match.group(1))

        # If description says "100g" or "per 100g", return 100
        if '100' in description:
            return 100.0

        return 100.0  # Default

    def clean_ingredients(self):
        """Clean and standardize ingredient formatting"""
        print("\n🧪 Cleaning ingredients...")

        self.cursor.execute("SELECT id, ingredients FROM foods WHERE ingredients IS NOT NULL")
        foods = self.cursor.fetchall()

        cleaned_count = 0

        for food in foods:
            food_id = food['id']
            ingredients = food['ingredients']

            # Clean ingredients
            cleaned = self._clean_ingredient_text(ingredients)

            if cleaned != ingredients:
                self.cursor.execute("""
                    UPDATE foods
                    SET ingredients = ?, updated_at = ?
                    WHERE id = ?
                """, (cleaned, int(datetime.now().timestamp()), food_id))
                cleaned_count += 1

        self.stats['ingredients_cleaned'] = cleaned_count
        print(f"✅ Cleaned {cleaned_count} ingredient lists")

    def _clean_ingredient_text(self, text: str) -> str:
        """Clean and standardize ingredient text"""
        if not text:
            return text

        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)

        # Standardize formatting
        text = text.strip()

        # Fix common issues
        text = text.replace('  ', ' ')
        text = text.replace(' ,', ',')
        text = text.replace(' .', '.')

        # Ensure first letter is capitalized
        if text:
            text = text[0].upper() + text[1:]

        return text

    def find_and_merge_duplicates(self):
        """Find and merge duplicate entries, keeping the best quality one"""
        print("\n🔍 Finding and merging duplicates...")

        # Find duplicates grouped by name and brand
        self.cursor.execute("""
            SELECT LOWER(name) as name_lower, LOWER(COALESCE(brand, '')) as brand_lower,
                   COUNT(*) as count
            FROM foods
            GROUP BY name_lower, brand_lower
            HAVING count > 1
        """)

        duplicate_groups = self.cursor.fetchall()
        removed_count = 0

        for group in duplicate_groups:
            name_lower = group['name_lower']
            brand_lower = group['brand_lower']

            # Get all entries in this group
            if brand_lower:
                self.cursor.execute("""
                    SELECT * FROM foods
                    WHERE LOWER(name) = ? AND LOWER(COALESCE(brand, '')) = ?
                    ORDER BY is_verified DESC, updated_at DESC
                """, (name_lower, brand_lower))
            else:
                self.cursor.execute("""
                    SELECT * FROM foods
                    WHERE LOWER(name) = ? AND (brand IS NULL OR brand = '')
                    ORDER BY is_verified DESC, updated_at DESC
                """, (name_lower,))

            entries = self.cursor.fetchall()

            if len(entries) <= 1:
                continue

            # Keep the best entry (verified, most recent, most complete)
            best_entry = self._select_best_entry(entries)

            # Delete others
            for entry in entries:
                if entry['id'] != best_entry['id']:
                    self.cursor.execute("DELETE FROM foods WHERE id = ?", (entry['id'],))
                    removed_count += 1

        self.stats['duplicates_removed'] = removed_count
        print(f"✅ Removed {removed_count} duplicate entries")

    def _select_best_entry(self, entries: List) -> Dict:
        """Select the best quality entry from duplicates"""
        # Score each entry
        best_entry = None
        best_score = -1

        for entry in entries:
            score = 0

            # Verified entries are best
            if entry['is_verified']:
                score += 1000

            # Has ingredients
            if entry['ingredients'] and len(entry['ingredients']) > 20:
                score += 100

            # Has barcode
            if entry['barcode']:
                score += 50

            # Has reasonable serving size
            if entry['serving_size_g'] and entry['serving_size_g'] > 0:
                score += 20

            # More recent
            if entry['updated_at']:
                score += entry['updated_at'] / 1000000000  # Normalize timestamp

            # Has micronutrients
            micronutrient_sum = sum([
                entry['vitamin_a'] or 0,
                entry['vitamin_c'] or 0,
                entry['calcium'] or 0,
                entry['iron'] or 0
            ])
            if micronutrient_sum > 0:
                score += 30

            if score > best_score:
                best_score = score
                best_entry = entry

        return best_entry

    def validate_nutrition_data(self):
        """Validate nutrition data for obvious errors"""
        print("\n🔬 Validating nutrition data...")

        # Check for impossible values
        self.cursor.execute("""
            SELECT id, name, brand, calories, protein, carbs, fat, fiber, sugar
            FROM foods
        """)

        foods = self.cursor.fetchall()
        fixed_count = 0

        for food in foods:
            issues = []

            # Calories from macros should roughly match stated calories
            # 1g protein = 4 cal, 1g carb = 4 cal, 1g fat = 9 cal
            calculated_calories = (food['protein'] * 4) + (food['carbs'] * 4) + (food['fat'] * 9)
            stated_calories = food['calories']

            # Allow 20% variance
            if stated_calories > 0:
                variance = abs(calculated_calories - stated_calories) / stated_calories
                if variance > 0.3:  # 30% variance is suspicious
                    issues.append('calorie_mismatch')

            # Sugar can't be more than carbs
            if food['sugar'] > food['carbs'] + 1:  # +1 for rounding
                issues.append('sugar_exceeds_carbs')

            # Fiber can't be more than carbs
            if food['fiber'] > food['carbs'] + 1:
                issues.append('fiber_exceeds_carbs')

            # Negative values are impossible
            if any(v < 0 for v in [food['calories'], food['protein'], food['carbs'],
                                    food['fat'], food['fiber'], food['sugar']]):
                issues.append('negative_values')

            if issues:
                # For now, just log these - manual review needed
                print(f"⚠️  {food['name']} ({food['brand']}): {', '.join(issues)}")
                fixed_count += 1

        self.stats['nutrition_validated'] = fixed_count
        print(f"✅ Validated nutrition data, found {fixed_count} potential issues")

    def standardize_names_and_brands(self):
        """Standardize capitalization and spelling"""
        print("\n✏️  Standardizing names and brands...")

        self.cursor.execute("SELECT id, name, brand FROM foods")
        foods = self.cursor.fetchall()

        corrected_count = 0

        for food in foods:
            food_id = food['id']
            name = food['name']
            brand = food['brand']

            # Standardize name
            new_name = self._standardize_text(name)
            new_brand = self._standardize_text(brand) if brand else brand

            if new_name != name or new_brand != brand:
                self.cursor.execute("""
                    UPDATE foods
                    SET name = ?, brand = ?, updated_at = ?
                    WHERE id = ?
                """, (new_name, new_brand, int(datetime.now().timestamp()), food_id))
                corrected_count += 1

        self.stats['names_corrected'] = corrected_count
        print(f"✅ Standardized {corrected_count} names and brands")

    def _standardize_text(self, text: str) -> str:
        """Standardize text capitalization"""
        if not text:
            return text

        # Remove extra whitespace
        text = ' '.join(text.split())

        # Title case, but preserve known acronyms
        words = text.split()
        result = []

        for word in words:
            # Preserve all-caps acronyms (2-4 letters)
            if word.isupper() and 2 <= len(word) <= 4:
                result.append(word)
            else:
                result.append(word.capitalize())

        return ' '.join(result)

    def print_summary(self):
        """Print cleanup summary"""
        print("\n" + "="*60)
        print("🎉 DATABASE CLEANUP SUMMARY")
        print("="*60)
        print(f"Serving sizes fixed:      {self.stats['serving_sizes_fixed']}")
        print(f"Duplicates removed:       {self.stats['duplicates_removed']}")
        print(f"Ingredients cleaned:      {self.stats['ingredients_cleaned']}")
        print(f"Names standardized:       {self.stats['names_corrected']}")
        print(f"Nutrition issues found:   {self.stats['nutrition_validated']}")
        print("="*60)

        # Final counts
        self.cursor.execute("SELECT COUNT(*) as count FROM foods")
        final_count = self.cursor.fetchone()['count']
        print(f"\n📊 Final database: {final_count} foods")
        print(f"📦 Backup saved: {self.backup_path}")

def main():
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"

    cleaner = DatabaseCleaner(db_path)

    # Backup first
    cleaner.backup_database()

    # Connect
    cleaner.connect()

    try:
        # Run cleanup steps
        cleaner.fix_serving_sizes()
        cleaner.clean_ingredients()
        cleaner.standardize_names_and_brands()
        cleaner.find_and_merge_duplicates()
        cleaner.validate_nutrition_data()

        # Commit changes
        cleaner.conn.commit()

        # Print summary
        cleaner.print_summary()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        cleaner.conn.rollback()
        raise
    finally:
        cleaner.close()

if __name__ == "__main__":
    main()
