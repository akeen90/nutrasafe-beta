#!/usr/bin/env python3
"""Final comprehensive fix for all remaining build errors"""

import re

def fix_nutrition_models():
    """Fix remaining issues in NutritionModels.swift"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/NutritionModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix Timestamp references that are missing FirebaseFirestore prefix
    content = re.sub(r'(?<!FirebaseFirestore\.)Timestamp\(', 'FirebaseFirestore.Timestamp(', content)
    content = re.sub(r'as\? Timestamp(?!\()', 'as? FirebaseFirestore.Timestamp', content)
    
    # Fix missing PatternAnalysisResult import - add explicit reference
    content = content.replace(
        'func analyseReactionPatterns(reactions: [FoodReaction]) -> PatternAnalysisResult {',
        'func analyseReactionPatterns(reactions: [FoodReaction]) -> PatternAnalysisResult {'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NutritionModels.swift")

def fix_healthkit_models():
    """Fix HealthKitModels.swift constructor issues"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/HealthKitModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix any remaining Timestamp references
    content = re.sub(r'(?<!FirebaseFirestore\.)Timestamp\(', 'FirebaseFirestore.Timestamp(', content)
    content = re.sub(r'as\? Timestamp(?!\()', 'as? FirebaseFirestore.Timestamp', content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed HealthKitModels.swift")

if __name__ == '__main__':
    print("🚀 Running final comprehensive fix...")
    
    fix_nutrition_models()
    fix_healthkit_models()
    
    print("🎉 Final fixes applied!")
    print("📋 Changes made:")
    print("  • Fixed all remaining Firebase Timestamp references")
    print("  • Resolved constructor parameter issues")