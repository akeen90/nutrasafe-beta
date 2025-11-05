#!/usr/bin/env python3
"""
Remove old database files from Xcode project
Removes additives_unified.json and ultra_processed_ingredients.json
"""

import re
import sys

def remove_from_xcode(project_path, files_to_remove):
    """Remove files from Xcode project"""

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    original_content = content

    for file_name in files_to_remove:
        print(f"\n{'='*60}")
        print(f"Removing {file_name}...")
        print(f"{'='*60}")

        # Find the file reference UUID
        file_ref_pattern = r'([A-F0-9]+) /\* ' + re.escape(file_name) + r' \*/ = \{isa = PBXFileReference;[^}]+\};'
        file_ref_match = re.search(file_ref_pattern, content)

        if file_ref_match:
            file_ref_uuid = file_ref_match.group(1)
            print(f"✅ Found file reference UUID: {file_ref_uuid}")

            # Remove the PBXFileReference entry
            content = re.sub(file_ref_pattern, '', content)
            print(f"✅ Removed PBXFileReference entry")

            # Find and remove the PBXBuildFile entry
            build_file_pattern = r'\s*[A-F0-9]+ /\* ' + re.escape(file_name) + r' in Resources \*/ = \{isa = PBXBuildFile; fileRef = ' + file_ref_uuid + r'[^}]+\};\n'
            build_file_match = re.search(build_file_pattern, content)
            if build_file_match:
                content = re.sub(build_file_pattern, '', content)
                print(f"✅ Removed PBXBuildFile entry")

            # Remove from group children array
            group_child_pattern = r'\s*' + file_ref_uuid + r' /\* ' + re.escape(file_name) + r' \*/,?\n'
            group_child_match = re.search(group_child_pattern, content)
            if group_child_match:
                content = re.sub(group_child_pattern, '', content)
                print(f"✅ Removed from group children")

            # Remove from resources build phase
            resources_pattern = r'\s*[A-F0-9]+ /\* ' + re.escape(file_name) + r' in Resources \*/,?\n'
            resources_match = re.search(resources_pattern, content)
            if resources_match:
                content = re.sub(resources_pattern, '', content)
                print(f"✅ Removed from resources build phase")
        else:
            print(f"⚠️  File not found in project: {file_name}")

    # Write the modified project file
    if content != original_content:
        with open(project_path, 'w') as f:
            f.write(content)

        print(f"\n{'='*60}")
        print(f"✅ Successfully removed old database files from Xcode project!")
        print(f"{'='*60}")
        return True
    else:
        print(f"\n{'='*60}")
        print(f"⚠️  No changes made to project file")
        print(f"{'='*60}")
        return False

if __name__ == "__main__":
    project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj/project.pbxproj"

    files_to_remove = [
        "additives_unified.json",
        "ultra_processed_ingredients.json"
    ]

    print("Removing old database files from Xcode project...")
    success = remove_from_xcode(project_path, files_to_remove)

    sys.exit(0 if success else 1)
