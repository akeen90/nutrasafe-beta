#!/usr/bin/env python3
"""
Remove DataModels.swift from Xcode project since we've split it into separate files
"""

import subprocess

def remove_datamodels():
    """Remove DataModels.swift using xcodeproj ruby gem"""
    
    # Ruby script to remove DataModels.swift
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

# Find and remove DataModels.swift
removed = false
project.files.each do |file|
  if file.path && file.path.end_with?("DataModels.swift")
    # Remove from build phases
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == file
        target.source_build_phase.remove_file_reference(file)
        break
      end
    end
    
    # Remove file reference
    file.remove_from_project
    removed = true
    puts "✅ Removed DataModels.swift from project"
    break
  end
end

unless removed
  puts "⚠️  DataModels.swift not found in project"
end

# Save the project
project.save
puts "✅ Project saved"
'''
    
    # Write the Ruby script to a temp file
    script_path = "/tmp/remove_datamodels.rb"
    with open(script_path, 'w') as f:
        f.write(ruby_script)
    
    # Execute the Ruby script
    print("Removing DataModels.swift from Xcode project...")
    result = subprocess.run(f"ruby {script_path}", shell=True, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print("Errors:", result.stderr)
    
    return result.returncode == 0

def main():
    print("🔧 Removing DataModels.swift from Xcode project...")
    if remove_datamodels():
        print("\n✅ DataModels.swift removed successfully")
        print("\n🔨 Now running build to verify...")
        
        # Run a build to verify
        build_cmd = '''cd "/Users/aaronkeen/Documents/My Apps/NutraSafe Beta" && \
xcodebuild -project NutraSafeBeta.xcodeproj \
-scheme "NutraSafe Beta" \
-destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
build 2>&1 | grep "BUILD SUCCEEDED" || echo "Build still in progress or failed"'''
        
        result = subprocess.run(build_cmd, shell=True, capture_output=True, text=True)
        print(result.stdout)
    else:
        print("❌ Failed to remove DataModels.swift")

if __name__ == "__main__":
    main()