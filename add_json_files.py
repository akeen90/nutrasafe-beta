#!/usr/bin/env python3
"""
Add JSON database files to Xcode project
"""

import uuid
import sys

def generate_uuid():
    """Generate a unique UUID for Xcode"""
    return ''.join(str(uuid.uuid4()).upper().split('-'))

def add_file_to_xcode(file_name):
    project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe/NutraSafeBeta.xcodeproj/project.pbxproj"

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for the new file reference and build file
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()

    # Create the PBXFileReference entry
    file_reference = f"""\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.json; path = "{file_name}"; sourceTree = "<group>"; }};"""

    # Create the PBXBuildFile entry
    build_file = f"""\t\t{build_file_uuid} /* {file_name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};"""

    # Find the PBXFileReference section and add our file
    pbx_file_ref_marker = "/* Begin PBXFileReference section */"
    if pbx_file_ref_marker in content:
        content = content.replace(
            pbx_file_ref_marker,
            pbx_file_ref_marker + "\n" + file_reference
        )
        print(f"✅ Added file reference: {file_ref_uuid} for {file_name}")
    else:
        print(f"❌ Could not find PBXFileReference section")
        return False

    # Find the PBXBuildFile section and add our build file
    pbx_build_file_marker = "/* Begin PBXBuildFile section */"
    if pbx_build_file_marker in content:
        content = content.replace(
            pbx_build_file_marker,
            pbx_build_file_marker + "\n" + build_file
        )
        print(f"✅ Added build file: {build_file_uuid} for {file_name}")
    else:
        print(f"❌ Could not find PBXBuildFile section")
        return False

    # Find the "NutraSafe Beta" group and add the file reference
    group_marker = '/* NutraSafe Beta */ = {'
    if group_marker in content:
        # Find the children array in this group
        start_idx = content.find(group_marker)
        children_start = content.find('children = (', start_idx)
        if children_start != -1:
            # Find the end of the children array
            children_end = content.find(');', children_start)
            # Insert our file reference before the closing parenthesis
            insert_point = children_end
            file_ref_entry = f"\n\t\t\t\t{file_ref_uuid} /* {file_name} */,"
            content = content[:insert_point] + file_ref_entry + content[insert_point:]
            print(f"✅ Added to group children for {file_name}")
        else:
            print(f"⚠️  Could not find children array in group")

    # Find the PBXResourcesBuildPhase and add our file to the files array
    resources_marker = 'isa = PBXResourcesBuildPhase;'
    if resources_marker in content:
        # Find the files array in the resources build phase
        start_idx = content.find(resources_marker)
        files_start = content.find('files = (', start_idx)
        if files_start != -1:
            files_end = content.find(');', files_start)
            insert_point = files_end
            build_file_entry = f"\n\t\t\t\t{build_file_uuid} /* {file_name} in Resources */,"
            content = content[:insert_point] + build_file_entry + content[insert_point:]
            print(f"✅ Added to resources build phase for {file_name}")
        else:
            print(f"⚠️  Could not find files array in resources build phase")

    # Write the modified project file
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"✅ Successfully added {file_name} to Xcode project!")
    return True

if __name__ == "__main__":
    files_to_add = [
        "additives_unified.json",
        "ultra_processed_ingredients.json",
        "ingredients_consolidated.json"
    ]

    print("Adding JSON database files to Xcode project...\n")

    success_count = 0
    for file_name in files_to_add:
        print(f"\n{'='*60}")
        print(f"Adding {file_name}...")
        print(f"{'='*60}")
        if add_file_to_xcode(file_name):
            success_count += 1

    print(f"\n{'='*60}")
    print(f"✅ Successfully added {success_count}/{len(files_to_add)} files!")
    print(f"{'='*60}")

    sys.exit(0 if success_count == len(files_to_add) else 1)
