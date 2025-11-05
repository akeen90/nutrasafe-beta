#!/usr/bin/env python3
import json

# Load the consolidated ingredients database
with open('ingredients_consolidated.json', 'r') as f:
    data = json.load(f)
    ingredients = data['ingredients']

# Define sources for the 3 ingredients that need them
sources_to_add = {
    "E559": {
        "name": "Aluminium silicate",
        "sources": [
            {
                "title": "EFSA: Re-evaluation of aluminium-containing food additives",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/754"
            },
            {
                "title": "FSA: Approved additives and E numbers",
                "url": "https://www.food.gov.uk/business-guidance/approved-additives-and-e-numbers"
            }
        ]
    },
    "E160b": {
        "name": "Annatto",
        "sources": [
            {
                "title": "FSA: Food Allergy and Intolerance guidance",
                "url": "https://www.food.gov.uk/safety-hygiene/food-allergy-and-intolerance"
            },
            {
                "title": "EFSA: Scientific Opinion on the re-evaluation of Annatto extracts (E160b)",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/1811"
            }
        ]
    },
    "E556": {
        "name": "Calcium aluminium silicate",
        "sources": [
            {
                "title": "EFSA: Re-evaluation of aluminium-containing food additives",
                "url": "https://www.efsa.europa.eu/en/efsajournal/pub/754"
            },
            {
                "title": "European Commission: Food Additives Database",
                "url": "https://food.ec.europa.eu/food-safety/food-improvement-agents/additives/database_en"
            }
        ]
    }
}

# Update ingredients with sources
updated_count = 0
for ingredient in ingredients:
    for e_number in ingredient.get("eNumbers", []):
        if e_number in sources_to_add:
            # Check if this is the right ingredient by name
            if sources_to_add[e_number]["name"].lower() in ingredient["name"].lower():
                # Add sources if not already present or empty
                if not ingredient.get("sources") or len(ingredient["sources"]) == 0:
                    ingredient["sources"] = sources_to_add[e_number]["sources"]
                    updated_count += 1
                    print(f"✅ Added sources to {ingredient['name']} ({e_number})")
                else:
                    print(f"⏭️  {ingredient['name']} ({e_number}) already has sources")

# Save the updated database
with open('ingredients_consolidated.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\n✅ Updated {updated_count} ingredients with scientific sources")
