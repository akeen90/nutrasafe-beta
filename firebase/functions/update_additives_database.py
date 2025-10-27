#!/usr/bin/env python3
"""
Update additives_master_database.json with missing common additives
and enhanced synonyms for better detection
"""

import json
import sys

def update_database(db_path):
    # Load existing database
    with open(db_path, 'r') as f:
        db = json.load(f)

    print(f"✅ Loaded database with {db['metadata']['total_additives']} additives")

    # Track changes
    changes = []

    # 1. Update E322 (Lecithin) to add "lecithin" as a synonym
    if 'E322' in db['categories']['emulsifiers']['E300-E399']:
        e322 = db['categories']['emulsifiers']['E300-E399']['E322']
        if 'lecithin' not in [s.lower() for s in e322['synonyms']]:
            e322['synonyms'].append('Lecithin')
            changes.append('Added "Lecithin" synonym to E322')

    # 2. Add E330 synonym for "citric acid" (without E)
    if 'E330' in db['categories']['antioxidants']['E300-E399']:
        e330 = db['categories']['antioxidants']['E300-E399']['E330']
        # Already has "Citric acid" as name, should match

    # 3. Add maltodextrin (no E-number, but should be flagged)
    # Add to "other" category
    if 'other_processing_aids' not in db['categories']:
        db['categories']['other_processing_aids'] = {}

    if 'MISC-001' not in db['categories']['other_processing_aids']:
        db['categories']['other_processing_aids']['MISC-001'] = {
            "name": "Maltodextrin",
            "origin": "corn/wheat/potato starch",
            "uses": "thickener, filler, sweetener in processed foods",
            "safety": "caution",
            "concerns": "High glycemic index; may spike blood sugar; derived from GMO corn",
            "vegetarian": True,
            "synonyms": [
                "Modified starch",
                "Corn maltodextrin",
                "Wheat maltodextrin"
            ]
        }
        changes.append('Added MISC-001 (Maltodextrin)')
        db['metadata']['total_additives'] += 1

    # 4. Add natural flavourings
    if 'MISC-002' not in db['categories']['other_processing_aids']:
        db['categories']['other_processing_aids']['MISC-002'] = {
            "name": "Natural flavourings",
            "origin": "plant/animal extracts",
            "uses": "flavor enhancement in all food categories",
            "safety": "neutral",
            "concerns": "Vague term; may contain hundreds of unlisted chemicals; check for allergens",
            "vegetarian": False,
            "synonyms": [
                "Natural flavouring",
                "Natural flavors",
                "Natural flavor",
                "Natural flavouring substances"
            ]
        }
        changes.append('Added MISC-002 (Natural flavourings)')
        db['metadata']['total_additives'] += 1

    # 5. Add medium-chain triglycerides (MCT)
    if 'MISC-003' not in db['categories']['other_processing_aids']:
        db['categories']['other_processing_aids']['MISC-003'] = {
            "name": "Medium-chain triglycerides",
            "origin": "coconut/palm oil",
            "uses": "carrier oil, emulsifier, energy supplement",
            "safety": "neutral",
            "concerns": "May cause digestive discomfort in large amounts; sustainability concerns with palm oil",
            "vegetarian": True,
            "synonyms": [
                "MCT oil",
                "MCT",
                "Medium chain triglycerides",
                "Fractionated coconut oil"
            ]
        }
        changes.append('Added MISC-003 (Medium-chain triglycerides)')
        db['metadata']['total_additives'] += 1

    # Update metadata
    db['metadata']['version'] = "2025.3"
    db['metadata']['last_updated'] = "2025-10-26"

    # Save updated database
    with open(db_path, 'w') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Updated database saved!")
    print(f"📊 New total: {db['metadata']['total_additives']} additives")
    print(f"\nChanges made:")
    for change in changes:
        print(f"  • {change}")

    return len(changes)

if __name__ == '__main__':
    db_path = sys.argv[1] if len(sys.argv) > 1 else '../../../NutraSafe Beta/additives_master_database.json'

    try:
        changes_count = update_database(db_path)
        print(f"\n✅ Successfully updated database with {changes_count} changes")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)
