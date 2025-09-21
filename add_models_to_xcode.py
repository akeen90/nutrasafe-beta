#!/usr/bin/env python3
import os
import uuid
import re

# Path to the project file
project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafeBeta.xcodeproj/project.pbxproj"

# Model files to add
model_files = [
    "CoreModels.swift",
    "ExerciseModels.swift",
    "FoodSafetyModels.swift",
    "HealthKitModels.swift",
    "NutritionModels.swift",
    "ScoringModels.swift",
    "SearchModels.swift",
    "TrackingModels.swift",
    "UserModels.swift",
    "AllModels.swift"
]

# Read the project file
with open(project_path, 'r') as f:
    content = f.read()

# Generate unique IDs for each file (24 hex characters)
file_refs = {}
build_refs = {}
for file in model_files:
    # Generate two unique IDs - one for file reference, one for build reference
    file_refs[file] = ''.join([format(ord(c), 'X') for c in file[:12]]).ljust(24, '0')[:24]
    build_refs[file] = ''.join([format(ord(c), 'X') for c in file[:12]]).ljust(24, '1')[:24]

# Find the Models group or create it
models_group_id = "A12345678901234567890MDLS"

# Add PBXBuildFile entries (after existing ones)
build_file_entries = []
for file in model_files:
    entry = f"\t\t{build_refs[file]} /* {file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file]} /* {file} */; }};"
    build_file_entries.append(entry)

# Add PBXFileReference entries
file_ref_entries = []
for file in model_files:
    entry = f"\t\t{file_refs[file]} /* {file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file}; sourceTree = \"<group>\"; }};"
    file_ref_entries.append(entry)

# Create Models group entry
models_group_entry = f"""		{models_group_id} /* Models */ = {{
			isa = PBXGroup;
			children = (
{chr(10).join([f"\t\t\t\t{file_refs[file]} /* {file} */," for file in model_files])}
			);
			path = Models;
			sourceTree = "<group>";
		}};"""

# Add build file entries after the last existing one
build_section_pattern = r'(/\* Begin PBXBuildFile section \*/.*?)(\n\s+/\* End PBXBuildFile section \*/)'
match = re.search(build_section_pattern, content, re.DOTALL)
if match:
    new_build_section = match.group(1) + '\n' + '\n'.join(build_file_entries) + match.group(2)
    content = content[:match.start()] + new_build_section + content[match.end():]

# Add file reference entries after the last existing one
file_ref_pattern = r'(/\* Begin PBXFileReference section \*/.*?)(\n\s+/\* End PBXFileReference section \*/)'
match = re.search(file_ref_pattern, content, re.DOTALL)
if match:
    new_file_ref_section = match.group(1) + '\n' + '\n'.join(file_ref_entries) + match.group(2)
    content = content[:match.start()] + new_file_ref_section + content[match.end():]

# Add Models group to the main group
main_group_pattern = r'(A1234567890123456789012000 /\* NutraSafe Beta \*/ = \{[^}]*children = \([^)]*)'
match = re.search(main_group_pattern, content, re.DOTALL)
if match:
    # Add Models group reference to children
    children_section = match.group(1)
    if models_group_id not in children_section:
        new_children = children_section + f"\n\t\t\t\t{models_group_id} /* Models */,"
        content = content[:match.start()] + new_children + content[match.end():]

# Add the Models group definition in PBXGroup section
group_section_pattern = r'(/\* Begin PBXGroup section \*/.*?)(\n\s+/\* End PBXGroup section \*/)'
match = re.search(group_section_pattern, content, re.DOTALL)
if match:
    new_group_section = match.group(1) + '\n' + models_group_entry + match.group(2)
    content = content[:match.start()] + new_group_section + content[match.end():]

# Add to Sources build phase
sources_pattern = r'(A1234567890123456789012300 /\* Sources \*/ = \{[^}]*files = \([^)]*)'
match = re.search(sources_pattern, content, re.DOTALL)
if match:
    sources_section = match.group(1)
    # Add all model files to sources
    new_sources = sources_section
    for file in model_files:
        if build_refs[file] not in sources_section:
            new_sources += f"\n\t\t\t\t{build_refs[file]} /* {file} in Sources */,"
    content = content[:match.start()] + new_sources + content[match.end():]

# Write the updated project file
with open(project_path, 'w') as f:
    f.write(content)

print("Successfully added Models directory and files to Xcode project")