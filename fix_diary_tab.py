#!/usr/bin/env python3
"""
Script to add missing DiaryTabView.swift to Xcode project and clean up duplicate implementations
"""

import os
import re
import sys

def add_files_to_xcode_project():
    """Add missing Swift files to the Xcode project"""

    project_root = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta"
    project_file = f"{project_root}/NutraSafeBeta.xcodeproj/project.pbxproj"

    # Files to add
    files_to_add = [
        "NutraSafe Beta/Views/DiaryTabView.swift",
        "NutraSafe Beta/Views/ExerciseTabView.swift",
        "NutraSafe Beta/Views/FoodTabView.swift",
        "NutraSafe Beta/Views/KitchenTabView.swift",
        "NutraSafe Beta/Views/AddTabView.swift",
    ]

    print("Reading project.pbxproj...")
    with open(project_file, 'r') as f:
        content = f.read()

    # Find the main group section and NutraSafe Beta group
    main_group_match = re.search(r'(\w+) /\* NutraSafe Beta \*/ = \{\s*isa = PBXGroup;.*?children = \(\s*(.*?)\s*\);', content, re.DOTALL)
    if not main_group_match:
        print("Could not find NutraSafe Beta group")
        return False

    main_group_id = main_group_match.group(1)

    # Generate UUIDs for new files
    import uuid

    added_files = []
    new_content = content

    for file_path in files_to_add:
        filename = os.path.basename(file_path)

        # Check if file already exists in project
        if filename in content:
            print(f"✅ {filename} already in project")
            continue

        # Check if file exists on disk
        full_path = f"{project_root}/{file_path}"
        if not os.path.exists(full_path):
            print(f"⚠️  {filename} not found on disk: {full_path}")
            continue

        # Generate UUIDs
        file_ref_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
        build_file_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]

        print(f"📄 Adding {filename} to project...")

        # Add PBXFileReference
        file_ref_entry = f'\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{filename}"; sourceTree = "<group>"; }};\n'

        # Find the end of PBXFileReference section
        file_ref_match = re.search(r'(.*?/\* End PBXFileReference section \*/)', new_content, re.DOTALL)
        if file_ref_match:
            new_content = new_content.replace(file_ref_match.group(0), file_ref_entry + file_ref_match.group(0))

        # Add PBXBuildFile
        build_file_entry = f'\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};\n'

        # Find the end of PBXBuildFile section
        build_file_match = re.search(r'(.*?/\* End PBXBuildFile section \*/)', new_content, re.DOTALL)
        if build_file_match:
            new_content = new_content.replace(build_file_match.group(0), build_file_entry + build_file_match.group(0))

        # Add to appropriate group (Views group)
        if "Views/" in file_path:
            # Find Views group
            views_group_match = re.search(r'(\w+) /\* Views \*/ = \{\s*isa = PBXGroup;.*?children = \(\s*(.*?)\s*\);', new_content, re.DOTALL)
            if views_group_match:
                views_group_id = views_group_match.group(1)
                children_content = views_group_match.group(2)

                # Add file reference to Views group
                new_children = children_content.strip() + f',\n\t\t\t\t{file_ref_uuid} /* {filename} */,'
                new_content = new_content.replace(
                    views_group_match.group(0),
                    views_group_match.group(0).replace(children_content, new_children)
                )

        # Add to Sources build phase
        sources_match = re.search(r'(\w+) /\* Sources \*/ = \{\s*isa = PBXSourcesBuildPhase;.*?files = \(\s*(.*?)\s*\);', new_content, re.DOTALL)
        if sources_match:
            sources_content = sources_match.group(2)
            new_sources = sources_content.strip() + f',\n\t\t\t\t{build_file_uuid} /* {filename} in Sources */,'
            new_content = new_content.replace(
                sources_match.group(0),
                sources_match.group(0).replace(sources_content, new_sources)
            )

        added_files.append(filename)

    if added_files:
        print(f"💾 Writing updated project.pbxproj...")
        with open(project_file, 'w') as f:
            f.write(new_content)
        print(f"✅ Successfully added {len(added_files)} files: {', '.join(added_files)}")
    else:
        print("✅ All files already in project")

    return True

def remove_duplicate_implementations():
    """Remove duplicate DiaryTabView implementation from ContentView.swift"""

    content_view_file = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift"

    print("📖 Reading ContentView.swift...")
    with open(content_view_file, 'r') as f:
        content = f.read()

    # Find and remove the duplicate DiaryTabView struct
    # Look for the placeholder implementation
    duplicate_pattern = r'// MARK: - Missing Tab Views.*?struct DiaryTabView: View \{.*?    \}\s*\}'

    if re.search(duplicate_pattern, content, re.DOTALL):
        print("🗑️  Removing duplicate DiaryTabView implementation...")
        new_content = re.sub(duplicate_pattern, '// MARK: - Tab Views properly imported from separate files', content, flags=re.DOTALL)

        with open(content_view_file, 'w') as f:
            f.write(new_content)
        print("✅ Removed duplicate DiaryTabView implementation")
        return True
    else:
        print("ℹ️  No duplicate DiaryTabView implementation found")
        return False

if __name__ == "__main__":
    print("🔧 Fixing diary tab navigation issue...")
    print("=" * 50)

    # Step 1: Add missing files to Xcode project
    print("\n1️⃣ Adding missing tab view files to Xcode project...")
    add_files_to_xcode_project()

    # Step 2: Remove duplicate implementations
    print("\n2️⃣ Cleaning up duplicate implementations...")
    remove_duplicate_implementations()

    print("\n✅ Diary tab fix complete!")
    print("🔨 Run the build to test the changes.")