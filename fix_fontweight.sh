#!/bin/bash

# Script to fix iOS 16 fontWeight compatibility issues
echo "Fixing fontWeight compatibility issues..."

EXERCISE_DIR="/Users/aaronkeen/Documents/My Apps/NutraSafe Beta/NutraSafe Beta/Views/Exercise"

# Fix fontWeight in all Exercise view files
find "$EXERCISE_DIR" -name "*.swift" -type f -exec perl -i -pe '
    # Match .fontWeight(.semibold) and replace with .font(.system(size: 16, weight: .semibold))
    s/\.fontWeight\(\.semibold\)/.font(.system(size: 16, weight: .semibold))/g;
    
    # Match .fontWeight(.bold) and replace with .font(.system(size: 16, weight: .bold))
    s/\.fontWeight\(\.bold\)/.font(.system(size: 16, weight: .bold))/g;
    
    # Match .fontWeight(.medium) and replace with .font(.system(size: 16, weight: .medium))
    s/\.fontWeight\(\.medium\)/.font(.system(size: 16, weight: .medium))/g;
    
    # Match .fontWeight(.regular) and replace with .font(.system(size: 16, weight: .regular))
    s/\.fontWeight\(\.regular\)/.font(.system(size: 16, weight: .regular))/g;
    
    # Match .fontWeight(.light) and replace with .font(.system(size: 16, weight: .light))
    s/\.fontWeight\(\.light\)/.font(.system(size: 16, weight: .light))/g;
    
    # Match .fontWeight(.heavy) and replace with .font(.system(size: 16, weight: .heavy))
    s/\.fontWeight\(\.heavy\)/.font(.system(size: 16, weight: .heavy))/g;
' {} \;

echo "FontWeight fixes complete!"
echo "Files processed:"
find "$EXERCISE_DIR" -name "*.swift" -type f | wc -l