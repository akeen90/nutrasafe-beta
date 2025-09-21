// Simple test for recheck functionality
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testRecheckFunction() {
  console.log('🧪 TESTING RECHECK FUNCTIONALITY 🧪\n');
  
  const testFood = {
    id: 'recheck-test-' + Date.now(),
    name: 'Coca Cola Classic',
    brand: 'Coca-Cola',
    barcode: '', // Empty barcode - should find real one
    ingredients: 'Carbonated Water, Sugar, Natural Flavourings, Caffeine',
    nutritionData: { calories: 139, protein: 0, carbs: 35, fat: 0 }
  };
  
  console.log('📤 SENDING FOOD FOR RECHECK:');
  console.log(`   Name: ${testFood.name}`);
  console.log(`   Brand: ${testFood.brand}`);
  console.log(`   Barcode: "${testFood.barcode}" (empty - should find real one)`);
  console.log(`   Ingredients: ${testFood.ingredients.substring(0, 50)}...`);
  
  try {
    const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        foods: [testFood],
        batchId: 'recheck-test-' + Date.now()
      })
    });
    
    if (!response.ok) {
      console.error(`❌ API Failed: ${response.status}`);
      const text = await response.text();
      console.error(text);
      return;
    }
    
    const result = await response.json();
    
    console.log('\n📋 AI RECHECK RESULTS:');
    console.log(`   ✅ Success: ${result.success}`);
    console.log(`   📊 Processed: ${result.processed} foods`);
    console.log(`   💰 Cost: $${result.summary.estimatedCost.toFixed(4)}`);
    
    if (result.results && result.results.length > 0) {
      const enhanced = result.results[0];
      
      console.log('\n🔍 DETAILED RESPONSE ANALYSIS:');
      console.log(`   - Has cleanedData: ${!!enhanced.cleanedData}`);
      console.log(`   - Issues: ${enhanced.issues?.join(', ') || 'None'}`);
      console.log(`   - Severity: ${enhanced.severity}`);
      
      if (enhanced.cleanedData) {
        const cd = enhanced.cleanedData;
        
        console.log('\n✅ ENHANCED DATA RECEIVED:');
        console.log(`   🏷️  Food Name: "${cd.foodName || cd.name || 'N/A'}"`);
        console.log(`   🏪 Brand: "${cd.brandName || cd.brand || 'N/A'}"`);
        console.log(`   📊 Barcode: "${cd.barcode || 'N/A'}"`);
        console.log(`   📏 Serving Size: "${cd.servingSize || 'N/A'}"`);
        console.log(`   🧪 Ingredients: "${(cd.ingredients || 'N/A').substring(0, 80)}..."`);
        console.log(`   🔥 Calories per 100g: ${cd.nutritionData?.calories || cd.nutritionPer100g?.calories || 'N/A'}`);
        console.log(`   🥩 Protein per 100g: ${cd.nutritionData?.protein || cd.nutritionPer100g?.protein || 'N/A'}g`);
        
        // Test serving nutrition
        if (cd.nutritionData?.perServing || cd.nutritionPerServing) {
          const perServing = cd.nutritionData?.perServing || cd.nutritionPerServing;
          console.log(`   🍽️  Calories per serving: ${perServing.calories || 'N/A'}`);
          console.log(`   🍽️  Protein per serving: ${perServing.protein || 'N/A'}g`);
        }
        
        console.log('\n🎯 RECHECK TEST SUMMARY:');
        
        // Check if barcode was enhanced
        if (testFood.barcode === '' && cd.barcode && cd.barcode.length > 8) {
          console.log(`   ✅ BARCODE ENHANCEMENT: Found real barcode "${cd.barcode}"`);
        } else if (testFood.barcode === cd.barcode) {
          console.log(`   ⚠️  BARCODE: No change (still "${cd.barcode}")`);
        }
        
        // Check if serving size was enhanced
        if (cd.servingSize && cd.servingSize !== '100g') {
          console.log(`   ✅ SERVING SIZE: Enhanced to "${cd.servingSize}"`);
        } else {
          console.log(`   ⚠️  SERVING SIZE: Standard 100g`);
        }
        
        // Check if ingredients were enhanced
        if (cd.ingredients && cd.ingredients.length > testFood.ingredients.length) {
          console.log(`   ✅ INGREDIENTS: Enhanced (${testFood.ingredients.length} → ${cd.ingredients.length} chars)`);
        } else {
          console.log(`   ⚠️  INGREDIENTS: No significant enhancement`);
        }
        
        console.log('\n🚀 DASHBOARD RECHECK SIMULATION:');
        console.log('   This is what would be updated in the dashboard form fields:');
        console.log(`   - Name field: "${cd.foodName || cd.name}"`);
        console.log(`   - Brand field: "${cd.brandName || cd.brand}"`);
        console.log(`   - Barcode field: "${cd.barcode}"`);
        console.log(`   - Ingredients field: "${(cd.ingredients || '').substring(0, 60)}..."`);
        console.log(`   - Serving field: "${cd.servingSize}"`);
        
      } else {
        console.log('\n❌ NO ENHANCED DATA:');
        console.log('   The AI function did not return cleanedData');
        console.log('   This means the recheck button would show "no data" in dashboard');
      }
    } else {
      console.log('\n❌ NO RESULTS: AI function returned empty results array');
    }
    
  } catch (error) {
    console.error('❌ Recheck test failed:', error.message);
  }
}

testRecheckFunction();