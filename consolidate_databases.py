#!/usr/bin/env python3
"""
Database Consolidation Script
Merges additives_unified.json and ultra_processed_ingredients.json
Deduplicates by ingredient name and consolidates all E-numbers
"""

import json
from typing import Dict, List, Set, Any
from collections import defaultdict

def load_additives_unified(filepath: str) -> List[Dict]:
    """Load the regular additives database"""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data.get('additives', [])

def load_ultra_processed(filepath: str) -> List[Dict]:
    """Load the ultra-processed ingredients database"""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Convert nested structure to flat list
    ingredients = []
    ultra_data = data.get('ultra_processed_ingredients', {})
    for category, items in ultra_data.items():
        for key, ingredient in items.items():
            ingredient['database_category'] = category
            ingredients.append(ingredient)
    return ingredients

def normalize_name(name: str) -> str:
    """Normalize ingredient name for comparison"""
    return name.lower().strip()

def is_basic_ingredient(name: str) -> bool:
    """Check if this is a basic cooking ingredient that should be excluded"""
    name_lower = name.lower().strip()

    # Basic ingredients to exclude
    basic_ingredients = {
        "salt", "sea salt", "table salt", "rock salt", "himalayan salt",
        "sugar", "cane sugar", "brown sugar", "white sugar", "granulated sugar",
        "water", "filtered water", "spring water",
        "flour", "wheat flour", "plain flour", "self-raising flour", "white flour", "wholemeal flour",
        "butter", "unsalted butter", "salted butter",
        "milk", "whole milk", "skimmed milk", "semi-skimmed milk",
        "cream", "double cream", "single cream", "whipping cream",
        "oil", "olive oil", "vegetable oil", "sunflower oil", "rapeseed oil", "coconut oil",
        "egg", "eggs", "free range egg", "free range eggs",
        "baking powder", "baking soda", "bicarbonate of soda",
        "yeast", "dried yeast", "fresh yeast", "active yeast",
        "vanilla", "vanilla extract", "vanilla essence",
        "pepper", "black pepper", "white pepper", "ground pepper",
        "vinegar", "white vinegar", "malt vinegar", "balsamic vinegar",
        "honey", "natural honey"
    }

    return name_lower in basic_ingredients

def consolidate_by_name(additives: List[Dict], ultra_processed: List[Dict]) -> Dict[str, Dict]:
    """Consolidate all ingredients by name, merging duplicates"""
    consolidated = {}

    # Process regular additives first
    for additive in additives:
        # Skip basic ingredients
        if is_basic_ingredient(additive['name']):
            continue

        name = normalize_name(additive['name'])

        if name not in consolidated:
            # Create unified structure
            consolidated[name] = {
                'name': additive['name'],  # Use original capitalization
                'eNumbers': [additive['eNumber']] if additive.get('eNumber') else [],
                'category': additive.get('category', 'unknown'),
                'group': additive.get('group', additive.get('category', 'unknown')),
                'origin': additive.get('origin', ''),
                'overview': additive.get('overview', ''),
                'what_it_is': additive.get('overview', ''),  # Map overview to what_it_is
                'why_its_used': additive.get('typicalUses', ''),
                'where_it_comes_from': additive.get('origin', ''),
                'typicalUses': additive.get('typicalUses', ''),
                'effectsVerdict': additive.get('effectsVerdict', 'neutral'),
                'effectsSummary': additive.get('effectsSummary', ''),
                'concerns': additive.get('effectsSummary', ''),  # Map effectsSummary to concerns
                'hasChildWarning': additive.get('hasChildWarning', False),
                'hasPKUWarning': additive.get('hasPKUWarning', False),
                'hasSulphitesAllergenLabel': additive.get('hasSulphitesAllergenLabel', False),
                'hasPolyolsWarning': additive.get('hasPolyolsWarning', False),
                'isPermittedGB': additive.get('isPermittedGB', True),
                'isPermittedNI': additive.get('isPermittedNI', True),
                'isPermittedEU': additive.get('isPermittedEU', True),
                'synonyms': additive.get('synonyms', []),
                'sources': additive.get('sources', []),
                'processingPenalty': 0,  # Default for regular additives
                'novaGroup': 0,  # Default for regular additives
                'database_origin': 'additives_unified'
            }
        else:
            # Merge E-number if different
            if additive.get('eNumber') and additive['eNumber'] not in consolidated[name]['eNumbers']:
                consolidated[name]['eNumbers'].append(additive['eNumber'])
            # Merge synonyms
            for syn in additive.get('synonyms', []):
                if syn not in consolidated[name]['synonyms']:
                    consolidated[name]['synonyms'].append(syn)
            # Merge sources
            for source in additive.get('sources', []):
                if source not in consolidated[name]['sources']:
                    consolidated[name]['sources'].append(source)

    # Process ultra-processed ingredients
    for ingredient in ultra_processed:
        # Skip basic ingredients
        if is_basic_ingredient(ingredient['name']):
            continue

        name = normalize_name(ingredient['name'])

        # Extract E-numbers from synonyms
        e_numbers = [s for s in ingredient.get('synonyms', []) if s.startswith('E') and len(s) <= 5]

        if name not in consolidated:
            # Create new entry
            consolidated[name] = {
                'name': ingredient['name'],
                'eNumbers': e_numbers,
                'category': ingredient.get('category', 'unknown'),
                'group': ingredient.get('category', 'unknown'),
                'origin': '',
                'overview': ingredient.get('what_it_is', ''),
                'what_it_is': ingredient.get('what_it_is', ''),
                'why_its_used': ingredient.get('why_its_used', ''),
                'where_it_comes_from': ingredient.get('where_it_comes_from', ''),
                'typicalUses': ingredient.get('why_its_used', ''),
                'effectsVerdict': 'caution' if ingredient.get('processing_penalty', 0) > 10 else 'neutral',
                'effectsSummary': ingredient.get('concerns', ''),
                'concerns': ingredient.get('concerns', ''),
                'hasChildWarning': False,
                'hasPKUWarning': False,
                'hasSulphitesAllergenLabel': False,
                'hasPolyolsWarning': False,
                'isPermittedGB': True,
                'isPermittedNI': True,
                'isPermittedEU': True,
                'synonyms': ingredient.get('synonyms', []),
                'sources': ingredient.get('sources', []),
                'processingPenalty': ingredient.get('processing_penalty', 0),
                'novaGroup': ingredient.get('nova_group', 4),
                'database_origin': 'ultra_processed'
            }
        else:
            # Merge with existing entry
            for e_num in e_numbers:
                if e_num not in consolidated[name]['eNumbers']:
                    consolidated[name]['eNumbers'].append(e_num)

            # If ultra-processed has better info, use it
            if ingredient.get('what_it_is') and not consolidated[name]['what_it_is']:
                consolidated[name]['what_it_is'] = ingredient['what_it_is']
            if ingredient.get('why_its_used') and not consolidated[name]['why_its_used']:
                consolidated[name]['why_its_used'] = ingredient['why_its_used']
            if ingredient.get('where_it_comes_from') and not consolidated[name]['where_it_comes_from']:
                consolidated[name]['where_it_comes_from'] = ingredient['where_it_comes_from']

            # Merge synonyms
            for syn in ingredient.get('synonyms', []):
                if syn not in consolidated[name]['synonyms']:
                    consolidated[name]['synonyms'].append(syn)

            # Merge sources
            for source in ingredient.get('sources', []):
                if source not in consolidated[name]['sources']:
                    consolidated[name]['sources'].append(source)

            # Update penalties if from ultra-processed
            if ingredient.get('processing_penalty', 0) > consolidated[name]['processingPenalty']:
                consolidated[name]['processingPenalty'] = ingredient['processing_penalty']
            if ingredient.get('nova_group', 0) > consolidated[name]['novaGroup']:
                consolidated[name]['novaGroup'] = ingredient['nova_group']
                consolidated[name]['database_origin'] = 'both'

    # Sort E-numbers for each entry
    for entry in consolidated.values():
        entry['eNumbers'] = sorted(set(entry['eNumbers']))

    return consolidated

