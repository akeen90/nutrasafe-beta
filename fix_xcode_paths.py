#!/usr/bin/env python3
"""
Fix the incorrect file paths in Xcode project
"""

import subprocess
import os

def fix_xcode_paths():
    """Fix file paths using xcodeproj ruby gem"""
    
    # Ruby script to fix paths
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

# Remove files with incorrect paths
files_to_remove = []
project.files.each do |file|
  if file.path && (
    file.path.include?("NutraSafe Beta/Views/Components/") ||
    file.path.include?("NutraSafe Beta/Views/Diary/") ||
    file.path.include?("NutraSafe Beta/Models/") ||
    file.path.include?("NutraSafe Beta/Configuration/")
  )
    files_to_remove << file
  end
end

# Remove from build phases first
files_to_remove.each do |file|
  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref == file
      target.source_build_phase.remove_file_reference(file)
      break
    end
  end
end

# Remove file references
files_to_remove.each do |file|
  file.remove_from_project
end

puts "Removed #{files_to_remove.length} files with incorrect paths"

# Find the main group
main_group = project.main_group["NutraSafe Beta"]
unless main_group
  puts "Could not find main group 'NutraSafe Beta'"
  exit 1
end

# Files to add with correct paths
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
    existing_group = current_group.children.find { |child| 
      child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == part 
    }
    if existing_group
      current_group = existing_group
    else
      new_group = project.new(Xcodeproj::Project::Object::PBXGroup)
      new_group.name = part
      new_group.path = part
      new_group.source_tree = '<group>'
      current_group.children << new_group
      current_group = new_group
    end
  end
  
  # Add files to the group
  files.each do |filename|
    # Relative path from the group
    relative_path = filename
    # Full path for existence check
    full_path = File.join("/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta", subdir, filename)
    
    unless File.exist?(full_path)
      puts "⚠️  File not found: #{full_path}"
      next
    end
    
    # Check if file is already in project with correct path
    file_exists = false
    project.files.each do |f|
      if f.path && f.path.end_with?(filename)
        # Check if it's in the right place
        if f.real_path.to_s == full_path
          file_exists = true
          break
        end
      end
    end
    
    unless file_exists
      # Create file reference with correct path
      file_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
      file_ref.path = relative_path
      file_ref.source_tree = '<group>'
      file_ref.last_known_file_type = 'sourcecode.swift'
      
      # Add to group
      current_group.children << file_ref
      
      # Add to build phase
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.file_ref = file_ref
      target.source_build_phase.files << build_file
      
      puts "✅ Added #{filename} with correct path"
      added_count += 1
    else
      puts "ℹ️  #{filename} already exists with correct path"
    end
  end
end

# Save the project
project.save
puts "\\n✅ Successfully fixed #{added_count} file paths in Xcode project"
'''
    
    # Write the Ruby script to a temp file
    script_path = "/tmp/fix_xcode_paths.rb"
    with open(script_path, 'w') as f:
        f.write(ruby_script)
    
    # Execute the Ruby script
    print("Fixing file paths in Xcode project...")
    result = subprocess.run(f"ruby {script_path}", shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("Errors:", result.stderr)
    
    return result.returncode == 0

def main():
    print("🔧 Fixing file paths in Xcode project...")
    if fix_xcode_paths():
        print("\n✅ File paths fixed successfully")
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
        print("❌ Failed to fix file paths")

if __name__ == "__main__":
    main()