#!/usr/bin/env python3
"""
Merge the comprehensive database (15 detailed) with the consolidated database (397 total).
Result: One unified database with comprehensive fields where available, legacy fields for others.
"""

import json
from datetime import datetime

print("🔄 Merging databases...")

# Load comprehensive database (15 ultra-detailed additives)
with open('NutraSafe Beta/ingredients_comprehensive.json', 'r') as f:
    comprehensive_db = json.load(f)

# Load consolidated database (397 additives with basic info)
with open('NutraSafe Beta/ingredients_consolidated.json', 'r') as f:
    consolidated_db = json.load(f)

comprehensive_additives = {tuple(sorted(a['eNumbers'])): a for a in comprehensive_db['ingredients'] if a['eNumbers']}
comprehensive_by_name = {a['name'].lower(): a for a in comprehensive_db['ingredients']}

print(f"📚 Comprehensive: {len(comprehensive_db['ingredients'])} ultra-detailed additives")
print(f"📚 Consolidated: {len(consolidated_db['ingredients'])} total additives")

# Merge: Use comprehensive data where available, otherwise use consolidated data
merged_additives = []
comprehensive_count = 0
legacy_count = 0

for cons_add in consolidated_db['ingredients']:
    cons_enums = tuple(sorted(cons_add.get('eNumbers', [])))
    cons_name = cons_add.get('name', '').lower()

    # Check if we have comprehensive data for this additive
    comp_add = None
    if cons_enums and cons_enums in comprehensive_additives:
        comp_add = comprehensive_additives[cons_enums]
    elif cons_name in comprehensive_by_name:
        comp_add = comprehensive_by_name[cons_name]

    if comp_add:
        # Use comprehensive version
        merged_additives.append(comp_add)
        comprehensive_count += 1
    else:
        # Use consolidated version (legacy fields only)
        merged_additives.append(cons_add)
        legacy_count += 1

# Create final unified database
final_db = {
    "metadata": {
        "version": "3.1.0-unified",
        "total_ingredients": len(merged_additives),
        "comprehensive_count": comprehensive_count,
        "legacy_count": legacy_count,
        "last_updated": datetime.now().strftime("%Y-%m-%d"),
        "description": "Unified additive database combining comprehensive consumer-focused entries with legacy data",
        "sources": [
            "UK Food Standards Agency (FSA)",
            "European Food Safety Authority (EFSA)",
            "US Food and Drug Administration (FDA)",
            "WHO International Agency for Research on Cancer (IARC)",
            "Scientific peer-reviewed literature"
        ],
        "notes": f"{comprehensive_count} additives have full comprehensive fields (shortSummary, whatItIs, whereItComesFrom, etc.). Remaining {legacy_count} use legacy fields with fallback display."
    },
    "ingredients": merged_additives
}

# Save unified database
output_path = "NutraSafe Beta/ingredients_comprehensive.json"
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(final_db, f, indent=2, ensure_ascii=False)

print(f"\n✅ Created unified database: {len(merged_additives)} total additives")
print(f"   📖 Comprehensive: {comprehensive_count} (with full consumer-focused fields)")
print(f"   📄 Legacy: {legacy_count} (using basic fields)")
print(f"\n💾 Saved to: {output_path}")
print(f"\n🎯 The app will now display:")
print(f"   • Rich, detailed information for {comprehensive_count} common additives")
print(f"   • Basic information for {legacy_count} remaining additives")
print(f"   • Seamless fallback ensures ALL additives display properly")
