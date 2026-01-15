#!/usr/bin/env python3
"""
UK Foods Database Quality Audit Script
Identifies data quality issues for cleanup
"""

import csv
import re
import os
from collections import defaultdict, Counter
from datetime import datetime

# Configuration
INPUT_FILE = "uk_foods_complete copy.csv"
OUTPUT_DIR = "audit_reports"

# Foreign language patterns
FOREIGN_PATTERNS = {
    'French': [
        r'\bsucrés\b', r'\bsalés\b', r'\bProduits laitiers\b', r'\bCompléments alimentaires\b',
        r'\bBoissons\b', r'\bfromage\b', r'\bgâteau\b', r'\bchocolat\b', r'\bNouilles\b',
        r'\bProduits fermentés\b', r'\bConfiseries\b'
    ],
    'German': [
        r'\bImbiss\b', r'\bSchokolade\b', r'\bKäse\b', r'\bMilch\b', r'\bZucker\b',
        r'\bGetränke\b', r'\bKekse und Kuchen\b', r'\bKakao\b', r'\bSüßigkeiten\b'
    ],
    'Spanish': [
        r'\bBotanas\b', r'\bSnacks dulces\b', r'\bSnacks salados\b', r'\bAlimentos\b'
    ],
    'Turkish': [
        r'\bBisküvi\b', r'\bÇikolata\b', r'\bşeker\b'
    ],
    'Other': [
        r'\bfr:\w+', r'\bde:\w+', r'\bes:\w+', r'\bit:\w+'
    ]
}

# OCR error patterns
OCR_ERRORS = {
    'Cluten': 'Gluten',
    'Clucose': 'Glucose',
    'Bliacin': 'Niacin',
    'Calctum': 'Calcium',
    'Hocolate': 'Chocolate',
    'Ingredlents': 'Ingredients',
    'Cround': 'Ground',
    'Crain': 'Grain',
    'Seit': 'Salt',
    'Sait': 'Salt',
    'Flou ': 'Flour ',
    'Oll': 'Oil',
    'Suger': 'Sugar',
    'Coiour': 'Colour',
    'Fiavour': 'Flavour',
    'Biack': 'Black',
    'Giuten': 'Gluten'
}

# Malformed name patterns
MALFORMED_NAME_PATTERNS = [
    r'^Serving Contains',
    r'^[0-9]{8,}$',  # Just a barcode
    r'^[0-9]+ [A-Z]{2}',  # Starts with numbers and letters
    r'-food-',  # M&S OCR artefact
    r'Si$',  # Truncated
    r'Sainsb$',  # Truncated
    r'^[A-Z]{2,4} [A-Z]{2,4} [A-Z]',  # Random capitals
    r'^\d+ \d+ \d+',  # Multiple numbers
    r';nut',  # OCR artefact
    r'\.nut',  # OCR artefact
    r'\{nut',  # OCR artefact
]

# Category prefix patterns (OpenFoodFacts style)
CATEGORY_PREFIXES = [
    r'en:[a-z-]+',
    r'fr:[a-z-]+',
    r'de:[a-z-]+',
    r'es:[a-z-]+',
    r'ms:[a-z-]+',
]


def create_output_dir():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)


def load_data(filename):
    """Load CSV data into list of dictionaries"""
    data = []
    with open(filename, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader, start=2):  # Start at 2 (1 is header)
            row['_row_num'] = i
            data.append(row)
    return data


def check_foreign_language(data):
    """Find products with foreign language content"""
    issues = defaultdict(list)

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')
        category = row.get('category', '')
        ingredients = row.get('ingredients', '')

        text_to_check = f"{name} {category} {ingredients}"

        for language, patterns in FOREIGN_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, text_to_check, re.IGNORECASE):
                    issues[language].append({
                        'row': row_num,
                        'name': name[:60],
                        'category': category[:40],
                        'pattern_matched': pattern
                    })
                    break

    return issues


def check_malformed_names(data):
    """Find products with malformed/garbage names"""
    issues = []

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')

        for pattern in MALFORMED_NAME_PATTERNS:
            if re.search(pattern, name):
                issues.append({
                    'row': row_num,
                    'name': name[:80],
                    'pattern': pattern,
                    'brand': row.get('brand', '')
                })
                break

    return issues


def check_ocr_errors(data):
    """Find products with OCR spelling errors"""
    issues = []

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')
        ingredients = row.get('ingredients', '')

        text_to_check = f"{name} {ingredients}"
        errors_found = []

        for error, correction in OCR_ERRORS.items():
            if error in text_to_check:
                errors_found.append(f"{error}->{correction}")

        if errors_found:
            issues.append({
                'row': row_num,
                'name': name[:50],
                'errors': ', '.join(errors_found)
            })

    return issues