def main():
    print("Loading databases...")
    additives = load_additives_unified('NutraSafe Beta/additives_unified.json')
    ultra = load_ultra_processed('NutraSafe Beta/ultra_processed_ingredients.json')

    print(f"Loaded {len(additives)} regular additives")
    print(f"Loaded {len(ultra)} ultra-processed ingredients")

    print("\nConsolidating by name...")
    consolidated = consolidate_by_name(additives, ultra)

    print(f"Consolidated to {len(consolidated)} unique ingredients")

    # Convert to list and sort by name
    ingredients_list = sorted(consolidated.values(), key=lambda x: x['name'])

    # Create output structure
    output = {
        'metadata': {
            'version': '2025.5-unified-consolidated',
            'total_ingredients': len(ingredients_list),
            'last_updated': '2025-11-05',
            'description': 'Unified and consolidated database of food additives and ultra-processed ingredients with complete deduplication by name',
            'sources': [
                'additives_full_described_with_sources_2025.csv',
                'additives_master_database.json',
                'ultra_processed_ingredients.json'
            ]
        },
        'ingredients': ingredients_list
    }

    # Save consolidated database
    output_path = 'NutraSafe Beta/ingredients_consolidated.json'
    print(f"\nSaving to {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print("✅ Database consolidation complete!")

    # Print some statistics
    print("\n=== Statistics ===")
    with_enumbers = sum(1 for ing in ingredients_list if ing['eNumbers'])
    multi_enumbers = sum(1 for ing in ingredients_list if len(ing['eNumbers']) > 1)
    with_sources = sum(1 for ing in ingredients_list if ing['sources'])
    with_complete_info = sum(1 for ing in ingredients_list if ing['what_it_is'] and ing['why_its_used'])

    print(f"Ingredients with E-numbers: {with_enumbers}")
    print(f"Ingredients with multiple E-numbers: {multi_enumbers}")
    print(f"Ingredients with sources: {with_sources}")
    print(f"Ingredients with complete info: {with_complete_info}")

    # Show examples of consolidated entries
    print("\n=== Examples of consolidated entries ===")
    multi_e_examples = [ing for ing in ingredients_list if len(ing['eNumbers']) > 1][:3]
    for ing in multi_e_examples:
        print(f"\n{ing['name']}: {', '.join(ing['eNumbers'])}")

if __name__ == '__main__':
    main()
