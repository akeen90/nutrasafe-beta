#!/usr/bin/env python3
"""
Script to analyze and refactor DataModels.swift into separate domain-specific files
"""

import re
import os
from collections import defaultdict

def analyze_datamodels(filepath):
    """Analyze DataModels.swift to identify different domains"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find all structs, classes, and enums
    struct_pattern = r'(struct|class|enum)\s+(\w+)[^{]*\{'
    matches = re.finditer(struct_pattern, content)
    
    domains = defaultdict(list)
    
    for match in matches:
        type_kind = match.group(1)
        type_name = match.group(2)
        
        # Categorize by domain based on naming patterns
        if any(word in type_name for word in ['Food', 'Nutrition', 'Nutrient', 'Macro', 'Micro', 'Calorie']):
            domains['Nutrition'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Exercise', 'Workout', 'Rest', 'Set', 'Rep', 'Cardio']):
            domains['Exercise'].append((type_kind, type_name))
        elif any(word in type_name for word in ['User', 'Profile', 'Settings', 'Preference']):
            domains['User'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Allergen', 'Allergy', 'Ingredient', 'Additive']):
            domains['FoodSafety'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Barcode', 'Scan', 'Recognition']):
            domains['Scanning'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Fast', 'Timer', 'Meal']):
            domains['Tracking'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Score', 'Grade', 'Rating']):
            domains['Scoring'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Search', 'Result', 'Query']):
            domains['Search'].append((type_kind, type_name))
        elif any(word in type_name for word in ['Health', 'Kit', 'Apple']):
            domains['HealthKit'].append((type_kind, type_name))
        else:
            domains['Core'].append((type_kind, type_name))
    
    return domains

def extract_type_definition(content, type_kind, type_name):
    """Extract a complete type definition from the content"""
    
    # Pattern to find the type definition with its complete body
    pattern = rf'((?:///.*\n)*(?:@\w+.*\n)*{type_kind}\s+{type_name}[^{{]*{{)'
    
    match = re.search(pattern, content, re.MULTILINE)
    if not match:
        return None
    
    start_pos = match.start()
    
    # Find the matching closing brace
    brace_count = 0
    in_string = False
    escape_next = False
    i = match.end() - 1  # Start from the opening brace
    
    while i < len(content):
        char = content[i]
        
        if escape_next:
            escape_next = False
        elif char == '\\':
            escape_next = True
        elif char == '"' and not escape_next:
            in_string = not in_string
        elif not in_string:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    # Found the matching closing brace
                    return content[start_pos:i+1]
        
        i += 1
    
    return None

def create_domain_files(filepath, domains):
    """Create separate files for each domain"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    base_dir = os.path.dirname(filepath)
    models_dir = os.path.join(base_dir, 'NutraSafe Beta', 'Models')
    
    # Create Models directory if it doesn't exist
    os.makedirs(models_dir, exist_ok=True)
    
    created_files = []
    
    for domain, types in domains.items():
        if not types:
            continue
        
        filename = f"{domain}Models.swift"
        filepath = os.path.join(models_dir, filename)
        
        file_content = f"""//
//  {filename}
//  NutraSafe Beta
//
//  Domain models for {domain}
//

import Foundation
import SwiftUI

"""
        
        # Extract each type definition
        for type_kind, type_name in types:
            type_def = extract_type_definition(content, type_kind, type_name)
            if type_def:
                file_content += type_def + "\n\n"
        
        # Write the domain file
        with open(filepath, 'w') as f:
            f.write(file_content)
        
        created_files.append((domain, filename, len(types)))
        print(f"✅ Created {filename} with {len(types)} types")
    
    return created_files

def main():
    datamodels_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/DataModels.swift"
    
    print("Analyzing DataModels.swift...")
    domains = analyze_datamodels(datamodels_path)
    
    print("\n📊 Domain Analysis:")
    total_types = 0
    for domain, types in domains.items():
        if types:
            print(f"  {domain}: {len(types)} types")
            total_types += len(types)
    
    print(f"\nTotal types found: {total_types}")
    
    # Create domain files
    print("\n🔨 Creating domain-specific model files...")
    created_files = create_domain_files(datamodels_path, domains)
    
    print(f"\n✅ Successfully created {len(created_files)} domain model files")
    
    # Create an import file to maintain compatibility
    models_dir = os.path.join(os.path.dirname(datamodels_path), 'NutraSafe Beta', 'Models')
    import_file = os.path.join(models_dir, 'AllModels.swift')
    
    import_content = """//
//  AllModels.swift
//  NutraSafe Beta
//
//  Central import for all domain models
//

import Foundation

// This file can be used to import all models if needed
// Individual model files should be imported directly where used
"""
    
    with open(import_file, 'w') as f:
        f.write(import_content)
    
    print("✅ Created AllModels.swift import file")

if __name__ == "__main__":
    main()