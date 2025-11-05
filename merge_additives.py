#!/usr/bin/env python3
"""
Merge CSV and JSON additive databases into a single unified JSON database.
Preserves all sources from CSV and merges with JSON data.
Maps free-form text to Swift enum values.
"""

import csv
import json
import sys
import re
from typing import Dict, List, Any

def map_to_additive_group(raw_group: str) -> str:
    """Map free-form group text to AdditiveGroup enum values."""
    group_lower = raw_group.lower().strip()

    # Direct matches
    if 'colour' in group_lower or 'color' in group_lower:
        return 'colour'
    elif 'preservative' in group_lower:
        return 'preservative'
    elif 'antioxidant' in group_lower:
        return 'antioxidant'
    elif 'emulsifier' in group_lower:
        return 'emulsifier'
    elif 'stabilizer' in group_lower or 'stabiliser' in group_lower:
        return 'stabilizer'
    elif 'thickener' in group_lower:
        return 'thickener'
    elif 'sweetener' in group_lower:
        return 'sweetener'
    elif 'flavour' in group_lower or 'flavor' in group_lower:
        return 'flavour_enhancer'
    elif 'acid' in group_lower:
        return 'acid_regulator'
    elif 'anticaking' in group_lower or 'anti-caking' in group_lower:
        return 'anticaking'
    else:
        return 'other'

def map_to_additive_category(raw_category: str) -> str:
    """Map free-form category text to AdditiveCategory enum values."""
    cat_lower = raw_category.lower().strip()

    if 'colour' in cat_lower or 'color' in cat_lower:
        return 'colour'
    elif 'preservative' in cat_lower:
        return 'preservative'
    else:
        return 'other'

def map_to_additive_origin(raw_origin: str) -> str:
    """Map free-form origin text to AdditiveOrigin enum values."""
    origin_lower = raw_origin.lower().strip()

    # Check for "varies" or multiple sources
    if 'varies' in origin_lower or ('/' in origin_lower and len(origin_lower) > 20):
        return 'synthetic/plant/mineral (varies by specification)'
    elif 'synthetic' in origin_lower or 'man-made' in origin_lower or 'artificial' in origin_lower:
        return 'synthetic'
    elif 'plant' in origin_lower or 'vegetable' in origin_lower:
        return 'plant'
    elif 'animal' in origin_lower:
        return 'animal'
    elif 'mineral' in origin_lower:
        return 'mineral'
    else:
        # Default to varies if uncertain
        return 'synthetic/plant/mineral (varies by specification)'

def map_to_additive_verdict(raw_verdict: str) -> str:
    """Map free-form verdict text to AdditiveVerdict enum values."""
    verdict_lower = raw_verdict.lower().strip()

    if 'avoid' in verdict_lower or 'banned' in verdict_lower:
        return 'avoid'
    elif 'caution' in verdict_lower or 'warning' in verdict_lower:
        return 'caution'
    else:
        return 'neutral'

def parse_csv_sources(sources_str: str) -> List[Dict[str, str]]:
    """Parse sources JSON string from CSV."""
    if not sources_str or sources_str.strip() == "":
        return []

    try:
        sources = json.loads(sources_str)
        return sources if isinstance(sources, list) else []
    except json.JSONDecodeError as e:
        print(f"⚠️  Error parsing sources: {sources_str[:100]}... Error: {e}")
        return []

def parse_csv_components(line: str) -> List[str]:
    """Parse CSV line handling quoted fields with commas."""
    components = []
    current = ""
    in_quotes = False
    i = 0

    while i < len(line):
        char = line[i]

        if in_quotes:
            if char == '"':
                # Check if next char is also a quote (escaped)
                if i + 1 < len(line) and line[i + 1] == '"':
                    current += '"'
                    i += 1  # Skip the second quote
                else:
                    in_quotes = False
            else:
                current += char
        else:
            if char == '"':
                in_quotes = True
            elif char == ',':
                components.append(current.strip())
                current = ""
            else:
                current += char

        i += 1

    # Add the last field
    components.append(current.strip())
    return components

