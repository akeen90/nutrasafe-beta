#!/usr/bin/env python3
"""
Script to fix the DataModels.swift reference and add all missing files to Xcode project
"""

import os
import re
import sys

def main():
    project_root = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta"
    project_file = f"{project_root}/NutraSafeBeta.xcodeproj/project.pbxproj"

    print("📖 Reading project file...")
    with open(project_file, 'r') as f:
        content = f.read()

    # Remove DataModels.swift references
    print("🗑️  Removing DataModels.swift references...")

    # Remove the file reference
    content = re.sub(r'\t\t[A-F0-9]{24} /\* DataModels\.swift \*/ = \{.*?\};\n', '', content, flags=re.DOTALL)

    # Remove from build files
    content = re.sub(r'\t\t[A-F0-9]{24} /\* DataModels\.swift in Sources \*/ = \{.*?\};\n', '', content, flags=re.DOTALL)

    # Remove from group children (may have trailing comma)
    content = re.sub(r',?\s*[A-F0-9]{24} /\* DataModels\.swift \*/,?', '', content)

    # Remove from sources build phase
    content = re.sub(r',?\s*[A-F0-9]{24} /\* DataModels\.swift in Sources \*/,?', '', content)

    print("✅ Removed DataModels.swift references")

    # Write the cleaned content back
    print("💾 Writing cleaned project file...")
    with open(project_file, 'w') as f:
        f.write(content)

    print("✅ Build fix complete!")
    print("🔨 DataModels.swift has been removed from the Xcode project.")
    print("🔨 The new modular files in Models/ directory should be added separately if needed.")

if __name__ == "__main__":
    main()