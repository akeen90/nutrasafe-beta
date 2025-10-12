#!/bin/bash

# Upload Spellchecked Foods Script
# This uses Firebase CLI and a simpler approach

CSV_FILE="/Users/aaronkeen/Desktop/Spellchecked foods .csv"
PROJECT_ID="nutrasafe-705c7"

echo "======================================"
echo "🚨 DELETING ALL EXISTING FOODS"
echo "======================================"
echo ""

# Delete all existing foods using Firebase CLI
firebase firestore:delete foods --project $PROJECT_ID --recursive --yes

echo ""
echo "✅ Deletion complete"
echo ""
echo "======================================"
echo "📤 Now run Node script to upload CSV"
echo "======================================"
echo ""

# The upload will be done by the Node script with proper auth
cd functions && GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json" node replace-foods-database.js
