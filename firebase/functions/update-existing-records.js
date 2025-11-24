#!/usr/bin/env node

const { algoliasearch } = require('algoliasearch');
const admin = require('firebase-admin');

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.argv[2];

if (!ALGOLIA_ADMIN_KEY) {
  console.error('Usage: node update-existing-records.js ALGOLIA_ADMIN_KEY');
  process.exit(1);
}

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const db = admin.firestore();

const indices = ['foods', 'user_added', 'ai_enhanced', 'ai_manually_added', 'manual_foods', 'verified_foods'];
const collections = ['foods', 'userAdded', 'aiEnhanced', 'aiManuallyAdded', 'manualFoods', 'verifiedFoods'];

async function updateIndex(indexName, collectionName) {
  console.log(`\n📊 Processing ${indexName}...`);

  try {
    // Get all documents from Firestore
    const snapshot = await db.collection(collectionName).get();
    console.log(`   Found ${snapshot.size} documents in Firestore`);

    if (snapshot.empty) {
      console.log(`   ⚠️  No documents found, skipping`);
      return 0;
    }

    // Prepare updates with new fields
    const updates = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      const name = data.name || data.foodName || '';
      const brandName = data.brandName || data.brand || '';

      // Calculate new fields
      const nameLength = name.length;
      const isGeneric = (brandName.toLowerCase() === 'generic' || brandName === '') ? 1 : 0;

      updates.push({
        objectID: doc.id,
        nameLength,
        isGeneric,
      });
    });

    console.log(`   Updating ${updates.length} records with new ranking fields...`);

    // Batch update in Algolia (partial update to just add the new fields)
    await client.partialUpdateObjects({
      indexName,
      objects: updates,
      createIfNotExists: false,
    });

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
  console.log('  - nameLength: length of food name for ranking');

  let totalUpdated = 0;

  for (let i = 0; i < indices.length; i++) {
    const count = await updateIndex(indices[i], collections[i]);
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
