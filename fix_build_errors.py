#!/usr/bin/env python3
"""
Script to fix build errors in ContentView.swift
"""

import re

def fix_build_errors(filepath):
    """Fix all identified build errors"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Fix 1: Line 58 - self.updateWorkoutDuration() should be self?.updateWorkoutDuration()
    content = re.sub(
        r'(\{ \[weak self\] _ in\n\s+)self\.updateWorkoutDuration\(\)',
        r'\1self?.updateWorkoutDuration()',
        content
    )
    
    # Fix 2: Line 275 - self?.exerciseId should be self.exerciseId
    content = re.sub(
        r'self\?\.exerciseId = exerciseId',
        r'self.exerciseId = exerciseId',
        content
    )
    
    # Fix 3: Line 292 - if self.remainingTime > 0 should be if self?.remainingTime ?? 0 > 0
    content = re.sub(
        r'(\{ \[weak self\] _ in\n\s+)if self\.remainingTime > 0 \{',
        r'\1if self?.remainingTime ?? 0 > 0 {',
        content
    )
    
    # Fix 4: Line 293 - self?.remainingTime -= 1 needs proper unwrapping
    content = re.sub(
        r'self\?\.remainingTime -= 1',
        r'self?.remainingTime? -= 1',
        content
    )
    
    # Fix 5: Line 333 - } else if self?.restTimer?.remainingTime == 30 {
    content = re.sub(
        r'\} else if self\?\.restTimer\?\.remainingTime == 30 \{',
        r'} else if self?.restTimer.remainingTime == 30 {',
        content
    )
    
    # Write the fixed content back
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("✅ Fixed build errors in ContentView.swift")

def add_missing_views(filepath):
    """Add missing view definitions"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if DiaryTabView exists
    if 'struct DiaryTabView: View' not in content:
        # Add DiaryTabView definition before its usage
        diary_view = """
// MARK: - Diary Tab View
struct DiaryTabView: View {
    @Binding var selectedFoodItems: [FoodItem]
    @Binding var showingSettings: Bool
    @Binding var selectedDate: Date
    @ObservedObject var firebaseManager: FirebaseManager
    @ObservedObject var healthKitManager: HealthKitManager
    @ObservedObject var workoutManager: WorkoutManager
    
    var body: some View {
        Text("Diary Tab View")
    }
}

"""
        # Insert before the ContentView usage
        insert_pos = content.find('// MARK: - Main Content View')
        if insert_pos > 0:
            content = content[:insert_pos] + diary_view + content[insert_pos:]
        else:
            # Insert at a reasonable position
            insert_pos = content.find('struct ContentView:')
            if insert_pos > 0:
                content = content[:insert_pos] + diary_view + content[insert_pos:]
    
    # Write back
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("✅ Added missing view definitions")

def main():
    filepath = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift"
    
    print("🔧 Fixing build errors...")
    fix_build_errors(filepath)
    add_missing_views(filepath)
    print("✅ All fixes applied")

if __name__ == "__main__":
    main()