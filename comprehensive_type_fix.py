#!/usr/bin/env python3
"""Comprehensive fix for all type conflicts and missing imports"""

import re
import os

def fix_nutrition_models():
    """Fix all type conflicts in NutritionModels.swift"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/NutritionModels.swift'
    
    print("🔧 Fixing NutritionModels.swift type conflicts...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # 1. Remove all previous AdditiveInfo structures (they exist in FoodSafetyModels)
    # Look for struct AdditiveInfo and remove the entire struct
    content = re.sub(
        r'struct AdditiveInfo[^}]*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )
    
    # 2. Remove all previous IngredientPattern structures (they exist in FoodSafetyModels) 
    content = re.sub(
        r'struct IngredientPattern[^}]*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )
    
    # 3. Remove all previous PatternAnalysisResult structures (they exist in FoodSafetyModels)
    content = re.sub(
        r'struct PatternAnalysisResult[^}]*\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )
    
    # 4. Fix Firebase Timestamp references
    content = re.sub(r'(?<!FirebaseFirestore\.)Timestamp\(', 'FirebaseFirestore.Timestamp(', content)
    content = re.sub(r'as\? Timestamp(?!\()', 'as? FirebaseFirestore.Timestamp', content)
    content = re.sub(r': Timestamp(?!\()', ': FirebaseFirestore.Timestamp', content)
    
    # 5. Clean up any duplicate imports or whitespace issues
    lines = content.split('\n')
    cleaned_lines = []
    prev_blank = False
    
    for line in lines:
        if line.strip() == '':
            if not prev_blank:
                cleaned_lines.append(line)
                prev_blank = True
        else:
            cleaned_lines.append(line)
            prev_blank = False
    
    content = '\n'.join(cleaned_lines)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NutritionModels.swift")

def check_food_safety_models():
    """Verify that FoodSafetyModels contains the required types"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/FoodSafetyModels.swift'
    
    print("🔍 Checking FoodSafetyModels.swift for required types...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    required_types = ['AdditiveInfo', 'IngredientPattern', 'PatternAnalysisResult']
    missing_types = []
    
    for type_name in required_types:
        if f'struct {type_name}' not in content:
            missing_types.append(type_name)
    
    if missing_types:
        print(f"❌ Missing types in FoodSafetyModels: {missing_types}")
        return False
    else:
        print("✅ All required types found in FoodSafetyModels.swift")
        return True

def fix_health_kit_models():
    """Fix HealthKitModels.swift constructor issues"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/HealthKitModels.swift'
    
    print("🔧 Fixing HealthKitModels.swift...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix Firebase Timestamp references
    content = re.sub(r'(?<!FirebaseFirestore\.)Timestamp\(', 'FirebaseFirestore.Timestamp(', content)
    content = re.sub(r'as\? Timestamp(?!\()', 'as? FirebaseFirestore.Timestamp', content)
    content = re.sub(r': Timestamp(?!\()', ': FirebaseFirestore.Timestamp', content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed HealthKitModels.swift")

if __name__ == '__main__':
    print("🚀 Running comprehensive type fix...")
    
    # Step 1: Check that FoodSafetyModels has the required types
    if not check_food_safety_models():
        print("❌ Cannot proceed - FoodSafetyModels.swift missing required types")
        exit(1)
    
    # Step 2: Fix NutritionModels
    fix_nutrition_models()
    
    # Step 3: Fix HealthKitModels
    fix_health_kit_models()
    
    print("🎉 Comprehensive type fixes applied!")
    print("📋 Changes made:")
    print("  • Removed duplicate type definitions from NutritionModels.swift") 
    print("  • Fixed all Firebase Timestamp references")
    print("  • Cleaned up whitespace and formatting")
    print("  • Verified FoodSafetyModels.swift contains required types")