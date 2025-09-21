// Test the improved AI function with mandatory research requirements
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testImprovedAI() {
  console.log('🧪 TESTING IMPROVED AI WITH MANDATORY RESEARCH 🧪\n');
  
  const testFood = {
    id: 'improved-test-' + Date.now(),
    name: 'Coca Cola Classic',
    brand: 'Coca-Cola',
    barcode: '', // Empty - should find real barcode
    ingredients: 'Carbonated Water, Sugar, Natural Flavourings, Caffeine',
    nutritionData: { calories: 139, protein: 0, carbs: 35, fat: 0 }
  };
  
  console.log('📤 SENDING FOOD FOR IMPROVED AI PROCESSING:');
  console.log(`   Name: ${testFood.name}`);
  console.log(`   Brand: ${testFood.brand}`);
  console.log(`   Current ingredients: ${testFood.ingredients}`);
  console.log(`   Expected: 330ml can serving size, complete ingredients with preservatives, full nutrition`);
  
  try {
    const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        foods: [testFood],
        batchId: 'improved-test-' + Date.now()
      })
    });
    
    if (!response.ok) {
      console.error(`❌ API Failed: ${response.status}`);
      const text = await response.text();
      console.error(text);
      return;
    }
    
    const result = await response.json();
    
    console.log('\n📋 IMPROVED AI RESULTS:');
    console.log(`   ✅ Success: ${result.success}`);
    console.log(`   📊 Processed: ${result.processed} foods`);
    console.log(`   💰 Cost: $${result.summary.estimatedCost.toFixed(4)}`);
    
    if (result.results && result.results.length > 0) {
      const enhanced = result.results[0];
      
      if (enhanced.cleanedData) {
        const cd = enhanced.cleanedData;
        
        console.log('\n🎯 DETAILED ENHANCED DATA ANALYSIS:');
        console.log('========================================');
        
        // Food Identity
        console.log(`🏷️  Food Name: "${cd.foodName || cd.name || 'MISSING'}"`);
        console.log(`🏪 Brand: "${cd.brandName || cd.brand || 'MISSING'}"`);
        console.log(`📊 Barcode: "${cd.barcode || 'MISSING'}"`);
        
        // Serving Size Analysis
        console.log(`\n📏 SERVING SIZE ANALYSIS:`);
        if (cd.servingSize) {
          if (typeof cd.servingSize === 'object') {
            console.log(`   Amount: ${cd.servingSize.amount || 'MISSING'}`);
            console.log(`   Unit: ${cd.servingSize.unit || 'MISSING'}`);
            console.log(`   Description: ${cd.servingSize.description || 'MISSING'}`);
          } else {
            console.log(`   Text: "${cd.servingSize}"`);
          }
        } else {
          console.log(`   ❌ MISSING SERVING SIZE`);
        }
        
        // Ingredients Analysis
        console.log(`\n🧪 INGREDIENTS ANALYSIS:`);
        const ingredients = cd.ingredients || cd.fullIngredientsList || 'MISSING';
        console.log(`   Length: ${ingredients.length} characters`);
        console.log(`   Content: "${ingredients.substring(0, 120)}..."`);
        console.log(`   Has preservatives: ${ingredients.includes('Phosphoric') ? '✅' : '❌'}`);
        console.log(`   Has E-numbers: ${ingredients.includes('E150') ? '✅' : '❌'}`);
        
        // Nutrition Per 100g Analysis
        console.log(`\n🔥 NUTRITION PER 100g ANALYSIS:`);
        const per100g = cd.nutritionPer100g || cd.nutritionData || {};
        console.log(`   Calories: ${per100g.calories || 'MISSING'} kcal`);
        console.log(`   Protein: ${per100g.protein || 'MISSING'}g`);
        console.log(`   Carbs: ${per100g.carbs || 'MISSING'}g`);
        console.log(`   Sugar: ${per100g.sugar || 'MISSING'}g`);
        console.log(`   Fat: ${per100g.fat || 'MISSING'}g`);
        console.log(`   Fiber: ${per100g.fiber || 'MISSING'}g`);
        console.log(`   Sodium: ${per100g.sodium || 'MISSING'}mg`);
        console.log(`   Salt: ${per100g.salt || 'MISSING'}g`);
        
        // Nutrition Per Serving Analysis
        console.log(`\n🍽️  NUTRITION PER SERVING ANALYSIS:`);
        const perServing = cd.nutritionPerServing || cd.nutritionData?.perServing || {};
        console.log(`   Calories: ${perServing.calories || 'MISSING'} kcal`);
        console.log(`   Protein: ${perServing.protein || 'MISSING'}g`);
        console.log(`   Carbs: ${perServing.carbs || 'MISSING'}g`);
        console.log(`   Sugar: ${perServing.sugar || 'MISSING'}g`);
        console.log(`   Fat: ${perServing.fat || 'MISSING'}g`);
        console.log(`   Fiber: ${perServing.fiber || 'MISSING'}g`);
        console.log(`   Sodium: ${perServing.sodium || 'MISSING'}mg`);
        console.log(`   Salt: ${perServing.salt || 'MISSING'}g`);
        
        // Success Validation
        console.log('\n🎯 IMPROVEMENT VALIDATION:');
        
        let improvements = 0;
        let issues = 0;
        
        // Check serving size
        if (cd.servingSize && (cd.servingSize.includes('330ml') || cd.servingSize.includes('ml'))) {
          console.log(`   ✅ SERVING SIZE: Correct liquid measure (${cd.servingSize})`);
          improvements++;
        } else {
          console.log(`   ❌ SERVING SIZE: Still wrong - should be 330ml can`);
          issues++;
        }
        
        // Check sugar values
        if (per100g.sugar && per100g.sugar > 8 && perServing.sugar && perServing.sugar > 25) {
          console.log(`   ✅ SUGAR VALUES: Realistic (${per100g.sugar}g per 100ml, ${perServing.sugar}g per serving)`);
          improvements++;
        } else {
          console.log(`   ❌ SUGAR VALUES: Missing or unrealistic`);
          issues++;
        }
        
        // Check ingredients
        if (ingredients.includes('Phosphoric') || ingredients.includes('E150')) {
          console.log(`   ✅ INGREDIENTS: Enhanced with preservatives/colors`);
          improvements++;
        } else {
          console.log(`   ❌ INGREDIENTS: Still basic - missing preservatives`);
          issues++;
        }
        
        // Check barcode
        if (cd.barcode && cd.barcode.length >= 12 && cd.barcode !== testFood.barcode) {
          console.log(`   ✅ BARCODE: Found real barcode (${cd.barcode})`);
          improvements++;
        } else {
          console.log(`   ❌ BARCODE: Missing or not enhanced`);
          issues++;
        }
        
        console.log(`\n📊 FINAL SCORE: ${improvements} improvements, ${issues} issues`);
        
        if (improvements >= 3) {
          console.log(`🎉 SUCCESS: AI is now providing enhanced product data!`);
        } else {
          console.log(`⚠️  PARTIAL: Some improvements but still needs work`);
        }
        
      } else {
        console.log('\n❌ CRITICAL: No cleanedData returned');
      }
    } else {
      console.log('\n❌ CRITICAL: No results returned');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testImprovedAI();