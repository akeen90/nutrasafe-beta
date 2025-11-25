#!/usr/bin/env node

const admin = require('firebase-admin');
const { algoliasearch } = require('algoliasearch');

// Initialize Firebase Admin with application default credentials
admin.initializeApp({
  projectId: 'nutrasafe-705c7'
});

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = process.env.ALGOLIA_ADMIN_API_KEY;

if (!ALGOLIA_ADMIN_KEY) {
  console.error('❌ Error: ALGOLIA_ADMIN_API_KEY environment variable not set');
  process.exit(1);
}

const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
const db = admin.firestore();

const collections = [
  {name: 'verifiedFoods', indexName: 'verified_foods'},
  {name: 'foods', indexName: 'foods'},
  {name: 'manualFoods', indexName: 'manual_foods'},
  {name: 'userAdded', indexName: 'user_added'},
  {name: 'aiEnhanced', indexName: 'ai_enhanced'},
  {name: 'aiManuallyAdded', indexName: 'ai_manually_added'},
];

function prepareForAlgolia(data) {
  const name = data.name || data.foodName || '';
  const brandName = data.brandName || data.brand || '';
  const nameLength = name.length;
  const isGeneric = (brandName.toLowerCase() === 'generic' || brandName === '') ? 1 : 0;

  return {
    name,
    brandName,
    ingredients: Array.isArray(data.ingredients) ? data.ingredients : (data.ingredients ? [data.ingredients] : []),
    barcode: data.barcode || '',
    calories: data.calories || 0,
    protein: data.protein || 0,
    carbs: data.carbs || 0,
    fat: data.fat || 0,
    fiber: data.fiber || 0,
    sugar: data.sugar || 0,
    sodium: data.sodium || 0,
    servingSize: data.servingSize || data.serving_size || data.servingDescription || data.serving_description || '',
    servingSizeG: data.servingSizeG || data.serving_size_g || 0,
    per_unit_nutrition: data.per_unit_nutrition || false,
    category: data.category || '',
    source: data.source || '',
    verified: data.verified || false,
    allergens: data.allergens || [],
    additives: data.additives || [],
    createdAt: data.createdAt?._seconds || Date.now() / 1000,
    updatedAt: data.updatedAt?._seconds || Date.now() / 1000,
    nutritionGrade: data.nutritionGrade || data.nutrition_grade || '',
    score: data.score || 0,
    nameLength,
    isGeneric,
    processingGrade: data.processingGrade || '',
  };
}

async function bulkImport() {
  console.log('🚀 Starting bulk import to Algolia with ingredients as arrays...\n');

  const results = {};
  let totalImported = 0;

  for (const collection of collections) {
    console.log(`📦 Processing ${collection.name}...`);
    const snapshot = await db.collection(collection.name).get();

    let algoliaObjects = snapshot.docs.map(doc => ({
      objectID: doc.id,
      ...prepareForAlgolia(doc.data()),
    }));

    // Filter aiEnhanced to only include approved foods
    if (collection.name === 'aiEnhanced') {
      const originalCount = algoliaObjects.length;
      algoliaObjects = algoliaObjects.filter(obj => obj.status === 'approved');
      console.log(`  Filtered: ${originalCount} total, ${algoliaObjects.length} approved`);
    }

    if (algoliaObjects.length > 0) {
      // Show sample ingredients for first item
      if (algoliaObjects[0].ingredients && algoliaObjects[0].ingredients.length > 0) {
        console.log(`  Sample ingredients from first item: ${algoliaObjects[0].ingredients.slice(0, 3).join(', ')}...`);
      }

      await client.saveObjects({
        indexName: collection.indexName,
        objects: algoliaObjects,
      });
      results[collection.name] = algoliaObjects.length;
      totalImported += algoliaObjects.length;
      console.log(`  ✅ Imported ${algoliaObjects.length} items to ${collection.indexName}`);
    } else {
      results[collection.name] = 0;
      console.log(`  ⚠️  No items to import for ${collection.indexName}`);
    }
  }

  console.log('\n🎉 Bulk import completed!\n');
  console.log('Results:');
  console.log(JSON.stringify(results, null, 2));
  console.log(`\n📊 Total items imported: ${totalImported}`);
}

bulkImport()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
