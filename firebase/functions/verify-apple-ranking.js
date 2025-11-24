#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node verify-apple-ranking.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

async function verifyAppleRanking() {
  console.log('🔍 Searching for "apple" to verify ranking...\n');

  try {
    const result = await client.searchSingleIndex({
      indexName: 'foods',
      searchParams: {
        query: 'apple',
        hitsPerPage: 15,
      },
    });

    console.log(`Found ${result.hits.length} results:\n`);

    result.hits.forEach((hit, index) => {
      const isGenericBadge = hit.isGeneric === 1 ? '✅ GENERIC' : '❌ Branded';
      console.log(`${index + 1}. ${hit.name}`);
      console.log(`   Brand: ${hit.brandName || 'N/A'}`);
      console.log(`   ${isGenericBadge} (isGeneric: ${hit.isGeneric})`);
      console.log(`   nameLength: ${hit.nameLength}`);
      console.log('');
    });

    // Check if generic apples are in top results
    const topResults = result.hits.slice(0, 10);
    const genericApples = topResults.filter(hit =>
      hit.brandName === 'Generic' && hit.name.toLowerCase().includes('apple')
    );

    if (genericApples.length > 0) {
      console.log(`\n✅ SUCCESS! Found ${genericApples.length} generic apple(s) in top 10 results:`);
      genericApples.forEach(apple => console.log(`   - ${apple.name}`));
    } else {
      console.log('\n⚠️  WARNING: No generic apples found in top 10 results');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function verifyCosta() {
  console.log('\n\n🔍 Searching for "costa" to verify ranking...\n');

  try {
    const result = await client.searchSingleIndex({
      indexName: 'foods',
      searchParams: {
        query: 'costa',
        hitsPerPage: 10,
      },
    });

    console.log(`Found ${result.hits.length} results:\n`);

    result.hits.forEach((hit, index) => {
      const isGenericBadge = hit.isGeneric === 1 ? '✅ GENERIC' : '❌ Branded';
      console.log(`${index + 1}. ${hit.name}`);
      console.log(`   Brand: ${hit.brandName || 'N/A'}`);
      console.log(`   ${isGenericBadge} (isGeneric: ${hit.isGeneric})`);
      console.log(`   nameLength: ${hit.nameLength}`);
      console.log('');
    });

    const costaItems = result.hits.filter(hit =>
      hit.name.toLowerCase().includes('costa') ||
      (hit.brandName && hit.brandName.toLowerCase().includes('costa'))
    );

    if (costaItems.length > 0) {
      console.log(`\n✅ SUCCESS! Found ${costaItems.length} Costa item(s):`);
      costaItems.forEach(item => console.log(`   - ${item.name} (${item.brandName})`));
    } else {
      console.log('\n⚠️  WARNING: No Costa items found');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function main() {
  await verifyAppleRanking();
  await verifyCosta();
}

main().catch(error => {
  console.error('💥 Fatal error:', error);
  process.exit(1);
});
