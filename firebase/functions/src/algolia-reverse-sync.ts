import * as functionsV1 from "firebase-functions";
import * as admin from "firebase-admin";
import {algoliasearch} from "algoliasearch";

// Algolia configuration
const ALGOLIA_APP_ID = "WK0TIF84M2";
const getAlgoliaAdminKey = () => functionsV1.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || "";

// Mapping of Algolia indices to Firebase collections
const INDEX_TO_COLLECTION: Record<string, string> = {
  "verified_foods": "verifiedFoods",
  "foods": "foods",
  "manual_foods": "manualFoods",
  "user_added": "userAdded",
  "ai_enhanced": "aiEnhanced",
  "ai_manually_added": "aiManuallyAdded",
  "tesco_products": "tescoProducts",
  "uk_foods_cleaned": "uk_foods_cleaned",
  "generic_database": "generic_database",
  "fast_foods_database": "fast_foods_database",
};

/**
 * Transform Algolia record back to Firebase format
 */
function transformAlgoliaToFirebase(algoliaRecord: any): any {
  // Remove Algolia-specific fields
  const {objectID, _highlightResult, _rankingInfo, nameLength, isGeneric, ...data} = algoliaRecord;

  return {
    ...data,
    // Ensure consistent field naming
    name: data.name || data.foodName || "",
    brand: data.brandName || data.brand || "",
    brandName: data.brandName || data.brand || "",
    // Ensure boolean fields
    verified: Boolean(data.verified || data.isVerified),
    isVerified: Boolean(data.isVerified || data.verified),
    // Convert timestamps if needed
    createdAt: data.createdAt ? admin.firestore.Timestamp.fromMillis(data.createdAt * 1000) : admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    // Mark as synced from Algolia
    syncedFromAlgolia: true,
    syncedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Check which Algolia records are missing from Firebase (dry run)
 * Returns a report of discrepancies without making changes
 */
export const checkAlgoliaFirebaseSync = functionsV1
  .runWith({memory: "1GB", timeoutSeconds: 540})
  .https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
      response.status(500).json({error: "Algolia admin key not configured"});
      return;
    }

    // Optional: specify which index to check
    const indexName = request.query.index as string || "";
    const indicesToCheck = indexName ? [indexName] : Object.keys(INDEX_TO_COLLECTION);

    const client = algoliasearch(ALGOLIA_APP_ID, adminKey);
    const db = admin.firestore();

    const report: Record<string, any> = {};

    for (const index of indicesToCheck) {
      const collectionName = INDEX_TO_COLLECTION[index];
      if (!collectionName) {
        report[index] = {error: `No Firebase collection mapping for index: ${index}`};
        continue;
      }

      console.log(`📊 Checking index: ${index} -> collection: ${collectionName}`);

      try {
        // Browse all records in Algolia index
        const algoliaRecords: any[] = [];
        let cursor: string | undefined;

        do {
          const browseResult = await client.browse({
            indexName: index,
            browseParams: {
              hitsPerPage: 1000,
              cursor: cursor,
            },
          });

          algoliaRecords.push(...(browseResult.hits || []));
          cursor = browseResult.cursor;
          console.log(`  Fetched ${algoliaRecords.length} Algolia records...`);
        } while (cursor);

        // Get all Firebase document IDs
        const firebaseSnapshot = await db.collection(collectionName).select().get();
        const firebaseIds = new Set(firebaseSnapshot.docs.map(doc => doc.id));

        // Find records in Algolia but not in Firebase
        const missingInFirebase = algoliaRecords.filter(record => !firebaseIds.has(record.objectID));

        // Find records in Firebase but not in Algolia (for completeness)
        const algoliaIds = new Set(algoliaRecords.map(r => r.objectID));
        const missingInAlgolia = firebaseSnapshot.docs.filter(doc => !algoliaIds.has(doc.id)).map(doc => doc.id);

        report[index] = {
          algoliaCount: algoliaRecords.length,
          firebaseCount: firebaseSnapshot.size,
          missingInFirebase: missingInFirebase.length,
          missingInAlgolia: missingInAlgolia.length,
          missingInFirebaseIds: missingInFirebase.slice(0, 50).map(r => ({
            objectID: r.objectID,
            name: r.name || r.foodName || "Unknown",
            brand: r.brandName || r.brand || "",
          })),
          missingInAlgoliaIds: missingInAlgolia.slice(0, 50),
        };

        console.log(`✅ ${index}: Algolia=${algoliaRecords.length}, Firebase=${firebaseSnapshot.size}, MissingInFB=${missingInFirebase.length}, MissingInAlgolia=${missingInAlgolia.length}`);
      } catch (error: any) {
        console.error(`❌ Error checking ${index}:`, error.message);
        report[index] = {error: error.message};
      }
    }

    response.json({
      success: true,
      message: "Sync check completed",
      report,
    });
  });

/**
 * Sync records from Algolia to Firebase
 * This will create any records that exist in Algolia but not in Firebase
 */
