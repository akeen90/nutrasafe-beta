import * as functionsV1 from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Import McCance and Widdowson UK Food Composition data to Firebase
 * This is the authoritative UK reference for generic food nutritional values
 */

interface McCanceFood {
  foodCode: string;
  name: string;
  description?: string;
  group?: string;
  calories: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
  saturatedFat?: number;
  cholesterol?: number;
  starch?: number;
  sodium?: number;
  potassium?: number;
  calcium?: number;
  magnesium?: number;
  phosphorus?: number;
  iron?: number;
  copper?: number;
  zinc?: number;
  manganese?: number;
  selenium?: number;
  iodine?: number;
  vitaminA?: number;
  retinol?: number;
  carotene?: number;
  vitaminD?: number;
  vitaminE?: number;
  vitaminK?: number;
  thiamin?: number;
  riboflavin?: number;
  niacin?: number;
  vitaminB6?: number;
  vitaminB12?: number;
  folate?: number;
  pantothenicAcid?: number;
  biotin?: number;
  vitaminC?: number;
  source?: string;
  isGeneric?: boolean;
  verified?: boolean;
  servingSize?: string;
  servingSizeG?: number;
}

/**
 * HTTP endpoint to import McCance & Widdowson data
 * Expects JSON body with foods array, or reads from default path
 */
