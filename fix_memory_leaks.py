#!/usr/bin/env python3
"""
Script to fix memory leak issues by adding weak references to Timer closures
and ensuring proper notification center handling
"""

import re
import os

def fix_timer_retain_cycles(content):
    """Fix Timer.scheduledTimer closures to use weak self"""
    
    # Pattern to match Timer.scheduledTimer without weak self
    pattern = r'(Timer\.scheduledTimer\(withTimeInterval:.*?repeats:.*?\)\s*\{)\s*(_|\w+)?\s*(in\s+)?'
    
    def replace_with_weak(match):
        base = match.group(1)
        param = match.group(2) if match.group(2) else "_"
        in_keyword = match.group(3) if match.group(3) else ""
        
        # Check if weak self is already present
        if '[weak self]' in match.group(0):
            return match.group(0)
        
        return f"{base} [weak self] {param} {in_keyword}"
    
    content = re.sub(pattern, replace_with_weak, content)
    
    # Fix self usage in timer closures to self?
    # Pattern to match self. that's not already self?.
    pattern2 = r'(Timer\.scheduledTimer.*?\[weak self\].*?\{[^}]*?)(?<!self\?)self\.(\w+)'
    
    def replace_self_with_optional(match):
        return match.group(1) + 'self?.' + match.group(2)
    
    content = re.sub(pattern2, replace_self_with_optional, content, flags=re.DOTALL)
    
    return content

def fix_notification_observers(content):
    """Ensure NotificationCenter observers are properly removed"""
    
    # Check if deinit exists, if not add it with notification removal
    if 'deinit {' not in content and 'NotificationCenter.default.addObserver' in content:
        # Find the class/struct definition
        class_match = re.search(r'(class|struct)\s+(\w+)[^{]*\{', content)
        if class_match:
            # Find the end of the class/struct
            # This is a simplified approach - for production use a proper parser
            insert_pos = content.rfind('}')
            if insert_pos > 0:
                deinit_code = """
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
"""
                content = content[:insert_pos] + deinit_code + content[insert_pos:]
    
    return content

def process_file(filepath):
    """Process a single Swift file to fix memory leaks"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Apply fixes
    content = fix_timer_retain_cycles(content)
    content = fix_notification_observers(content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    # Files that need memory leak fixes
    files_to_fix = [
        "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/ContentView.swift",
        "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Components/Exercise/RestTimerViews.swift",
        "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/Exercise/NewWorkoutView.swift",
        "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/Food/FoodSearchViews.swift",
    ]
    
    print("Fixing memory leak issues in Swift files...")
    fixed_count = 0
    
    for filepath in files_to_fix:
        if os.path.exists(filepath):
            if process_file(filepath):
                print(f"✅ Fixed: {os.path.basename(filepath)}")
                fixed_count += 1
            else:
                print(f"⏭️  No changes needed: {os.path.basename(filepath)}")
        else:
            print(f"❌ File not found: {filepath}")
    
    print(f"\n✅ Fixed memory leaks in {fixed_count} files")

if __name__ == "__main__":
    main()