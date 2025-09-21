"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAllFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.getAllFoods = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const limit = parseInt(req.query.limit) || 1000;
        const collection = req.query.collection || 'all';
        console.log(`Getting all foods from collection: ${collection}, limit: ${limit}`);
        const allFoods = [];
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
                    var _a, _b, _c, _d, _e, _f, _g;
                    const data = doc.data();
                    allFoods.push({
                        id: doc.id,
                        collection: collectionName,
                        name: data.foodName || data.name || 'Unknown',
                        brand: data.brandName || data.brand || null,
                        calories: data.calories || ((_a = data.nutritionPer100g) === null || _a === void 0 ? void 0 : _a.calories) || null,
                        protein: data.protein || ((_b = data.nutritionPer100g) === null || _b === void 0 ? void 0 : _b.protein) || null,
                        carbs: data.carbs || data.carbohydrates || ((_c = data.nutritionPer100g) === null || _c === void 0 ? void 0 : _c.carbs) || null,
                        fat: data.fat || ((_d = data.nutritionPer100g) === null || _d === void 0 ? void 0 : _d.fat) || null,
                        sugar: data.sugar || ((_e = data.nutritionPer100g) === null || _e === void 0 ? void 0 : _e.sugar) || null,
                        fiber: data.fiber || ((_f = data.nutritionPer100g) === null || _f === void 0 ? void 0 : _f.fiber) || null,
                        sodium: data.sodium || ((_g = data.nutritionPer100g) === null || _g === void 0 ? void 0 : _g.sodium) || null,
                        ingredients: data.ingredients || data.extractedIngredients || null,
                        barcode: data.barcode || null,
                        source: data.source || data.verifiedBy || 'manual',
                        verifiedAt: data.verifiedAt || data.createdAt || null,
                        servingDescription: data.servingDescription || null
                    });
                });
            }
            catch (error) {
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
    }
    catch (error) {
        console.error('Error getting all foods:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
//# sourceMappingURL=get-all-foods.js.map