export const importMcCanceWiddowson = functionsV1
  .runWith({ memory: "1GB", timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    if (request.method !== "POST") {
      response.status(405).json({ error: "Use POST with JSON body containing foods array" });
      return;
    }

    const dryRun = request.query.dryRun === "true";
    const clearExisting = request.query.clearExisting === "true";

    try {
      const foods: McCanceFood[] = request.body.foods || request.body;

      if (!Array.isArray(foods) || foods.length === 0) {
        response.status(400).json({ error: "Request body must contain a foods array" });
        return;
      }

      console.log(`📦 Importing ${foods.length} McCance & Widdowson foods (dryRun: ${dryRun}, clearExisting: ${clearExisting})`);

      const db = admin.firestore();
      const collectionRef = db.collection("generic_database");

      // Optionally clear existing data
      if (clearExisting && !dryRun) {
        console.log("🗑️ Clearing existing generic_database...");
        const existingDocs = await collectionRef.listDocuments();
        const BATCH_SIZE = 500;

        for (let i = 0; i < existingDocs.length; i += BATCH_SIZE) {
          const batch = db.batch();
          const batchDocs = existingDocs.slice(i, i + BATCH_SIZE);
          batchDocs.forEach(doc => batch.delete(doc));
          await batch.commit();
          console.log(`  Deleted ${Math.min(i + BATCH_SIZE, existingDocs.length)}/${existingDocs.length}`);
        }
        console.log(`✅ Cleared ${existingDocs.length} existing documents`);
      }

      // Import new data
      const BATCH_SIZE = 500;
      let imported = 0;
      const errors: string[] = [];

      for (let i = 0; i < foods.length; i += BATCH_SIZE) {
        if (dryRun) {
          imported += Math.min(BATCH_SIZE, foods.length - i);
          continue;
        }

        const batch = db.batch();
        const batchFoods = foods.slice(i, i + BATCH_SIZE);

        for (const food of batchFoods) {
          try {
            // Generate a clean document ID from food code or name
            const docId = food.foodCode
              ? `mw_${food.foodCode.replace(/[^a-zA-Z0-9-]/g, "_")}`
              : `mw_${food.name.toLowerCase().replace(/[^a-z0-9]/g, "_").substring(0, 50)}`;

            // Build micronutrient profile
            const vitamins: Record<string, number> = {};
            const minerals: Record<string, number> = {};

            if (food.vitaminA) vitamins.vitaminA = food.vitaminA;
            if (food.vitaminC) vitamins.vitaminC = food.vitaminC;
            if (food.vitaminD) vitamins.vitaminD = food.vitaminD;
            if (food.vitaminE) vitamins.vitaminE = food.vitaminE;
            if (food.vitaminK) vitamins.vitaminK = food.vitaminK;
            if (food.thiamin) vitamins.thiamin = food.thiamin;
            if (food.riboflavin) vitamins.riboflavin = food.riboflavin;
            if (food.niacin) vitamins.niacin = food.niacin;
            if (food.vitaminB6) vitamins.vitaminB6 = food.vitaminB6;
            if (food.vitaminB12) vitamins.vitaminB12 = food.vitaminB12;
            if (food.folate) vitamins.folate = food.folate;
            if (food.pantothenicAcid) vitamins.pantothenicAcid = food.pantothenicAcid;
            if (food.biotin) vitamins.biotin = food.biotin;

            if (food.calcium) minerals.calcium = food.calcium;
            if (food.iron) minerals.iron = food.iron;
            if (food.magnesium) minerals.magnesium = food.magnesium;
            if (food.phosphorus) minerals.phosphorus = food.phosphorus;
            if (food.potassium) minerals.potassium = food.potassium;
            if (food.sodium) minerals.sodium = food.sodium;
            if (food.zinc) minerals.zinc = food.zinc;
            if (food.copper) minerals.copper = food.copper;
            if (food.manganese) minerals.manganese = food.manganese;
            if (food.selenium) minerals.selenium = food.selenium;
            if (food.iodine) minerals.iodine = food.iodine;

            const docData = {
              // Core identifiers
              foodCode: food.foodCode,
              name: food.name,
              brandName: "Generic",
              description: food.description || null,
              group: food.group || null,
              barcode: "",

              // Macros (per 100g)
              calories: food.calories,
              protein: food.protein || 0,
              carbs: food.carbs || 0,
              fat: food.fat || 0,
              saturatedFat: food.saturatedFat || null,
              fiber: food.fiber || 0,
              sugar: food.sugar || 0,
              sodium: food.sodium || null,
              cholesterol: food.cholesterol || null,
              starch: food.starch || null,

              // Micronutrient profile (structured)
              micronutrientProfile: {
                vitamins,
                minerals,
                confidenceScore: "high",
                dataSource: "McCance and Widdowson 2021",
              },

              // Flat micronutrient fields (for querying/filtering)
              ...vitamins,
              ...minerals,

              // Metadata
              source: "McCance and Widdowson 2021",
              dataSource: "mccance_widdowson",
              isGeneric: true,
              verified: true,
              isVerified: true,
              servingSize: "per 100g",
              servingSizeG: 100,
              per_unit_nutrition: false,

              // Timestamps
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            batch.set(collectionRef.doc(docId), docData);
            imported++;
          } catch (err: any) {
            errors.push(`${food.name}: ${err.message}`);
          }
        }

        await batch.commit();
        console.log(`  Imported ${imported}/${foods.length} foods...`);
      }

      response.json({
        success: true,
        dryRun,
        imported,
        total: foods.length,
        errors: errors.length > 0 ? errors.slice(0, 10) : undefined,
        message: dryRun
          ? `Would import ${imported} foods to generic_database`
          : `Successfully imported ${imported} foods to generic_database`,
      });
    } catch (error: any) {
      console.error("❌ Import error:", error);
      response.status(500).json({ error: error.message });
    }
  });

/**
 * Sync generic_database to Algolia
 */
export const syncGenericDatabaseToAlgolia = functionsV1
  .runWith({ memory: "1GB", timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    // Dynamic import algoliasearch
    const { algoliasearch } = await import("algoliasearch");

    const ALGOLIA_APP_ID = "WK0TIF84M2";
    const ALGOLIA_ADMIN_KEY = functionsV1.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || "";

    if (!ALGOLIA_ADMIN_KEY) {
      response.status(500).json({ error: "Algolia admin key not configured. Set via: firebase functions:config:set algolia.admin_key=YOUR_KEY" });
      return;
    }

    const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
    const db = admin.firestore();

    const clearFirst = request.query.clearFirst !== "false"; // Default to true

    try {
      console.log(`📦 Syncing generic_database to Algolia (clearFirst: ${clearFirst})...`);

      // Clear existing Algolia index first to remove stale records
      if (clearFirst) {
        console.log("  Clearing existing Algolia index...");
        await client.clearObjects({ indexName: "generic_database" });
        console.log("  Index cleared");
      }

      // Get all documents from Firebase
      const snapshot = await db.collection("generic_database").get();
      console.log(`  Found ${snapshot.size} documents in Firebase`);

      // Transform to Algolia format
      const algoliaObjects = snapshot.docs.map(doc => {
        const data = doc.data();
        const name = data.name || "";
        const brandName = data.brandName || "Generic";

        return {
          objectID: doc.id,
          name,
          foodName: name,
          brandName,
          brand: brandName,
          barcode: data.barcode || "",
          ingredients: data.ingredients || [name.toLowerCase()],

          // Macros
          calories: data.calories || 0,
          protein: data.protein || 0,
          carbs: data.carbs || 0,
          fat: data.fat || 0,
          saturatedFat: data.saturatedFat || 0,
          fiber: data.fiber || 0,
          sugar: data.sugar || 0,
          sodium: data.sodium || 0,

          // Metadata
          servingSize: data.servingSize || "per 100g",
          servingSizeG: data.servingSizeG || 100,
          per_unit_nutrition: false,
          category: data.group || "",
          source: "McCance and Widdowson 2021",
          verified: true,
          isVerified: true,

          // Custom ranking
          nameLength: name.length,
          isGeneric: 1, // Boost generic foods in search
          score: 0,

          // Micronutrients (for filtering)
          vitaminC: data.vitaminC || 0,
          vitaminA: data.vitaminA || 0,
          vitaminD: data.vitaminD || 0,
          calcium: data.calcium || 0,
          iron: data.iron || 0,
          potassium: data.potassium || 0,

          // Include full micronutrient profile
          micronutrientProfile: data.micronutrientProfile || null,
        };
      });

      // Configure index settings first
      await client.setSettings({
        indexName: "generic_database",
        indexSettings: {
          searchableAttributes: [
            "unordered(name)",
            "unordered(brandName)",
            "barcode",
            "unordered(ingredients)",
          ],
          customRanking: [
            "desc(isGeneric)",
            "asc(nameLength)",
            "desc(verified)",
          ],
          ranking: ["typo", "words", "filters", "proximity", "attribute", "exact", "custom"],
          minWordSizefor1Typo: 3,
          minWordSizefor2Typos: 6,
          typoTolerance: true,
          exactOnSingleWordQuery: "word",
          ignorePlurals: ["en"],
          removeStopWords: ["en"],
        },
      });
      console.log("  Configured index settings");

      // Batch save in chunks
      const BATCH_SIZE = 1000;
      let synced = 0;

      for (let i = 0; i < algoliaObjects.length; i += BATCH_SIZE) {
        const batch = algoliaObjects.slice(i, i + BATCH_SIZE);
        await client.saveObjects({
          indexName: "generic_database",
          objects: batch,
        });
        synced += batch.length;
        console.log(`  Synced ${synced}/${algoliaObjects.length}`);
      }

      response.json({
        success: true,
        synced,
        total: snapshot.size,
        message: `Successfully synced ${synced} foods to Algolia generic_database index`,
      });
    } catch (error: any) {
      console.error("❌ Sync error:", error);
      response.status(500).json({ error: error.message });
    }
  });

/**
 * Clean up generic_database by removing non-McCance & Widdowson data
 * Only keeps documents with "mw_" prefix (McCance & Widdowson imports)
 */
export const cleanupGenericDatabase = functionsV1
  .runWith({ memory: "512MB", timeoutSeconds: 300 })
  .https.onRequest(async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    const dryRun = request.query.dryRun === "true";
    const db = admin.firestore();

    try {
      console.log(`🧹 Cleaning up generic_database (dryRun: ${dryRun})...`);

      // Get all documents
      const snapshot = await db.collection("generic_database").get();
      console.log(`  Found ${snapshot.size} total documents`);

      // Find documents NOT starting with "mw_" (non-McCance & Widdowson)
      const toDelete: string[] = [];
      const toKeep: string[] = [];

      snapshot.docs.forEach(doc => {
        if (doc.id.startsWith("mw_")) {
          toKeep.push(doc.id);
        } else {
          toDelete.push(doc.id);
        }
      });

      console.log(`  McCance & Widdowson (keep): ${toKeep.length}`);
      console.log(`  Other (delete): ${toDelete.length}`);

      if (dryRun) {
        response.json({
          success: true,
          dryRun: true,
          toDelete: toDelete.length,
          toKeep: toKeep.length,
          sampleToDelete: toDelete.slice(0, 10),
          message: `Would delete ${toDelete.length} non-McCance & Widdowson documents`,
        });
        return;
      }

      // Delete in batches
      const BATCH_SIZE = 500;
      let deleted = 0;

      for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchIds = toDelete.slice(i, i + BATCH_SIZE);

        batchIds.forEach(docId => {
          batch.delete(db.collection("generic_database").doc(docId));
        });

        await batch.commit();
        deleted += batchIds.length;
        console.log(`  Deleted ${deleted}/${toDelete.length}...`);
      }

      response.json({
        success: true,
        deleted,
        kept: toKeep.length,
        message: `Deleted ${deleted} non-McCance & Widdowson documents, kept ${toKeep.length} McCance & Widdowson entries`,
      });
    } catch (error: any) {
      console.error("❌ Cleanup error:", error);
      response.status(500).json({ error: error.message });
    }
  });

