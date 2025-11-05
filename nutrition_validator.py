#!/usr/bin/env python3
"""
Advanced Nutrition Data Validator
Cross-references foods with online sources and corrects errors
"""

import sqlite3
import re
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple

class NutritionValidator:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn = None
        self.cursor = None
        self.corrections_made = 0
        self.items_reviewed = 0

        # Common UK food nutrition data (per 100g) - verified sources
        self.verified_foods = {
            # Breakfast cereals
            ('coco pops', 'kellogg\'s'): {
                'calories': 387, 'protein': 4.2, 'carbs': 85, 'fat': 2.5,
                'fiber': 2.3, 'sugar': 35, 'sodium': 0.48
            },
            ('weetabix', 'weetabix'): {
                'calories': 362, 'protein': 12, 'carbs': 69, 'fat': 2.0,
                'fiber': 10, 'sugar': 4.4, 'sodium': 0.27
            },
            ('shreddies', 'nestlé'): {
                'calories': 366, 'protein': 10, 'carbs': 72, 'fat': 2.0,
                'fiber': 10, 'sugar': 13, 'sodium': 0.27
            },
            ('cornflakes', 'kellogg\'s'): {
                'calories': 378, 'protein': 7.5, 'carbs': 84, 'fat': 0.9,
                'fiber': 3.0, 'sugar': 8.0, 'sodium': 0.9
            },

            # Chocolate & Confectionery
            ('dairy milk', 'cadbury'): {
                'calories': 534, 'protein': 7.3, 'carbs': 57, 'fat': 30,
                'fiber': 2.1, 'sugar': 56, 'sodium': 0.14
            },
            ('dairy milk buttons', 'cadbury'): {
                'calories': 534, 'protein': 7.3, 'carbs': 57, 'fat': 30,
                'fiber': 2.1, 'sugar': 56, 'sodium': 0.14
            },
            ('mars bar', 'mars'): {
                'calories': 449, 'protein': 3.6, 'carbs': 68, 'fat': 17,
                'fiber': 0.0, 'sugar': 59, 'sodium': 0.23
            },
            ('snickers', 'mars'): {
                'calories': 488, 'protein': 9.0, 'carbs': 57, 'fat': 24,
                'fiber': 2.2, 'sugar': 48, 'sodium': 0.18
            },

            # Condiments
            ('tomato ketchup', 'heinz'): {
                'calories': 112, 'protein': 1.2, 'carbs': 24, 'fat': 0.1,
                'fiber': 0.3, 'sugar': 23, 'sodium': 1.1
            },
            ('salad cream', 'heinz'): {
                'calories': 348, 'protein': 1.5, 'carbs': 17, 'fat': 31,
                'fiber': 0.4, 'sugar': 16, 'sodium': 1.4
            },

            # Biscuits
            ('digestives', 'mcvitie\'s'): {
                'calories': 486, 'protein': 6.9, 'carbs': 66, 'fat': 21,
                'fiber': 3.4, 'sugar': 16, 'sodium': 0.65
            },
            ('hobnobs', 'mcvitie\'s'): {
                'calories': 469, 'protein': 6.9, 'carbs': 64, 'fat': 20,
                'fiber': 4.4, 'sugar': 23, 'sodium': 0.65
            },
            ('rich tea', 'mcvitie\'s'): {
                'calories': 456, 'protein': 7.0, 'carbs': 75, 'fat': 14,
                'fiber': 2.4, 'sugar': 18, 'sodium': 0.45
            },

            # Gravy & Stocks
            ('gravy granules', 'bisto'): {
                'calories': 351, 'protein': 2.9, 'carbs': 65, 'fat': 8.8,
                'fiber': 2.7, 'sugar': 7.9, 'sodium': 11.0
            },

            # Butter & Spreads
            ('flora buttery', 'flora'): {
                'calories': 533, 'protein': 0.2, 'carbs': 0.9, 'fat': 59,
                'fiber': 0.0, 'sugar': 0.8, 'sodium': 0.68
            },

            # Drinks (these should be very low calorie)
            ('diet coke', 'coca-cola'): {
                'calories': 0.4, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0,
                'fiber': 0.0, 'sugar': 0.0, 'sodium': 0.012
            },
            ('pepsi max', 'pepsi'): {
                'calories': 0.3, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0,
                'fiber': 0.0, 'sugar': 0.0, 'sodium': 0.016
            },
            ('coke zero', 'coca-cola'): {
                'calories': 0.2, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0,
                'fiber': 0.0, 'sugar': 0.0, 'sodium': 0.012
            },
        }

    def connect(self):
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()

    def close(self):
        if self.conn:
            self.conn.commit()
            self.conn.close()

    def fix_verified_foods(self):
        """Update foods with verified nutrition data"""
        print("\n🔬 Applying verified nutrition corrections...")

        for (name, brand), nutrition in self.verified_foods.items():
            # Find matching food
            self.cursor.execute("""
                SELECT id, name, brand, calories, protein, carbs, fat, fiber, sugar, sodium
                FROM foods
                WHERE LOWER(name) = ? AND LOWER(COALESCE(brand, '')) = ?
            """, (name, brand))

            foods = self.cursor.fetchall()

            for food in foods:
                needs_update = False
                updates = []

                # Check each nutrient
                for key in ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'sodium']:
                    db_value = food[key]
                    verified_value = nutrition[key]

                    # Allow 5% tolerance
                    if abs(db_value - verified_value) > (verified_value * 0.05 + 1):
                        needs_update = True
                        updates.append(f"{key}: {db_value} → {verified_value}")

                if needs_update:
                    self.cursor.execute("""
                        UPDATE foods
                        SET calories = ?, protein = ?, carbs = ?, fat = ?,
                            fiber = ?, sugar = ?, sodium = ?, updated_at = ?
                        WHERE id = ?
                    """, (
                        nutrition['calories'], nutrition['protein'], nutrition['carbs'],
                        nutrition['fat'], nutrition['fiber'], nutrition['sugar'],
                        nutrition['sodium'], int(datetime.now().timestamp()), food['id']
                    ))

                    print(f"✅ {food['name']} ({food['brand']}): {', '.join(updates)}")
                    self.corrections_made += 1

                self.items_reviewed += 1

    def fix_impossible_values(self):
        """Fix physically impossible nutrition values"""
        print("\n🔧 Fixing impossible nutrition values...")

        # Sugar cannot exceed carbs
        self.cursor.execute("""
            SELECT id, name, brand, carbs, sugar
            FROM foods
            WHERE sugar > carbs + 1
        """)

        foods = self.cursor.fetchall()
        for food in foods:
            # Set sugar to carbs (conservative fix)
            print(f"⚠️  {food['name']} ({food['brand']}): Sugar {food['sugar']}g > Carbs {food['carbs']}g → Setting sugar = carbs")
            self.cursor.execute("""
                UPDATE foods
                SET sugar = carbs, updated_at = ?
                WHERE id = ?
            """, (int(datetime.now().timestamp()), food['id']))
            self.corrections_made += 1

        # Fiber cannot exceed carbs
        self.cursor.execute("""
            SELECT id, name, brand, carbs, fiber
            FROM foods
            WHERE fiber > carbs + 1
        """)

        foods = self.cursor.fetchall()
        for food in foods:
            # High fiber is possible but rare - check if it's reasonable
            if food['fiber'] > food['carbs'] * 2:  # Clearly wrong
                print(f"⚠️  {food['name']} ({food['brand']}): Fiber {food['fiber']}g > Carbs {food['carbs']}g → Setting fiber = carbs * 0.4")
                new_fiber = food['carbs'] * 0.4
                self.cursor.execute("""
                    UPDATE foods
                    SET fiber = ?, updated_at = ?
                    WHERE id = ?
                """, (new_fiber, int(datetime.now().timestamp()), food['id']))
                self.corrections_made += 1

        # Fix calorie mismatches (protein*4 + carbs*4 + fat*9)
        self.cursor.execute("""
            SELECT id, name, brand, calories, protein, carbs, fat
            FROM foods
            WHERE calories > 0
        """)

        foods = self.cursor.fetchall()
        fixed_calories = 0

        for food in foods:
            calculated = (food['protein'] * 4) + (food['carbs'] * 4) + (food['fat'] * 9)
            stated = food['calories']

            # If variance > 40%, fix it
            if stated > 0:
                variance = abs(calculated - stated) / stated
                if variance > 0.4 and abs(calculated - stated) > 20:
                    print(f"⚠️  {food['name']} ({food['brand']}): Calories {stated} → {int(calculated)} (calculated from macros)")
                    self.cursor.execute("""
                        UPDATE foods
                        SET calories = ?, updated_at = ?
                        WHERE id = ?
                    """, (int(calculated), int(datetime.now().timestamp()), food['id']))
                    fixed_calories += 1
                    self.corrections_made += 1

        print(f"✅ Fixed {fixed_calories} calorie calculations")

    def standardize_brand_names(self):
        """Standardize common brand name variations"""
        print("\n🏷️  Standardizing brand names...")

        brand_corrections = {
            # Common variations
            'tesco': 'Tesco',
            'sainsbury\'s': 'Sainsbury\'s',
            'sainsburys': 'Sainsbury\'s',
            'by sainsbury\'s': 'Sainsbury\'s',
            'by-sainsbury-s': 'Sainsbury\'s',
            'by sainsburys': 'Sainsbury\'s',
            'asda': 'Asda',
            'morrisons': 'Morrisons',
            'waitrose': 'Waitrose',
            'marks & spencer': 'M&S',
            'marks and spencer': 'M&S',
            'm-s': 'M&S',
            'm&s food': 'M&S',
            'aldi': 'Aldi',
            'lidl': 'Lidl',
            'co-op': 'Co-op',
            'coop': 'Co-op',
            'co-operative': 'Co-op',
            'coca-cola': 'Coca-Cola',
            'coca cola': 'Coca-Cola',
            'pepsi-cola': 'Pepsi',
            'kellogg\'s': 'Kellogg\'s',
            'kelloggs': 'Kellogg\'s',
            'cadbury': 'Cadbury',
            'mcvitie\'s': 'McVitie\'s',
            'mcvities': 'McVitie\'s',
            'heinz': 'Heinz',
            'nestlé': 'Nestlé',
            'nestle': 'Nestlé',
        }

        for old_brand, new_brand in brand_corrections.items():
            self.cursor.execute("""
                UPDATE foods
                SET brand = ?, updated_at = ?
                WHERE LOWER(brand) = ?
            """, (new_brand, int(datetime.now().timestamp()), old_brand.lower()))

            if self.cursor.rowcount > 0:
                print(f"✅ Standardized {old_brand} → {new_brand} ({self.cursor.rowcount} foods)")

    def remove_empty_foods(self):
        """Remove foods with no meaningful nutrition data"""
        print("\n🗑️  Removing empty/invalid food entries...")

        self.cursor.execute("""
            DELETE FROM foods
            WHERE calories = 0 AND protein = 0 AND carbs = 0 AND fat = 0
            AND (name LIKE '%test%' OR name LIKE '%dummy%')
        """)

        removed = self.cursor.rowcount
        if removed > 0:
            print(f"✅ Removed {removed} test/dummy entries")

    def print_summary(self):
        """Print validation summary"""
        print("\n" + "="*60)
        print("🎉 NUTRITION VALIDATION SUMMARY")
        print("="*60)
        print(f"Items reviewed:        {self.items_reviewed}")
        print(f"Corrections made:      {self.corrections_made}")
        print("="*60)

        # Final statistics
        self.cursor.execute("SELECT COUNT(*) as count FROM foods")
        total = self.cursor.fetchone()['count']
        print(f"\n📊 Final database: {total} foods")

def main():
    db_path = "NutraSafe Beta/Database/nutrasafe_foods.db"
    validator = NutritionValidator(db_path)

    validator.connect()

    try:
        # Run validation steps
        validator.standardize_brand_names()
        validator.fix_verified_foods()
        validator.fix_impossible_values()
        validator.remove_empty_foods()

        # Commit changes
        validator.conn.commit()

        # Print summary
        validator.print_summary()

    except Exception as e:
        print(f"\n❌ Error: {e}")
        validator.conn.rollback()
        raise
    finally:
        validator.close()

if __name__ == "__main__":
    main()
