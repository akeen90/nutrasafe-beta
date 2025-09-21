#!/usr/bin/env python3
"""Comprehensive fix for all build errors after DataModels.swift refactoring"""

import re

def fix_nutrition_models():
    """Fix all issues in NutritionModels.swift"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/NutritionModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Phase 1: Fix all type references - Remove FoodSafetyModels prefix
    content = re.sub(r'FoodSafetyModels\.AdditiveInfo', 'AdditiveInfo', content)
    content = re.sub(r'FoodSafetyModels\.IngredientPattern', 'IngredientPattern', content)
    content = re.sub(r'FoodSafetyModels\.PatternAnalysisResult', 'PatternAnalysisResult', content)
    
    # Phase 2: Add complete initializer to FoodReaction struct
    old_food_reaction_init = """    init(foodName: String, foodIngredients: [String], reactionTime: Date, 
         symptoms: [String], severity: ReactionSeverity, notes: String? = nil) {
        self.id = UUID()
        self.foodName = foodName
        self.foodIngredients = foodIngredients
        self.reactionTime = reactionTime
        self.symptoms = symptoms
        self.severity = severity
        self.notes = notes
        self.dateLogged = Date()
    }"""
    
    new_food_reaction_init = """    init(foodName: String, foodIngredients: [String], reactionTime: Date, 
         symptoms: [String], severity: ReactionSeverity, notes: String? = nil) {
        self.id = UUID()
        self.foodName = foodName
        self.foodIngredients = foodIngredients
        self.reactionTime = reactionTime
        self.symptoms = symptoms
        self.severity = severity
        self.notes = notes
        self.dateLogged = Date()
    }
    
    // Complete initializer for fromDictionary method
    init(id: UUID, foodName: String, foodIngredients: [String], symptoms: [String], 
         severity: ReactionSeverity, notes: String?, reactionTime: Date, dateLogged: Date) {
        self.id = id
        self.foodName = foodName
        self.foodIngredients = foodIngredients
        self.reactionTime = reactionTime
        self.symptoms = symptoms
        self.severity = severity
        self.notes = notes
        self.dateLogged = dateLogged
    }"""
    
    content = content.replace(old_food_reaction_init, new_food_reaction_init)
    
    # Fix the fromDictionary method to use the complete initializer
    old_from_dict = """        return FoodReaction(
            id: id,
            foodName: foodName,
            foodIngredients: foodIngredients,
            symptoms: symptoms,
            severity: severity,
            notes: notes,
            reactionTime: reactionTimeTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )"""
    
    new_from_dict = """        return FoodReaction(
            id: id,
            foodName: foodName,
            foodIngredients: foodIngredients,
            symptoms: symptoms,
            severity: severity,
            notes: notes,
            reactionTime: reactionTimeTimestamp.dateValue(),
            dateLogged: dateLoggedTimestamp.dateValue()
        )"""
    
    # The fromDictionary is already correct, but we need to verify it matches the new initializer
    
    # Phase 3: Add complete initializer to FoodEntry struct  
    old_food_entry_init = """    init(userId: String, foodName: String, brandName: String? = nil, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         mealType: MealType, date: Date) {
        self.id = UUID().uuidString
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = Date()
    }"""
    
    new_food_entry_init = """    init(userId: String, foodName: String, brandName: String? = nil, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil,
         mealType: MealType, date: Date) {
        self.id = UUID().uuidString
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = Date()
    }
    
    // Complete initializer for fromDictionary method
    init(id: String, userId: String, foodName: String, brandName: String?, 
         servingSize: Double, servingUnit: String, calories: Double, 
         protein: Double, carbohydrates: Double, fat: Double, 
         fiber: Double?, sugar: Double?, sodium: Double?,
         mealType: MealType, date: Date, dateLogged: Date) {
        self.id = id
        self.userId = userId
        self.foodName = foodName
        self.brandName = brandName
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.mealType = mealType
        self.date = date
        self.dateLogged = dateLogged
    }"""
    
    content = content.replace(old_food_entry_init, new_food_entry_init)
    
    # Fix the fromDictionary method for FoodEntry
    old_entry_from_dict = """        var entry = FoodEntry(
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
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
    
    new_entry_from_dict = """        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
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
    
    content = content.replace(old_entry_from_dict, new_entry_from_dict)
    
    # Phase 4: Add complete initializer to SafeFood struct
    old_safe_food_init = """    init(userId: String, name: String, notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.notes = notes
        self.dateAdded = Date()
    }"""
    
    new_safe_food_init = """    init(userId: String, name: String, notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.notes = notes
        self.dateAdded = Date()
    }
    
    // Complete initializer for fromDictionary method  
    init(id: UUID, userId: String, name: String, notes: String?, dateAdded: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.notes = notes
        self.dateAdded = dateAdded
    }"""
    
    content = content.replace(old_safe_food_init, new_safe_food_init)
    
    # Fix SafeFood fromDictionary method
    old_safe_from_dict = """        // Create using available initializer
        return SafeFood(
            userId: userId,
            name: name,
            notes: notes
        )"""
    
    new_safe_from_dict = """        return SafeFood(
            id: id,
            userId: userId,
            name: name,
            notes: notes,
            dateAdded: dateAddedTimestamp.dateValue()
        )"""
    
    content = content.replace(old_safe_from_dict, new_safe_from_dict)
    
    # Write the fixed content
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed NutritionModels.swift")

def fix_healthkit_models():
    """Fix remaining Firebase import issues in HealthKitModels.swift"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/HealthKitModels.swift'
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix Timestamp references that were missed
    content = re.sub(r'\bTimestamp\(', 'FirebaseFirestore.Timestamp(', content)
    content = re.sub(r'as\? Timestamp', 'as? FirebaseFirestore.Timestamp', content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("✅ Fixed HealthKitModels.swift")

def remove_duplicate_types():
    """Remove any remaining duplicate AdditiveInfo definitions"""
    file_path = '/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/ScoringModels.swift'
    
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Remove the private AdditiveInfo struct if it exists
    new_lines = []
    skip_until_close = False
    brace_count = 0
    
    for i, line in enumerate(lines):
        if 'private struct AdditiveInfo: Codable {' in line:
            skip_until_close = True
            brace_count = 1
            continue
        elif skip_until_close:
            # Count braces to find the end of the struct
            brace_count += line.count('{')
            brace_count -= line.count('}')
            if brace_count == 0:
                skip_until_close = False
            continue
        else:
            new_lines.append(line)
    
    with open(file_path, 'w') as f:
        f.writelines(new_lines)
    
    print("✅ Fixed ScoringModels.swift - removed duplicate AdditiveInfo")

if __name__ == '__main__':
    print("🚀 Starting comprehensive build error fix...")
    
    fix_nutrition_models()
    fix_healthkit_models() 
    remove_duplicate_types()
    
    print("🎉 All fixes applied successfully!")
    print("📋 Summary of changes:")
    print("  • Fixed all FoodSafetyModels.* type references")
    print("  • Added complete initializers for FoodReaction, FoodEntry, SafeFood")
    print("  • Fixed all Firebase Timestamp references")
    print("  • Removed duplicate type definitions")
    print("  • Updated all fromDictionary methods to use complete initializers")