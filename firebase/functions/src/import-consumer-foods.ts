import * as functionsV1 from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface ConsumerFood {
  id: string;
  name: string;
  category: string;
  servingSizeG: number;
  servingSize: string;
  per100g: {
    calories: number;
    protein: number;
    carbs: number;
    fat: number;
  };
  mwSource: string;
  tags: string[];
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber?: number;
  sugar?: number;
  saturatedFat?: number;
  sodium?: number;
  micronutrientProfile?: {
    vitamins: Record<string, number>;
    minerals: Record<string, number>;
    confidenceScore: string;
    dataSource: string;
  };
}

/**
 * Import consumer-friendly foods database to Firebase
 * POST body should contain array of foods
 */
export const importConsumerFoods = functionsV1
  .runWith({ memory: '1GB', timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    response.set('Access-Control-Allow-Origin', '*');
    if (request.method === 'OPTIONS') {
      response.set('Access-Control-Allow-Methods', 'POST');
      response.set('Access-Control-Allow-Headers', 'Content-Type');
      response.status(204).send('');
      return;
    }

    try {
      if (request.method !== 'POST') {
        response.status(405).json({ error: 'Method not allowed. Use POST.' });
        return;
      }

      const foods: ConsumerFood[] = request.body.foods || request.body;

      if (!Array.isArray(foods) || foods.length === 0) {
        response.status(400).json({ error: 'No foods provided. Expected { foods: [...] } or array directly.' });
        return;
      }

      console.log(`📥 Importing ${foods.length} consumer foods...`);

      const collectionRef = db.collection('consumer_foods');
      const batchSize = 500;
      let imported = 0;
      const errors: string[] = [];

      // Process in batches
      for (let i = 0; i < foods.length; i += batchSize) {
        const batch = db.batch();
        const chunk = foods.slice(i, i + batchSize);

        for (const food of chunk) {
          try {
            const docRef = collectionRef.doc(food.id);
            const docData = {
              ...food,
              searchableName: food.name.toLowerCase(),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              source: 'consumer_foods',
              dataSource: 'McCance and Widdowson 2021'
            };
            batch.set(docRef, docData);
            imported++;
          } catch (err) {
            errors.push(`Failed to prepare ${food.name}: ${err}`);
          }
        }

        await batch.commit();
        console.log(`✅ Committed batch ${Math.floor(i / batchSize) + 1}, total imported: ${imported}`);
      }

      response.json({
        success: true,
        imported,
        total: foods.length,
        errors: errors.length > 0 ? errors : undefined
      });

    } catch (error) {
      console.error('❌ Import failed:', error);
      response.status(500).json({
        error: 'Import failed',
        details: error instanceof Error ? error.message : String(error)
      });
    }
  });

/**
 * Get statistics about the consumer foods database
 */
export const getConsumerFoodsStats = functionsV1.https.onRequest(async (request, response) => {
  response.set('Access-Control-Allow-Origin', '*');
  if (request.method === 'OPTIONS') {
    response.set('Access-Control-Allow-Methods', 'GET');
    response.set('Access-Control-Allow-Headers', 'Content-Type');
    response.status(204).send('');
    return;
  }

  try {
    const collectionRef = db.collection('consumer_foods');
    const snapshot = await collectionRef.get();

    const categoryCount: Record<string, number> = {};
    let totalCalories = 0;

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const category = data.category || 'Unknown';
      categoryCount[category] = (categoryCount[category] || 0) + 1;
      totalCalories += data.calories || 0;
    });

    response.json({
      totalFoods: snapshot.size,
      categories: categoryCount,
      averageCalories: snapshot.size > 0 ? Math.round(totalCalories / snapshot.size) : 0
    });

  } catch (error) {
    console.error('❌ Failed to get stats:', error);
    response.status(500).json({
      error: 'Failed to get stats',
      details: error instanceof Error ? error.message : String(error)
    });
  }
});

/**
 * Sync consumer foods to Algolia
 */
