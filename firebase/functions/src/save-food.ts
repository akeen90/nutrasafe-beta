import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function to save a food item to Firestore
 * This will trigger the syncFoodToAlgolia function automatically
 * Used by Database Manager to save/update foods
 */
export const saveFood = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ success: false, error: 'Method not allowed' });
    return;
  }

  try {
    const foodData = req.body;

    if (!foodData || !foodData.objectID) {
      res.status(400).json({
        success: false,
        error: 'Food data with objectID is required'
      });
      return;
    }

    const db = admin.firestore();
    const foodId = foodData.objectID;

    // Prepare the food document for Firestore
    // Remove objectID from the data (it's used as the document ID)
    const { objectID, ...foodDataWithoutId } = foodData;

    // Add metadata
    const firestoreData = {
      ...foodDataWithoutId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: 'database_manager',
    };

    // If this is a new food, add createdAt
    const existingDoc = await db.collection('foods').doc(foodId).get();
    if (!existingDoc.exists) {
      firestoreData.createdAt = admin.firestore.FieldValue.serverTimestamp();
      firestoreData.source = foodData.source || 'database_manager';
    }

    // Save to Firestore - this will trigger syncFoodToAlgolia automatically
    await db.collection('foods').doc(foodId).set(firestoreData, { merge: true });

    console.log(`✅ Saved food ${foodId} to Firestore (will sync to Algolia via trigger)`);

    res.status(200).json({
      success: true,
      message: 'Food saved successfully',
      foodId: foodId
    });

  } catch (error) {
    console.error('❌ Error saving food:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save food'
    });
  }
});

/**
 * Cloud Function to delete a food item from Firestore
 * This will trigger the syncFoodToAlgolia function to remove from Algolia
 */
export const deleteFood = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { foodId } = req.body;

    if (!foodId) {
      res.status(400).json({ success: false, error: 'Food ID is required' });
      return;
    }

    const db = admin.firestore();
    await db.collection('foods').doc(foodId).delete();

    console.log(`✅ Deleted food ${foodId} from Firestore (will remove from Algolia via trigger)`);

    res.status(200).json({
      success: true,
      message: 'Food deleted successfully'
    });

  } catch (error) {
    console.error('❌ Error deleting food:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete food'
    });
  }
});

/**
 * Cloud Function to batch save multiple foods to Firestore
 * Used by Database Manager for bulk operations
 */
export const batchSaveFoods = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const { foods } = req.body;

    if (!foods || !Array.isArray(foods) || foods.length === 0) {
      res.status(400).json({
        success: false,
        error: 'Array of foods is required'
      });
      return;
    }

    const db = admin.firestore();
    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    for (const food of foods) {
      if (!food.objectID) {
        continue; // Skip foods without objectID
      }

      const foodRef = db.collection('foods').doc(food.objectID);
      const { objectID, ...foodDataWithoutId } = food;

      batch.set(foodRef, {
        ...foodDataWithoutId,
        updatedAt: timestamp,
        updatedBy: 'database_manager',
      }, { merge: true });
    }

    await batch.commit();

    console.log(`✅ Batch saved ${foods.length} foods to Firestore`);

    res.status(200).json({
      success: true,
      message: `Successfully saved ${foods.length} foods`,
      count: foods.length
    });

  } catch (error) {
    console.error('❌ Error batch saving foods:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to batch save foods'
    });
  }
});
