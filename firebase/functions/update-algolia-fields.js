#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node update-algolia-fields.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

const indices = ['foods', 'user_added', 'ai_enhanced', 'ai_manually_added', 'manual_foods', 'verified_foods'];

async function updateIndexRecords(indexName) {
  console.log(`\n📊 Processing ${indexName}...`);

  try {
    const allRecords = [];
    let page = 0;
    const hitsPerPage = 1000;

    // Paginate through ALL records
    while (true) {
      const result = await client.searchSingleIndex({
        indexName,
        searchParams: {
          query: '',
          hitsPerPage,
          page,
        },
      });

      allRecords.push(...result.hits);
      console.log(`   Page ${page + 1}: fetched ${result.hits.length} records (total: ${allRecords.length})`);

      // Stop if we've fetched all records
      if (result.hits.length < hitsPerPage) {
        break;
      }
      page++;
    }

    console.log(`   Total found: ${allRecords.length} records`);

    if (allRecords.length === 0) {
      console.log(`   ⚠️  No records found, skipping`);
      return 0;
    }

    // Prepare updates with new fields
    const updates = allRecords.map(record => {
      const name = record.name || '';
      const brandName = record.brandName || '';

      // Calculate new fields
      const nameLength = name.length;
      const isGeneric = (brandName.toLowerCase() === 'generic' || brandName === '') ? 1 : 0;

      return {
        objectID: record.objectID,
        nameLength,
        isGeneric,
      };
    });

    console.log(`   Updating ${updates.length} records with new ranking fields...`);

    // Batch update in Algolia (partial update) - process in batches of 1000
    for (let i = 0; i < updates.length; i += 1000) {
      const batch = updates.slice(i, i + 1000);
      await client.partialUpdateObjects({
        indexName,
        objects: batch,
        createIfNotExists: false,
      });
      console.log(`   Updated batch ${Math.floor(i / 1000) + 1}/${Math.ceil(updates.length / 1000)}`);
    }

    console.log(`   ✅ Successfully updated ${indexName}`);
    return updates.length;
  } catch (error) {
    console.error(`   ❌ Error updating ${indexName}:`, error.message);
    return 0;
  }
}

async function main() {
  console.log('🚀 Updating all Algolia records with new ranking fields...\n');
  console.log('This adds:');
  console.log('  - isGeneric: 1 for "Generic" brand, 0 for others');
  console.log('  - nameLength: length of food name for ranking\n');

  let totalUpdated = 0;

  for (const indexName of indices) {
    const count = await updateIndexRecords(indexName);
    totalUpdated += count;
  }

  console.log(`\n${'='.repeat(50)}`);
  console.log(`✅ Total records updated: ${totalUpdated}`);
  console.log(`${'='.repeat(50)}\n`);
  console.log('🎉 Done! Now test searching for "apple" in your app.');
  console.log('   Generic Apple entries should now appear first!\n');
}

main().catch(error => {
  console.error('💥 Fatal error:', error);
  process.exit(1);
});
