/**
 * Database Sync Functions
 *
 * Provides version tracking and delta sync for the local SQLite database
 * Used by the iOS app to keep local food database up to date
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

// Initialize Algolia
const ALGOLIA_APP_ID = process.env.ALGOLIA_APP_ID || 'DJGM1VQOY4';
const ALGOLIA_ADMIN_KEY = process.env.ALGOLIA_ADMIN_KEY || '';

// Collection to track database versions
const DB_VERSION_COLLECTION = 'databaseVersions';
const FOOD_UPDATES_COLLECTION = 'foodUpdates';

/**
 * Get the current database version
 * Called by iOS app to check if sync is needed
 */
export const getCurrentDatabaseVersion = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const db = admin.firestore();
    const versionDoc = await db.collection(DB_VERSION_COLLECTION).doc('current').get();

    if (!versionDoc.exists) {
      // Initialize version if it doesn't exist
      const initialVersion = {
        version: '1.0.0',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        foodCount: 0,
        lastUpdated: new Date().toISOString(),
      };
      await db.collection(DB_VERSION_COLLECTION).doc('current').set(initialVersion);
      res.json({ version: '1.0.0' });
      return;
    }

    const data = versionDoc.data();
    res.json({
      version: data?.version || '1.0.0',
      timestamp: data?.lastUpdated || new Date().toISOString(),
      foodCount: data?.foodCount || 0,
    });
  } catch (error) {
    console.error('Error getting database version:', error);
    res.status(500).json({ error: 'Failed to get database version' });
  }
});

/**
 * Get delta updates since a specific version
 * Returns foods that have been added/updated/deleted since the given version
 */
export const getFoodDatabaseDelta = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { since } = req.body;

    if (!since) {
      res.status(400).json({ error: 'Missing "since" parameter (version string)' });
      return;
    }

    const db = admin.firestore();

    // Get updates since the given version
    const updatesSnapshot = await db
      .collection(FOOD_UPDATES_COLLECTION)
      .where('version', '>', since)
      .orderBy('version', 'asc')
      .limit(1000) // Limit to prevent huge responses
      .get();

    const updates: any[] = [];
    updatesSnapshot.forEach(doc => {
      const data = doc.data();
      updates.push({
        id: doc.id,
        action: data.action, // 'add', 'update', 'delete'
        food: data.food,
        version: data.version,
        timestamp: data.timestamp?.toDate?.()?.toISOString() || null,
      });
    });

    // Get current version
    const versionDoc = await db.collection(DB_VERSION_COLLECTION).doc('current').get();
    const currentVersion = versionDoc.data()?.version || '1.0.0';

    res.json({
      updates,
      currentVersion,
      hasMore: updates.length === 1000,
    });
  } catch (error) {
    console.error('Error getting delta updates:', error);
    res.status(500).json({ error: 'Failed to get delta updates' });
  }
});

/**
 * Record a food update (called when foods are added/updated/deleted)
 * This should be called from admin dashboard or other food management functions
 */
