#!/bin/bash

# Test script for Live Ingredient Scanner Firebase Functions
echo "🧪 Testing Live Ingredient Scanner Functions"
echo "============================================="

# Test 1: Test detectLiveText function with sample base64 image data
echo "Test 1: Testing detectLiveText function..."

SAMPLE_BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

curl -X POST \
  "https://us-central1-nutrasafe-705c7.cloudfunctions.net/detectLiveText" \
  -H "Content-Type: application/json" \
  -d "{
    \"imageData\": \"$SAMPLE_BASE64\",
    \"sessionId\": \"test-session-123\",
    \"scanType\": \"ingredients\"
  }" | jq '.'

echo ""
echo "Test 2: Testing processIngredientText function..."

# Test 2: Test processIngredientText function with sample text
curl -X POST \
  "https://us-central1-nutrasafe-705c7.cloudfunctions.net/processIngredientText" \
  -H "Content-Type: application/json" \
  -d "{
    \"textChunks\": [\"Water, wheat flour, sugar, yeast, salt\", \"Contains gluten\"],
    \"sessionId\": \"test-session-123\",
    \"scanType\": \"ingredients\",
    \"finalProcess\": true
  }" | jq '.'

echo ""
echo "Test 3: Testing nutrition processing..."

# Test 3: Test nutrition processing
curl -X POST \
  "https://us-central1-nutrasafe-705c7.cloudfunctions.net/processIngredientText" \
  -H "Content-Type: application/json" \
  -d "{
    \"textChunks\": [\"Nutrition Facts Per 100g: Energy 250kcal, Protein 12g, Carbohydrates 45g, Fat 5g, Sugar 2g, Salt 1.2g\"],
    \"sessionId\": \"test-session-456\",
    \"scanType\": \"nutrition\",
    \"finalProcess\": true
  }" | jq '.'

echo ""
echo "✅ Live Scanner Testing Complete!"
echo ""
echo "📋 Summary:"
echo "- detectLiveText: Processes camera frames with Google Cloud Vision"
echo "- processIngredientText: Uses Gemini AI for intelligent text processing"
echo "- Supports both ingredients and nutrition label scanning"
echo "- Real-time text accumulation and deduplication"
echo "- Structured data extraction with confidence scoring"