/**
 * Clear all data from generic_database (Firebase + Algolia)
 */
export const clearGenericDatabase = functionsV1
  .runWith({ memory: "512MB", timeoutSeconds: 300 })
  .https.onRequest(async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    if (request.method === "OPTIONS") {
      response.set("Access-Control-Allow-Methods", "GET, POST");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.status(204).send("");
      return;
    }

    const confirm = request.query.confirm === "true";
    const clearAlgolia = request.query.clearAlgolia !== "false"; // Default true

    if (!confirm) {
      response.status(400).json({
        error: "Add ?confirm=true to confirm deletion",
        warning: "This will delete ALL data from generic_database (Firebase and Algolia)",
      });
      return;
    }

    const db = admin.firestore();

    try {
      console.log("🗑️ Clearing generic_database...");

      // Clear Firebase
      const snapshot = await db.collection("generic_database").get();
      const total = snapshot.size;

      if (total > 0) {
        const BATCH_SIZE = 500;
        let deleted = 0;

        for (let i = 0; i < snapshot.docs.length; i += BATCH_SIZE) {
          const batch = db.batch();
          const batchDocs = snapshot.docs.slice(i, i + BATCH_SIZE);
          batchDocs.forEach(doc => batch.delete(doc.ref));
          await batch.commit();
          deleted += batchDocs.length;
          console.log(`  Deleted ${deleted}/${total} from Firebase...`);
        }
      }

      // Clear Algolia index
      let algoliaCleared = false;
      if (clearAlgolia) {
        try {
          const { algoliasearch } = await import("algoliasearch");
          const ALGOLIA_APP_ID = "WK0TIF84M2";
          const ALGOLIA_ADMIN_KEY = functionsV1.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || "";

          if (ALGOLIA_ADMIN_KEY) {
            const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
            await client.clearObjects({ indexName: "generic_database" });
            algoliaCleared = true;
            console.log("  Cleared Algolia generic_database index");
          } else {
            console.log("  Skipped Algolia (no admin key configured)");
          }
        } catch (algoliaErr: any) {
          console.log(`  Algolia clear failed: ${algoliaErr.message}`);
        }
      }

      response.json({
        success: true,
        firebaseDeleted: total,
        algoliaCleared,
        message: `Deleted ${total} documents from Firebase${algoliaCleared ? " and cleared Algolia index" : ""}`,
      });
    } catch (error: any) {
      console.error("❌ Clear error:", error);
      response.status(500).json({ error: error.message });
    }
  });

/**
 * Get stats about the generic_database
 */
export const getGenericDatabaseStats = functionsV1.https.onRequest(async (request, response) => {
  response.set("Access-Control-Allow-Origin", "*");
  if (request.method === "OPTIONS") {
    response.set("Access-Control-Allow-Methods", "GET");
    response.set("Access-Control-Allow-Headers", "Content-Type");
    response.status(204).send("");
    return;
  }

  const db = admin.firestore();

  try {
    const countSnapshot = await db.collection("generic_database").count().get();
    const total = countSnapshot.data().count;

    // Get sample foods
    const sampleSnapshot = await db.collection("generic_database").limit(10).get();
    const samples = sampleSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        name: data.name,
        calories: data.calories,
        protein: data.protein,
        hasVitamins: Object.keys(data.micronutrientProfile?.vitamins || {}).length,
        hasMinerals: Object.keys(data.micronutrientProfile?.minerals || {}).length,
      };
    });

    response.json({
      total,
      samples,
    });
  } catch (error: any) {
    response.status(500).json({ error: error.message });
  }
});
