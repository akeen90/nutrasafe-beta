#!/usr/bin/env node

/**
 * Fix Product Name Capitalization
 * This script tidies up product names with proper capitalization
 */

const https = require('https');
const { URL } = require('url');

const CONFIG = {
  FIREBASE_FUNCTION_BASE: 'https://us-central1-nutrasafe-705c7.cloudfunctions.net',
  DRY_RUN: false, // Set to false to actually update
  BATCH_SIZE: 100
};

async function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    const postData = data ? JSON.stringify(data) : null;
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(postData && { 'Content-Length': Buffer.byteLength(postData) })
      },
      timeout: 30000
    };
    
    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(responseData);
          resolve({ 
            success: res.statusCode === 200, 
            data: response 
          });
        } catch (parseError) {
          resolve({ success: false, error: 'Parse error: ' + parseError.message });
        }
      });
    });
    
    req.on('error', (error) => {
      resolve({ success: false, error: error.message });
    });
    
    req.on('timeout', () => {
      req.abort();
      resolve({ success: false, error: 'Request timeout' });
    });
    
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

function toTitleCase(str) {
  if (!str) return str;
  
  // Words that should remain lowercase (articles, prepositions, conjunctions)
  const lowerCaseWords = [
    'a', 'an', 'and', 'as', 'at', 'but', 'by', 'for', 'if', 'in', 'nor', 'of', 
    'on', 'or', 'so', 'the', 'to', 'up', 'yet', 'with', 'from'
  ];
  
  // Words that should be uppercase
  const upperCaseWords = [
    'uk', 'usa', 'diy', 'bbq', 'tv', 'pc', 'dvd', 'cd', 'usb', 'wifi', 'gps'
  ];
  
  // Brand names and special cases
  const specialCases = {
    'mcdonalds': 'McDonalds',
    'mcdonald\'s': 'McDonald\'s',
    'coca cola': 'Coca Cola',
    'coca-cola': 'Coca-Cola',
    'dr pepper': 'Dr Pepper',
    'dr. pepper': 'Dr. Pepper',
    'kit kat': 'Kit Kat',
    'mars bar': 'Mars Bar',
    'cadbury': 'Cadbury',
    'nestlé': 'Nestlé',
    'nestle': 'Nestlé',
    'kellogg\'s': 'Kellogg\'s',
    'kelloggs': 'Kellogg\'s',
    'heinz': 'Heinz',
    'tesco': 'Tesco',
    'asda': 'ASDA',
    'sainsburys': 'Sainsburys',
    'sainsbury\'s': 'Sainsbury\'s',
    'morrisons': 'Morrisons',
    'waitrose': 'Waitrose',
    'aldi': 'ALDI',
    'lidl': 'Lidl',
    'co-op': 'Co-op',
    'marks & spencer': 'Marks & Spencer',
    'm&s': 'M&S'
  };
  
  // Check for special cases first
  const lowerStr = str.toLowerCase();
  for (const [key, value] of Object.entries(specialCases)) {
    if (lowerStr.includes(key)) {
      return str.toLowerCase().replace(key, value);
    }
  }
  
  return str.toLowerCase().split(' ').map((word, index) => {
    // Always capitalize first word
    if (index === 0) {
      return word.charAt(0).toUpperCase() + word.slice(1);
    }
    
    // Check if word should be uppercase
    if (upperCaseWords.includes(word.toLowerCase())) {
      return word.toUpperCase();
    }
    
    // Check if word should remain lowercase
    if (lowerCaseWords.includes(word.toLowerCase())) {
      return word.toLowerCase();
    }
    
    // Default title case
    return word.charAt(0).toUpperCase() + word.slice(1);
  }).join(' ');
}

function shouldFixCapitalization(name) {
  if (!name) return false;
  
  // Check if name is all uppercase
  if (name === name.toUpperCase() && name.length > 3) {
    return true;
  }
  
  // Check if name is all lowercase
  if (name === name.toLowerCase()) {
    return true;
  }
  
  // Check if name has inconsistent capitalization
  const words = name.split(' ');
  const hasInconsistentCase = words.some(word => {
    if (word.length <= 1) return false;
    const firstChar = word.charAt(0);
    const restOfWord = word.slice(1);
    
    // Check for camelCase or mixed case issues
    return (firstChar === firstChar.toLowerCase() && word.length > 2) ||
           (restOfWord !== restOfWord.toLowerCase() && !word.includes('-'));
  });
  
  return hasInconsistentCase;
}

