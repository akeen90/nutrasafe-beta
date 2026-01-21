#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node update-banana-records.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

// Correct per 100g values for raw banana
const BANANA_NUTRITION_PER_100G = {
  calories: 90,
  protein: 1.2,
  carbs: 20.3,
  fat: 0.1,
  saturatedFat: 0.0,
  fiber: 1.4,  // UK: fibre
  sugar: 18.1,
  sodium: 1,   // 1mg per 100g (very low sodium)
};

// Indices to update
const INDICES_TO_UPDATE = ['generic_database', 'foods', 'verified_foods', 'uk_foods_cleaned'];

// Banana variants to update (exact name matches)
const BANANA_NAMES = [
  'banana',
  'banana (small)',
  'banana (medium)',
  'banana (large)',
  'banana raw',
  'banana, raw',
  'bananas',
  'cavendish banana',
  'red banana',
  'lady finger banana',
];

async function updateBananaRecords(indexName) {
  console.log(`\n📊 Processing ${indexName}...`);

  try {
    // Search for banana records
    const result = await client.searchSingleIndex({
      indexName,
      searchParams: {
        query: 'banana',
        hitsPerPage: 100,
      },
    });

    console.log(`   Found ${result.hits.length} records matching 'banana'`);

    // Filter to only base banana records (not processed foods)
    const bananaRecords = result.hits.filter(record => {
      const name = (record.name || '').toLowerCase();
      const brand = (record.brandName || record.brand || '').toLowerCase();

      // Check if it's a base banana (not a processed food)
      const isBaseBanana = BANANA_NAMES.some(bn => name === bn || name.startsWith(bn + ' ')) ||
                          (name.includes('banana') &&
                           !name.includes('bread') &&
                           !name.includes('chip') &&
                           !name.includes('bar') &&
                           !name.includes('cake') &&
                           !name.includes('muffin') &&
                           !name.includes('smoothie') &&
                           !name.includes('shake') &&
                           !name.includes('protein') &&
                           !name.includes('whey') &&
                           !name.includes('yogurt') &&
                           !name.includes('yoghurt') &&
                           !name.includes('ice cream') &&
                           !name.includes('pudding') &&
                           !name.includes('shrimp') &&
                           !name.includes('shallot') &&
                           !name.includes('&') &&
                           !name.includes(' and ') &&
                           !name.includes(' with ') &&
                           (brand === '' || brand === 'generic' || brand === null));

      return isBaseBanana;
    });

    console.log(`   Filtered to ${bananaRecords.length} base banana records`);

    if (bananaRecords.length === 0) {
      console.log(`   ⚠️  No base banana records found, skipping`);
      return { updated: 0, records: [] };
    }

    // Log what we're updating
    bananaRecords.forEach(r => {
      console.log(`   - "${r.name}" (${r.objectID}) - current: ${r.calories} cal`);
    });

    // Prepare updates - scale nutrition based on serving size
    const updates = bananaRecords.map(record => {
      const servingSizeG = record.servingSizeG || 100;
      const scale = servingSizeG / 100;

      return {
        objectID: record.objectID,
        // Per 100g values (stored as base)
        calories: Math.round(BANANA_NUTRITION_PER_100G.calories * scale),
        protein: Math.round(BANANA_NUTRITION_PER_100G.protein * scale * 10) / 10,
        carbs: Math.round(BANANA_NUTRITION_PER_100G.carbs * scale * 10) / 10,
        fat: Math.round(BANANA_NUTRITION_PER_100G.fat * scale * 10) / 10,
        saturatedFat: Math.round(BANANA_NUTRITION_PER_100G.saturatedFat * scale * 10) / 10,
        fiber: Math.round(BANANA_NUTRITION_PER_100G.fiber * scale * 10) / 10,
        fibre: Math.round(BANANA_NUTRITION_PER_100G.fiber * scale * 10) / 10, // UK spelling
        sugar: Math.round(BANANA_NUTRITION_PER_100G.sugar * scale * 10) / 10,
        sodium: Math.round(BANANA_NUTRITION_PER_100G.sodium * scale),
        // Also store the per-100g values for reference
        caloriesPer100g: BANANA_NUTRITION_PER_100G.calories,
        proteinPer100g: BANANA_NUTRITION_PER_100G.protein,
        carbsPer100g: BANANA_NUTRITION_PER_100G.carbs,
        fatPer100g: BANANA_NUTRITION_PER_100G.fat,
        isVerified: true,
      };
    });

    // Update in Algolia
    await client.partialUpdateObjects({
      indexName,
      objects: updates,
      createIfNotExists: false,
    });

    console.log(`   ✅ Updated ${updates.length} banana records in ${indexName}`);
    return { updated: updates.length, records: bananaRecords.map(r => r.name) };
  } catch (error) {
    console.error(`   ❌ Error updating ${indexName}:`, error.message);
    return { updated: 0, records: [] };
  }
}

async function main() {
  console.log('🍌 Updating banana records with correct nutrition values...\n');
  console.log('Per 100g values:');
  console.log(`  Calories: ${BANANA_NUTRITION_PER_100G.calories} kcal`);
  console.log(`  Protein:  ${BANANA_NUTRITION_PER_100G.protein} g`);
  console.log(`  Carbs:    ${BANANA_NUTRITION_PER_100G.carbs} g`);
  console.log(`  Fat:      ${BANANA_NUTRITION_PER_100G.fat} g`);
  console.log(`  Sat Fat:  ${BANANA_NUTRITION_PER_100G.saturatedFat} g`);
  console.log(`  Fibre:    ${BANANA_NUTRITION_PER_100G.fiber} g`);
  console.log(`  Sugar:    ${BANANA_NUTRITION_PER_100G.sugar} g`);
  console.log(`  Sodium:   ${BANANA_NUTRITION_PER_100G.sodium} mg`);

  let totalUpdated = 0;
  const allUpdatedRecords = [];

  for (const indexName of INDICES_TO_UPDATE) {
    const result = await updateBananaRecords(indexName);
    totalUpdated += result.updated;
    allUpdatedRecords.push(...result.records);
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(`✅ Total banana records updated: ${totalUpdated}`);
  console.log(`${'='.repeat(50)}\n`);

  if (totalUpdated > 0) {
    console.log('Updated records:');
    [...new Set(allUpdatedRecords)].forEach(name => console.log(`  - ${name}`));
    console.log('\n🎉 Done! Force quit the app and search for "banana" to see the changes.');
  }
}

main().catch(error => {
  console.error('💥 Fatal error:', error);
  process.exit(1);
});
