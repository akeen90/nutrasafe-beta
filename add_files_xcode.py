#!/usr/bin/env python3
"""
Script to add new component files to Xcode project
"""

import subprocess
import os

def add_files_with_xcodeproj():
    """Add files using xcodeproj ruby gem"""
    
    # First check if the gem is installed
    check_cmd = "gem list xcodeproj -i"
    result = subprocess.run(check_cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Installing xcodeproj gem...")
        install_cmd = "sudo gem install xcodeproj"
        subprocess.run(install_cmd, shell=True)
    
    # Ruby script to add files
    ruby_script = '''
require 'xcodeproj'

project_path = "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafeBeta.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == "NutraSafe Beta" }
unless target
  puts "Could not find target 'NutraSafe Beta'"
  exit 1
end

# Find the main group
main_group = project.main_group["NutraSafe Beta"]
unless main_group
  puts "Could not find main group 'NutraSafe Beta'"
  exit 1
end

# Files to add organized by subdirectory
files_to_add = {
  "Views/Components" => [
    "ActionButtons.swift",
    "CustomTabBar.swift",
    "MacroViews.swift",
    "NutritionScoreViews.swift",
  ],
  "Views/Diary" => [
    "DiaryComponents.swift",
    "DiaryExerciseComponents.swift",
  ],
  "Models" => [
    "CoreModels.swift",
    "ExerciseModels.swift",
    "FoodSafetyModels.swift",
    "HealthKitModels.swift",
    "NutritionModels.swift",
    "ScoringModels.swift",
    "SearchModels.swift",
    "TrackingModels.swift",
    "UserModels.swift",
    "AllModels.swift",
  ],
  "Configuration" => [
    "AppConfig.swift",
  ],
}

added_count = 0

files_to_add.each do |subdir, files|
  # Navigate/create subdirectory groups
  current_group = main_group
  subdir.split("/").each do |part|
    existing_group = current_group.children.find { |child| child.display_name == part }
    if existing_group
      current_group = existing_group
    else
      current_group = current_group.new_group(part, part)
    end
  end
  
  # Add files to the group
  files.each do |filename|
    file_path = File.join("NutraSafe Beta", subdir, filename)
    full_path = File.join("/Users/aaronkeen/Documents/My Apps/NutraSafe Beta", file_path)
    
    unless File.exist?(full_path)
      puts "⚠️  File not found: #{full_path}"
      next
    end
    
    # Check if file is already in project
    file_exists = project.files.any? { |f| f.path&.end_with?(filename) }
    
    unless file_exists
      # Add file reference
      file_ref = current_group.new_reference(file_path)
      
      # Add to build phase
      target.source_build_phase.add_file_reference(file_ref)
      
      puts "✅ Added #{filename}"
      added_count += 1
    else
      puts "ℹ️  #{filename} already in project"
    end
  end
end

# Save the project
project.save
puts "\\n✅ Successfully added #{added_count} files to Xcode project"
'''
    
    # Write the Ruby script to a temp file
    script_path = "/tmp/add_files_to_xcode.rb"
    with open(script_path, 'w') as f:
        f.write(ruby_script)
    
    # Execute the Ruby script
    print("Adding files to Xcode project...")
    result = subprocess.run(f"ruby {script_path}", shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("Errors:", result.stderr)
    
    return result.returncode == 0

def main():
    print("🔧 Adding files to Xcode project using xcodeproj gem...")
    if add_files_with_xcodeproj():
        print("\n✅ Files successfully added to Xcode project")
        print("\n🔨 Now running build to verify...")
        
        # Run a build to verify
        build_cmd = '''cd "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta" && \
xcodebuild -project NutraSafeBeta.xcodeproj \
-scheme "NutraSafe Beta" \
-destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
build 2>&1 | tail -5'''
        
        result = subprocess.run(build_cmd, shell=True, capture_output=True, text=True)
        print(result.stdout)
    else:
        print("❌ Failed to add files to Xcode project")

if __name__ == "__main__":
    main()