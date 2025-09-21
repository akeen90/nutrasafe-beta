"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodsWeb = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Web dashboard compatible search function
exports.searchFoodsWeb = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        // Support various query formats for web dashboard
        const query = req.query.q ||
            req.query.query ||
            (req.body && req.body.query) ||
            (req.body && req.body.q) || '';
        if (!query || query.trim().length < 2) {
            res.status(400).json({ error: 'Query must be at least 2 characters' });
            return;
        }
        console.log(`Web dashboard searching for: "${query}"`);
        // Search verified foods collection
        const verifiedSnapshot = await admin.firestore()
            .collection('verifiedFoods')
            .where('foodName', '>=', query)
            .where('foodName', '<=', query + '\uf8ff')
            .limit(20)
            .get();
        const results = verifiedSnapshot.docs.map(doc => {
            const data = doc.data();
            const nutrition = data.nutritionData || {};
            // Return comprehensive data for web dashboard
            return {
                id: doc.id,
                foodName: data.foodName || '',
                name: data.foodName || '',
                brand: data.brandName || null,
                brandName: data.brandName || null,
                barcode: data.barcode || '',
                // Both ingredient field formats
                ingredients: data.extractedIngredients || data.ingredients || '',
                extractedIngredients: data.extractedIngredients || data.ingredients || '',
                // Comprehensive nutrition data
                calories: nutrition.calories || nutrition.energy || 0,
                protein: nutrition.protein || 0,
                carbs: nutrition.carbs || nutrition.carbohydrates || 0,
                fat: nutrition.fat || 0,
                fiber: nutrition.fiber || nutrition.fibre || 0,
                sugar: nutrition.sugar || nutrition.sugars || 0,
                sodium: nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0),
                nutritionData: nutrition,
                // Additional fields for web dashboard
                category: data.category || '',
                nutritionGrade: data.nutritionGrade || '',
                novaGroup: data.novaGroup || '',
                servingSize: data.servingSize || '',
                servingDescription: data.servingSize || '100g serving',
                // Images
                imageFrontUrl: data.imageFrontUrl || '',
                imageNutritionUrl: data.imageNutritionUrl || '',
                imageIngredientsUrl: data.imageIngredientsUrl || '',
                // Metadata
                verified: data.verified !== false,
                isVerified: true,
                source: data.source || 'verifiedFoods',
                verifiedBy: data.verifiedBy || '',
                completeness: data.completeness || 0
            };
        });
        console.log(`Web dashboard found ${results.length} verified foods`);
        // Return in multiple formats to support different web dashboard expectations
        res.json({
            success: true,
            foods: results,
            results: results,
            data: results,
            count: results.length
        });
    }
    catch (error) {
        console.error('Error in web dashboard search:', error);
        res.status(500).json({ error: 'Failed to search foods' });
    }
});
//# sourceMappingURL=search-foods-web.js.map