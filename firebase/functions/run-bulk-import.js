#!/usr/bin/env node

const admin = require('firebase-admin');
const { algoliasearch } = require('algoliasearch');

// Initialize Firebase Admin with service account
const serviceAccount = require('/tmp/service-account-temp.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'nutrasafe-705c7'
});

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = 'd7334de1f8cb66eaba016ad9b2ded473';

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
  let totalWithIngredients = 0;

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

    // Count items with ingredients
    const withIngredients = algoliaObjects.filter(obj => obj.ingredients && obj.ingredients.length > 0).length;
    totalWithIngredients += withIngredients;

    if (algoliaObjects.length > 0) {
      // Show sample
      const sample = algoliaObjects.find(obj => obj.ingredients && obj.ingredients.length > 0);
      if (sample) {
        console.log(`  Sample: "${sample.name}" has ${sample.ingredients.length} ingredients: ${sample.ingredients.slice(0, 3).join(', ')}...`);
      }

      await client.saveObjects({
        indexName: collection.indexName,
        objects: algoliaObjects,
      });
      results[collection.name] = algoliaObjects.length;
      totalImported += algoliaObjects.length;
      console.log(`  ✅ Imported ${algoliaObjects.length} items (${withIngredients} with ingredients) to ${collection.indexName}`);
    } else {
      results[collection.name] = 0;
      console.log(`  ⚠️  No items to import for ${collection.indexName}`);
    }
  }

  console.log('\n🎉 Bulk import completed!\n');
  console.log('Results:');
  console.log(JSON.stringify(results, null, 2));
  console.log(`\n📊 Total: ${totalImported} items imported, ${totalWithIngredients} with ingredients`);
}

bulkImport()
  .then(() => {
    console.log('\n✅ Success! Now cleaning up temporary service account key...');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