def check_missing_fields(data):
    """Find products with missing required fields"""
    issues = {
        'missing_brand': [],
        'missing_category': [],
        'missing_calories': [],
        'missing_ingredients': [],
        'undefined_category': []
    }

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')[:50]

        if not row.get('brand', '').strip():
            issues['missing_brand'].append({'row': row_num, 'name': name})

        if not row.get('category', '').strip():
            issues['missing_category'].append({'row': row_num, 'name': name})

        if not row.get('calories', '').strip():
            issues['missing_calories'].append({'row': row_num, 'name': name})

        if not row.get('ingredients', '').strip():
            issues['missing_ingredients'].append({'row': row_num, 'name': name})

        if row.get('category', '').strip().lower() == 'undefined':
            issues['undefined_category'].append({'row': row_num, 'name': name})

    return issues


def check_invalid_barcodes(data):
    """Find products with invalid barcodes"""
    issues = {
        'too_long': [],
        'too_short': [],
        'non_numeric': [],
        'barcode_as_name': []
    }

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')
        barcode = row.get('barcode', '').strip()

        if barcode:
            # Check if barcode is numeric
            if not barcode.isdigit():
                issues['non_numeric'].append({
                    'row': row_num,
                    'name': name[:40],
                    'barcode': barcode[:30]
                })
            else:
                # Check length (valid: 8, 12, 13, 14 digits)
                if len(barcode) > 14:
                    issues['too_long'].append({
                        'row': row_num,
                        'name': name[:40],
                        'barcode': barcode,
                        'length': len(barcode)
                    })
                elif len(barcode) < 8:
                    issues['too_short'].append({
                        'row': row_num,
                        'name': name[:40],
                        'barcode': barcode,
                        'length': len(barcode)
                    })

        # Check if name is just a barcode
        if name.strip().isdigit() and len(name.strip()) >= 8:
            issues['barcode_as_name'].append({
                'row': row_num,
                'name': name,
                'barcode': barcode
            })

    return issues


def check_duplicates(data):
    """Find duplicate product names"""
    name_counts = Counter(row.get('name', '') for row in data)

    duplicates = []
    for name, count in name_counts.most_common():
        if count > 1 and name.strip():
            rows = [row['_row_num'] for row in data if row.get('name', '') == name]
            duplicates.append({
                'name': name[:60],
                'count': count,
                'rows': rows[:10]  # First 10 rows
            })

    return duplicates


def check_nutritional_values(data):
    """Find products with implausible nutritional values"""
    issues = {
        'high_calories': [],  # >900 per 100g
        'high_sodium': [],    # >1000mg per 100g
        'high_sugar': [],     # >100g per 100g (impossible)
        'negative_values': []
    }

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')[:40]

        try:
            calories = float(row.get('calories', 0) or 0)
            if calories > 900:
                issues['high_calories'].append({
                    'row': row_num,
                    'name': name,
                    'calories': calories
                })
            if calories < 0:
                issues['negative_values'].append({
                    'row': row_num,
                    'name': name,
                    'field': 'calories',
                    'value': calories
                })
        except (ValueError, TypeError):
            pass

        try:
            sodium = float(row.get('sodium', 0) or 0)
            if sodium > 1000:
                issues['high_sodium'].append({
                    'row': row_num,
                    'name': name,
                    'sodium': sodium
                })
        except (ValueError, TypeError):
            pass

        try:
            sugar = float(row.get('sugar', 0) or 0)
            if sugar > 100:
                issues['high_sugar'].append({
                    'row': row_num,
                    'name': name,
                    'sugar': sugar
                })
        except (ValueError, TypeError):
            pass

    return issues


def check_category_formats(data):
    """Find inconsistent category formats"""
    issues = {
        'with_prefix': [],      # en:, fr:, etc.
        'hyphenated': [],       # plant-based-foods
        'mixed_language': [],   # English, French in same field
        'lowercase_only': []    # all lowercase
    }

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '')[:40]
        category = row.get('category', '')

        if not category:
            continue

        # Check for prefixes
        for prefix_pattern in CATEGORY_PREFIXES:
            if re.search(prefix_pattern, category):
                issues['with_prefix'].append({
                    'row': row_num,
                    'name': name,
                    'category': category[:50]
                })
                break

        # Check for hyphenated style
        if re.search(r'[a-z]+-[a-z]+-[a-z]+', category):
            issues['hyphenated'].append({
                'row': row_num,
                'name': name,
                'category': category[:50]
            })

    return issues