export const syncConsumerFoodsToAlgolia = functionsV1
  .runWith({ memory: '1GB', timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    response.set('Access-Control-Allow-Origin', '*');
    if (request.method === 'OPTIONS') {
      response.set('Access-Control-Allow-Methods', 'GET, POST');
      response.set('Access-Control-Allow-Headers', 'Content-Type');
      response.status(204).send('');
      return;
    }

    try {
      // Dynamic import for Algolia
      const { algoliasearch } = await import('algoliasearch');

      const ALGOLIA_APP_ID = 'WK0TIF84M2';
      const ALGOLIA_ADMIN_KEY = functionsV1.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || '';

      if (!ALGOLIA_ADMIN_KEY) {
        response.status(500).json({ error: 'Algolia admin key not configured' });
        return;
      }

      const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
      const indexName = 'consumer_foods';

      // Get all consumer foods from Firebase
      const snapshot = await db.collection('consumer_foods').get();
      console.log(`📊 Found ${snapshot.size} consumer foods to sync`);

      if (snapshot.empty) {
        response.json({ success: true, synced: 0, message: 'No foods to sync' });
        return;
      }

      // Clear existing index first (to remove stale records)
      const clearFirst = request.query.clearFirst !== 'false';
      if (clearFirst) {
        console.log('🧹 Clearing existing Algolia index...');
        await client.clearObjects({ indexName });
      }

      // Prepare Algolia records
      const records = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          objectID: doc.id,
          name: data.name,
          searchableName: data.searchableName || data.name.toLowerCase(),
          category: data.category,
          servingSizeG: data.servingSizeG,
          servingSize: data.servingSize,
          per100g: data.per100g,
          mwSource: data.mwSource,
          tags: data.tags || [],
          calories: data.calories,
          protein: data.protein,
          carbs: data.carbs,
          fat: data.fat,
          fiber: data.fiber,
          sugar: data.sugar,
          saturatedFat: data.saturatedFat,
          sodium: data.sodium,
          micronutrientProfile: data.micronutrientProfile,
          portions: data.portions || null,
          source: 'consumer_foods',
          dataSource: 'McCance and Widdowson 2021'
        };
      });

      // Save to Algolia in batches
      const batchSize = 1000;
      let synced = 0;

      for (let i = 0; i < records.length; i += batchSize) {
        const batch = records.slice(i, i + batchSize);
        await client.saveObjects({ indexName, objects: batch });
        synced += batch.length;
        console.log(`✅ Synced batch: ${synced}/${records.length}`);
      }

      // Configure index settings for optimal search
      await client.setSettings({
        indexName,
        indexSettings: {
          searchableAttributes: [
            'name',
            'searchableName',
            'category',
            'tags',
            'mwSource'
          ],
          attributesForFaceting: [
            'category',
            'tags',
            'filterOnly(source)'
          ],
          customRanking: [
            'asc(name)'
          ],
          highlightPreTag: '<mark>',
          highlightPostTag: '</mark>'
        }
      });

      response.json({
        success: true,
        synced,
        clearedFirst: clearFirst,
        indexName
      });

    } catch (error) {
      console.error('❌ Algolia sync failed:', error);
      response.status(500).json({
        error: 'Algolia sync failed',
        details: error instanceof Error ? error.message : String(error)
      });
    }
  });

// Size patterns for consolidation
const sizePatterns = [
  { pattern: /\s*\(Small\)$/i, size: 'Small', order: 1 },
  { pattern: /\s*\(Medium\)$/i, size: 'Medium', order: 2 },
  { pattern: /\s*\(Large\)$/i, size: 'Large', order: 3 },
  { pattern: /\s*\(Extra Large\)$/i, size: 'Extra Large', order: 4 },
  { pattern: /\s*\(Mini\)$/i, size: 'Mini', order: 0 },
];

function getBaseName(name: string): string {
  let baseName = name;
  for (const { pattern } of sizePatterns) {
    baseName = baseName.replace(pattern, '');
  }
  return baseName.trim();
}

function getSizeInfo(name: string): { size: string; order: number } | null {
  for (const { pattern, size, order } of sizePatterns) {
    if (pattern.test(name)) {
      return { size, order };
    }
  }
  return null;
}

interface FoodVariant {
  docId: string;
  data: any;
  sizeInfo: { size: string; order: number } | null;
  originalName: string;
}

/**
 * Consolidate consumer foods with size variants into single entries with portions
 * Before: Banana (Small), Banana (Medium), Banana (Large) - 3 separate documents
 * After: Banana - 1 document with portions array
 */
