#!/usr/bin/env python3
import re

def fix_empty_defaults(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # Pattern to find empty default cases
    pattern = r'(\s+)(default|@unknown default):\s*$'

    lines = content.split('\n')
    fixed_lines = []

    for i, line in enumerate(lines):
        fixed_lines.append(line)
        # Check if this is an empty default case
        if re.match(pattern, line):
            # Add a break statement on the next line with proper indentation
            indent = len(line) - len(line.lstrip())
            fixed_lines.append(' ' * (indent + 4) + 'break')

    return '\n'.join(fixed_lines)

# Fix the files
files = [
    "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift",
    "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/DiaryTabView.swift"
]

for file_path in files:
    print(f"Fixing {file_path.split('/')[-1]}...")
    fixed_content = fix_empty_defaults(file_path)
    with open(file_path, 'w') as f:
        f.write(fixed_content)
    print(f"  Done")

print("All empty default cases fixed!")