def check_mismatched_data(data):
    """Find products where name doesn't match ingredients"""
    issues = []

    # Keywords that indicate product type
    fish_keywords = ['haddock', 'salmon', 'cod', 'fish', 'prawn', 'seafood', 'tuna', 'mackerel']
    sweet_keywords = ['chocolate', 'cocoa', 'sugar', 'syrup', 'caramel', 'fudge', 'cake', 'cookie']
    meat_keywords = ['beef', 'chicken', 'pork', 'lamb', 'turkey', 'ham', 'bacon', 'sausage']
    veg_keywords = ['vegetarian', 'vegan', 'plant-based', 'meat-free']

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '').lower()
        ingredients = row.get('ingredients', '').lower()

        if not ingredients:
            continue

        # Check for fish products with sweet ingredients (no fish)
        if any(kw in name for kw in fish_keywords):
            has_fish_ingredient = any(kw in ingredients for kw in fish_keywords)
            has_sweet_ingredient = sum(1 for kw in sweet_keywords if kw in ingredients) >= 3

            if not has_fish_ingredient and has_sweet_ingredient:
                issues.append({
                    'row': row_num,
                    'name': row.get('name', '')[:50],
                    'issue': 'Fish product name but sweet/dessert ingredients',
                    'sample_ingredients': ingredients[:100]
                })

        # Check for meat in vegetarian products
        if any(kw in name for kw in veg_keywords):
            meat_found = [kw for kw in meat_keywords if kw in ingredients and kw not in name]
            if meat_found:
                issues.append({
                    'row': row_num,
                    'name': row.get('name', '')[:50],
                    'issue': f'Vegetarian product contains: {", ".join(meat_found)}',
                    'sample_ingredients': ingredients[:100]
                })

    return issues


def check_non_uk_products(data):
    """Find products likely not intended for UK market"""
    issues = []

    # US brand indicators
    us_brands = ['spartan', 'wegmans', 'key food', 'kroger', 'safeway', 'publix', 'trader joe']
    us_ingredient_patterns = [
        r'ENRICHED.*FLOUR.*FOLIC ACID',  # US fortification
        r'INS\d{3}',  # Indian additive codes
        r'CONTAINS.*PHENYLALANINE',  # US FDA warning
        r'USDA',
    ]

    for row in data:
        row_num = row['_row_num']
        name = row.get('name', '').lower()
        brand = row.get('brand', '').lower()
        ingredients = row.get('ingredients', '')

        # Check US brands
        for us_brand in us_brands:
            if us_brand in brand or us_brand in name:
                issues.append({
                    'row': row_num,
                    'name': row.get('name', '')[:50],
                    'brand': row.get('brand', ''),
                    'reason': f'US brand detected: {us_brand}'
                })
                break

        # Check US-style ingredients
        for pattern in us_ingredient_patterns:
            if re.search(pattern, ingredients, re.IGNORECASE):
                issues.append({
                    'row': row_num,
                    'name': row.get('name', '')[:50],
                    'brand': row.get('brand', ''),
                    'reason': f'US-style ingredient labeling: {pattern}'
                })
                break

    return issues


def write_report(filename, title, data, headers):
    """Write a CSV report"""
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        for item in data:
            # Filter to only include specified headers
            filtered_item = {k: v for k, v in item.items() if k in headers}
            writer.writerow(filtered_item)
    print(f"  Written: {filepath} ({len(data)} rows)")


