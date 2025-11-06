#!/usr/bin/env python3
"""
Clean up ingredients_consolidated.json database:
1. Fix empty origins
2. Add sources where missing
3. Remove duplicates
"""
import json
import re

# Default source for additives
DEFAULT_SOURCE = {
    "title": "Food Standards Agency (FSA)",
    "url": "https://www.food.gov.uk/business-guidance/approved-additives-and-e-numbers",
    "covers": "UK food additive regulations and safety information"
}

# Origin mappings for common ultra-processed ingredients
ORIGIN_MAPPINGS = {
    # Plant-based
    "barley malt extract": "plant",
    "cellulose gum": "plant",
    "dextrose": "plant",
    "high-fructose corn syrup": "plant",
    "hydrolysed protein": "plant",
    "hydrolysed vegetable protein": "plant",
    "maltodextrin": "plant",
    "modified starch": "plant",
    "vegetable oil": "plant",

    # Synthetic
    "butylated hydroxyanisole": "synthetic",
    "butylated hydroxytoluene": "synthetic",
    "hydrogenated oil": "synthetic",
    "interesterified fat": "synthetic",
    "partially hydrogenated": "synthetic",
    "trans fat": "synthetic",
}

def fix_empty_origins(data):
    """Fix ingredients with empty origin field"""
    fixed_count = 0

    for ing in data['ingredients']:
        if ing.get('origin', '') == '':
            name_lower = ing['name'].lower()

            # Try to find mapping
            origin = None
            for key, value in ORIGIN_MAPPINGS.items():
                if key in name_lower:
                    origin = value
                    break

            # Default to 'synthetic' for ultra-processed items
            if origin is None:
                origin = "synthetic"

            ing['origin'] = origin
            fixed_count += 1
            print(f"  Fixed origin for: {ing['name']} -> {origin}")

    return fixed_count

def add_missing_sources(data):
    """Add default source to ingredients without sources"""
    fixed_count = 0

    for ing in data['ingredients']:
        if not ing.get('sources') or len(ing['sources']) == 0:
            ing['sources'] = [DEFAULT_SOURCE]
            fixed_count += 1
            print(f"  Added source for: {ing['name']}")

    return fixed_count

def remove_duplicates(data):
    """Remove duplicate ingredients (same name, different spelling)"""
    seen = {}
    to_remove = []

    for i, ing in enumerate(data['ingredients']):
        # Normalize name (lowercase, remove hyphens, etc.)
        normalized = re.sub(r'[^a-z0-9]', '', ing['name'].lower())

        if normalized in seen:
            # Found duplicate
            original_idx = seen[normalized]
            original = data['ingredients'][original_idx]

            print(f"  Duplicate found:")
            print(f"    Original: {original['name']}")
            print(f"    Duplicate: {ing['name']}")

            # Merge E-numbers, synonyms, sources
            original['eNumbers'] = list(set(original['eNumbers'] + ing['eNumbers']))
            original['synonyms'] = list(set(original['synonyms'] + ing['synonyms'] + [ing['name']]))

            # Merge sources
            existing_urls = {s['url'] for s in original['sources']}
            for source in ing['sources']:
                if source['url'] not in existing_urls:
                    original['sources'].append(source)

            # Keep better data if duplicate has more info
            if not original['origin'] and ing['origin']:
                original['origin'] = ing['origin']
            if not original['overview'] and ing['overview']:
                original['overview'] = ing['overview']

            to_remove.append(i)
        else:
            seen[normalized] = i

    # Remove duplicates (in reverse order to preserve indices)
    for idx in reversed(to_remove):
        del data['ingredients'][idx]

    return len(to_remove)

def main():
    input_file = '/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafe Beta/ingredients_consolidated.json'
    output_file = input_file  # Overwrite

    print("Loading database...")
    with open(input_file, 'r') as f:
        data = json.load(f)

    original_count = len(data['ingredients'])
    print(f"Original ingredient count: {original_count}")

    print("\nFixing empty origins...")
    origins_fixed = fix_empty_origins(data)
    print(f"Fixed {origins_fixed} empty origins")

    print("\nAdding missing sources...")
    sources_added = add_missing_sources(data)
    print(f"Added sources to {sources_added} ingredients")

    print("\nRemoving duplicates...")
    duplicates_removed = remove_duplicates(data)
    print(f"Removed {duplicates_removed} duplicates")

    # Update metadata
    data['metadata']['totalCount'] = len(data['ingredients'])
    data['metadata']['last_updated'] = "2025-11-06"

    print(f"\nFinal ingredient count: {len(data['ingredients'])}")

    print(f"\nSaving to {output_file}...")
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)

    print("✅ Database cleaned successfully!")
    print(f"   - Origins fixed: {origins_fixed}")
    print(f"   - Sources added: {sources_added}")
    print(f"   - Duplicates removed: {duplicates_removed}")

if __name__ == '__main__':
    main()
