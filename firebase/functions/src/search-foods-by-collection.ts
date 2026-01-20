import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const searchFoodsByCollection = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const query = (req.query.q as string) || '';
    const collection = (req.query.collection as string) || 'verifiedFoods';
    
    if (!query || query.trim().length < 2) {
      res.status(400).json({ error: 'Query must be at least 2 characters' });
      return;
    }

    console.log(`Searching for: "${query}" in collection: ${collection}`);

    // Map collection names - for now, everything searches verifiedFoods
    let actualCollection = 'verifiedFoods';
    switch(collection) {
      case 'unverifiedFoods':
        actualCollection = 'verifiedFoods'; // Currently all foods are here
        break;
      case 'aiVerifiedFoods':
        actualCollection = 'aiVerifiedFoods';
        break;
      case 'humanVerifiedFoods':
        actualCollection = 'humanVerifiedFoods';
        break;
      default:
        actualCollection = 'verifiedFoods';
    }

    // Search with case-insensitive approach
    let snapshot = await admin.firestore()
      .collection(actualCollection)
      .where('foodName', '>=', query)
      .where('foodName', '<=', query + '\uf8ff')
      .limit(20)
      .get();
    
    // If no results, try with capitalized first letter
    if (snapshot.empty) {
      const capitalizedQuery = query.charAt(0).toUpperCase() + query.slice(1).toLowerCase();
      snapshot = await admin.firestore()
        .collection(actualCollection)
        .where('foodName', '>=', capitalizedQuery)
        .where('foodName', '<=', capitalizedQuery + '\uf8ff')
        .limit(20)
        .get();
    }
    
    // If still no results, try all uppercase
    if (snapshot.empty) {
      const upperQuery = query.toUpperCase();
      snapshot = await admin.firestore()
        .collection(actualCollection)
        .where('foodName', '>=', upperQuery)
        .where('foodName', '<=', upperQuery + '\uf8ff')
        .limit(20)
        .get();
    }

    const results = snapshot.docs.map(doc => {
      const data = doc.data();
      const nutrition = data.nutritionData || {};
      
      // Extract serving size from multiple possible field names
      const servingDescription = data.servingDescription ||
                                 data.serving_description ||
                                 data.servingSize ||
                                 data.serving_size ||
                                 '100g serving';

      // Format data exactly as dashboard expects
      return {
        id: doc.id,
        name: data.foodName || data.title || data.name || '',
        brand: data.brandName || data.brand || null,
        barcode: data.barcode || data.gtin || '',
        calories: nutrition.calories || nutrition.energyKcal || nutrition.energy || 0,
        protein: nutrition.protein || 0,
        carbs: nutrition.carbs || nutrition.carbohydrates || nutrition.carbohydrate || 0,
        fat: nutrition.fat || 0,
        fiber: nutrition.fiber || nutrition.fibre || 0,
        sugar: nutrition.sugar || nutrition.sugars || 0,
        sodium: nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0),
        servingDescription: servingDescription,
        servingSizeG: data.servingSizeG || data.serving_size_g || data.servingWeightG || 100,
        ingredients: data.extractedIngredients || data.ingredients || null
      };
    });

    console.log(`Found ${results.length} foods in ${actualCollection}`);

    res.json({
      foods: results,
      collection: collection,
      actualCollection: actualCollection
    });

  } catch (error) {
    console.error('Error searching foods by collection:', error);
    res.status(500).json({ error: 'Failed to search foods' });
  }
});