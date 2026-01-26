/**
 * Update Food Nutrition
 * Updates nutrition data for foods in Firebase and Algolia
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { algoliasearch } from 'algoliasearch';

const algoliaAppId = 'WK0TIF84M2';
const getAlgoliaAdminKey = () => functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || '';

const INDEX_TO_COLLECTION: { [key: string]: string } = {
  'verified_foods': 'verifiedFoods',
  'foods': 'foods',
  'manual_foods': 'manualFoods',
  'user_added': 'userAddedFoods',
  'ai_enhanced': 'aiEnhancedFoods',
  'ai_manually_added': 'aiManuallyAddedFoods',
  'tesco_products': 'tescoProducts',
  'uk_foods_cleaned': 'ukFoodsCleaned',
  'fast_foods_database': 'fastFoods',
  'generic_database': 'genericFoods',
  'consumer_foods': 'consumerFoods',
};

export const updateFoodNutrition = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { index, objectID, nutritionData } = req.body;

    if (!index || !objectID || !nutritionData) {
      res.status(400).json({ error: 'Missing required fields: index, objectID, nutritionData' });
      return;
    }

    console.log(`Updating nutrition for ${objectID} in index ${index}`);

    // Get collection name from index
    const collection = INDEX_TO_COLLECTION[index];
    if (!collection) {
      res.status(400).json({ error: `Unknown index: ${index}` });
      return;
    }

    // Prepare nutrition update
    const updateData: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // For fast food database, include all fields (even null) to overwrite existing data
    const isFastFood = index === 'fast_foods_database';

    if (isFastFood) {
      // Include all fields, allowing null to clear old values
      updateData.calories = nutritionData.calories !== undefined ? nutritionData.calories : null;
      updateData.protein = nutritionData.protein !== undefined ? nutritionData.protein : null;
      updateData.carbs = nutritionData.carbs !== undefined ? nutritionData.carbs : null;
      updateData.fat = nutritionData.fat !== undefined ? nutritionData.fat : null;
      updateData.saturatedFat = nutritionData.saturatedFat !== undefined ? nutritionData.saturatedFat : null;
      updateData.fiber = nutritionData.fiber !== undefined ? nutritionData.fiber : null;
      updateData.sugar = nutritionData.sugar !== undefined ? nutritionData.sugar : null;
      updateData.sodium = nutritionData.sodium !== undefined ? nutritionData.sodium : null;
      updateData.salt = nutritionData.salt !== undefined ? nutritionData.salt : null;
      updateData.servingSizeG = nutritionData.servingSizeG !== undefined ? nutritionData.servingSizeG : null;
      updateData.ingredients = nutritionData.ingredients !== undefined ? nutritionData.ingredients : null;

      // Mark as per unit for fast food - set isPerUnit flag and use food name as serving description
      updateData.isPerUnit = nutritionData.isPerUnit !== undefined ? nutritionData.isPerUnit : true;
      updateData.servingDescription = nutritionData.servingDescription || null;

      console.log(`🍔 Fast food mode: Setting isPerUnit=true, servingSizeG=${updateData.servingSizeG}, description="${updateData.servingDescription}"`);
    } else {
      // For other databases, only include fields that are defined (partial update)
      if (nutritionData.calories !== undefined) updateData.calories = nutritionData.calories;
      if (nutritionData.protein !== undefined) updateData.protein = nutritionData.protein;
      if (nutritionData.carbs !== undefined) updateData.carbs = nutritionData.carbs;
      if (nutritionData.fat !== undefined) updateData.fat = nutritionData.fat;
      if (nutritionData.saturatedFat !== undefined) updateData.saturatedFat = nutritionData.saturatedFat;
      if (nutritionData.fiber !== undefined) updateData.fiber = nutritionData.fiber;
      if (nutritionData.sugar !== undefined) updateData.sugar = nutritionData.sugar;
      if (nutritionData.sodium !== undefined) updateData.sodium = nutritionData.sodium;
      if (nutritionData.salt !== undefined) updateData.salt = nutritionData.salt;
      if (nutritionData.servingSizeG !== undefined) updateData.servingSizeG = nutritionData.servingSizeG;
      if (nutritionData.servingDescription !== undefined) updateData.servingDescription = nutritionData.servingDescription;
      if (nutritionData.isPerUnit !== undefined) updateData.isPerUnit = nutritionData.isPerUnit;
      if (nutritionData.ingredients !== undefined) updateData.ingredients = nutritionData.ingredients;
    }

    // Update Firebase (if document exists)
    const db = admin.firestore();
    const docRef = db.collection(collection).doc(objectID);

    // Check if document exists
    const doc = await docRef.get();
    let firebaseUpdated = false;
    if (doc.exists) {
      await docRef.update(updateData);
      console.log(`✓ Updated Firebase document ${objectID} in ${collection}`);
      firebaseUpdated = true;
    } else {
      console.log(`⚠ Document ${objectID} not found in Firebase ${collection} - skipping Firebase update, will update Algolia only`);
    }

    // Update Algolia (v5 API)
    const algoliaKey = getAlgoliaAdminKey();
    if (!algoliaKey) {
      throw new Error('Algolia admin key not configured');
    }

    const client = algoliasearch(algoliaAppId, algoliaKey);

    const algoliaUpdate: any = {
      ...updateData,
    };
    delete algoliaUpdate.updatedAt; // Remove Firestore timestamp

    await client.partialUpdateObject({
      indexName: index,
      objectID,
      attributesToUpdate: algoliaUpdate,
    });
    console.log(`✓ Updated Algolia index ${index} for ${objectID}`);

    res.status(200).json({
      success: true,
      message: firebaseUpdated
        ? `Updated nutrition for ${objectID} in Firebase and Algolia`
        : `Updated nutrition for ${objectID} in Algolia only (not in Firebase)`,
      updatedFields: Object.keys(updateData),
      firebaseUpdated,
    });
  } catch (error) {
    console.error('Error updating nutrition:', error);
    res.status(500).json({
      error: 'Failed to update nutrition',
      details: error instanceof Error ? error.message : String(error),
    });
  }
});