export const consolidateConsumerFoods = functionsV1
  .runWith({ memory: '1GB', timeoutSeconds: 540 })
  .https.onRequest(async (request, response) => {
    response.set('Access-Control-Allow-Origin', '*');
    if (request.method === 'OPTIONS') {
      response.set('Access-Control-Allow-Methods', 'GET, POST');
      response.set('Access-Control-Allow-Headers', 'Content-Type');
      response.status(204).send('');
      return;
    }

    try {
      const dryRun = request.query.dryRun !== 'false'; // Default to dry run

      console.log(`📦 Consolidating consumer_foods (dryRun: ${dryRun})...`);

      const snapshot = await db.collection('consumer_foods').get();
      console.log(`Found ${snapshot.size} documents`);

      // Group foods by base name
      const foodGroups = new Map<string, FoodVariant[]>();

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const name = data.name as string;
        const baseName = getBaseName(name);
        const sizeInfo = getSizeInfo(name);

        if (!foodGroups.has(baseName)) {
          foodGroups.set(baseName, []);
        }

        foodGroups.get(baseName)!.push({
          docId: doc.id,
          data,
          sizeInfo,
          originalName: name
        });
      });

      console.log(`Grouped into ${foodGroups.size} unique foods`);

      // Process each group
      const consolidatedFoods: any[] = [];
      const toDelete: string[] = [];
      let consolidatedCount = 0;

      for (const [baseName, variants] of foodGroups) {
        // Check if this food has multiple size variants
        const hasMultipleSizes = variants.length > 1 && variants.some(v => v.sizeInfo);

        if (hasMultipleSizes) {
          // Sort by size order
          variants.sort((a, b) => {
            const orderA = a.sizeInfo?.order ?? 99;
            const orderB = b.sizeInfo?.order ?? 99;
            return orderA - orderB;
          });

          // Use the smallest (or first) as the base
          const baseData = variants[0].data;

          // Build portions array
          const portions = variants
            .filter(v => v.sizeInfo)
            .map(v => ({
              name: `${v.sizeInfo!.size} (${v.data.servingSizeG}g)`,
              calories: v.data.calories,
              serving_g: v.data.servingSizeG
            }));

          // Create consolidated food entry with per100g as base
          const consolidatedFood = {
            id: `consumer_${baseName.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`,
            name: baseName,
            searchableName: baseName.toLowerCase(),
            category: baseData.category,
            servingSizeG: 100,
            servingSize: 'per 100g',
            per100g: baseData.per100g,
            // Use per100g values as base nutrition
            calories: baseData.per100g?.calories ?? baseData.calories,
            protein: baseData.per100g?.protein ?? baseData.protein,
            carbs: baseData.per100g?.carbs ?? baseData.carbs,
            fat: baseData.per100g?.fat ?? baseData.fat,
            fiber: baseData.fiber,
            sugar: baseData.sugar,
            saturatedFat: baseData.saturatedFat,
            sodium: baseData.sodium,
            mwSource: baseData.mwSource,
            tags: baseData.tags || [],
            portions: portions,
            micronutrientProfile: baseData.micronutrientProfile,
            source: 'consumer_foods',
            dataSource: 'McCance and Widdowson 2021'
          };

          consolidatedFoods.push(consolidatedFood);
          variants.forEach(v => toDelete.push(v.docId));
          consolidatedCount++;

          console.log(`✓ ${baseName}: ${variants.length} sizes → portions [${portions.map(p => p.name).join(', ')}]`);
        } else {
          // Single entry - keep but clean up name if it has size suffix
          const variant = variants[0];
          const data = variant.data;
          const cleanName = getBaseName(data.name);

          const food = {
            id: variant.docId,
            name: cleanName,
            searchableName: cleanName.toLowerCase(),
            category: data.category,
            servingSizeG: data.servingSizeG || 100,
            servingSize: data.servingSize || 'per 100g',
            per100g: data.per100g,
            calories: data.per100g?.calories ?? data.calories,
            protein: data.per100g?.protein ?? data.protein,
            carbs: data.per100g?.carbs ?? data.carbs,
            fat: data.per100g?.fat ?? data.fat,
            fiber: data.fiber,
            sugar: data.sugar,
            saturatedFat: data.saturatedFat,
            sodium: data.sodium,
            mwSource: data.mwSource,
            tags: data.tags || [],
            micronutrientProfile: data.micronutrientProfile,
            source: 'consumer_foods',
            dataSource: 'McCance and Widdowson 2021',
            // Add default portion if non-100g serving
            ...(data.servingSizeG && data.servingSizeG !== 100 ? {
              portions: [{
                name: `1 serving (${data.servingSizeG}g)`,
                calories: data.calories,
                serving_g: data.servingSizeG
              }]
            } : {})
          };

          consolidatedFoods.push(food);
          toDelete.push(variant.docId);
        }
      }

      if (dryRun) {
        response.json({
          success: true,
          dryRun: true,
          originalCount: snapshot.size,
          consolidatedCount: consolidatedFoods.length,
          foodsWithPortions: consolidatedCount,
          sampleConsolidated: consolidatedFoods.filter(f => f.portions?.length > 1).slice(0, 5),
          message: `Would consolidate ${snapshot.size} → ${consolidatedFoods.length} foods (${consolidatedCount} with portions). Add ?dryRun=false to execute.`
        });
        return;
      }

      // Execute the consolidation
      console.log('🔄 Executing consolidation...');

      // Delete old documents
      const BATCH_SIZE = 500;
      for (let i = 0; i < toDelete.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchIds = toDelete.slice(i, i + BATCH_SIZE);
        batchIds.forEach(docId => {
          batch.delete(db.collection('consumer_foods').doc(docId));
        });
        await batch.commit();
        console.log(`  Deleted ${Math.min(i + BATCH_SIZE, toDelete.length)}/${toDelete.length}`);
      }

      // Add consolidated documents
      for (let i = 0; i < consolidatedFoods.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const batchFoods = consolidatedFoods.slice(i, i + BATCH_SIZE);
        batchFoods.forEach(food => {
          const docRef = db.collection('consumer_foods').doc(food.id);
          batch.set(docRef, {
            ...food,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });
        await batch.commit();
        console.log(`  Added ${Math.min(i + BATCH_SIZE, consolidatedFoods.length)}/${consolidatedFoods.length}`);
      }

      response.json({
        success: true,
        originalCount: snapshot.size,
        consolidatedCount: consolidatedFoods.length,
        foodsWithPortions: consolidatedCount,
        message: `Consolidated ${snapshot.size} → ${consolidatedFoods.length} foods. Run syncConsumerFoodsToAlgolia to update search.`
      });

    } catch (error) {
      console.error('❌ Consolidation failed:', error);
      response.status(500).json({
        error: 'Consolidation failed',
        details: error instanceof Error ? error.message : String(error)
      });
    }
  });

