#!/usr/bin/env python3
"""
Script to properly add files to Xcode project using pbxproj
"""

from pbxproj import XcodeProject
import os

def add_files_to_xcode():
    """Add all new component files to the Xcode project"""
    
    project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafeBeta.xcodeproj"
    project = XcodeProject.load(os.path.join(project_path, 'project.pbxproj'))
    
    # Find the main group for NutraSafe Beta
    main_group = None
    for group in project.objects.get_objects_in_section('PBXGroup'):
        if hasattr(group, 'name') and group.name == 'NutraSafe Beta':
            main_group = group
            break
    
    if not main_group:
        print("Could not find main NutraSafe Beta group")
        return False
    
    # Files to add organized by subdirectory
    files_to_add = {
        'Views/Components': [
            'ActionButtons.swift',
            'CustomTabBar.swift',
            'MacroViews.swift',
            'NutritionScoreViews.swift',
        ],
        'Views/Diary': [
            'DiaryComponents.swift',
            'DiaryExerciseComponents.swift',
        ],
        'Models': [
            'CoreModels.swift',
            'ExerciseModels.swift',
            'FoodSafetyModels.swift',
            'HealthKitModels.swift',
            'NutritionModels.swift',
            'ScoringModels.swift',
            'SearchModels.swift',
            'TrackingModels.swift',
            'UserModels.swift',
            'AllModels.swift',
        ],
        'Configuration': [
            'AppConfig.swift',
        ],
    }
    
    added_count = 0
    
    for subdir, files in files_to_add.items():
        # Create or find the subdirectory group
        subdir_parts = subdir.split('/')
        current_group = main_group
        
        for part in subdir_parts:
            # Check if this group already exists
            found_group = None
            if hasattr(current_group, 'children'):
                for child_id in current_group.children:
                    child = project.objects[child_id]
                    if hasattr(child, 'name') and child.name == part:
                        found_group = child
                        break
                    elif hasattr(child, 'path') and child.path == part:
                        found_group = child
                        break
            
            if found_group:
                current_group = found_group
            else:
                # Create the group
                new_group = project.objects.get_or_create('PBXGroup', name=part, path=part)
                current_group.add_child(new_group)
                current_group = new_group
        
        # Add files to the group
        for filename in files:
            file_path = os.path.join('NutraSafe Beta', subdir, filename)
            
            # Check if file exists
            full_path = os.path.join('/Users/aaronkeen/Documents/My Apps/NutraSafe Beta', file_path)
            if not os.path.exists(full_path):
                print(f"⚠️  File not found: {full_path}")
                continue
            
            # Check if file is already in project
            file_exists = False
            for file_ref in project.objects.get_objects_in_section('PBXFileReference'):
                if hasattr(file_ref, 'path') and file_ref.path == filename:
                    file_exists = True
                    break
            
            if not file_exists:
                # Add the file to the project
                file_ref = project.objects.get_or_create(
                    'PBXFileReference',
                    path=filename,
                    sourceTree='<group>',
                    lastKnownFileType='sourcecode.swift'
                )
                current_group.add_child(file_ref)
                
                # Add to build phase
                for target in project.objects.get_targets():
                    if target.name == 'NutraSafe Beta':
                        target.add_file_if_doesnt_exist(file_ref)
                        break
                
                print(f"✅ Added {filename}")
                added_count += 1
            else:
                print(f"ℹ️  {filename} already in project")
    
    # Save the project
    project.save()
    print(f"\n✅ Successfully added {added_count} files to Xcode project")
    return True

def main():
    print("Adding files to Xcode project using pbxproj...")
    add_files_to_xcode()

if __name__ == "__main__":
    main()