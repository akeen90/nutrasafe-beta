import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

export const getAllFoods = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const limit = parseInt(req.query.limit as string) || 1000;
    const collection = (req.query.collection as string) || 'all';
    
    console.log(`Getting all foods from collection: ${collection}, limit: ${limit}`);

    const allFoods: any[] = [];

    // Define collections to search
    const collections = collection === 'all' 
      ? ['verifiedFoods', 'foods', 'manualFoods', 'aiVerifiedFoods', 'humanVerifiedFoods']
      : [collection];

    for (const collectionName of collections) {
      try {
        const snapshot = await admin.firestore()
          .collection(collectionName)
          .limit(Math.ceil(limit / collections.length))
          .get();

        console.log(`Collection ${collectionName}: ${snapshot.docs.length} foods found`);

        snapshot.docs.forEach(doc => {
          const data = doc.data();
          allFoods.push({
            id: doc.id,
            collection: collectionName,
            name: data.foodName || data.name || 'Unknown',
            brand: data.brandName || data.brand || null,
            calories: data.calories || data.nutritionPer100g?.calories || null,
            protein: data.protein || data.nutritionPer100g?.protein || null,
            carbs: data.carbs || data.carbohydrates || data.nutritionPer100g?.carbs || null,
            fat: data.fat || data.nutritionPer100g?.fat || null,
            sugar: data.sugar || data.nutritionPer100g?.sugar || null,
            fiber: data.fiber || data.nutritionPer100g?.fiber || null,
            sodium: data.sodium || data.nutritionPer100g?.sodium || null,
            ingredients: data.ingredients || data.extractedIngredients || null,
            barcode: data.barcode || null,
            source: data.source || data.verifiedBy || 'manual',
            verifiedAt: data.verifiedAt || data.createdAt || null,
            servingDescription: data.servingDescription || null
          });
        });
      } catch (error) {
        console.error(`Error accessing collection ${collectionName}:`, error);
      }
    }

    // Sort by name
    allFoods.sort((a, b) => (a.name || '').localeCompare(b.name || ''));

    console.log(`Total foods returned: ${allFoods.length}`);

    res.json({
      foods: allFoods,
      total: allFoods.length,
      collections: collections
    });

  } catch (error) {
    console.error('Error getting all foods:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});