/**
 * Sync Master Database to Algolia
 * Syncs deduplicated master database from Firestore to Algolia index
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const cors = require('cors')({ origin: true });

const ALGOLIA_APP_ID = 'WK0TIF84M2';

function getAlgoliaAdminKey(): string | null {
  return functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || null;
}

/**
 * Clear all records from an Algolia index (keeps settings)
 */
export const clearAlgoliaIndex = functions.runWith({
  timeoutSeconds: 540,
  memory: '1GB'
}).https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { indexName } = req.body;

      if (!indexName) {
        res.status(400).json({ success: false, error: 'indexName is required' });
        return;
      }

      const adminKey = getAlgoliaAdminKey();
      if (!adminKey) {
        res.status(500).json({ success: false, error: 'Algolia admin key not configured' });
        return;
      }

      const client = algoliasearch(ALGOLIA_APP_ID, adminKey);

      console.log(`🗑️ Clearing all records from ${indexName}...`);

      // Clear all objects (keeps index settings, synonyms, rules)
      await client.clearObjects({ indexName });

      console.log(`✅ Cleared ${indexName}`);

      res.json({
        success: true,
        message: `Cleared all records from ${indexName}. Settings preserved.`,
        indexName,
      });

    } catch (error: any) {
      console.error('Clear index error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * Sync master database from Firestore to Algolia
 */
export const syncMasterDatabaseToAlgolia = functions.runWith({
  timeoutSeconds: 540,
  memory: '2GB'
}).https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const {
        targetIndex = 'uk_foods_cleaned',
        batchSize = 1000,
        clearFirst = false
      } = req.body;

      const adminKey = getAlgoliaAdminKey();
      if (!adminKey) {
        res.status(500).json({ success: false, error: 'Algolia admin key not configured' });
        return;
      }

      const client = algoliasearch(ALGOLIA_APP_ID, adminKey);
      const db = admin.firestore();

      console.log(`📊 Syncing master database to ${targetIndex}...`);

      // Clear index first if requested
      if (clearFirst) {
        console.log(`🗑️ Clearing ${targetIndex} first...`);
        await client.clearObjects({ indexName: targetIndex });
      }

      // Get all products from master database
      const snapshot = await db.collection('masterDatabase').get();
      console.log(`📦 Found ${snapshot.size} products in master database`);

      const products: any[] = [];
      snapshot.forEach(doc => {
        const data = doc.data();
        products.push({
          objectID: doc.id,
          ...data,
        });
      });

      // Batch sync to Algolia
      let syncedCount = 0;
      const batches = Math.ceil(products.length / batchSize);

      for (let i = 0; i < batches; i++) {
        const start = i * batchSize;
        const end = Math.min(start + batchSize, products.length);
        const batch = products.slice(start, end);

        console.log(`📤 Syncing batch ${i + 1}/${batches} (${batch.length} products)...`);

        await client.saveObjects({
          indexName: targetIndex,
          objects: batch,
        });

        syncedCount += batch.length;
        console.log(`  ✅ Synced ${syncedCount}/${products.length} products`);
      }

      console.log(`✅ Master database synced to ${targetIndex}: ${syncedCount} products`);

      res.json({
        success: true,
        targetIndex,
        totalProducts: products.length,
        synced: syncedCount,
        batches,
      });

    } catch (error: any) {
      console.error('Sync master database error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});

/**
 * Get master database stats
 */
export const getMasterDatabaseStats = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const db = admin.firestore();
      const snapshot = await db.collection('masterDatabase').get();

      const stats = {
        totalProducts: snapshot.size,
        withBarcodes: 0,
        withImages: 0,
        withIngredients: 0,
        sourceBreakdown: {} as Record<string, number>,
      };

      snapshot.forEach(doc => {
        const data = doc.data();

        if (data.barcode) stats.withBarcodes++;
        if (data.imageUrl) stats.withImages++;
        if (data.ingredients) stats.withIngredients++;

        const source = data.sourceIndex || 'unknown';
        stats.sourceBreakdown[source] = (stats.sourceBreakdown[source] || 0) + 1;
      });

      res.json({
        success: true,
        ...stats,
      });

    } catch (error: any) {
      console.error('Get master database stats error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});
