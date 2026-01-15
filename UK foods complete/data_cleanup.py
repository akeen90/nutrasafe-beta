#!/usr/bin/env python3
"""
UK Foods Database Cleanup Script
Processes up to 500 records per run to prevent mass errors.
Creates backups and logs all changes.

Usage:
    python3 data_cleanup.py              # Run cleanup (max 500 changes)
    python3 data_cleanup.py --dry-run    # Preview changes without applying
    python3 data_cleanup.py --reset      # Reset progress tracking
    python3 data_cleanup.py --status     # Show cleanup progress
"""

import csv
import os
import re
import sys
import json
import shutil
from datetime import datetime
from collections import defaultdict

# Configuration
INPUT_FILE = "uk_foods_complete copy.csv"
OUTPUT_FILE = "uk_foods_cleaned.csv"
BACKUP_DIR = "backups"
LOG_DIR = "cleanup_logs"
PROGRESS_FILE = "cleanup_progress.json"
MAX_CHANGES_PER_RUN = 500

# ============================================================================
# CORRECTION MAPPINGS
# ============================================================================

# OCR spelling corrections (only actual errors, not UK spellings)
OCR_CORRECTIONS = {
    # Common OCR misreads
    'Cluten': 'Gluten',
    'Giuten': 'Gluten',
    'Clucose': 'Glucose',
    'Bliacin': 'Niacin',
    'Calctum': 'Calcium',
    'Hocolate': 'Chocolate',
    'Ingredlents': 'Ingredients',
    'Cround': 'Ground',
    'Crain': 'Grain',
    'Seit ': 'Salt ',
    'Sait': 'Salt',
    'Suger': 'Sugar',
    'Coiour': 'Colour',
    'Fiavour': 'Flavour',
    'Biack': 'Black',
    'Oii': 'Oil',
    'oii': 'oil',
    ' Flou ': ' Flour ',
    ' Fiou ': ' Flour ',
    'Forallergens': 'For allergens',
    'Emulsifer:': 'Emulsifier:',
    'Caiories': 'Calories',
    'Giycero': 'Glycero',
    'Rapeseed Oi1': 'Rapeseed Oil',
    'Sunflower Oi1': 'Sunflower Oil',
    'Palm Oi1': 'Palm Oil',
    'Vegetable Oi1': 'Vegetable Oil',
    ';nut': '',  # Remove OCR artefacts
    '.nut': '',
    '{nut': '',
    # Number/letter confusion
    'B1)': 'B1)',
    'O%': '0%',
}

# Category translations (foreign -> English)
CATEGORY_TRANSLATIONS = {
    'Snacks sucrés': 'Sweet snacks',
    'Snacks salés': 'Salty snacks',
    'Produits laitiers': 'Dairy products',
    'Produits fermentés': 'Fermented products',
    'Compléments alimentaires': 'Dietary supplements',
    'Boissons': 'Beverages',
    'Confiseries': 'Confectionery',
    'Nouilles': 'Noodles',
    'Botanas': 'Snacks',
    'Snacks dulces': 'Sweet snacks',
    'Snacks salados': 'Salty snacks',
    'Imbiss': 'Snacks',
    'Kekse und Kuchen': 'Biscuits and cakes',
    'Kakao und Kakaoprodukte': 'Cocoa and cocoa products',
    'Getränke': 'Beverages',
    'Süßigkeiten': 'Confectionery',
    'Bisküvi': 'Biscuits',
}

# Category prefix patterns to remove (en:, fr:, etc.)
CATEGORY_PREFIX_PATTERN = re.compile(r'\b(en|fr|de|es|it|ms):[a-z-]+,?\s*')

# Hyphenated category conversions
HYPHENATED_CATEGORIES = {
    'plant-based-foods-and-beverages': 'Plant-based foods and beverages',
    'plant-based-foods': 'Plant-based foods',
    'meat-analogues': 'Meat alternatives',
    'dairy-desserts': 'Dairy desserts',
    'potato-crisps': 'Potato crisps',
    'milk-chocolates': 'Milk chocolates',
    'mashed-vegetables': 'Mashed vegetables',
    'custards-and-pastry-creams': 'Custards and pastry creams',
    'mint-sauces': 'Mint sauces',
    'prepared-lasagne': 'Prepared lasagne',
}

# Malformed name patterns and actions
MALFORMED_NAME_FIXES = [
    # Pattern: M&S -food- prefix - extract actual product name
    (r'^M&S -food-\s*', ''),
    # Pattern: Random packaging text at start
    (r'^(BEST B|NLY MI|MBS CHIC|GER |Saiss|Power |Blond |AIR FRY|CH BEEF|RN EO|SKIN NS)\s*', ''),
    # Pattern: Numbers at very start that aren't part of product
    (r'^[0-9]+ [0-9]+ [0-9]+[A-Z]*\s+', ''),
]

