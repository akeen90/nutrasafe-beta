// Test the updated AI system through dashboard
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testDashboard() {
  console.log('🔍 TESTING UPDATED AI SYSTEM VIA DASHBOARD 🔍\n');
  
  const testFood = {
    id: 'dashboard-test-' + Date.now(),
    name: 'Tesco Apple Juice',
    brand: 'Tesco',
    barcode: '000000000000', // Fake barcode to test validation
    ingredients: 'Apple Juice from Concentrate 95%, Water, Natural Flavouring, Potassium Sorbate',
    nutritionData: {
      calories: 42,
      protein: 0.1,
      carbs: 10.3,
      fat: 0.1,
      fiber: 0.1,
      sugar: 9.7
    }
  };
  
  try {
    console.log('📤 Testing AI with Tesco Apple Juice:');
    console.log(`   Name: ${testFood.name}`);
    console.log(`   Brand: ${testFood.brand}`);
    console.log(`   Fake Barcode: ${testFood.barcode} (should be removed)`);
    console.log(`   Ingredients: ${testFood.ingredients.substring(0, 50)}...`);
    
    // Call the analyzeAndCleanFoods function
    const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        foods: [testFood],
        batchId: 'dashboard-test-' + Date.now()
      })
    });
    
    if (!response.ok) {
      console.error(`❌ AI analysis failed: ${response.status}`);
      const text = await response.text();
      console.error(text);
      return;
    }
    
    const result = await response.json();
    console.log('\n📋 AI ANALYSIS RESULT:');
    console.log(JSON.stringify(result, null, 2));
    
    // Wait for database
    console.log('\n⏳ Waiting for database (8 seconds)...');
    await new Promise(resolve => setTimeout(resolve, 8000));
    
    // Check the processed result
    const savedResponse = await fetch(`${API_BASE}/getCleansedFoods?limit=1`);
    if (savedResponse.ok) {
      const savedData = await savedResponse.json();
      
      if (savedData.foods && savedData.foods.length > 0) {
        const processedFood = savedData.foods[0];
        
        console.log('\n✅ DASHBOARD TEST RESULTS:');
        console.log('=================================');
        
        console.log(`📍 Food Name: ${processedFood.name || processedFood.cleanedData?.foodName}`);
        console.log(`🏪 Brand: ${processedFood.brand || processedFood.cleanedData?.brandName}`);
        
        // Check barcode validation
        const barcode = processedFood.barcode || processedFood.cleanedData?.barcode;
        console.log(`📊 Barcode: "${barcode}" ${barcode === "" ? "✅ (Fake barcode removed!)" : barcode.length > 0 ? "❌ (Should be empty)" : "✅ (Empty as expected)"}`);
        
        // Check serving size extraction
        const servingSize = processedFood.cleanedData?.servingSize;
        console.log(`📏 Serving Size: "${servingSize}" ${servingSize && servingSize !== "100g serving" ? "✅ (Extracted from source)" : "❌ (Should extract from source)"}`);
        
        // Check ingredients preservation
        const ingredients = processedFood.cleanedData?.ingredients || processedFood.cleanedData?.extractedIngredients;
        const originalLength = testFood.ingredients.length;
        const preservedLength = ingredients ? ingredients.length : 0;
        const preservationRate = Math.round((preservedLength / originalLength) * 100);
        console.log(`🧪 Ingredients Preservation: ${preservationRate}% (${preservedLength}/${originalLength} chars) ${preservationRate >= 90 ? "✅" : "❌"}`);
        
        // Check nutrition data
        const nutritionData = processedFood.cleanedData?.nutritionData;
        if (nutritionData) {
          console.log('\n📊 NUTRITION DATA:');
          console.log(`   Per 100g: ${nutritionData.calories || 'N/A'} calories, ${nutritionData.protein || 'N/A'}g protein, ${nutritionData.carbs || 'N/A'}g carbs`);
          
          if (nutritionData.perServing) {
            console.log(`   Per Serving: ${nutritionData.perServing.calories || 'N/A'} calories, ${nutritionData.perServing.protein || 'N/A'}g protein, ${nutritionData.perServing.carbs || 'N/A'}g carbs ✅`);
          } else {
            console.log(`   Per Serving: ❌ Missing per-serving data`);
          }
        }
        
        console.log('\n🎯 OVERALL STATUS:');
        console.log(`   ✅ Barcode validation: ${barcode === "" ? "PASSED" : "FAILED"}`);
        console.log(`   ✅ Serving size extraction: ${servingSize && servingSize !== "100g serving" ? "PASSED" : "NEEDS CHECK"}`);
        console.log(`   ✅ Ingredient preservation: ${preservationRate >= 90 ? "PASSED" : "FAILED"}`);
        console.log(`   ✅ Nutrition data: ${nutritionData ? "PASSED" : "FAILED"}`);
        
      } else {
        console.log('\n❌ No processed food found in database');
      }
    } else {
      console.error('❌ Failed to retrieve processed food from database');
    }
    
  } catch (error) {
    console.error('❌ Dashboard test failed:', error.message);
  }
}

testDashboard();