export const recordFoodUpdate = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { action, foodId, food } = req.body;

    if (!action || !foodId) {
      res.status(400).json({ error: 'Missing required parameters: action, foodId' });
      return;
    }

    const db = admin.firestore();

    // Get current version and increment
    const versionRef = db.collection(DB_VERSION_COLLECTION).doc('current');
    const versionDoc = await versionRef.get();

    let currentVersion = versionDoc.data()?.version || '1.0.0';
    const versionParts = currentVersion.split('.').map(Number);
    versionParts[2] = (versionParts[2] || 0) + 1; // Increment patch version
    const newVersion = versionParts.join('.');

    // Record the update
    await db.collection(FOOD_UPDATES_COLLECTION).add({
      action, // 'add', 'update', 'delete'
      foodId,
      food: food || null,
      version: newVersion,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update current version
    await versionRef.set({
      version: newVersion,
      lastUpdated: new Date().toISOString(),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    res.json({
      success: true,
      version: newVersion,
    });
  } catch (error) {
    console.error('Error recording food update:', error);
    res.status(500).json({ error: 'Failed to record food update' });
  }
});

/**
 * Initialize or reset the database version
 * Called manually to set up versioning or after a full database rebuild
 */
export const initializeDatabaseVersion = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { version, foodCount } = req.body;
    const db = admin.firestore();

    // Get food count from Algolia if not provided
    let actualFoodCount = foodCount;
    if (!actualFoodCount && ALGOLIA_ADMIN_KEY) {
      try {
        const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
        const indices = [
          'verified_foods',
          'consumer_foods',
          'uk_supermarket_foods',
          'tesco_products',
        ];

        actualFoodCount = 0;
        for (const indexName of indices) {
          try {
            const searchResult = await client.searchSingleIndex({
              indexName,
              searchParams: {
                query: '',
                hitsPerPage: 0,
              },
            });
            actualFoodCount += searchResult.nbHits || 0;
          } catch (e) {
            console.log(`Could not get count for ${indexName}`);
          }
        }
      } catch (e) {
        console.error('Error getting Algolia stats:', e);
      }
    }

    const versionData = {
      version: version || '1.0.0',
      foodCount: actualFoodCount || 0,
      lastUpdated: new Date().toISOString(),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      initializedAt: new Date().toISOString(),
    };

    await db.collection(DB_VERSION_COLLECTION).doc('current').set(versionData);

    // Clear old updates if resetting
    if (req.body.clearUpdates) {
      const updatesSnapshot = await db.collection(FOOD_UPDATES_COLLECTION).get();
      const batch = db.batch();
      updatesSnapshot.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    res.json({
      success: true,
      ...versionData,
    });
  } catch (error) {
    console.error('Error initializing database version:', error);
    res.status(500).json({ error: 'Failed to initialize database version' });
  }
});

/**
 * Get sync statistics
 * Returns info about pending updates, version history, etc.
 */
export const getSyncStats = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const db = admin.firestore();

    // Get current version
    const versionDoc = await db.collection(DB_VERSION_COLLECTION).doc('current').get();
    const versionData = versionDoc.data() || {};

    // Count pending updates
    const updatesSnapshot = await db.collection(FOOD_UPDATES_COLLECTION).get();
    const updateCount = updatesSnapshot.size;

    // Get recent updates summary
    const recentUpdates = await db
      .collection(FOOD_UPDATES_COLLECTION)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const recentUpdatesList: any[] = [];
    recentUpdates.forEach(doc => {
      const data = doc.data();
      recentUpdatesList.push({
        action: data.action,
        foodId: data.foodId,
        version: data.version,
        timestamp: data.timestamp?.toDate?.()?.toISOString() || null,
      });
    });

    res.json({
      currentVersion: versionData.version || '1.0.0',
      lastUpdated: versionData.lastUpdated || null,
      foodCount: versionData.foodCount || 0,
      pendingUpdates: updateCount,
      recentUpdates: recentUpdatesList,
    });
  } catch (error) {
    console.error('Error getting sync stats:', error);
    res.status(500).json({ error: 'Failed to get sync stats' });
  }
});

/**
 * Scheduled cleanup of old food updates
 * Runs daily to remove updates older than 30 days
 * This keeps the foodUpdates collection from growing indefinitely
 */
export const cleanupOldFoodUpdates = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    console.log(`🧹 Starting cleanup of food updates older than ${thirtyDaysAgo.toISOString()}`);

    let totalDeleted = 0;
    let batchCount = 0;
    const MAX_BATCHES = 20; // Safety limit to prevent runaway execution

    try {
      // Delete in batches of 500 (Firestore batch limit)
      while (batchCount < MAX_BATCHES) {
        const oldUpdates = await db
          .collection(FOOD_UPDATES_COLLECTION)
          .where('timestamp', '<', thirtyDaysAgo)
          .limit(500)
          .get();

        if (oldUpdates.empty) {
          break;
        }

        const batch = db.batch();
        oldUpdates.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();

        totalDeleted += oldUpdates.size;
        batchCount++;

        console.log(`  Deleted batch ${batchCount}: ${oldUpdates.size} updates`);

        // If we got less than 500, we're done
        if (oldUpdates.size < 500) {
          break;
        }
      }

      console.log(`✅ Cleanup complete: deleted ${totalDeleted} old food updates`);
      return null;
    } catch (error) {
      console.error('❌ Error during cleanup:', error);
      throw error;
    }
  });
