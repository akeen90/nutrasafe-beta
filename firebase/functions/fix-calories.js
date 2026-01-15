// Targeted calorie fix script - only fixes SINGLE INGREDIENT raw foods with wildly wrong values
const { algoliasearch } = require('algoliasearch');
const client = algoliasearch('WK0TIF84M2', 'd7334de1f8cb66eaba016ad9b2ded473');

// Reference values for raw single-ingredient foods (cal per 100g)
const CORRECT_VALUES = {
  // Vegetables
  'broccoli': { calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6 },
  'baby broccoli': { calories: 35, protein: 3, carbs: 5.5, fat: 0.5, fiber: 3 },
  'tenderstem broccoli': { calories: 35, protein: 3.5, carbs: 4, fat: 0.9, fiber: 2.3 },
  'spinach': { calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2 },
  'baby spinach': { calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2 },
  'kale': { calories: 49, protein: 4.3, carbs: 8.8, fat: 0.9, fiber: 3.6 },
  'lettuce': { calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, fiber: 1.3 },
  'iceberg lettuce': { calories: 14, protein: 0.9, carbs: 3, fat: 0.1, fiber: 1.2 },
  'romaine lettuce': { calories: 17, protein: 1.2, carbs: 3.3, fat: 0.3, fiber: 2.1 },
  'cabbage': { calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, fiber: 2.5 },
  'cauliflower': { calories: 25, protein: 1.9, carbs: 5, fat: 0.3, fiber: 2 },
  'carrot': { calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8 },
  'celery': { calories: 16, protein: 0.7, carbs: 3, fat: 0.2, fiber: 1.6 },
  'cucumber': { calories: 16, protein: 0.7, carbs: 3.6, fat: 0.1, fiber: 0.5 },
  'courgette': { calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, fiber: 1 },
  'zucchini': { calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, fiber: 1 },
  'pepper': { calories: 31, protein: 1, carbs: 6, fat: 0.3, fiber: 2.1 },
  'red pepper': { calories: 31, protein: 1, carbs: 6, fat: 0.3, fiber: 2.1 },
  'green pepper': { calories: 20, protein: 0.9, carbs: 4.6, fat: 0.2, fiber: 1.7 },
  'yellow pepper': { calories: 27, protein: 1, carbs: 6.3, fat: 0.2, fiber: 0.9 },
  'tomato': { calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2 },
  'mushroom': { calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, fiber: 1 },
  'onion': { calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, fiber: 1.7 },
  'asparagus': { calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, fiber: 2.1 },
  'green beans': { calories: 31, protein: 1.8, carbs: 7, fat: 0.1, fiber: 2.7 },
  'peas': { calories: 81, protein: 5.4, carbs: 14.5, fat: 0.4, fiber: 5.1 },
  'sweetcorn': { calories: 86, protein: 3.3, carbs: 19, fat: 1.2, fiber: 2.7 },
  'beetroot': { calories: 43, protein: 1.6, carbs: 10, fat: 0.2, fiber: 2.8 },
  'aubergine': { calories: 25, protein: 1, carbs: 6, fat: 0.2, fiber: 3 },
  'eggplant': { calories: 25, protein: 1, carbs: 6, fat: 0.2, fiber: 3 },

  // Fruits (raw)
  'apple': { calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4 },
  'banana': { calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6 },
  'orange': { calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4 },
  'grape': { calories: 69, protein: 0.7, carbs: 18, fat: 0.2, fiber: 0.9 },
  'strawberry': { calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2 },
  'blueberry': { calories: 57, protein: 0.7, carbs: 14, fat: 0.3, fiber: 2.4 },
  'raspberry': { calories: 52, protein: 1.2, carbs: 12, fat: 0.7, fiber: 6.5 },
  'mango': { calories: 60, protein: 0.8, carbs: 15, fat: 0.4, fiber: 1.6 },
  'pineapple': { calories: 50, protein: 0.5, carbs: 13, fat: 0.1, fiber: 1.4 },
  'watermelon': { calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, fiber: 0.4 },
  'melon': { calories: 34, protein: 0.8, carbs: 8, fat: 0.2, fiber: 0.9 },
  'kiwi': { calories: 61, protein: 1.1, carbs: 15, fat: 0.5, fiber: 3 },
  'pear': { calories: 57, protein: 0.4, carbs: 15, fat: 0.1, fiber: 3.1 },
  'peach': { calories: 39, protein: 0.9, carbs: 10, fat: 0.3, fiber: 1.5 },
  'plum': { calories: 46, protein: 0.7, carbs: 11, fat: 0.3, fiber: 1.4 },
  'cherry': { calories: 63, protein: 1.1, carbs: 16, fat: 0.2, fiber: 2.1 },
  'avocado': { calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7 },
  'grapefruit': { calories: 42, protein: 0.8, carbs: 11, fat: 0.1, fiber: 1.6 },

  // Proteins (raw/plain)
  'chicken breast': { calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0 },
  'turkey breast': { calories: 135, protein: 30, carbs: 0, fat: 1, fiber: 0 },
  'salmon': { calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0 },
  'tuna': { calories: 132, protein: 28, carbs: 0, fat: 1.3, fiber: 0 },
  'cod': { calories: 82, protein: 18, carbs: 0, fat: 0.7, fiber: 0 },
  'egg': { calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0 },
  'boiled egg': { calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0 },
  'beef mince': { calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0 },

  // Dairy
  'milk whole': { calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0 },
  'milk skimmed': { calories: 34, protein: 3.4, carbs: 5, fat: 0.1, fiber: 0 },
  'greek yogurt': { calories: 97, protein: 9, carbs: 3.6, fat: 5, fiber: 0 },
  'natural yogurt': { calories: 61, protein: 3.5, carbs: 4.7, fat: 3.3, fiber: 0 },

  // Grains (cooked)
  'rice': { calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4 },
  'white rice': { calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4 },
  'brown rice': { calories: 111, protein: 2.6, carbs: 23, fat: 0.9, fiber: 1.8 },
  'pasta': { calories: 131, protein: 5, carbs: 25, fat: 1.1, fiber: 1.8 },
  'quinoa': { calories: 120, protein: 4.4, carbs: 21, fat: 1.9, fiber: 2.8 },
  'oats': { calories: 68, protein: 2.4, carbs: 12, fat: 1.4, fiber: 1.7 },
};

