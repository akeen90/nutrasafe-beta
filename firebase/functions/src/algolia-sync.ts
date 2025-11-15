import * as functions from "firebase-functions/v2";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {algoliasearch} from "algoliasearch";

// Algolia configuration
const ALGOLIA_APP_ID = "WK0TIF84M2";
const algoliaAdminKey = defineSecret("ALGOLIA_ADMIN_API_KEY");

// Index names
const VERIFIED_FOODS_INDEX = "verified_foods";
const FOODS_INDEX = "foods";
const MANUAL_FOODS_INDEX = "manual_foods";

/**
 * Sync verified foods to Algolia when they're created/updated/deleted
 */
export const syncVerifiedFoodToAlgolia = onDocumentWritten({
  document: "verifiedFoods/{foodId}",
  secrets: [algoliaAdminKey],
}, async (event) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const foodId = event.params.foodId;
  const afterData = event.data?.after?.data();

  // Delete
  if (!afterData) {
    await client.deleteObject({
      indexName: VERIFIED_FOODS_INDEX,
      objectID: foodId,
    });
    console.log(`Deleted verified food ${foodId} from Algolia`);
    return;
  }

  // Create or Update
  const algoliaObject = {
    objectID: foodId,
    ...prepareForAlgolia(afterData),
  };

  await client.saveObject({
    indexName: VERIFIED_FOODS_INDEX,
    body: algoliaObject,
  });
  console.log(`Synced verified food ${foodId} to Algolia`);
});

/**
 * Sync foods collection to Algolia
 */
export const syncFoodToAlgolia = onDocumentWritten({
  document: "foods/{foodId}",
  secrets: [algoliaAdminKey],
}, async (event) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const foodId = event.params.foodId;
  const afterData = event.data?.after?.data();

  // Delete
  if (!afterData) {
    await client.deleteObject({
      indexName: FOODS_INDEX,
      objectID: foodId,
    });
    console.log(`Deleted food ${foodId} from Algolia`);
    return;
  }

  // Create or Update
  const algoliaObject = {
    objectID: foodId,
    ...prepareForAlgolia(afterData),
  };

  await client.saveObject({
    indexName: FOODS_INDEX,
    body: algoliaObject,
  });
  console.log(`Synced food ${foodId} to Algolia`);
});

/**
 * Sync manual foods to Algolia
 */
export const syncManualFoodToAlgolia = onDocumentWritten({
  document: "manualFoods/{foodId}",
  secrets: [algoliaAdminKey],
}, async (event) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const foodId = event.params.foodId;
  const afterData = event.data?.after?.data();

  // Delete
  if (!afterData) {
    await client.deleteObject({
      indexName: MANUAL_FOODS_INDEX,
      objectID: foodId,
    });
    console.log(`Deleted manual food ${foodId} from Algolia`);
    return;
  }

  // Create or Update
  const algoliaObject = {
    objectID: foodId,
    ...prepareForAlgolia(afterData),
  };

  await client.saveObject({
    indexName: MANUAL_FOODS_INDEX,
    body: algoliaObject,
  });
  console.log(`Synced manual food ${foodId} to Algolia`);
});

/**
 * Bulk import all existing foods to Algolia
 * Call this once to migrate existing data
 */
export const bulkImportFoodsToAlgolia = functions.https.onCall({
  secrets: [algoliaAdminKey],
  memory: "512MiB", // Increased memory for bulk operations
  timeoutSeconds: 300, // 5 minutes timeout for large datasets
}, async (request) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());
  const db = admin.firestore();

  const collections = [
    {name: "verifiedFoods", indexName: VERIFIED_FOODS_INDEX},
    {name: "foods", indexName: FOODS_INDEX},
    {name: "manualFoods", indexName: MANUAL_FOODS_INDEX},
  ];

  const results: any = {
    verifiedFoods: 0,
    foods: 0,
    manualFoods: 0,
  };

  for (const collection of collections) {
    const snapshot = await db.collection(collection.name).get();

    const algoliaObjects = snapshot.docs.map((doc) => ({
      objectID: doc.id,
      ...prepareForAlgolia(doc.data()),
    }));

    if (algoliaObjects.length > 0) {
      // Batch save objects
      await client.saveObjects({
        indexName: collection.indexName,
        objects: algoliaObjects,
      });
      results[collection.name] = algoliaObjects.length;
      console.log(`Imported ${algoliaObjects.length} items to ${collection.indexName}`);
    }
  }

  return {
    success: true,
    message: "Bulk import completed",
    results,
  };
});

/**
 * Search foods using Algolia
 * This provides a fast search endpoint for the iOS app
 */
export const searchFoodsAlgolia = functions.https.onCall({
  secrets: [algoliaAdminKey],
}, async (request) => {
  const {query, filters, hitsPerPage = 20} = request.data;

  if (!query || typeof query !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Query is required and must be a string"
    );
  }

  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  // Search across all indices
  const indices = [
    VERIFIED_FOODS_INDEX,
    FOODS_INDEX,
    MANUAL_FOODS_INDEX,
  ];

  const searchResults = await Promise.all(
    indices.map((indexName) =>
      client.searchSingleIndex({
        indexName,
        searchParams: {
          query,
          hitsPerPage,
          filters,
        },
      })
    )
  );

  // Combine results, prioritizing verified foods
  const combinedHits = [
    ...searchResults[0].hits, // Verified foods first
    ...searchResults[1].hits, // Regular foods
    ...searchResults[2].hits, // Manual foods
  ];

  return {
    hits: combinedHits.slice(0, hitsPerPage),
    nbHits: combinedHits.length,
  };
});

/**
 * Prepare food data for Algolia indexing
 * This transforms the Firebase document into an Algolia-optimized format
 */
function prepareForAlgolia(data: any): any {
  return {
    // Searchable fields
    name: data.name || data.foodName || "",
    brandName: data.brandName || data.brand || "",
    ingredients: data.ingredients || "",
    barcode: data.barcode || "",

    // Nutrition data for filtering
    calories: data.calories || 0,
    protein: data.protein || 0,
    carbs: data.carbs || 0,
    fat: data.fat || 0,
    fiber: data.fiber || 0,
    sugar: data.sugar || 0,
    sodium: data.sodium || 0,

    // Metadata
    servingSize: data.servingSize || data.serving_size || "",
    servingSizeG: data.servingSizeG || data.serving_size_g || 0,
    category: data.category || "",
    source: data.source || "",
    verified: data.verified || false,

    // Allergen info
    allergens: data.allergens || [],
    additives: data.additives || [],

    // Timestamps
    createdAt: data.createdAt?._seconds || Date.now() / 1000,
    updatedAt: data.updatedAt?._seconds || Date.now() / 1000,

    // Nutrition score for ranking
    nutritionGrade: data.nutritionGrade || data.nutrition_grade || "",
    score: data.score || 0,
  };
}
