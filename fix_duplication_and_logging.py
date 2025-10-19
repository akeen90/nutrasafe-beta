#!/usr/bin/env python3
"""
Script to fix duplication bug and remove excessive logging from NutraSafe Beta
"""

import re
import os

# File paths
CORE_MODELS = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Models/CoreModels.swift"
DIARY_TAB_VIEW = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/DiaryTabView.swift"
FOOD_DETAIL_VIEW = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/Food/FoodDetailViewFromSearch.swift"
CONTENT_VIEW = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift"
FIREBASE_MANAGER = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/FirebaseManager.swift"

def remove_print_statements(file_path):
    """Remove print statements but keep error prints"""
    print(f"Processing {os.path.basename(file_path)}...")

    with open(file_path, 'r') as f:
        content = f.read()

    original_lines = len(content.split('\n'))

    # Pattern to match print statements (but keep ones with "ERROR" or "error" in them)
    lines = content.split('\n')
    filtered_lines = []

    for line in lines:
        stripped = line.strip()
        # Keep the line if:
        # 1. It's not a print statement, OR
        # 2. It's a print with ERROR/error in it
        if not stripped.startswith('print(') or ('ERROR' in line or 'error:' in line.lower()):
            filtered_lines.append(line)
        else:
            # Replace print line with comment showing what was removed
            indent = len(line) - len(line.lstrip())
            # filtered_lines.append(' ' * indent + f"// Removed: {stripped[:80]}")
            pass  # Just remove it entirely

    new_content = '\n'.join(filtered_lines)
    new_lines = len(new_content.split('\n'))

    with open(file_path, 'w') as f:
        f.write(new_content)

    removed = original_lines - new_lines
    print(f"  Removed {removed} lines from {os.path.basename(file_path)}")
    return removed

def fix_duplication_bug():
    """Fix the duplication bug in DiaryDataManager.addFoodItem"""
    print("Fixing duplication bug in CoreModels.swift...")

    with open(CORE_MODELS, 'r') as f:
        content = f.read()

    # Find and replace the addFoodItem method
    old_method = r'''    // Add a single food item to a specific meal
    func addFoodItem\(_ item: DiaryFoodItem, to meal: String, for date: Date\) \{
        print\("DiaryDataManager: Adding food item '\\item\.name\)' to meal '\\meal\)' for date \\date\)"\)
        let \(breakfast, lunch, dinner, snacks\) = getFoodData\(for: date\)
        print\("DiaryDataManager: Current counts - Breakfast: \\breakfast\.count\), Lunch: \\lunch\.count\), Dinner: \\dinner\.count\), Snacks: \\snacks\.count\)"\)

        switch meal\.lowercased\(\) \{
        case "breakfast":
            var updatedBreakfast = breakfast
            updatedBreakfast\.append\(item\)
            print\("DiaryDataManager: Adding to breakfast\. New count: \\updatedBreakfast\.count\)"\)
            saveFoodData\(for: date, breakfast: updatedBreakfast, lunch: lunch, dinner: dinner, snacks: snacks\)
        case "lunch":
            var updatedLunch = lunch
            updatedLunch\.append\(item\)
            print\("DiaryDataManager: Adding to lunch\. New count: \\updatedLunch\.count\)"\)
            saveFoodData\(for: date, breakfast: breakfast, lunch: updatedLunch, dinner: dinner, snacks: snacks\)
        case "dinner":
            var updatedDinner = dinner
            updatedDinner\.append\(item\)
            print\("DiaryDataManager: Adding to dinner\. New count: \\updatedDinner\.count\)"\)
            saveFoodData\(for: date, breakfast: breakfast, lunch: lunch, dinner: updatedDinner, snacks: snacks\)
        case "snacks":
            var updatedSnacks = snacks
            updatedSnacks\.append\(item\)
            print\("DiaryDataManager: Adding to snacks\. New count: \\updatedSnacks\.count\)"\)
            saveFoodData\(for: date, breakfast: breakfast, lunch: lunch, dinner: dinner, snacks: updatedSnacks\)
        default:
            print\("DiaryDataManager: ERROR - Unknown meal type: \\meal\)"\)
        \}

        // Add to recent foods for quick access in search
        addToRecentFoods\(item\)

        // Sync to Firebase immediately
        syncFoodItemToFirebase\(item, meal: meal, date: date\)
    \}'''

    # Simpler approach: Just save directly to Firebase
    new_method = '''    // Add a single food item to a specific meal
    func addFoodItem(_ item: DiaryFoodItem, to meal: String, for date: Date) {
        // Add to recent foods for quick access in search
        addToRecentFoods(item)

        // Save directly to Firebase (single source of truth)
        // This prevents duplicates by avoiding the UserDefaults save
        syncFoodItemToFirebase(item, meal: meal, date: date)
    }'''

    # Try to find and replace the method
    # First, let's use a simpler approach - find the method start and replace the whole block
    if '    // Add a single food item to a specific meal\n    func addFoodItem(' in content:
        # Find the start
        start_idx = content.find('    // Add a single food item to a specific meal')
        # Find the end (next function or class closing brace)
        # Look for the next "func " or "    }\n\n    // MARK:" pattern
        search_from = start_idx + 100
        end_pattern1 = '\n    }\n\n    // MARK:'
        end_pattern2 = '\n    }\n\n    private func'
        end_pattern3 = '\n    }\n\n    func'

        end_idx1 = content.find(end_pattern1, search_from)
        end_idx2 = content.find(end_pattern2, search_from)
        end_idx3 = content.find(end_pattern3, search_from)

        # Get the minimum valid end index
        end_indices = [idx for idx in [end_idx1, end_idx2, end_idx3] if idx > 0]
        if end_indices:
            end_idx = min(end_indices)
            # Replace the method
            old_code = content[start_idx:end_idx + 6]  # +6 for '\n    }'
            new_code = new_method
            content = content[:start_idx] + new_code + content[end_idx + 6:]

            with open(CORE_MODELS, 'w') as f:
                f.write(content)

            print("  Fixed addFoodItem method - now saves directly to Firebase only")
            return True

    print("  Could not find addFoodItem method to fix")
    return False

def main():
    print("=" * 60)
    print("NutraSafe Beta: Fixing Duplication and Removing Logging")
    print("=" * 60)
    print()

    # Fix duplication bug first
    fix_duplication_bug()
    print()

    # Remove excessive logging
    total_removed = 0
    files_to_clean = [
        CORE_MODELS,
        DIARY_TAB_VIEW,
        FOOD_DETAIL_VIEW,
        CONTENT_VIEW,
        FIREBASE_MANAGER
    ]

    for file_path in files_to_clean:
        if os.path.exists(file_path):
            removed = remove_print_statements(file_path)
            total_removed += removed
        else:
            print(f"  Warning: {file_path} not found")

    print()
    print("=" * 60)
    print(f"COMPLETE: Removed {total_removed} print statement lines")
    print("=" * 60)

if __name__ == "__main__":
    main()
