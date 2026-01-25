import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const cors = require('cors')({ origin: true });

// Upload master database products to Firestore
export const uploadMasterDatabase = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { products } = req.body;

      if (!products || !Array.isArray(products) || products.length === 0) {
        res.status(400).json({ success: false, error: 'Products array is required' });
        return;
      }

      console.log(`📤 Uploading ${products.length} products to Firestore...`);

      const db = admin.firestore();
      const batch = db.batch();
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
          batchCount = 0;
        }
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      console.log(`✅ Uploaded ${products.length} products to masterDatabase collection`);

      res.json({
        success: true,
        uploaded: products.length,
      });

    } catch (error: any) {
      console.error('❌ Upload error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to upload to Firestore',
        details: error.message,
      });
    }
  });
});
