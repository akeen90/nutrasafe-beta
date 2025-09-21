#!/bin/bash

echo "🧪 Testing Enhanced Additive Detection for Hidden Additives"
echo "========================================================="

# Test with gelatin (marshmallows)
echo ""
echo "1. Testing marshmallow ingredients (should detect GELATIN):"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "glucose syrup, sugar, water, pork gelatin, dextrose, natural flavoring, colorant"}' \
  | jq -r '.additives[] | select(.code == "GELATIN") | "✅ Found: \(.code) - \(.name) (\(.origin))"'

# Test with carmine (red sweets)  
echo ""
echo "2. Testing red candy ingredients (should detect E120 Carmine):"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "sugar, glucose syrup, carmine, natural strawberry flavor, citric acid"}' \
  | jq -r '.additives[] | select(.code == "E120") | "✅ Found: \(.code) - \(.name) (\(.origin))"'

# Test with hidden dairy (casein in non-dairy creamer)
echo ""
echo "3. Testing non-dairy creamer with casein (should detect CASEIN):"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "corn syrup solids, vegetable oil, sodium caseinate, natural flavor, dipotassium phosphate"}' \
  | jq -r '.additives[] | select(.code == "CASEIN") | "✅ Found: \(.code) - \(.name) - HIDDEN DAIRY ALERT"'

# Test with cheese rennet
echo ""
echo "4. Testing traditional cheese (should detect RENNET):"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "pasteurized milk, salt, cheese cultures, animal rennet"}' \
  | jq -r '.additives[] | select(.code == "RENNET") | "✅ Found: \(.code) - \(.name) - ANIMAL ENZYME"'

# Test comprehensive product (multiple hidden additives)
echo ""
echo "5. Testing complex processed food (should detect multiple):"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "wheat flour, sugar, vegetable oils, cochineal, soy lecithin, gelatin, sodium nitrite, BHA, natural flavoring"}' \
  | jq -r '.additives[] | "✅ \(.code): \(.name) (\(.origin // "synthetic"))"'

echo ""
echo "🔍 Enhanced Detection Summary:"
curl -s -X POST https://us-central1-nutrasafe-705c7.cloudfunctions.net/analyzeAdditivesEnhanced \
  -H "Content-Type: application/json" \
  -d '{"ingredients": "wheat flour, sugar, vegetable oils, cochineal, soy lecithin, gelatin, sodium nitrite, BHA, natural flavoring"}' \
  | jq -r '"Total additives detected: \(.metadata.totalAdditives)"'

echo ""
echo "✅ Enhanced additive detection test completed!"