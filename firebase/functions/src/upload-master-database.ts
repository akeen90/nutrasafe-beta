import * as functions from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const cors = require('cors')({ origin: true });

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const algoliaAdminKey = defineSecret('ALGOLIA_ADMIN_API_KEY');

// Upload master database products to BOTH Firestore AND Algolia
export const uploadMasterDatabase = functions.runWith({ secrets: [algoliaAdminKey] }).https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { products, algoliaIndexName = 'master_database' } = req.body;

      if (!products || !Array.isArray(products) || products.length === 0) {
        res.status(400).json({ success: false, error: 'Products array is required' });
        return;
      }

      console.log(`📤 Uploading ${products.length} products to BOTH Firestore AND Algolia...`);

      // 1. Upload to Firestore
      const db = admin.firestore();
      let batch = db.batch();
      let batchCount = 0;

      for (const product of products) {
        const docRef = db.collection('masterDatabase').doc(product.objectID);
        batch.set(docRef, {
          ...product,
          uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batchCount++;

        // Firestore batch limit is 500
        if (batchCount >= 500) {
          await batch.commit();
          batch = db.batch(); // Create new batch
          batchCount = 0;
        }
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      console.log(`✅ Uploaded ${products.length} products to Firestore masterDatabase collection`);

      // 2. Upload to Algolia
      const adminKey = algoliaAdminKey.value()?.trim();
      if (!adminKey) {
        console.warn('⚠️ Algolia API key not configured - skipping Algolia upload');
        res.json({
          success: true,
          uploaded: products.length,
          algoliaSkipped: true,
          warning: 'Algolia API key not configured'
        });
        return;
      }

      const client = algoliasearch(ALGOLIA_APP_ID, adminKey);

      // Algolia accepts batches of 1000 objects
      const ALGOLIA_BATCH_SIZE = 1000;
      for (let i = 0; i < products.length; i += ALGOLIA_BATCH_SIZE) {
        const algoliaBatch = products.slice(i, Math.min(i + ALGOLIA_BATCH_SIZE, products.length));

        await client.saveObjects({
          indexName: algoliaIndexName,
          objects: algoliaBatch.map(p => ({
            ...p,
            objectID: p.objectID,
            uploadedAt: new Date().toISOString(),
          })),
        });

        console.log(`  ✓ Algolia batch ${Math.floor(i / ALGOLIA_BATCH_SIZE) + 1}/${Math.ceil(products.length / ALGOLIA_BATCH_SIZE)} uploaded`);
      }

      console.log(`✅ Uploaded ${products.length} products to Algolia index: ${algoliaIndexName}`);

      res.json({
        success: true,
        uploaded: products.length,
        firestoreCollection: 'masterDatabase',
        algoliaIndex: algoliaIndexName,
      });

    } catch (error: any) {
      console.error('❌ Upload error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to upload to Firestore and Algolia',
        details: error.message,
      });
    }
  });
});
