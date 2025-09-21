// Debug AI response to see exactly what it's returning for barcode validation
const API_BASE = 'https://us-central1-nutrasafe-705c7.cloudfunctions.net';

async function testAIResponse() {
  console.log('🔍 DEBUGGING AI BARCODE RESPONSE 🔍\n');
  
  const testFood = {
    id: 'debug-test-' + Date.now(),
    name: 'Test Apple Juice',
    brand: 'Tesco',
    barcode: '000000000000', // Fake barcode
    ingredients: 'Apple Juice from Concentrate 95%, Water',
    nutritionData: {
      calories: 42,
      protein: 0.1,
      carbs: 10.3,
      fat: 0.1
    }
  };
  
  try {
    console.log('📤 Sending to AI:');
    console.log(`   Original barcode: "${testFood.barcode}"`);
    
    // Call the AI analysis function
    const response = await fetch(`${API_BASE}/analyzeAndCleanFoods`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        foods: [testFood],
        batchId: 'debug-test-' + Date.now()
      })
    });
    
    if (!response.ok) {
      console.error(`❌ AI analysis failed: ${response.status}`);
      return;
    }
    
    const result = await response.json();
    console.log('\n📋 AI ANALYSIS RESULT:');
    console.log(JSON.stringify(result, null, 2));
    
    // Wait and check processed food in database
    console.log('\n⏳ Waiting for database processing...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Check the latest processed food
    const savedResponse = await fetch(`${API_BASE}/getCleansedFoods?limit=1`);
    if (savedResponse.ok) {
      const savedData = await savedResponse.json();
      
      if (savedData.foods && savedData.foods.length > 0) {
        const processedFood = savedData.foods[0];
        
        console.log('\n✅ PROCESSED FOOD IN DATABASE:');
        console.log('=================================');
        console.log(`📊 Final barcode in cleanedData: "${processedFood.cleanedData?.barcode}"`);
        console.log(`📊 Final barcode in root: "${processedFood.barcode}"`);
        console.log(`📊 Original barcode preserved: "${processedFood.originalData?.barcode}"`);
        
        // Show full cleanedData structure
        console.log('\n📋 Full cleanedData structure:');
        console.log(JSON.stringify(processedFood.cleanedData, null, 2));
        
      } else {
        console.log('❌ No processed food found in database');
      }
    }
    
  } catch (error) {
    console.error('❌ Debug test failed:', error.message);
  }
}

testAIResponse();