/**
 * Clear all consumer foods from Firebase
 */
export const clearConsumerFoods = functionsV1
  .runWith({ timeoutSeconds: 300 })
  .https.onRequest(async (request, response) => {
    response.set('Access-Control-Allow-Origin', '*');
    if (request.method === 'OPTIONS') {
      response.set('Access-Control-Allow-Methods', 'GET, POST');
      response.set('Access-Control-Allow-Headers', 'Content-Type');
      response.status(204).send('');
      return;
    }

    try {
      const confirm = request.query.confirm === 'true';

      if (!confirm) {
        response.status(400).json({
          error: 'Add ?confirm=true to confirm deletion',
          warning: 'This will delete ALL consumer foods from Firebase'
        });
        return;
      }

      const collectionRef = db.collection('consumer_foods');
      const snapshot = await collectionRef.get();

      const batchSize = 500;
      let deleted = 0;

      for (let i = 0; i < snapshot.docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = snapshot.docs.slice(i, i + batchSize);

        chunk.forEach(doc => {
          batch.delete(doc.ref);
        });

        await batch.commit();
        deleted += chunk.length;
        console.log(`🗑️ Deleted batch: ${deleted}/${snapshot.size}`);
      }

      response.json({
        success: true,
        deleted
      });

    } catch (error) {
      console.error('❌ Clear failed:', error);
      response.status(500).json({
        error: 'Clear failed',
        details: error instanceof Error ? error.message : String(error)
      });
    }
  });
