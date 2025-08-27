#!/bin/bash

# Deploy Firebase Functions with VPC connector
echo "🚀 Deploying Firebase Functions with static IP configuration..."

# Set PATH for Firebase CLI
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin

# Deploy functions with VPC connector
firebase deploy --only functions

echo "✅ Functions deployed with static IP configuration!"
echo ""
echo "🔍 Test your static IP:"
echo "  curl https://us-central1-nutrasafe-705c7.cloudfunctions.net/checkIP"
echo ""
echo "🍌 Test food search:"
echo "  curl -X POST -H 'Content-Type: application/json' -d '{\"query\": \"banana\"}' https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoods"