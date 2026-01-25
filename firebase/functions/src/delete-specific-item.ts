import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY;

export const deleteSpecificItem = functions
  .runWith({ timeoutSeconds: 60 })
  .https.onRequest(async (req, res) => {
    try {
      const { itemId } = req.body;

      if (!itemId) {
        res.status(400).json({ success: false, error: 'itemId required' });
        return;
      }

      const db = admin.firestore();
      const client = algoliasearch(ALGOLIA_APP_ID!, ALGOLIA_ADMIN_KEY!);

      // Delete from Firestore
      await db.collection('uk_foods_cleaned').doc(itemId).delete();
      console.log(`Deleted ${itemId} from Firestore`);

      // Delete from Algolia
      await client.deleteObjects({
        indexName: 'uk_foods_cleaned',
        objectIDs: [itemId],
      });
      console.log(`Deleted ${itemId} from Algolia`);

      res.json({
        success: true,
        message: `Successfully deleted item ${itemId}`,
        deletedId: itemId,
      });
    } catch (error) {
      console.error('Error deleting item:', error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  });