def parse_csv_database(csv_path: str) -> Dict[str, Dict[str, Any]]:
    """Parse CSV database and return dict of additives by E-number."""
    additives = {}

    with open(csv_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

        # Skip title row and header row (lines 0 and 1)
        for line in lines[2:]:
            if not line.strip():
                continue

            components = parse_csv_components(line)
            if len(components) < 16:
                continue

            e_number = components[0].strip()
            name = components[1].strip()

            # Get sources from column 20 (index 19)
            sources = []
            if len(components) > 19:
                sources = parse_csv_sources(components[19])

            # Parse synonyms from column 17 (index 16)
            synonyms = []
            if len(components) > 16:
                raw_synonyms = components[16].split(';')
                synonyms = [s.strip() for s in raw_synonyms if s.strip() and s.strip() != e_number and s.strip().lower() != name.lower()]

            # Map raw CSV text to enum values
            raw_group = components[2].strip() if len(components) > 2 else "other"
            raw_origin = components[11].strip() if len(components) > 11 else "unknown"
            raw_verdict = components[15].strip() if len(components) > 15 else "neutral"

            additives[e_number] = {
                "id": e_number,  # Add id field for Swift Identifiable conformance
                "eNumber": e_number,
                "name": name,
                "group": map_to_additive_group(raw_group),  # Map to enum value
                "category": map_to_additive_category(raw_group),  # Map to enum value
                "origin": map_to_additive_origin(raw_origin),  # Map to enum value
                "overview": components[12].strip() if len(components) > 12 else "",  # overview column
                "typicalUses": components[13].strip() if len(components) > 13 else "",  # typical_uses column
                "effectsVerdict": map_to_additive_verdict(raw_verdict),  # Map to enum value
                "effectsSummary": components[14].strip() if len(components) > 14 else "",  # effects_summary column
                "hasChildWarning": components[7].strip().lower() == 'true' if len(components) > 7 else False,  # child_warning column
                "hasPKUWarning": components[8].strip().lower() == 'true' if len(components) > 8 else False,  # PKU_warning column
                "hasSulphitesAllergenLabel": components[10].strip().lower() == 'true' if len(components) > 10 else False,  # sulphites_allergen_label column
                "hasPolyolsWarning": components[9].strip().lower() == 'true' if len(components) > 9 else False,  # polyols_warning column
                "isPermittedGB": components[3].strip().lower() != 'false' if len(components) > 3 else True,  # permitted_GB column
                "isPermittedNI": components[4].strip().lower() != 'false' if len(components) > 4 else True,  # permitted_NI column
                "isPermittedEU": components[5].strip().lower() != 'false' if len(components) > 5 else True,  # permitted_EU column
                "synonyms": synonyms,
                "sources": sources,
                "statusNotes": components[6].strip() if len(components) > 6 and components[6].strip() else None,  # status_notes column
                "insNumber": components[18].strip() if len(components) > 18 and components[18].strip() else None,  # ins_number column
                "consumerInfo": None
            }

    return additives

def parse_json_database(json_path: str) -> Dict[str, Dict[str, Any]]:
    """Parse JSON database and return dict of additives by E-number."""
    additives = {}

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Navigate through nested categories structure
    if "categories" in data:
        for category_name, category_data in data["categories"].items():
            for range_name, range_data in category_data.items():
                for e_number, additive_data in range_data.items():
                    name = additive_data.get("name", "")
                    origin = additive_data.get("origin", "unknown")
                    uses = additive_data.get("uses", "")
                    safety = additive_data.get("safety", "neutral")
                    concerns = additive_data.get("concerns", "")
                    synonyms = additive_data.get("synonyms", [])

                    # Map to enum values using same functions
                    additives[e_number] = {
                        "id": e_number,  # Add id field for Swift Identifiable conformance
                        "eNumber": e_number,
                        "name": name,
                        "group": map_to_additive_group(category_name),  # Map to enum
                        "category": map_to_additive_category(category_name),  # Map to enum
                        "origin": map_to_additive_origin(origin),  # Map to enum
                        "overview": "",
                        "typicalUses": uses,
                        "effectsVerdict": map_to_additive_verdict(safety),  # Map to enum
                        "effectsSummary": concerns if concerns else "Generally recognized as safe when used as directed.",
                        "hasChildWarning": "child" in concerns.lower() or "hyperactivity" in concerns.lower(),
                        "hasPKUWarning": "pku" in concerns.lower() or "phenylketonuria" in concerns.lower(),
                        "hasSulphitesAllergenLabel": "sulphite" in concerns.lower() or "sulfite" in concerns.lower(),
                        "hasPolyolsWarning": "polyol" in concerns.lower() or "laxative" in concerns.lower(),
                        "isPermittedGB": "banned" not in concerns.lower(),
                        "isPermittedNI": "banned" not in concerns.lower(),
                        "isPermittedEU": "banned" not in concerns.lower(),
                        "synonyms": synonyms if isinstance(synonyms, list) else [],
                        "sources": [],  # JSON doesn't have sources
                        "statusNotes": concerns if "banned" in concerns.lower() else None,
                        "insNumber": None,
                        "consumerInfo": None
                    }

    return additives

def merge_databases(csv_additives: Dict[str, Dict], json_additives: Dict[str, Dict]) -> List[Dict[str, Any]]:
    """Merge CSV and JSON databases, preferring CSV data when available."""
    merged = {}

    # Start with CSV additives (they have sources)
    for e_number, data in csv_additives.items():
        merged[e_number] = data
        print(f"✅ CSV: {e_number} - {data['name']} ({len(data['sources'])} sources)")

    # Add JSON additives that aren't in CSV
    for e_number, data in json_additives.items():
        if e_number not in merged:
            merged[e_number] = data
            print(f"➕ JSON: {e_number} - {data['name']} (new)")
        else:
            # If JSON has better data, update specific fields
            # But keep CSV sources!
            print(f"🔄 Exists: {e_number} - keeping CSV version with sources")

    # Convert to sorted list
    additive_list = list(merged.values())
    additive_list.sort(key=lambda x: x['eNumber'])

    return additive_list

def create_unified_json(additives: List[Dict[str, Any]], output_path: str):
    """Create unified JSON file with metadata."""
    unified = {
        "metadata": {
            "version": "2025.4-unified",
            "total_additives": len(additives),
            "last_updated": "2025-11-04",
            "description": "Unified food additives database merging CSV and JSON sources with complete citation data",
            "source": "Merged from additives_full_described_with_sources_2025.csv and additives_master_database.json"
        },
        "additives": additives
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(unified, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Created unified database: {output_path}")
    print(f"📊 Total additives: {len(additives)}")

    # Count sources
    with_sources = sum(1 for a in additives if a['sources'])
    total_sources = sum(len(a['sources']) for a in additives)
    print(f"📚 Additives with sources: {with_sources}")
    print(f"📖 Total source citations: {total_sources}")

def main():
    base_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafe Beta"
    csv_path = f"{base_path}/additives_full_described_with_sources_2025.csv"
    json_path = f"{base_path}/additives_master_database.json"
    output_path = f"{base_path}/additives_unified.json"

    print("🔄 Merging additive databases...\n")

    # Parse CSV
    print("📄 Parsing CSV database...")
    csv_additives = parse_csv_database(csv_path)
    print(f"✅ Loaded {len(csv_additives)} additives from CSV\n")

    # Parse JSON
    print("📄 Parsing JSON database...")
    json_additives = parse_json_database(json_path)
    print(f"✅ Loaded {len(json_additives)} additives from JSON\n")

    # Merge
    print("🔄 Merging databases...\n")
    merged_additives = merge_databases(csv_additives, json_additives)

    # Create unified JSON
    print("\n💾 Creating unified JSON file...")
    create_unified_json(merged_additives, output_path)

    print("\n✨ Done! Unified database created successfully.")

if __name__ == "__main__":
    main()
