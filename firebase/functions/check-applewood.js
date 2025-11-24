#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

async function checkApplewood() {
  console.log('🔍 Searching for "apple" with more results to find Applewood...\n');

  try {
    const result = await client.searchSingleIndex({
      indexName: 'foods',
      searchParams: {
        query: 'apple',
        hitsPerPage: 50,
      },
    });

    const applewoodItems = result.hits.filter(hit =>
      hit.name.toLowerCase().includes('applewood')
    );

    if (applewoodItems.length > 0) {
      console.log(`✅ Found ${applewoodItems.length} Applewood item(s):\n`);
      applewoodItems.forEach(item => {
        const position = result.hits.indexOf(item) + 1;
        console.log(`Position ${position}: ${item.name}`);
        console.log(`   Brand: ${item.brandName || 'N/A'}`);
        console.log(`   isGeneric: ${item.isGeneric}, nameLength: ${item.nameLength}\n`);
      });
    } else {
      console.log('⚠️  No Applewood items found in top 50 results');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkApplewood();
