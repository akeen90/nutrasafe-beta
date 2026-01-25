import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY;

export const deleteGenericFoods = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '2GB',
  })
  .https.onRequest(async (req, res) => {
    try {
      const db = admin.firestore();
      const client = algoliasearch(ALGOLIA_APP_ID!, ALGOLIA_ADMIN_KEY!);
      const indexName = 'uk_foods_cleaned';

      // Step 1: Query Firestore for all generic items
      console.log('Querying Firestore for generic items...');
      const snapshot = await db.collection('uk_foods_cleaned')
        .where('brand', '==', 'Generic')
        .get();

      const itemsToDelete: string[] = [];
      const itemDetails: any[] = [];
      snapshot.forEach(doc => {
        itemsToDelete.push(doc.id);
        const data = doc.data();
        itemDetails.push({
          id: doc.id,
          name: data.name || data.foodName,
          brand: data.brand || data.brandName,
        });
      });

      // Also check for brandName field
      const snapshot2 = await db.collection('uk_foods_cleaned')
        .where('brandName', '==', 'Generic')
        .get();

      snapshot2.forEach(doc => {
        if (!itemsToDelete.includes(doc.id)) {
          itemsToDelete.push(doc.id);
          const data = doc.data();
          itemDetails.push({
            id: doc.id,
            name: data.name || data.foodName,
            brand: data.brand || data.brandName,
          });
        }
      });

      console.log(`Found ${itemsToDelete.length} generic items to delete`);
      console.log('Sample items:', itemDetails.slice(0, 10));

      if (itemsToDelete.length === 0) {
        res.json({
          success: true,
          message: 'No generic items found',
          deletedCount: 0,
        });
        return;
      }

      // Step 2: Delete from Firestore in batches (max 500 per batch)
      console.log('Deleting from Firestore...');
      const batchSize = 500;
      let deletedFromFirestore = 0;

      for (let i = 0; i < itemsToDelete.length; i += batchSize) {
        const batch = db.batch();
        const batchItems = itemsToDelete.slice(i, i + batchSize);

        batchItems.forEach(docId => {
          const docRef = db.collection('uk_foods_cleaned').doc(docId);
          batch.delete(docRef);
        });

        await batch.commit();
        deletedFromFirestore += batchItems.length;
        console.log(`Deleted ${deletedFromFirestore}/${itemsToDelete.length} from Firestore`);
      }

      // Step 3: Delete from Algolia
      console.log('Deleting from Algolia...');
      await client.deleteObjects({
        indexName,
        objectIDs: itemsToDelete,
      });
      console.log(`Deleted ${itemsToDelete.length} items from Algolia`);

      res.json({
        success: true,
        message: `Successfully deleted ${itemsToDelete.length} generic items`,
        deletedCount: itemsToDelete.length,
        deletedIds: itemsToDelete,
      });

    } catch (error) {
      console.error('Error deleting generic foods:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
