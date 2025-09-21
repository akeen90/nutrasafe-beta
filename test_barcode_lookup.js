// Test the enhanced barcode lookup functionality
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testBarcodeSearch() {
  console.log('🔍 TESTING BARCODE LOOKUP FUNCTIONALITY 🔍\n');
  
  const testCases = [
    {
      name: 'Fake Barcode Replacement',
      food: {
        id: 'barcode-test-1-' + Date.now(),
        name: 'Tesco Apple Juice',
        brand: 'Tesco',
        barcode: '000000000000', // Fake barcode - should find real one
        ingredients: 'Apple Juice from Concentrate 95%, Water',
      }
    },
    {
      name: 'Missing Barcode Search',
      food: {
        id: 'barcode-test-2-' + Date.now(),
        name: 'Coca Cola',
        brand: 'Coca-Cola',
        barcode: '', // Empty - should search for real barcode
        ingredients: 'Carbonated Water, Sugar, Natural Flavourings',
      }
    },
    {
      name: 'Valid Barcode Preservation',
      food: {
        id: 'barcode-test-3-' + Date.now(),
        name: 'Mars Bar',
        brand: 'Mars',
        barcode: '5000159407236', // Real barcode - should keep it
        ingredients: 'Sugar, Glucose Syrup, Cocoa Butter',
      }
    }
  ];
  
  for (const testCase of testCases) {
    console.log(`📤 TESTING: ${testCase.name}`);
    console.log(`   Product: ${testCase.food.name} (${testCase.food.brand})`);
    console.log(`   Original barcode: "${testCase.food.barcode}"`);
    
    try {
      // Call the AI analysis function
      const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          foods: [testCase.food],
          batchId: testCase.food.id
        })
      });
      
      if (!response.ok) {
        console.error(`   ❌ Failed: ${response.status}`);
        continue;
      }
      
      const result = await response.json();
      console.log(`   📊 AI detected issues: ${result.results[0]?.issues?.join(', ') || 'None'}`);
      
      // Wait for database processing
      await new Promise(resolve => setTimeout(resolve, 4000));
      
      // Check processed result
      const savedResponse = await fetch(`${API_BASE}/getCleansedFoods?limit=1`);
      if (savedResponse.ok) {
        const savedData = await savedResponse.json();
        
        if (savedData.foods && savedData.foods.length > 0) {
          const processedFood = savedData.foods[0];
          const finalBarcode = processedFood.cleanedData?.barcode || processedFood.barcode;
          
          console.log(`   📊 Final barcode: "${finalBarcode}"`);
          
          // Analyze the result
          if (testCase.food.barcode === '000000000000' || testCase.food.barcode === '') {
            if (finalBarcode && finalBarcode.length >= 12 && finalBarcode !== testCase.food.barcode) {
              console.log(`   ✅ SUCCESS: Found real barcode!`);
            } else if (finalBarcode === '') {
              console.log(`   ⚠️  OK: No barcode found (searched but none available)`);
            } else {
              console.log(`   ❌ FAILED: Expected real barcode or empty string`);
            }
          } else {
            // Should preserve valid barcode
            if (finalBarcode === testCase.food.barcode) {
              console.log(`   ✅ SUCCESS: Valid barcode preserved!`);
            } else {
              console.log(`   ❌ FAILED: Valid barcode was changed`);
            }
          }
          
          console.log('   ═══════════════════════════════════════\n');
          
        } else {
          console.log(`   ❌ No processed food found in database\n`);
        }
      }
      
    } catch (error) {
      console.error(`   ❌ Test failed:`, error.message);
      console.log('   ═══════════════════════════════════════\n');
    }
  }
  
  console.log('🎯 BARCODE LOOKUP TEST COMPLETE!');
}

testBarcodeSearch();