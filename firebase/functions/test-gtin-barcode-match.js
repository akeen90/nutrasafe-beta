/**
 * Test script to check if Tesco GTINs match barcodes in uk_foods_cleaned
 *
 * This will:
 * 1. Fetch 20 Tesco products with GTINs
 * 2. Search uk_foods_cleaned for each GTIN as a barcode
 * 3. Report matches to see if GTINs = barcodes
 */

const axios = require('axios');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e';
const BASE_URL = `https://${ALGOLIA_APP_ID}-dsn.algolia.net/1/indexes`;

async function searchIndex(indexName, query, hitsPerPage = 20) {
  try {
    const response = await axios.post(
      `${BASE_URL}/${indexName}/query`,
      {
        query: query,
        hitsPerPage: hitsPerPage,
        attributesToRetrieve: ['name', 'brandName', 'gtin', 'barcode', 'objectID']
      },
      {
        headers: {
          'X-Algolia-Application-Id': ALGOLIA_APP_ID,
          'X-Algolia-API-Key': ALGOLIA_SEARCH_KEY,
          'Content-Type': 'application/json'
        }
      }
    );
    return response.data.hits || [];
  } catch (error) {
    console.error(`Error searching ${indexName}:`, error.message);
    return [];
  }
}

async function searchByBarcode(indexName, barcode) {
  const results = await searchIndex(indexName, barcode, 5);
  // Find exact barcode match
  return results.find(hit => hit.barcode === barcode || hit.gtin === barcode);
}

async function testGTINMatching() {
  console.log('🔍 Testing Tesco GTIN vs UK Foods Cleaned Barcode Matching\n');
  console.log('=' .repeat(80));

  // Step 1: Get 20 Tesco products with GTINs
  console.log('\n📦 Fetching 20 Tesco products...\n');
  const tescoProducts = await searchIndex('tesco_products', '', 20);

  if (tescoProducts.length === 0) {
    console.log('❌ No Tesco products found!');
    return;
  }

  console.log(`✅ Found ${tescoProducts.length} Tesco products\n`);

  // Step 2: Check each GTIN against uk_foods_cleaned
  let matchCount = 0;
  let noGtinCount = 0;
  const matches = [];
  const noMatches = [];

  for (const product of tescoProducts) {
    const gtin = product.gtin || product.barcode;

    if (!gtin) {
      noGtinCount++;
      console.log(`⚠️  No GTIN: ${product.name}`);
      continue;
    }

    console.log(`\n🔎 Testing: ${product.name}`);
    console.log(`   Brand: ${product.brandName || 'N/A'}`);
    console.log(`   GTIN: ${gtin}`);

    const ukMatch = await searchByBarcode('uk_foods_cleaned', gtin);

    if (ukMatch) {
      matchCount++;
      console.log(`   ✅ MATCH in uk_foods_cleaned: ${ukMatch.name}`);
      console.log(`      Barcode: ${ukMatch.barcode}`);
      matches.push({
        tescoName: product.name,
        tescoBrand: product.brandName,
        gtin: gtin,
        ukName: ukMatch.name,
        ukBarcode: ukMatch.barcode
      });
    } else {
      console.log(`   ❌ NO MATCH in uk_foods_cleaned`);
      noMatches.push({
        tescoName: product.name,
        tescoBrand: product.brandName,
        gtin: gtin
      });
    }
  }

  // Summary
  console.log('\n' + '='.repeat(80));
  console.log('\n📊 SUMMARY\n');
  console.log(`Total Tesco products tested: ${tescoProducts.length}`);
  console.log(`Products without GTIN: ${noGtinCount}`);
  console.log(`Products with GTIN: ${tescoProducts.length - noGtinCount}`);
  console.log(`✅ Matches found: ${matchCount}`);
  console.log(`❌ No matches: ${noMatches.length}`);
  console.log(`\nMatch rate: ${((matchCount / (tescoProducts.length - noGtinCount)) * 100).toFixed(1)}%`);

  if (matches.length > 0) {
    console.log('\n\n📋 MATCHED PRODUCTS:');
    matches.forEach((m, i) => {
      console.log(`\n${i + 1}. Tesco: ${m.tescoName} (${m.tescoBrand || 'N/A'})`);
      console.log(`   UK Foods: ${m.ukName}`);
      console.log(`   GTIN/Barcode: ${m.gtin}`);
    });
  }

  if (noMatches.length > 0 && noMatches.length <= 5) {
    console.log('\n\n❌ NO MATCH EXAMPLES:');
    noMatches.slice(0, 5).forEach((m, i) => {
      console.log(`${i + 1}. ${m.tescoName} (${m.tescoBrand || 'N/A'}) - GTIN: ${m.gtin}`);
    });
  }

  console.log('\n' + '='.repeat(80));
  console.log('\n💡 CONCLUSION:');
  if (matchCount > 0) {
    console.log('✅ GTINs DO match barcodes! Tesco products can be found in uk_foods_cleaned.');
    console.log('   This means barcode search SHOULD include tesco_products.');
  } else {
    console.log('❌ GTINs do NOT match barcodes in uk_foods_cleaned.');
    console.log('   Tesco uses a different identifier system (GTIN ≠ barcode).');
  }
  console.log('');
}

// Run the test
testGTINMatching().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
