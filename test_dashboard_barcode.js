// Dashboard test for enhanced barcode lookup functionality
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testDashboardBarcode() {
  console.log('🔍 DASHBOARD BARCODE LOOKUP TEST 🔍\n');
  
  const testFoods = [
    {
      id: 'dash-barcode-1-' + Date.now(),
      name: 'Tesco Apple Juice',
      brand: 'Tesco', 
      barcode: '000000000000', // Fake - should be replaced or removed
      ingredients: 'Apple Juice from Concentrate 95%, Water, Natural Flavouring',
      nutritionData: { calories: 42, protein: 0.1, carbs: 10.3, fat: 0.1 }
    },
    {
      id: 'dash-barcode-2-' + Date.now(),
      name: 'Coca Cola Classic',
      brand: 'Coca-Cola',
      barcode: '', // Empty - should search for real barcode
      ingredients: 'Carbonated Water, Sugar, Natural Flavourings, Caffeine',
      nutritionData: { calories: 139, protein: 0, carbs: 35, fat: 0 }
    },
    {
      id: 'dash-barcode-3-' + Date.now(),
      name: 'Mars Bar',
      brand: 'Mars',
      barcode: '5000159407236', // Real barcode - should be preserved
      ingredients: 'Sugar, Glucose Syrup, Cocoa Butter, Skimmed Milk Powder',
      nutritionData: { calories: 449, protein: 4.2, carbs: 65, fat: 17.4 }
    },
    {
      id: 'dash-barcode-4-' + Date.now(),
      name: 'Heinz Baked Beans',
      brand: 'Heinz',
      barcode: '123456789012', // Fake pattern - should search for real one
      ingredients: 'Beans (51%), Tomatoes, Water, Sugar, Spirit Vinegar',
      nutritionData: { calories: 75, protein: 4.7, carbs: 13, fat: 0.6 }
    }
  ];
  
  console.log(`📤 SENDING ${testFoods.length} FOODS TO AI FOR BARCODE PROCESSING:`);
  testFoods.forEach((food, i) => {
    console.log(`   ${i+1}. ${food.name} (${food.brand}) - Barcode: "${food.barcode}"`);
  });
  
  try {
    const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        foods: testFoods,
        batchId: 'dashboard-barcode-test-' + Date.now()
      })
    });
    
    if (!response.ok) {
      console.error(`❌ Failed: ${response.status}`);
      const text = await response.text();
      console.error(text);
      return;
    }
    
    const result = await response.json();
    console.log('\n📋 AI PROCESSING RESULTS:');
    console.log(`   ✅ Success: ${result.success}`);
    console.log(`   📊 Processed: ${result.processed} foods`);
    console.log(`   💰 Cost: $${result.summary.estimatedCost.toFixed(4)}`);
    
    result.results.forEach((res, i) => {
      console.log(`   ${i+1}. Issues: ${res.issues?.join(', ') || 'None'}`);
    });
    
    console.log('\n⏳ Waiting for database processing (10 seconds)...');
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    // Check results in database
    const savedResponse = await fetch(`${API_BASE}/getCleansedFoods?limit=10`);
    if (savedResponse.ok) {
      const savedData = await savedResponse.json();
      
      console.log('\n🎯 DASHBOARD RESULTS:');
      console.log('==================================================');
      
      if (savedData.foods && savedData.foods.length > 0) {
        // Show the latest processed foods
        const recentFoods = savedData.foods.slice(0, 4);
        
        recentFoods.forEach((food, i) => {
          const finalBarcode = food.cleanedData?.barcode || food.barcode || 'null';
          const originalBarcode = food.originalData?.barcode || testFoods[i]?.barcode || 'unknown';
          
          console.log(`\n📍 FOOD ${i+1}: ${food.cleanedData?.foodName || food.name}`);
          console.log(`   🏪 Brand: ${food.cleanedData?.brandName || food.brand}`);
          console.log(`   📊 Original Barcode: "${originalBarcode}"`);
          console.log(`   📊 Final Barcode: "${finalBarcode}"`);
          
          // Analyze the result
          if (originalBarcode === '000000000000' || originalBarcode === '123456789012' || originalBarcode === '') {
            if (finalBarcode && finalBarcode !== 'null' && finalBarcode.length >= 12 && finalBarcode !== originalBarcode) {
              console.log(`   ✅ SUCCESS: Found real barcode replacement!`);
            } else if (finalBarcode === '' || finalBarcode === 'null') {
              console.log(`   ⚠️  OK: Invalid barcode removed (no replacement found)`);
            } else {
              console.log(`   ❌ ISSUE: Expected barcode change or removal`);
            }
          } else {
            // Should preserve valid barcode
            if (finalBarcode === originalBarcode) {
              console.log(`   ✅ SUCCESS: Valid barcode preserved!`);
            } else {
              console.log(`   ❌ ISSUE: Valid barcode was changed unexpectedly`);
            }
          }
          
          // Show additional processing info
          console.log(`   🧪 Ingredients: ${(food.cleanedData?.ingredients || '').substring(0, 50)}...`);
          console.log(`   📏 Serving Size: ${food.cleanedData?.servingSize || 'Not specified'}`);
        });
        
        console.log('\n🎯 SUMMARY:');
        console.log(`   📊 Total foods processed: ${recentFoods.length}`);
        console.log(`   🔍 Barcode validation: ACTIVE`);
        console.log(`   🔎 Barcode lookup: ENABLED`); 
        console.log(`   🤖 AI Provider: OpenAI GPT-4o`);
        console.log('\n✅ Check your Firebase dashboard at: https://nutrasafe-705c7.web.app/admin.html');
        console.log('   The processed foods should now be visible with enhanced barcode processing!');
        
      } else {
        console.log('❌ No processed foods found in database');
      }
    } else {
      console.error('❌ Failed to retrieve processed foods from database');
    }
    
  } catch (error) {
    console.error('❌ Dashboard test failed:', error.message);
  }
}

testDashboardBarcode();