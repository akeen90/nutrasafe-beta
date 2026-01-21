#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node fix-banana-records.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

// Correct per 100g values for RAW banana ONLY
const BANANA_NUTRITION_PER_100G = {
  calories: 90,
  protein: 1.2,
  carbs: 20.3,
  fat: 0.1,
  saturatedFat: 0.0,
  fiber: 1.4,
  sugar: 18.1,
  sodium: 1,
};

// EXACT object IDs for base bananas ONLY (from generic_database)
const BASE_BANANA_IDS = {
  'generic_database': [
    'generic_database_3',   // Banana (Small)
    'generic_database_4',   // Banana (Medium)
    'generic_database_5',   // Banana (Large)
    'generic_database_486', // Cavendish Banana
    'generic_database_489', // Lady Finger Banana
    'generic_database_490', // Red Banana
  ],
  'foods': [
    'generic-895dfd29-af2a-4bca-9f42-c4f4a0b10b69', // Banana (Small)
    'generic-408fe235-578f-4d64-96f2-cc586d502727', // Banana (Large)
    'generic-897a0fda-6d17-499b-a9e2-a9d9b24cdf85', // Banana (Medium)
    'C18DD203-8706-499B-ADB7-5E58ACE1852C',         // Banana
  ],
};

// Serving sizes for each variant
const SERVING_SIZES = {
  'generic_database_3': 81,   // Small
  'generic_database_4': 118,  // Medium
  'generic_database_5': 136,  // Large
  'generic_database_486': 118, // Cavendish (medium)
  'generic_database_489': 100, // Lady Finger
  'generic_database_490': 100, // Red Banana
  'generic-895dfd29-af2a-4bca-9f42-c4f4a0b10b69': 81,
  'generic-408fe235-578f-4d64-96f2-cc586d502727': 136,
  'generic-897a0fda-6d17-499b-a9e2-a9d9b24cdf85': 118,
  'C18DD203-8706-499B-ADB7-5E58ACE1852C': 100,
};

async function updateBaseBananas(indexName) {
  const objectIDs = BASE_BANANA_IDS[indexName];
  if (!objectIDs || objectIDs.length === 0) {
    console.log(`   No base bananas defined for ${indexName}, skipping`);
    return 0;
  }

  console.log(`\n📊 Updating ${objectIDs.length} base bananas in ${indexName}...`);

  try {
    // Prepare updates with correct per-serving values
    const updates = objectIDs.map(objectID => {
      const servingSizeG = SERVING_SIZES[objectID] || 100;
      const scale = servingSizeG / 100;

      return {
        objectID,
        // Scaled values for the serving size
        calories: Math.round(BANANA_NUTRITION_PER_100G.calories * scale),
        protein: Math.round(BANANA_NUTRITION_PER_100G.protein * scale * 10) / 10,
        carbs: Math.round(BANANA_NUTRITION_PER_100G.carbs * scale * 10) / 10,
        fat: Math.round(BANANA_NUTRITION_PER_100G.fat * scale * 10) / 10,
        saturatedFat: Math.round(BANANA_NUTRITION_PER_100G.saturatedFat * scale * 10) / 10,
        fiber: Math.round(BANANA_NUTRITION_PER_100G.fiber * scale * 10) / 10,
        fibre: Math.round(BANANA_NUTRITION_PER_100G.fiber * scale * 10) / 10,
        sugar: Math.round(BANANA_NUTRITION_PER_100G.sugar * scale * 10) / 10,
        sodium: Math.round(BANANA_NUTRITION_PER_100G.sodium * scale),
        servingSizeG: servingSizeG,
        isVerified: true,
        isGeneric: 1,
      };
    });

    // Log what we're updating
    updates.forEach(u => {
      console.log(`   - ${u.objectID}: ${u.calories} cal (${SERVING_SIZES[u.objectID] || 100}g serving)`);
    });

    // Update in Algolia
    await client.partialUpdateObjects({
      indexName,
      objects: updates,
      createIfNotExists: false,
    });

    console.log(`   ✅ Updated ${updates.length} records`);
    return updates.length;
  } catch (error) {
    console.error(`   ❌ Error:`, error.message);
    return 0;
  }
}

async function main() {
  console.log('🍌 Fixing BASE banana records ONLY with correct nutrition...\n');
  console.log('Per 100g values:');
  console.log(`  Calories: ${BANANA_NUTRITION_PER_100G.calories} kcal`);
  console.log(`  Protein:  ${BANANA_NUTRITION_PER_100G.protein} g`);
  console.log(`  Carbs:    ${BANANA_NUTRITION_PER_100G.carbs} g`);
  console.log(`  Fat:      ${BANANA_NUTRITION_PER_100G.fat} g`);
  console.log(`  Fibre:    ${BANANA_NUTRITION_PER_100G.fiber} g`);
  console.log(`  Sugar:    ${BANANA_NUTRITION_PER_100G.sugar} g`);

  let total = 0;
  for (const indexName of Object.keys(BASE_BANANA_IDS)) {
    total += await updateBaseBananas(indexName);
  }

  console.log(`\n✅ Total base banana records fixed: ${total}`);
  console.log('\n🎉 Done! Force quit app and search "banana" to verify.');
}

main().catch(console.error);
