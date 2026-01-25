/**
 * One-time sync to push imageQuality flags from Firestore to Algolia
 * Run this after the Vision AI filtering job completes
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const cors = require('cors')({ origin: true });

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const TESCO_PRODUCTS_INDEX = 'tesco_products';

// Get Algolia admin key
const getAlgoliaAdminKey = () => functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || "";

/**
 * Sync imageQuality fields from Firestore tescoProducts to Algolia tesco_products
 */
export const syncTescoImageQuality = functions.runWith({
  timeoutSeconds: 540,
  memory: '2GB'
}).https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { batchSize = 1000, dryRun = false } = req.body;

      const adminKey = getAlgoliaAdminKey();
      if (!adminKey) {
        throw new Error('Algolia admin key not configured');
      }

      const client = algoliasearch(ALGOLIA_APP_ID, adminKey.trim());
      const db = admin.firestore();

      // Get all products with imageQuality field set
      const snapshot = await db.collection('tescoProducts')
        .where('imageQuality', '!=', null)
        .get();

      console.log(`Found ${snapshot.size} products with imageQuality field`);

      const updates: any[] = [];
      let flaggedCount = 0;
      let cleanCount = 0;

      snapshot.forEach(doc => {
        const data = doc.data();

        // Prepare partial update for Algolia
        const update = {
          objectID: doc.id,
          imageQuality: data.imageQuality,
          imageFlags: data.imageFlags || undefined,
          flaggedAt: data.flaggedAt || undefined,
        };

        updates.push(update);

        if (data.imageQuality === 'flagged') {
          flaggedCount++;
        } else {
          cleanCount++;
        }
      });

      // Batch update to Algolia
      if (!dryRun && updates.length > 0) {
        console.log(`Updating ${updates.length} products in Algolia...`);

        // Split into batches
        const batches = [];
        for (let i = 0; i < updates.length; i += batchSize) {
          batches.push(updates.slice(i, i + batchSize));
        }

        for (let i = 0; i < batches.length; i++) {
          const batch = batches[i];
          console.log(`Processing batch ${i + 1}/${batches.length} (${batch.length} products)...`);

          await client.partialUpdateObjects({
            indexName: TESCO_PRODUCTS_INDEX,
            objects: batch,
            createIfNotExists: true,
          });
        }

        console.log(`Successfully updated ${updates.length} products in Algolia`);
      }

      res.json({
        success: true,
        totalProducts: snapshot.size,
        flagged: flaggedCount,
        clean: cleanCount,
        updated: dryRun ? 0 : updates.length,
        dryRun,
      });

    } catch (error: any) {
      console.error('Sync Tesco image quality error:', error);
      res.status(500).json({ success: false, error: error.message });
    }
  });
});
