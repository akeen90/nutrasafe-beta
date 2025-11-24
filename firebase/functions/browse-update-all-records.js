#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node browse-update-all-records.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

const indices = ['foods', 'user_added', 'ai_enhanced', 'ai_manually_added', 'manual_foods', 'verified_foods'];

async function browseAndUpdateIndex(indexName) {
  console.log(`\n📊 Processing ${indexName}...`);

  try {
    const allRecords = [];
    let cursor = undefined;
    let hasMore = true;
    let batchCount = 0;

    // Browse through ALL records using the browse API
    while (hasMore) {
      const response = await client.browse({
        indexName,
        browseParams: {
          hitsPerPage: 1000,
          ...(cursor && { cursor })
        }
      });

      if (response.hits && response.hits.length > 0) {
        allRecords.push(...response.hits);
        batchCount++;
        console.log(`   Batch ${batchCount}: fetched ${response.hits.length} records (total: ${allRecords.length})`);
      }

      // Check if there are more results
      cursor = response.cursor;
      hasMore = response.cursor !== undefined && response.cursor !== null;
    }

    console.log(`   ✅ Total found: ${allRecords.length} records`);

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
    console.error('   Error details:', error);
    return 0;
  }
}

async function main() {
  console.log('🚀 Browsing and updating ALL Algolia records with new ranking fields...\n');
  console.log('This adds:');
  console.log('  - isGeneric: 1 for "Generic" brand, 0 for others');
  console.log('  - nameLength: length of food name for ranking\n');

  let totalUpdated = 0;

  for (const indexName of indices) {
    const count = await browseAndUpdateIndex(indexName);
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