# Non-UK brands to flag (not auto-delete, just mark)
NON_UK_BRANDS = [
    'spartan', 'wegmans', 'key food', 'kroger', 'safeway',
    'publix', 'trader joe', 'walmart', 'target'
]


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_dirs():
    """Create necessary directories"""
    for d in [BACKUP_DIR, LOG_DIR]:
        if not os.path.exists(d):
            os.makedirs(d)


def create_backup(filename):
    """Create a timestamped backup of the file"""
    if not os.path.exists(filename):
        return None
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_name = f"{BACKUP_DIR}/backup_{timestamp}.csv"
    shutil.copy(filename, backup_name)
    return backup_name


def load_progress():
    """Load cleanup progress from file"""
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r') as f:
            return json.load(f)
    return {
        'processed_rows': [],
        'total_changes': 0,
        'runs': 0,
        'last_run': None
    }


def save_progress(progress):
    """Save cleanup progress to file"""
    with open(PROGRESS_FILE, 'w') as f:
        json.dump(progress, f, indent=2)


def load_data(filename):
    """Load CSV data"""
    data = []
    with open(filename, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        for row in reader:
            data.append(row)
    return data, fieldnames


def save_data(filename, data, fieldnames):
    """Save CSV data"""
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        # Filter out any extra keys not in fieldnames
        for row in data:
            clean_row = {k: v for k, v in row.items() if k in fieldnames}
            writer.writerow(clean_row)


# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

def fix_ocr_errors(text):
    """Fix OCR spelling errors in text"""
    if not text:
        return text, []

    changes = []
    fixed_text = text

    for error, correction in OCR_CORRECTIONS.items():
        if error in fixed_text:
            fixed_text = fixed_text.replace(error, correction)
            changes.append(f"OCR: {error}->{correction}")

    return fixed_text, changes


def fix_category(category):
    """Fix category formatting and translate foreign text"""
    if not category:
        return category, []

    changes = []
    fixed = category

    # Remove category prefixes (en:, fr:, etc.)
    if CATEGORY_PREFIX_PATTERN.search(fixed):
        new_fixed = CATEGORY_PREFIX_PATTERN.sub('', fixed)
        if new_fixed != fixed:
            changes.append(f"Removed prefix from: {fixed[:30]}")
            fixed = new_fixed

    # Translate foreign categories
    for foreign, english in CATEGORY_TRANSLATIONS.items():
        if foreign in fixed:
            fixed = fixed.replace(foreign, english)
            changes.append(f"Translated: {foreign}->{english}")

    # Convert hyphenated categories
    for hyphenated, proper in HYPHENATED_CATEGORIES.items():
        if hyphenated in fixed.lower():
            fixed = re.sub(re.escape(hyphenated), proper, fixed, flags=re.IGNORECASE)
            changes.append(f"Dehyphenated: {hyphenated}")

    # Standardize case (Title Case for categories)
    if fixed and fixed == fixed.lower():
        new_fixed = fixed.title()
        if new_fixed != fixed:
            changes.append(f"Case fix: {fixed[:20]}->{new_fixed[:20]}")
            fixed = new_fixed

    # Clean up double spaces and trailing commas
    fixed = re.sub(r'\s+', ' ', fixed).strip()
    fixed = re.sub(r',\s*$', '', fixed)

    return fixed, changes


def fix_malformed_name(name):
    """Fix malformed product names"""
    if not name:
        return name, []

    changes = []
    fixed = name

    # Apply regex fixes
    for pattern, replacement in MALFORMED_NAME_FIXES:
        match = re.search(pattern, fixed)
        if match:
            new_fixed = re.sub(pattern, replacement, fixed)
            if new_fixed != fixed and len(new_fixed) > 5:  # Don't empty the name
                changes.append(f"Name cleanup: removed '{match.group()[:20]}'")
                fixed = new_fixed

    # Clean up the result
    fixed = fixed.strip()

    # If name is just a barcode, mark it (don't auto-fix)
    if fixed.isdigit() and len(fixed) >= 8:
        changes.append(f"WARNING: Name is barcode: {fixed}")

    return fixed, changes


def fix_barcode(barcode):
    """Fix or flag invalid barcodes"""
    if not barcode:
        return barcode, []

    changes = []
    fixed = barcode.strip()

    # Flag (don't auto-fix) overly long barcodes
    if len(fixed) > 14:
        changes.append(f"WARNING: Barcode too long ({len(fixed)} digits): {fixed[:20]}...")

    return fixed, changes


def fix_ingredients(ingredients):
    """Fix OCR errors in ingredients"""
    if not ingredients:
        return ingredients, []

    fixed, changes = fix_ocr_errors(ingredients)
    return fixed, changes


def should_flag_non_uk(row):
    """Check if product appears to be non-UK"""
    brand = (row.get('brand', '') or '').lower()
    name = (row.get('name', '') or '').lower()
    ingredients = (row.get('ingredients', '') or '')

    flags = []

    # Check brand
    for non_uk in NON_UK_BRANDS:
        if non_uk in brand or non_uk in name:
            flags.append(f"Non-UK brand: {non_uk}")
            break

    # Check for US-style ingredient labeling
    if re.search(r'INS\d{3}', ingredients):
        flags.append("Indian additive codes (INS) found")

    if 'FOLIC ACID' in ingredients and 'ENRICHED' in ingredients:
        flags.append("US-style fortification labeling")

    return flags


def is_mismatched_data(row):
    """Check for name/ingredient mismatches"""
    name = (row.get('name', '') or '').lower()
    ingredients = (row.get('ingredients', '') or '').lower()

    if not ingredients:
        return []

    flags = []

    # Fish product with no fish ingredients but lots of sweet
    fish_words = ['haddock', 'salmon', 'cod', 'fish', 'prawn', 'tuna']
    sweet_words = ['chocolate', 'cocoa', 'sugar', 'syrup', 'caramel', 'cake']

    if any(fw in name for fw in fish_words):
        has_fish = any(fw in ingredients for fw in fish_words)
        sweet_count = sum(1 for sw in sweet_words if sw in ingredients)

        if not has_fish and sweet_count >= 3:
            flags.append("MISMATCH: Fish name but dessert ingredients")

    return flags


# ============================================================================
# MAIN CLEANUP LOGIC
# ============================================================================

def process_row(row, row_num, processed_rows):
    """Process a single row and return changes"""
    if row_num in processed_rows:
        return row, [], False  # Already processed

    all_changes = []
    modified = False

    # 1. Fix product name
    if row.get('name'):
        fixed_name, name_changes = fix_malformed_name(row['name'])
        if name_changes:
            all_changes.extend([f"[name] {c}" for c in name_changes])
            if not any('WARNING' in c for c in name_changes):
                row['name'] = fixed_name
                modified = True

    # 2. Fix category
    if row.get('category'):
        fixed_cat, cat_changes = fix_category(row['category'])
        if cat_changes:
            all_changes.extend([f"[category] {c}" for c in cat_changes])
            row['category'] = fixed_cat
            modified = True

    # 3. Fix ingredients (OCR errors)
    if row.get('ingredients'):
        fixed_ing, ing_changes = fix_ingredients(row['ingredients'])
        if ing_changes:
            all_changes.extend([f"[ingredients] {c}" for c in ing_changes])
            row['ingredients'] = fixed_ing
            modified = True

    # 4. Check barcode
    if row.get('barcode'):
        fixed_bc, bc_changes = fix_barcode(row['barcode'])
        if bc_changes:
            all_changes.extend([f"[barcode] {c}" for c in bc_changes])

    # 5. Flag non-UK products (don't delete, just log)
    non_uk_flags = should_flag_non_uk(row)
    if non_uk_flags:
        all_changes.extend([f"[non-uk] {f}" for f in non_uk_flags])

    # 6. Flag mismatched data
    mismatch_flags = is_mismatched_data(row)
    if mismatch_flags:
        all_changes.extend([f"[mismatch] {f}" for f in mismatch_flags])

    return row, all_changes, modified


def run_cleanup(dry_run=False):
    """Run the cleanup process"""
    create_dirs()

    # Load progress
    progress = load_progress()
    processed_rows = set(progress['processed_rows'])

    print("=" * 60)
    print("UK Foods Database Cleanup")
    print(f"Mode: {'DRY RUN (no changes saved)' if dry_run else 'LIVE'}")
    print(f"Max changes this run: {MAX_CHANGES_PER_RUN}")
    print("=" * 60)

    # Determine input file
    if os.path.exists(OUTPUT_FILE):
        input_file = OUTPUT_FILE
        print(f"\nContinuing from previous cleaned file: {OUTPUT_FILE}")
    else:
        input_file = INPUT_FILE
        print(f"\nStarting fresh from: {INPUT_FILE}")

    # Load data
    print("\nLoading data...")
    data, fieldnames = load_data(input_file)
    print(f"  Loaded {len(data)} products")
    print(f"  Previously processed: {len(processed_rows)} rows")

    # Create backup before changes
    if not dry_run:
        backup = create_backup(input_file)
        if backup:
            print(f"  Backup created: {backup}")

    # Process rows
    changes_made = 0
    change_log = []
    rows_modified = []

    print(f"\nProcessing (max {MAX_CHANGES_PER_RUN} changes)...")

    for i, row in enumerate(data):
        row_num = i + 2  # CSV row number (1-indexed, skip header)

        if changes_made >= MAX_CHANGES_PER_RUN:
            print(f"\n  Reached limit of {MAX_CHANGES_PER_RUN} changes. Stopping.")
            break

        # Process the row
        fixed_row, changes, modified = process_row(row, row_num, processed_rows)

        if changes:
            changes_made += 1
            rows_modified.append(row_num)
            processed_rows.add(row_num)

            # Log the changes
            log_entry = {
                'row': row_num,
                'name': row.get('name', '')[:50],
                'changes': changes,
                'modified': modified
            }
            change_log.append(log_entry)

            # Update the data
            if modified and not dry_run:
                data[i] = fixed_row

            # Progress indicator
            if changes_made % 50 == 0:
                print(f"  Processed {changes_made} changes...")

    print(f"\n  Total changes identified: {changes_made}")

    # Save results
    if not dry_run and changes_made > 0:
        print("\nSaving cleaned data...")
        save_data(OUTPUT_FILE, data, fieldnames)
        print(f"  Saved to: {OUTPUT_FILE}")

        # Update progress
        progress['processed_rows'] = list(processed_rows)
        progress['total_changes'] += changes_made
        progress['runs'] += 1
        progress['last_run'] = datetime.now().isoformat()
        save_progress(progress)
        print(f"  Progress saved")

    # Write change log
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_filename = f"{LOG_DIR}/cleanup_log_{timestamp}.json"
    with open(log_filename, 'w', encoding='utf-8') as f:
        json.dump({
            'timestamp': timestamp,
            'dry_run': dry_run,
            'changes_count': changes_made,
            'rows_modified': rows_modified,
            'details': change_log
        }, f, indent=2)
    print(f"  Change log: {log_filename}")

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    # Count by type
    type_counts = defaultdict(int)
    warning_counts = defaultdict(int)

    for entry in change_log:
        for change in entry['changes']:
            if 'WARNING' in change or 'MISMATCH' in change:
                warning_counts[change.split(']')[0] + ']'] += 1
            else:
                type_counts[change.split(']')[0] + ']'] += 1

    print("\nChanges applied:")
    for change_type, count in sorted(type_counts.items()):
        print(f"  {change_type}: {count}")

    if warning_counts:
        print("\nWarnings (not auto-fixed, review needed):")
        for warning_type, count in sorted(warning_counts.items()):
            print(f"  {warning_type}: {count}")

    print(f"\nTotal rows touched: {changes_made}")
    print(f"Cumulative progress: {progress['total_changes']} changes over {progress['runs']} runs")

    remaining = len(data) - len(processed_rows)
    print(f"Remaining to process: ~{remaining} rows")

    if remaining > 0 and not dry_run:
        print(f"\nRun again to process next batch of up to {MAX_CHANGES_PER_RUN} changes.")

    return changes_made


def show_status():
    """Show current cleanup progress"""
    progress = load_progress()

    print("=" * 60)
    print("CLEANUP STATUS")
    print("=" * 60)
    print(f"Total runs completed: {progress['runs']}")
    print(f"Total changes made: {progress['total_changes']}")
    print(f"Rows processed: {len(progress['processed_rows'])}")
    print(f"Last run: {progress['last_run'] or 'Never'}")

    if os.path.exists(OUTPUT_FILE):
        print(f"\nCleaned file exists: {OUTPUT_FILE}")
    else:
        print(f"\nNo cleaned file yet. Will start from: {INPUT_FILE}")

    # List recent logs
    if os.path.exists(LOG_DIR):
        logs = sorted(os.listdir(LOG_DIR), reverse=True)[:5]
        if logs:
            print(f"\nRecent logs:")
            for log in logs:
                print(f"  {log}")


def reset_progress():
    """Reset cleanup progress"""
    if os.path.exists(PROGRESS_FILE):
        os.remove(PROGRESS_FILE)
        print("Progress reset.")

    if os.path.exists(OUTPUT_FILE):
        response = input(f"Delete cleaned file {OUTPUT_FILE}? (y/n): ")
        if response.lower() == 'y':
            os.remove(OUTPUT_FILE)
            print("Cleaned file deleted.")

    print("Ready to start fresh.")


# ============================================================================
# ENTRY POINT
# ============================================================================

def main():
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == '--dry-run':
            run_cleanup(dry_run=True)
        elif arg == '--status':
            show_status()
        elif arg == '--reset':
            reset_progress()
        elif arg == '--help':
            print(__doc__)
        else:
            print(f"Unknown argument: {arg}")
            print("Use --help for usage information")
    else:
        run_cleanup(dry_run=False)


if __name__ == "__main__":
    main()