def write_summary(all_issues):
    """Write a summary report"""
    filepath = os.path.join(OUTPUT_DIR, "00_SUMMARY.txt")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write("=" * 70 + "\n")
        f.write("UK FOODS DATABASE - DATA QUALITY AUDIT SUMMARY\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 70 + "\n\n")

        for category, issues in all_issues.items():
            f.write(f"\n{category}\n")
            f.write("-" * 50 + "\n")

            if isinstance(issues, dict):
                for sub_cat, sub_issues in issues.items():
                    count = len(sub_issues) if isinstance(sub_issues, list) else sub_issues
                    f.write(f"  {sub_cat}: {count}\n")
            elif isinstance(issues, list):
                f.write(f"  Total: {len(issues)}\n")
            else:
                f.write(f"  Total: {issues}\n")

        f.write("\n" + "=" * 70 + "\n")
        f.write("See individual CSV files for detailed row-by-row listings.\n")

    print(f"  Written: {filepath}")


def main():
    print("=" * 60)
    print("UK Foods Database Quality Audit")
    print("=" * 60)

    create_output_dir()

    print("\nLoading data...")
    data = load_data(INPUT_FILE)
    print(f"  Loaded {len(data)} products")

    all_issues = {}

    # 1. Foreign Language
    print("\nChecking for foreign language content...")
    foreign = check_foreign_language(data)
    all_issues['FOREIGN_LANGUAGE'] = {lang: len(items) for lang, items in foreign.items()}
    for lang, items in foreign.items():
        if items:
            write_report(
                f"01_foreign_language_{lang.lower()}.csv",
                f"Foreign Language - {lang}",
                items,
                ['row', 'name', 'category', 'pattern_matched']
            )

    # 2. Malformed Names
    print("\nChecking for malformed product names...")
    malformed = check_malformed_names(data)
    all_issues['MALFORMED_NAMES'] = len(malformed)
    write_report(
        "02_malformed_names.csv",
        "Malformed Product Names",
        malformed,
        ['row', 'name', 'brand', 'pattern']
    )

    # 3. OCR Errors
    print("\nChecking for OCR spelling errors...")
    ocr = check_ocr_errors(data)
    all_issues['OCR_ERRORS'] = len(ocr)
    write_report(
        "03_ocr_errors.csv",
        "OCR Spelling Errors",
        ocr,
        ['row', 'name', 'errors']
    )

    # 4. Missing Fields
    print("\nChecking for missing required fields...")
    missing = check_missing_fields(data)
    all_issues['MISSING_FIELDS'] = {k: len(v) for k, v in missing.items()}
    for field_type, items in missing.items():
        if items:
            write_report(
                f"04_{field_type}.csv",
                f"Missing Field - {field_type}",
                items,
                ['row', 'name']
            )

    # 5. Invalid Barcodes
    print("\nChecking for invalid barcodes...")
    barcodes = check_invalid_barcodes(data)
    all_issues['INVALID_BARCODES'] = {k: len(v) for k, v in barcodes.items()}
    for issue_type, items in barcodes.items():
        if items:
            headers = ['row', 'name', 'barcode']
            if 'length' in items[0]:
                headers.append('length')
            write_report(
                f"05_barcode_{issue_type}.csv",
                f"Invalid Barcode - {issue_type}",
                items,
                headers
            )

    # 6. Duplicates
    print("\nChecking for duplicate entries...")
    duplicates = check_duplicates(data)
    all_issues['DUPLICATES'] = len([d for d in duplicates if d['count'] > 2])
    write_report(
        "06_duplicates.csv",
        "Duplicate Product Names",
        duplicates[:500],  # Top 500
        ['name', 'count', 'rows']
    )

    # 7. Nutritional Values
    print("\nChecking for implausible nutritional values...")
    nutrition = check_nutritional_values(data)
    all_issues['NUTRITIONAL_ISSUES'] = {k: len(v) for k, v in nutrition.items()}
    for issue_type, items in nutrition.items():
        if items:
            headers = ['row', 'name']
            if items and len(items) > 0:
                headers.extend([k for k in items[0].keys() if k not in headers])
            write_report(
                f"07_nutrition_{issue_type}.csv",
                f"Nutritional Issue - {issue_type}",
                items,
                headers
            )

    # 8. Category Formats
    print("\nChecking for inconsistent category formats...")
    categories = check_category_formats(data)
    all_issues['CATEGORY_FORMAT_ISSUES'] = {k: len(v) for k, v in categories.items()}
    for issue_type, items in categories.items():
        if items:
            write_report(
                f"08_category_{issue_type}.csv",
                f"Category Format - {issue_type}",
                items,
                ['row', 'name', 'category']
            )

    # 9. Mismatched Data
    print("\nChecking for mismatched name/ingredients...")
    mismatched = check_mismatched_data(data)
    all_issues['MISMATCHED_DATA'] = len(mismatched)
    write_report(
        "09_mismatched_data.csv",
        "Mismatched Name/Ingredients",
        mismatched,
        ['row', 'name', 'issue', 'sample_ingredients']
    )

    # 10. Non-UK Products
    print("\nChecking for non-UK products...")
    non_uk = check_non_uk_products(data)
    all_issues['NON_UK_PRODUCTS'] = len(non_uk)
    write_report(
        "10_non_uk_products.csv",
        "Non-UK Products",
        non_uk,
        ['row', 'name', 'brand', 'reason']
    )

    # Write summary
    print("\nWriting summary report...")
    write_summary(all_issues)

    print("\n" + "=" * 60)
    print("AUDIT COMPLETE")
    print(f"Reports saved to: {OUTPUT_DIR}/")
    print("=" * 60)

    # Print quick summary
    print("\nQUICK SUMMARY:")
    print(f"  Foreign Language: {sum(all_issues['FOREIGN_LANGUAGE'].values())} products")
    print(f"  Malformed Names: {all_issues['MALFORMED_NAMES']} products")
    print(f"  OCR Errors: {all_issues['OCR_ERRORS']} products")
    print(f"  Missing Calories: {all_issues['MISSING_FIELDS']['missing_calories']} products")
    print(f"  Missing Brand: {all_issues['MISSING_FIELDS']['missing_brand']} products")
    print(f"  Invalid Barcodes: {sum(all_issues['INVALID_BARCODES'].values())} products")
    print(f"  Duplicates (>2): {all_issues['DUPLICATES']} unique names")
    print(f"  Mismatched Data: {all_issues['MISMATCHED_DATA']} products")
    print(f"  Non-UK Products: {all_issues['NON_UK_PRODUCTS']} products")


if __name__ == "__main__":
    main()
