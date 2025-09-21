"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getFoodDetails = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Fixed getFoodDetails function that properly maps ingredients field
exports.getFoodDetails = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const foodId = req.query.id || (req.body && req.body.foodId) || req.query.foodId;
        if (!foodId) {
            res.status(400).json({ error: 'Food ID is required' });
            return;
        }
        console.log(`Getting details for food ID: ${foodId}`);
        // Get food details from verified foods collection
        const foodDoc = await admin.firestore()
            .collection('verifiedFoods')
            .doc(foodId)
            .get();
        if (!foodDoc.exists) {
            res.status(404).json({ error: 'Food not found' });
            return;
        }
        const data = foodDoc.data();
        if (!data) {
            res.status(404).json({ error: 'Food data not found' });
            return;
        }
        // CRITICAL FIX: Map existing 'ingredients' field to 'extractedIngredients' for iOS app
        const foodDetails = {
            id: foodDoc.id,
            foodName: data.foodName || '',
            brandName: data.brandName || '',
            barcode: data.barcode || '',
            // This is the key fix! Map ingredients → extractedIngredients
            ingredients: data.extractedIngredients || data.ingredients || '',
            extractedIngredients: data.extractedIngredients || data.ingredients || '',
            // Complete nutrition data
            nutritionData: data.nutritionData || {},
            // Quality scores
            category: data.category || '',
            nutritionGrade: data.nutritionGrade || '',
            novaGroup: data.novaGroup || '',
            // Images for display
            imageFrontUrl: data.imageFrontUrl || '',
            imageNutritionUrl: data.imageNutritionUrl || '',
            imageIngredientsUrl: data.imageIngredientsUrl || '',
            // Product details
            servingSize: data.servingSize || '',
            servingQuantity: data.servingQuantity || '',
            packaging: data.packaging || '',
            stores: data.stores || '',
            countries: data.countries || '',
            // Metadata
            verified: data.verified || false,
            isVerified: true,
            source: data.source || 'verifiedFoods',
            verifiedBy: data.verifiedBy || '',
            verifiedAt: data.verifiedAt || null,
            completeness: data.completeness || 0
        };
        // Log ingredients info for debugging
        const hasIngredients = !!(foodDetails.ingredients && foodDetails.ingredients.length > 0);
        console.log(`Food "${foodDetails.foodName}" has ingredients: ${hasIngredients}`);
        if (hasIngredients) {
            console.log(`Ingredients preview: ${foodDetails.ingredients.substring(0, 100)}...`);
        }
        res.json({
            success: true,
            food: foodDetails
        });
    }
    catch (error) {
        console.error('Error getting food details:', error);
        res.status(500).json({ error: 'Failed to get food details' });
    }
});
//# sourceMappingURL=food-details.js.map