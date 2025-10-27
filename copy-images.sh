#!/bin/bash
# Script to copy screenshots to firebase public directory

echo "Copying screenshots to firebase public folder..."

cp "/Users/aaronkeen/Documents/My Apps/NutraSafe/public/nutrition-dashboard.png" "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/public/"
cp "/Users/aaronkeen/Documents/My Apps/NutraSafe/public/ingredients-view.png" "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/public/"
cp "/Users/aaronkeen/Documents/My Apps/NutraSafe/public/allergy-alerts.png" "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/public/"
cp "/Users/aaronkeen/Documents/My Apps/NutraSafe/public/scan-screen.png" "/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/public/"

echo "Done! Screenshots copied successfully."
echo ""
echo "Now run: cd firebase && firebase deploy"