// Patterns that indicate a SINGLE INGREDIENT food (not a dish)
const SINGLE_INGREDIENT_PATTERNS = [
  /^(baby |fresh |raw |organic |british |english )?(broccoli|spinach|kale|lettuce|cabbage|cauliflower|carrot|celery|cucumber|courgette|zucchini|pepper|tomato|mushroom|onion|asparagus|green beans?|peas?|sweetcorn|beetroot|aubergine|eggplant)(\s*\([^)]*\))?$/i,
  /^(iceberg|romaine|cos|little gem|butterhead)\s*(lettuce)?$/i,
  /^(red|green|yellow|orange)\s*pepper$/i,
  /^(baby|tenderstem)?\s*broccoli$/i,
  /^(baby)?\s*spinach$/i,
  /^(apple|banana|orange|grape|strawberry|blueberry|raspberry|mango|pineapple|watermelon|melon|kiwi|pear|peach|plum|cherry|avocado|grapefruit)s?(\s*\([^)]*\))?$/i,
  /^(chicken|turkey)\s*breast$/i,
  /^(salmon|tuna|cod)(\s*fillet)?$/i,
  /^(boiled|poached|fried|scrambled)?\s*eggs?$/i,
  /^(white|brown|basmati|jasmine)?\s*rice(\s*\(cooked\))?$/i,
  /^pasta(\s*\(cooked\))?$/i,
  /^(greek|natural|plain)\s*yogu?rt$/i,
];

// Compound food indicators - these are NOT single ingredients
const COMPOUND_INDICATORS = [
  'with', 'and', '&', 'sauce', 'dip', 'soup', 'salad', 'stir', 'fry', 'bake',
  'pie', 'cake', 'roll', 'wrap', 'sandwich', 'burger', 'pizza', 'pasta dish',
  'curry', 'stew', 'casserole', 'gratin', 'mornay', 'kiev', 'nugget', 'finger',
  'bite', 'crisp', 'chip', 'fries', 'roast', 'ravioli', 'lasagne', 'cannelloni',
  'tortellini', 'gnocchi', 'bowl', 'meal', 'kit', 'mix', 'blend', 'medley',
  'parcels', 'filo', 'pastry', 'muffin', 'bread', 'tortilla', 'flatbread'
];

function isSingleIngredient(name) {
  const nameLower = name.toLowerCase().trim();

  // Check for compound indicators
  for (const indicator of COMPOUND_INDICATORS) {
    if (nameLower.includes(indicator)) {
      return false;
    }
  }

  // Check if matches single ingredient pattern
  for (const pattern of SINGLE_INGREDIENT_PATTERNS) {
    if (pattern.test(nameLower)) {
      return true;
    }
  }

  return false;
}

function getCorrectValues(name) {
  const nameLower = name.toLowerCase().trim();

  // Try exact matches first
  for (const [food, values] of Object.entries(CORRECT_VALUES)) {
    if (nameLower === food || nameLower.startsWith(food + ' ') || nameLower.includes('(' + food)) {
      return { food, values };
    }
  }

  // Try partial matches
  for (const [food, values] of Object.entries(CORRECT_VALUES)) {
    if (nameLower.includes(food)) {
      return { food, values };
    }
  }

  return null;
}