async function updateFoodName(foodId, newName) {
  if (CONFIG.DRY_RUN) {
    console.log(`[DRY RUN] Would update food ${foodId} name to: "${newName}"`);
    return { success: true };
  }
  
  const result = await makeRequest(
    `${CONFIG.FIREBASE_FUNCTION_BASE}/updateVerifiedFood`,
    'POST',
    {
      foodId: foodId,
      foodName: newName
    }
  );
  
  return result;
}

async function searchAllFoods() {
  console.log('🔍 Searching for foods with capitalization issues...');
  
  // Search with common 2-letter combinations to get a broad sample (API requires min 2 chars)
  const searchQueries = ['ap', 'br', 'ch', 'dr', 'eg', 'fi', 'gr', 'ha', 'ic', 'ju', 'ki', 'le', 'mi', 'nu', 'or', 'po', 'qu', 're', 'sa', 'te', 'un', 've', 'wa', 'yo', 'ze'];
  let allFoods = new Map();
  
  for (const query of searchQueries) {
    console.log(`  Searching foods starting with "${query}"`);
    
    const result = await makeRequest(`${CONFIG.FIREBASE_FUNCTION_BASE}/searchFoods?q=${query}`);
    
    if (result.success && result.data.foods) {
      result.data.foods.forEach(food => {
        allFoods.set(food.id, food);
      });
    }
    
    // Small delay between searches
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  return Array.from(allFoods.values());
}

async function fixCapitalization() {
  console.log('🚀 Starting Product Name Capitalization Fix');
  console.log(`🔧 Configuration:`);
  console.log(`   - Dry Run: ${CONFIG.DRY_RUN ? 'YES' : 'NO'}`);
  console.log(`   - Batch Size: ${CONFIG.BATCH_SIZE}`);
  console.log('');
  
  const allFoods = await searchAllFoods();
  console.log(`📊 Found ${allFoods.length} total foods to analyze`);
  
  // Find foods with capitalization issues
  const foodsToFix = [];
  
  for (const food of allFoods) {
    if (shouldFixCapitalization(food.name)) {
      const fixedName = toTitleCase(food.name);
      
      if (fixedName !== food.name) {
        foodsToFix.push({
          id: food.id,
          originalName: food.name,
          fixedName: fixedName,
          brand: food.brand || 'No brand'
        });
      }
    }
  }
  
  console.log(`🔧 Found ${foodsToFix.length} foods needing capitalization fixes\n`);
  
  if (foodsToFix.length === 0) {
    console.log('✅ No capitalization issues found!');
    return;
  }
  
  // Show preview of changes
  console.log('📝 Preview of changes:');
  foodsToFix.slice(0, 10).forEach((food, index) => {
    console.log(`${index + 1}. "${food.originalName}" → "${food.fixedName}" (${food.brand})`);
  });
  
  if (foodsToFix.length > 10) {
    console.log(`   ... and ${foodsToFix.length - 10} more\n`);
  }
  
  let successCount = 0;
  let errorCount = 0;
  
  // Process foods in batches
  for (let i = 0; i < foodsToFix.length; i += CONFIG.BATCH_SIZE) {
    const batch = foodsToFix.slice(i, i + CONFIG.BATCH_SIZE);
    console.log(`\n🔄 Processing batch ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} foods)`);
    
    for (const food of batch) {
      const result = await updateFoodName(food.id, food.fixedName);
      
      if (result.success) {
        console.log(`✅ Fixed: "${food.originalName}" → "${food.fixedName}"`);
        successCount++;
      } else {
        console.log(`❌ Failed: "${food.originalName}" - ${result.error}`);
        errorCount++;
      }
      
      // Small delay between updates
      await new Promise(resolve => setTimeout(resolve, 200));
    }
  }
  
  console.log('\n🎉 Capitalization Fix Complete!');
  console.log(`📊 Results:`);
  console.log(`   ✅ Successfully fixed: ${successCount} foods`);
  console.log(`   ❌ Failed: ${errorCount} foods`);
  console.log(`   📈 Total processed: ${successCount + errorCount} foods`);
}

fixCapitalization().catch(error => {
  console.error('❌ Capitalization fix failed:', error);
  process.exit(1);
});