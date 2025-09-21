#!/usr/bin/env python3
"""
Script to add new files to Xcode project
"""

import os
import re
import uuid

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project(project_path, files_to_add):
    """Add files to the Xcode project"""
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Find the main group ID for the app
    main_group_match = re.search(r'(\w{24})\s*/\* NutraSafe Beta \*/ = \{', content)
    if not main_group_match:
        print("Could not find main group")
        return False
    
    main_group_id = main_group_match.group(1)
    
    # Dictionary to store file references
    file_refs = {}
    build_file_refs = {}
    
    # Add each file
    for file_path, group_name in files_to_add:
        file_name = os.path.basename(file_path)
        file_ref_id = generate_uuid()
        build_file_id = generate_uuid()
        
        file_refs[file_path] = file_ref_id
        build_file_refs[file_path] = build_file_id
        
        # Add file reference to PBXFileReference section
        file_ref_entry = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};\n'
        
        # Find PBXFileReference section and add entry
        pbx_file_ref_match = re.search(r'/\* Begin PBXFileReference section \*/\n', content)
        if pbx_file_ref_match:
            insert_pos = pbx_file_ref_match.end()
            content = content[:insert_pos] + file_ref_entry + content[insert_pos:]
        
        # Add build file reference
        build_file_entry = f'\t\t{build_file_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};\n'
        
        # Find PBXBuildFile section and add entry
        pbx_build_file_match = re.search(r'/\* Begin PBXBuildFile section \*/\n', content)
        if pbx_build_file_match:
            insert_pos = pbx_build_file_match.end()
            content = content[:insert_pos] + build_file_entry + content[insert_pos:]
    
    # Add files to groups
    groups_to_create = {}
    for file_path, group_name in files_to_add:
        if group_name not in groups_to_create:
            groups_to_create[group_name] = []
        groups_to_create[group_name].append(file_refs[file_path])
    
    # Add each group
    for group_name, file_ref_ids in groups_to_create.items():
        group_id = generate_uuid()
        
        # Create children list
        children_list = ',\n\t\t\t\t'.join([f'{ref_id} /* {os.path.basename([k for k, v in file_refs.items() if v == ref_id][0])} */' for ref_id in file_ref_ids])
        
        # Create group entry
        group_entry = f'''\t\t{group_id} /* {group_name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{children_list},
\t\t\t);
\t\t\tpath = {group_name};
\t\t\tsourceTree = "<group>";
\t\t}};
'''
        
        # Find PBXGroup section and add entry
        pbx_group_match = re.search(r'/\* Begin PBXGroup section \*/\n', content)
        if pbx_group_match:
            insert_pos = pbx_group_match.end()
            content = content[:insert_pos] + group_entry + content[insert_pos:]
        
        # Add group reference to main group
        main_group_pattern = rf'{main_group_id} /\* NutraSafe Beta \*/ = {{\s+isa = PBXGroup;\s+children = \('
        main_group_match = re.search(main_group_pattern, content, re.MULTILINE | re.DOTALL)
        if main_group_match:
            insert_pos = main_group_match.end()
            content = content[:insert_pos] + f'\n\t\t\t\t{group_id} /* {group_name} */,' + content[insert_pos:]
    
    # Add files to Sources build phase
    sources_pattern = r'(/\* Sources \*/ = \{[^}]+files = \([^)]+)'
    sources_match = re.search(sources_pattern, content, re.DOTALL)
    if sources_match:
        insert_pos = sources_match.group(1).rfind(')')
        full_match_start = sources_match.start()
        
        # Build the list of build file references to add
        build_refs_to_add = []
        for file_path, _ in files_to_add:
            if file_path in build_file_refs:
                file_name = os.path.basename(file_path)
                build_refs_to_add.append(f'\t\t\t\t{build_file_refs[file_path]} /* {file_name} in Sources */,')
        
        if build_refs_to_add:
            build_refs_str = '\n'.join(build_refs_to_add)
            before = content[:full_match_start + insert_pos]
            after = content[full_match_start + insert_pos:]
            content = before + ',\n' + build_refs_str + after
    
    # Write the modified content back
    with open(project_path, 'w') as f:
        f.write(content)
    
    return True

def main():
    project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafeBeta.xcodeproj/project.pbxproj"
    
    # Define files to add with their group names
    files_to_add = [
        # Components
        ("NutraSafe Beta/Views/Components/ActionButtons.swift", "Components"),
        ("NutraSafe Beta/Views/Components/CustomTabBar.swift", "Components"),
        ("NutraSafe Beta/Views/Components/MacroViews.swift", "Components"),
        ("NutraSafe Beta/Views/Components/NutritionScoreViews.swift", "Components"),
        
        # Diary
        ("NutraSafe Beta/Views/Diary/DiaryComponents.swift", "Diary"),
        ("NutraSafe Beta/Views/Diary/DiaryExerciseComponents.swift", "Diary"),
        
        # Models
        ("NutraSafe Beta/Models/CoreModels.swift", "Models"),
        ("NutraSafe Beta/Models/ExerciseModels.swift", "Models"),
        ("NutraSafe Beta/Models/FoodSafetyModels.swift", "Models"),
        ("NutraSafe Beta/Models/HealthKitModels.swift", "Models"),
        ("NutraSafe Beta/Models/NutritionModels.swift", "Models"),
        ("NutraSafe Beta/Models/ScoringModels.swift", "Models"),
        ("NutraSafe Beta/Models/SearchModels.swift", "Models"),
        ("NutraSafe Beta/Models/TrackingModels.swift", "Models"),
        ("NutraSafe Beta/Models/UserModels.swift", "Models"),
        ("NutraSafe Beta/Models/AllModels.swift", "Models"),
        
        # Configuration
        ("NutraSafe Beta/Configuration/AppConfig.swift", "Configuration"),
    ]
    
    print("Adding files to Xcode project...")
    
    if add_files_to_xcode_project(project_path, files_to_add):
        print("✅ Successfully added all files to Xcode project")
    else:
        print("❌ Failed to add files to Xcode project")

if __name__ == "__main__":
    main()