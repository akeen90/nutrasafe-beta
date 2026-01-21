#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY);

const INDICES = ['generic_database', 'foods', 'verified_foods', 'uk_foods_cleaned'];

// These are the ONLY records that SHOULD have ~90 cal banana nutrition
const VALID_BANANA_IDS = new Set([
  'generic_database_3',
  'generic_database_4',
  'generic_database_5',
  'generic_database_486',
  'generic_database_489',
  'generic_database_490',
  'generic-895dfd29-af2a-4bca-9f42-c4f4a0b10b69',
  'generic-408fe235-578f-4d64-96f2-cc586d502727',
  'generic-897a0fda-6d17-499b-a9e2-a9d9b24cdf85',
  'C18DD203-8706-499B-ADB7-5E58ACE1852C',
]);

async function checkIndex(indexName) {
  console.log(`\n📊 Checking ${indexName}...`);

  try {
    const result = await client.searchSingleIndex({
      indexName,
      searchParams: {
        query: 'banana',
        hitsPerPage: 100,
      },
    });

    console.log(`   Found ${result.hits.length} records matching 'banana'`);

    const corrupted = [];
    const valid = [];

    result.hits.forEach(record => {
      const name = record.name || '';
      const cal = record.calories;

      // Check if this record has banana-like calories (~73-106 range for size variants)
      // but is NOT a valid base banana
      const hasBananaCalories = cal >= 70 && cal <= 110;
      const isValidBanana = VALID_BANANA_IDS.has(record.objectID);

      if (hasBananaCalories && !isValidBanana) {
        corrupted.push({
          objectID: record.objectID,
          name,
          calories: cal,
          brand: record.brandName || record.brand || '(no brand)',
        });
      } else if (isValidBanana) {
        valid.push({ objectID: record.objectID, name, calories: cal });
      }
    });

    if (corrupted.length > 0) {
      console.log(`   ❌ ${corrupted.length} CORRUPTED records (have banana calories but shouldn't):`);
      corrupted.forEach(r => {
        console.log(`      - "${r.name}" [${r.objectID}] - ${r.calories} cal - brand: ${r.brand}`);
      });
    } else {
      console.log(`   ✅ No corrupted records found`);
    }

    if (valid.length > 0) {
      console.log(`   ✅ ${valid.length} valid base bananas found:`);
      valid.forEach(r => {
        console.log(`      - "${r.name}" [${r.objectID}] - ${r.calories} cal`);
      });
    }

    return corrupted;
  } catch (error) {
    console.error(`   ❌ Error:`, error.message);
    return [];
  }
}

async function main() {
  console.log('🔍 Checking for corrupted banana records...\n');

  let allCorrupted = [];
  for (const indexName of INDICES) {
    const corrupted = await checkIndex(indexName);
    allCorrupted.push(...corrupted.map(r => ({ ...r, indexName })));
  }

  console.log('\n' + '='.repeat(60));
  console.log(`Total corrupted records: ${allCorrupted.length}`);
  console.log('='.repeat(60));

  if (allCorrupted.length > 0) {
    console.log('\nFull list of corrupted records to restore:');
    allCorrupted.forEach(r => {
      console.log(`  ${r.indexName}: "${r.name}" [${r.objectID}]`);
    });
  }
}

main().catch(console.error);
