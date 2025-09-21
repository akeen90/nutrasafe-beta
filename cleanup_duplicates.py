#!/usr/bin/env python3
"""
Script to comment out duplicate view structs from ContentView.swift
These views have already been extracted to separate files
"""

import re

# List of duplicate structs to remove with their line ranges
duplicates_to_remove = [
    # Views that exist in separate files
    ("DiaryTabView", 2083, 2223),
    ("ExerciseTabView", 2224, 2381),
    ("AddTabView", 4486, 4529),
    
    # Views extracted to MacroViews.swift
    ("MacroProgressView", 3249, 3320),
    ("CompactMacroItem", 3789, 3811),
    ("MacroLabel", 3929, 3946),
    
    # Views extracted to DiaryComponents.swift
    ("DiaryMealCard", 3578, 3772),
    ("DiaryFoodRow", 3813, 3927),
    
    # Views extracted to NutritionScoreViews.swift
    ("NutritionScoreView", 4004, 4035),
    ("ModernNutritionScore", 4036, 4078),
    ("NutritionScoreDetailView", 4079, 4200),
    ("GradeExplanationRow", 4201, 4223),
    
    # Views extracted to DiaryExerciseComponents.swift
    ("DiaryExerciseSummaryCard", 4224, 4290),
    ("DiaryExerciseStat", 4292, 4310),
    ("DiaryExerciseCard", 4312, 4435),
    ("DiaryExerciseRow", 4437, 4484),
    
    # Views extracted to ActionButtons.swift
    ("PersistentBottomMenu", 5514, 5549),
    ("SlimActionButton", 5551, 5573),
    ("SlimButtonStyle", 5575, 5582),
    ("PremiumActionButton", 5584, 5622),
    ("PremiumButtonStyle", 5624, 5630),
    ("CompactActionButton", 5632, 5663),
    ("ActionButton", 5665, 5698),
]

def comment_out_lines(filepath, removals):
    """Comment out specified line ranges in a file"""
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Sort removals by start line (descending) to avoid index issues
    removals.sort(key=lambda x: x[1], reverse=True)
    
    for name, start, end in removals:
        # Convert to 0-based indexing
        start_idx = start - 1
        end_idx = end
        
        # Add comment header
        comment_header = f"\n// MARK: - {name} moved to separate file\n"
        comment_footer = f"// End of {name} - see extracted file for implementation\n\n"
        
        # Comment out the lines
        for i in range(start_idx, min(end_idx, len(lines))):
            if not lines[i].strip().startswith('//'):
                lines[i] = '// ' + lines[i]
        
        # Add header and footer comments
        if start_idx > 0:
            lines[start_idx] = comment_header + lines[start_idx]
        if end_idx < len(lines):
            lines[end_idx-1] = lines[end_idx-1].rstrip() + '\n' + comment_footer
    
    return lines

def main():
    filepath = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift"
    
    print(f"Processing {filepath}")
    print(f"Commenting out {len(duplicates_to_remove)} duplicate view structs...")
    
    updated_lines = comment_out_lines(filepath, duplicates_to_remove)
    
    # Write back the modified content
    with open(filepath, 'w') as f:
        f.writelines(updated_lines)
    
    print("✅ Successfully commented out duplicate views")
    print("\nDuplicate views removed:")
    for name, _, _ in duplicates_to_remove:
        print(f"  - {name}")

if __name__ == "__main__":
    main()