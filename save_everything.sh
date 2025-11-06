#!/bin/bash
# Save everything script - run this anytime

echo "Checking for changes..."
if [[ -n $(git status -s) ]]; then
    echo "📦 Saving all changes..."
    git add .
    git commit -m "chore: Save current state $(date '+%Y-%m-%d %H:%M')"
    git push
    echo "✅ Everything saved and backed up to GitHub!"
else
    echo "✅ Nothing to save - already up to date!"
fi
