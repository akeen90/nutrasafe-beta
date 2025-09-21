#!/usr/bin/env python3
"""Fix remaining build errors in model files"""

import re

def fix_nutrition_models():
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/NutritionModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix AdditiveInfo references
    content = re.sub(r'(\s+)let additives: \[AdditiveInfo\]\?', r'\1let additives: [FoodSafetyModels.AdditiveInfo]?', content)
    content = re.sub(r'additives: \[AdditiveInfo\]\? = nil', r'additives: [FoodSafetyModels.AdditiveInfo]? = nil', content)
    
    # Fix Timestamp references
    content = re.sub(r'Timestamp\(date:', r'FirebaseFirestore.Timestamp(date:', content)
    content = re.sub(r' as\? Timestamp', r' as? FirebaseFirestore.Timestamp', content)
    
    # Fix PatternAnalysisResult
    content = re.sub(r'-> PatternAnalysisResult \{', r'-> FoodSafetyModels.PatternAnalysisResult {', content)
    
    # Fix IngredientPattern
    content = re.sub(r': \[IngredientPattern\]', r': [FoodSafetyModels.IngredientPattern]', content)
    content = re.sub(r'= \[IngredientPattern\]', r'= [FoodSafetyModels.IngredientPattern]', content)
    content = re.sub(r'\.append\(IngredientPattern\(', r'.append(FoodSafetyModels.IngredientPattern(', content)
    
    # Fix FoodReaction initializer - use id and dateLogged
    old_reaction = """        var reaction = FoodReaction(
            foodName: foodName,
            foodIngredients: foodIngredients,
            reactionTime: reactionTimeTimestamp.dateValue(),
            symptoms: symptoms,
            severity: severity,
            notes: notes
        )
        
        // This is a hack to maintain the stored id and dateLogged
        // In a real implementation, we'd need to add another initializer
        return reaction"""
    
    new_reaction = """        return FoodReaction(
            id: id,
            foodName: foodName,
            foodIngredients: foodIngredients,
            symptoms: symptoms,
            severity: severity,
            notes: notes,
            reactionTime: reactionTimeTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )"""
    
    content = content.replace(old_reaction, new_reaction)
    
    # Fix FoodEntry initializer - use id, userId and dateLogged
    old_entry = """        let entry = FoodEntry(
            foodName: foodName,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue()
        )
        
        // Return the created entry (it already has all the right values)
        return entry"""
    
    new_entry = """        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            mealType: mealType,
            date: dateTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )"""
    
    content = content.replace(old_entry, new_entry)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Fixed NutritionModels.swift")

def fix_healthkit_models():
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/HealthKitModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix Timestamp references
    content = re.sub(r' as\? Timestamp', r' as? FirebaseFirestore.Timestamp', content)
    
    # Fix KitchenItem initializer - use id and dateAdded
    old_item = """        var item = KitchenItem(
            userId: userId,
            name: name,
            quantity: quantity,
            unit: unit,
            expiryDate: expiryDate,
            category: category,
            notes: notes
        )
        
        // Override generated values with stored ones
        return KitchenItem("""
    
    new_item = """        return KitchenItem("""
    
    content = content.replace(old_item, new_item)
    
    # Need to add all the parameters for the full initializer
    content = re.sub(
        r'        return KitchenItem\(\n            userId: userId,',
        r'        return KitchenItem(\n            id: id,\n            userId: userId,',
        content
    )
    
    # Add dateAdded to the end
    content = re.sub(
        r'(            category: category,\n            notes: notes)\n        \)',
        r'\1,\n            dateAdded: dateAddedTimestamp.dateValue()\n        )',
        content
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Fixed HealthKitModels.swift")

def fix_scoring_models():
    """Remove duplicate AdditiveInfo from ScoringModels.swift"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/ScoringModels.swift'
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Find and remove the private AdditiveInfo struct  
    new_lines = []
    skip_until_close = False
    
    for i, line in enumerate(lines):
        if 'private struct AdditiveInfo: Codable {' in line:
            skip_until_close = True
            continue
        elif skip_until_close and line.strip() == '}':
            skip_until_close = False
            continue
        elif not skip_until_close:
            new_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    
    print(f"Fixed ScoringModels.swift - removed duplicate AdditiveInfo")

if __name__ == '__main__':
    fix_nutrition_models()
    fix_healthkit_models()
    fix_scoring_models()
    print("All model files fixed!")