export const syncAlgoliaToFirebase = functionsV1
  .runWith({memory: "1GB", timeoutSeconds: 540})
  .https.onRequest(async (request, response) => {
    // Handle CORS
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    const adminKey = getAlgoliaAdminKey();
    if (!adminKey) {
      response.status(500).json({error: "Algolia admin key not configured"});
      return;
    }

    // Require index parameter for safety
    const indexName = request.query.index as string;
    if (!indexName) {
      response.status(400).json({error: "Please specify an index parameter (e.g., ?index=verified_foods)"});
      return;
    }

    const collectionName = INDEX_TO_COLLECTION[indexName];
    if (!collectionName) {
      response.status(400).json({error: `No Firebase collection mapping for index: ${indexName}`});
      return;
    }

    // Optional dry run mode (default: true for safety)
    const dryRun = request.query.dryRun !== "false";

    const client = algoliasearch(ALGOLIA_APP_ID, adminKey);
    const db = admin.firestore();

    console.log(`🔄 Syncing index: ${indexName} -> collection: ${collectionName} (dryRun: ${dryRun})`);

    try {
      // Browse all records in Algolia index
      const algoliaRecords: any[] = [];
      let cursor: string | undefined;

      do {
        const browseResult = await client.browse({
          indexName: indexName,
          browseParams: {
            hitsPerPage: 1000,
            cursor: cursor,
          },
        });

        algoliaRecords.push(...(browseResult.hits || []));
        cursor = browseResult.cursor;
        console.log(`  Fetched ${algoliaRecords.length} Algolia records...`);
      } while (cursor);

      // Get all Firebase document IDs
      const firebaseSnapshot = await db.collection(collectionName).select().get();
      const firebaseIds = new Set(firebaseSnapshot.docs.map(doc => doc.id));

      // Find records in Algolia but not in Firebase
      const missingInFirebase = algoliaRecords.filter(record => !firebaseIds.has(record.objectID));

      console.log(`📊 Found ${missingInFirebase.length} records missing in Firebase`);

      if (dryRun) {
        response.json({
          success: true,
          dryRun: true,
          message: `Would sync ${missingInFirebase.length} records from Algolia to Firebase`,
          index: indexName,
          collection: collectionName,
          algoliaCount: algoliaRecords.length,
          firebaseCount: firebaseSnapshot.size,
          missingCount: missingInFirebase.length,
          sampleRecords: missingInFirebase.slice(0, 20).map(r => ({
            objectID: r.objectID,
            name: r.name || r.foodName || "Unknown",
            brand: r.brandName || r.brand || "",
            calories: r.calories,
          })),
        });
        return;
      }

      // Batch write to Firebase
      const BATCH_SIZE = 500;
      let synced = 0;

      for (let i = 0; i < missingInFirebase.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchRecords = missingInFirebase.slice(i, i + BATCH_SIZE);

        for (const record of batchRecords) {
          const docRef = db.collection(collectionName).doc(record.objectID);
          const firebaseData = transformAlgoliaToFirebase(record);
          batch.set(docRef, firebaseData);
        }

        await batch.commit();
        synced += batchRecords.length;
        console.log(`  Synced ${synced}/${missingInFirebase.length} records...`);
      }

      response.json({
        success: true,
        dryRun: false,
        message: `Successfully synced ${synced} records from Algolia to Firebase`,
        index: indexName,
        collection: collectionName,
        syncedCount: synced,
      });
    } catch (error: any) {
      console.error(`❌ Error syncing ${indexName}:`, error.message);
      response.status(500).json({error: error.message});
    }
  });

/**
 * Get stats for all Algolia indices
 */
export const getAlgoliaIndexStats = functionsV1.https.onRequest(async (request, response) => {
  // Handle CORS
  response.set("Access-Control-Allow-Origin", "*");
  if (request.method === "OPTIONS") {
    response.set("Access-Control-Allow-Methods", "GET");
    response.set("Access-Control-Allow-Headers", "Content-Type");
    response.status(204).send("");
    return;
  }

  const adminKey = getAlgoliaAdminKey();
  if (!adminKey) {
    response.status(500).json({error: "Algolia admin key not configured"});
    return;
  }

  const client = algoliasearch(ALGOLIA_APP_ID, adminKey);
  const stats: Record<string, any> = {};

  for (const indexName of Object.keys(INDEX_TO_COLLECTION)) {
    try {
      // Use search with empty query to get count
      const searchResult = await client.searchSingleIndex({
        indexName,
        searchParams: {
          query: "",
          hitsPerPage: 0,
        },
      });

      stats[indexName] = {
        recordCount: searchResult.nbHits,
        firebaseCollection: INDEX_TO_COLLECTION[indexName],
      };
    } catch (error: any) {
      stats[indexName] = {
        error: error.message,
        firebaseCollection: INDEX_TO_COLLECTION[indexName],
      };
    }
  }

  response.json({success: true, stats});
});