async function findAndFixBadItems(indexName) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`FIXING: ${indexName}`);
  console.log('='.repeat(60));

  const fixes = [];
  const deletions = [];

  // Search for common single ingredients
  const searchTerms = Object.keys(CORRECT_VALUES);

  for (const term of searchTerms) {
    try {
      const results = await client.searchSingleIndex({
        indexName,
        searchParams: {
          query: term,
          hitsPerPage: 100,
          attributesToRetrieve: ['objectID', 'name', 'brandName', 'calories', 'servingSizeG', 'protein', 'carbs', 'fat', 'fiber']
        }
      });

      for (const hit of results.hits) {
        const name = hit.name || '';
        if (!isSingleIngredient(name)) continue;

        const correctData = getCorrectValues(name);
        if (!correctData) continue;

        const servingG = hit.servingSizeG || 100;
        const cal100g = Math.round((hit.calories / servingG) * 100);
        const expectedCal = correctData.values.calories;

        // Only flag if calories are WAY off (more than 2x expected or less than 0.5x)
        const ratio = cal100g / expectedCal;
        if (ratio > 2 || ratio < 0.5) {
          console.log(`\n${ratio > 2 ? '📈 TOO HIGH' : '📉 TOO LOW'}: ${name}`);
          console.log(`   Current: ${cal100g} cal/100g`);
          console.log(`   Expected: ${expectedCal} cal/100g (${correctData.food})`);
          console.log(`   Ratio: ${ratio.toFixed(1)}x`);
          console.log(`   ID: ${hit.objectID}`);

          fixes.push({
            objectID: hit.objectID,
            name: name,
            oldCalories: hit.calories,
            oldServingG: servingG,
            oldCal100g: cal100g,
            // Fix to 100g serving with correct values
            newCalories: correctData.values.calories,
            newServingG: 100,
            newProtein: correctData.values.protein,
            newCarbs: correctData.values.carbs,
            newFat: correctData.values.fat,
            newFiber: correctData.values.fiber,
            referenceFoodType: correctData.food
          });
        }
      }
    } catch (e) {
      // Ignore search errors
    }
  }

  return fixes;
}

async function applyFixes(indexName, fixes) {
  if (fixes.length === 0) {
    console.log('No fixes to apply.');
    return;
  }

  console.log(`\n📝 Applying ${fixes.length} fixes to ${indexName}...`);

  const updates = fixes.map(fix => ({
    objectID: fix.objectID,
    calories: fix.newCalories,
    servingSizeG: fix.newServingG,
    protein: fix.newProtein,
    carbs: fix.newCarbs,
    fat: fix.newFat,
    fiber: fix.newFiber,
    // Keep track that this was auto-corrected
    caloriesCorrected: true,
    correctedFrom: fix.oldCal100g,
    correctedTo: fix.newCalories,
    correctedDate: new Date().toISOString()
  }));

  try {
    await client.partialUpdateObjects({
      indexName,
      objects: updates,
      createIfNotExists: false
    });
    console.log(`✅ Successfully updated ${updates.length} items in ${indexName}`);
  } catch (e) {
    console.error(`❌ Error updating ${indexName}:`, e.message);
  }
}

async function main() {
  console.log('🔧 TARGETED CALORIE FIX');
  console.log('Fixing SINGLE INGREDIENT foods with wildly incorrect calories...\n');

  const indices = ['uk_foods_cleaned', 'foods', 'generic_database'];
  const allFixes = {};

  // First, find all issues
  for (const indexName of indices) {
    const fixes = await findAndFixBadItems(indexName);
    allFixes[indexName] = fixes;
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));

  let totalFixes = 0;
  for (const [index, fixes] of Object.entries(allFixes)) {
    console.log(`${index}: ${fixes.length} items to fix`);
    totalFixes += fixes.length;
  }
  console.log(`Total: ${totalFixes} items`);

  if (totalFixes === 0) {
    console.log('\n✅ No single-ingredient foods with bad calories found!');
    return;
  }

  // Ask for confirmation before applying
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('\nApply these fixes? (yes/no): ', async (answer) => {
    if (answer.toLowerCase() === 'yes') {
      for (const [indexName, fixes] of Object.entries(allFixes)) {
        await applyFixes(indexName, fixes);
      }
      console.log('\n✅ All fixes applied!');
    } else {
      console.log('\n⏭️ Fixes not applied. Run again with "yes" to apply.');

      // Save fixes to file for review
      const fs = require('fs');
      fs.writeFileSync(
        '/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/functions/proposed_fixes.json',
        JSON.stringify(allFixes, null, 2)
      );
      console.log('📄 Proposed fixes saved to: proposed_fixes.json');
    }
    rl.close();
  });
}

main().catch(console.error);
