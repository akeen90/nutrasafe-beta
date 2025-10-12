"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodsWithMicronutrients = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Enhanced search that includes micronutrient data from UK database
exports.searchFoodsWithMicronutrients = functions.https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        const query = req.query.q || (req.body && req.body.query) || '';
        if (!query || query.trim().length < 2) {
            res.status(400).json({ error: 'Query must be at least 2 characters' });
            return;
        }
        console.log(`Enhanced micronutrient search for: "${query}"`);
        // First search Firebase for verified foods (highest priority)
        const verifiedResults = await searchVerifiedFoods(query);
        // Then search UK database for additional micronutrient data
        const ukResults = await searchUKDatabase(query);
        // Merge and enhance results with micronutrient data
        const enhancedResults = await enhanceWithMicronutrients(verifiedResults, ukResults);
        console.log(`Found ${enhancedResults.length} enhanced foods with micronutrient data`);
        res.json({
            foods: enhancedResults.slice(0, 20), // Limit to 20 results
            micronutrientCoverage: {
                withMicronutrients: enhancedResults.filter(f => f.micronutrients).length,
                total: enhancedResults.length
            }
        });
    }
    catch (error) {
        console.error('Error in enhanced micronutrient search:', error);
        res.status(500).json({ error: 'Failed to search foods with micronutrients' });
    }
});
// Search verified foods from Firebase
async function searchVerifiedFoods(query) {
    try {
        const queryWords = query.toLowerCase().split(/\s+/).filter(word => word.length > 0);
        const firstWord = queryWords[0];
        const searchVariation = firstWord.charAt(0).toUpperCase() + firstWord.slice(1);
        const snapshot = await admin.firestore()
            .collection('verifiedFoods')
            .where('foodName', '>=', searchVariation)
            .where('foodName', '<=', searchVariation + '\uf8ff')
            .limit(50)
            .get();
        return snapshot.docs.map(doc => {
            const data = doc.data();
            const nutrition = data.nutritionData || data.nutrition || {};
            return {
                id: doc.id,
                name: data.foodName || '',
                brand: data.brandName || null,
                barcode: data.barcode || '',
                calories: nutrition.calories || nutrition.energy || 0,
                protein: nutrition.protein || 0,
                carbs: nutrition.carbs || nutrition.carbohydrates || 0,
                fat: nutrition.fat || 0,
                fiber: nutrition.fiber || nutrition.fibre || 0,
                sugar: nutrition.sugar || nutrition.sugars || 0,
                sodium: nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0),
                servingDescription: data.servingSize || '100g serving',
                ingredients: data.extractedIngredients || data.ingredients || null,
                confidence: 1.0,
                isVerified: true,
                dataSource: 'firebase_verified'
            };
        });
    }
    catch (error) {
        console.error('Error searching verified foods:', error);
        return [];
    }
}
// Search UK database for foods with micronutrient data
async function searchUKDatabase(query) {
    try {
        // For development, use SQLite file directly
        const sqlite3 = require('sqlite3').verbose();
        const { open } = require('sqlite');
        const db = await open({
            filename: './lib/micronutrient_reference.db', // Comprehensive reference database
            driver: sqlite3.Database
        });
        // Search comprehensive reference database with micronutrient data
        const searchTerm = `%${query.toLowerCase()}%`;
        const sql = `
      SELECT 
        id, name, category, source,
        vitamin_a, vitamin_d, vitamin_e, vitamin_k, vitamin_c,
        thiamine, riboflavin, niacin, pantothenic_acid, vitamin_b6, 
        biotin, folate, vitamin_b12,
        calcium, iron, magnesium, phosphorus, potassium, zinc, 
        copper, manganese, selenium, chromium, molybdenum, iodine
      FROM reference_foods 
      WHERE LOWER(name) LIKE ? 
         OR LOWER(search_terms) LIKE ?
      ORDER BY 
        CASE 
          WHEN LOWER(name) = LOWER(?) THEN 1
          WHEN LOWER(name) LIKE ? THEN 2
          WHEN source = 'cofid' THEN 3
          ELSE 4
        END
      LIMIT 50
    `;
        const rows = await db.all(sql, [
            searchTerm, searchTerm, // LIKE searches for name and search terms
            query, `${query.toLowerCase()}%` // Exact and prefix matches for ranking
        ]);
        await db.close();
        return rows.map((row) => ({
            id: row.id,
            name: row.name || '',
            brand: null, // Reference database doesn't have brands
            barcode: '',
            calories: 0, // Focus on micronutrients, not macros
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            servingDescription: '100g serving',
            ingredients: null,
            confidence: row.source === 'cofid' ? 0.9 : 0.8, // UK CoFID = high, USDA = medium-high
            isVerified: false,
            dataSource: 'reference_database',
            // Include comprehensive micronutrient data
            existingMicronutrients: {
                vitaminA: row.vitamin_a,
                vitaminD: row.vitamin_d,
                vitaminE: row.vitamin_e,
                vitaminK: row.vitamin_k,
                vitaminC: row.vitamin_c,
                thiamine: row.thiamine,
                riboflavin: row.riboflavin,
                niacin: row.niacin,
                pantothenicAcid: row.pantothenic_acid,
                vitaminB6: row.vitamin_b6,
                biotin: row.biotin,
                folate: row.folate,
                vitaminB12: row.vitamin_b12,
                calcium: row.calcium,
                iron: row.iron,
                magnesium: row.magnesium,
                phosphorus: row.phosphorus,
                potassium: row.potassium,
                zinc: row.zinc,
                copper: row.copper,
                manganese: row.manganese,
                selenium: row.selenium,
                chromium: row.chromium,
                molybdenum: row.molybdenum,
                iodine: row.iodine
            }
        }));
    }
    catch (error) {
        console.error('Error searching UK database:', error);
        return [];
    }
}
// Enhance results with comprehensive micronutrient data
async function enhanceWithMicronutrients(verifiedResults, ukResults) {
    const allResults = [...verifiedResults, ...ukResults];
    // Remove duplicates (prefer verified over UK database)
    const deduped = new Map();
    for (const result of allResults) {
        const key = result.barcode || `${result.name}_${result.brand}`.toLowerCase();
        if (!deduped.has(key) || result.dataSource === 'firebase_verified') {
            deduped.set(key, result);
        }
    }
    const uniqueResults = Array.from(deduped.values());
    // Enhance each result with micronutrient data
    const enhanced = await Promise.all(uniqueResults.map(async (food) => {
        const micronutrients = await getMicronutrientsForFood(food);
        return Object.assign(Object.assign({}, food), { micronutrients: micronutrients ? Object.assign(Object.assign({}, micronutrients), { dataSource: micronutrients.dataSource, confidenceScore: micronutrients.confidenceScore }) : null });
    }));
    // Sort by relevance and data quality
    return enhanced.sort((a, b) => {
        // Prioritize foods with micronutrient data
        if (a.micronutrients && !b.micronutrients)
            return -1;
        if (!a.micronutrients && b.micronutrients)
            return 1;
        // Then by verification status
        if (a.isVerified && !b.isVerified)
            return -1;
        if (!a.isVerified && b.isVerified)
            return 1;
        // Then by confidence
        return b.confidence - a.confidence;
    });
}
// Get micronutrients for a specific food using the pipeline approach
async function getMicronutrientsForFood(food) {
    try {
        // 1. Check if we already have comprehensive micronutrient data from reference database
        if (food.existingMicronutrients) {
            const existing = food.existingMicronutrients;
            const hasSignificantData = existing.vitaminC || existing.calcium || existing.iron ||
                existing.vitaminA || existing.vitaminD || existing.folate;
            if (hasSignificantData) {
                return {
                    // Fat-soluble vitamins (maintain original units)
                    vitaminA: existing.vitaminA, // µg RAE
                    vitaminD: existing.vitaminD, // µg
                    vitaminE: existing.vitaminE, // mg α-TE
                    vitaminK: existing.vitaminK, // µg
                    // Water-soluble vitamins
                    vitaminC: existing.vitaminC, // mg
                    thiamine: existing.thiamine, // mg
                    riboflavin: existing.riboflavin, // mg
                    niacin: existing.niacin, // mg
                    pantothenicAcid: existing.pantothenicAcid, // mg
                    vitaminB6: existing.vitaminB6, // mg
                    biotin: existing.biotin, // µg
                    folate: existing.folate, // µg DFE
                    vitaminB12: existing.vitaminB12, // µg
                    // Minerals
                    calcium: existing.calcium, // mg
                    iron: existing.iron, // mg
                    magnesium: existing.magnesium, // mg
                    phosphorus: existing.phosphorus, // mg
                    potassium: existing.potassium, // mg
                    zinc: existing.zinc, // mg
                    copper: existing.copper, // mg
                    manganese: existing.manganese, // mg
                    selenium: existing.selenium, // µg
                    chromium: existing.chromium, // µg
                    molybdenum: existing.molybdenum, // µg
                    iodine: existing.iodine, // µg
                    dataSource: food.dataSource === 'reference_database' ? 'reference_database' : 'uk_database',
                    confidenceScore: 'high'
                };
            }
        }
        // 2. Try recipe decomposition if ingredients available
        if (food.ingredients &&
            ((Array.isArray(food.ingredients) && food.ingredients.length > 0) ||
                (typeof food.ingredients === 'string' && food.ingredients.trim().length > 0))) {
            return await performSimpleRecipeEstimation(food);
        }
        // 3. Category-based estimation
        return await getCategoryBasedMicronutrients(food);
    }
    catch (error) {
        console.error('Error getting micronutrients for food:', error);
        return null;
    }
}
// Simple recipe estimation based on ingredient keywords
async function performSimpleRecipeEstimation(food) {
    // Handle both string and array ingredients
    let ingredients;
    if (typeof food.ingredients === 'string') {
        // Split string ingredients by comma and clean up
        ingredients = food.ingredients.split(',').map((ingredient) => ingredient.trim().toLowerCase());
    }
    else if (Array.isArray(food.ingredients)) {
        ingredients = food.ingredients;
    }
    else {
        return null;
    }
    // Map ingredients to the nutrients they're commonly sources of
    const ingredientNutrientSources = {
        'tomato': ['vitaminC', 'vitaminK'],
        'tomatoes': ['vitaminC', 'vitaminK'],
        'orange': ['vitaminC', 'folate'],
        'lemon': ['vitaminC'],
        'spinach': ['vitaminC', 'vitaminK', 'folate', 'calcium', 'iron'],
        'broccoli': ['vitaminC', 'vitaminK', 'folate'],
        'milk': ['calcium', 'vitaminD', 'vitaminB12'],
        'cream': ['calcium', 'vitaminA'],
        'butter': ['vitaminA', 'vitaminD'],
        'cheese': ['calcium', 'vitaminA', 'vitaminB12'],
        'yogurt': ['calcium', 'vitaminB12'],
        'bread': ['iron', 'thiamine', 'niacin', 'folate'],
        'wheat': ['iron', 'thiamine', 'niacin'],
        'beef': ['iron', 'vitaminB12', 'zinc'],
        'chicken': ['iron', 'vitaminB6', 'niacin'],
        'egg': ['vitaminB12', 'vitaminD', 'choline'],
        'red pepper': ['vitaminC', 'vitaminA'],
        'red peppers': ['vitaminC', 'vitaminA'],
        'yellow pepper': ['vitaminC', 'vitaminA'],
        'yellow peppers': ['vitaminC', 'vitaminA'],
        'peppers': ['vitaminC', 'vitaminA'],
        'onion': ['vitaminC'],
        'onions': ['vitaminC'],
        'rice': ['thiamine', 'niacin'],
        'carrots': ['vitaminA'],
        'carrot': ['vitaminA'],
        'salmon': ['vitaminD', 'omega3'],
        'tuna': ['vitaminD', 'omega3'],
        'nuts': ['vitaminE', 'magnesium'],
        'almonds': ['vitaminE', 'magnesium'],
        'seeds': ['vitaminE', 'magnesium'],
        'sunflower': ['vitaminE']
    };
    // Collect unique nutrients from all recognized ingredients
    const foundNutrients = new Set();
    let recognizedIngredientCount = 0;
    for (const ingredient of ingredients) {
        const ingredientLower = ingredient.toLowerCase();
        for (const [key, nutrients] of Object.entries(ingredientNutrientSources)) {
            if (ingredientLower.includes(key)) {
                nutrients.forEach(nutrient => foundNutrients.add(nutrient));
                recognizedIngredientCount++;
                break; // Only count each ingredient once
            }
        }
    }
    if (recognizedIngredientCount > 0) {
        // Return which nutrients this food is a source of (without quantities)
        const result = {
            dataSource: 'ingredient_analysis',
            confidenceScore: 'medium',
            isSourceOf: Array.from(foundNutrients)
        };
        // Only include the nutrients we found sources for
        foundNutrients.forEach(nutrient => {
            result[nutrient] = true; // Boolean indicator: "is a source of"
        });
        return result;
    }
    return null;
}
// Category-based micronutrient estimation
async function getCategoryBasedMicronutrients(food) {
    const name = food.name.toLowerCase();
    const brand = (food.brand || '').toLowerCase();
    const combined = `${name} ${brand}`;
    // Basic category detection and typical micronutrient ranges
    if (combined.includes('milk') || combined.includes('dairy')) {
        return {
            calcium: 113,
            iron: 0.03,
            dataSource: 'category_estimate',
            confidenceScore: 'low'
        };
    }
    if (combined.includes('orange') || combined.includes('citrus')) {
        return {
            vitaminC: 53,
            calcium: 40,
            iron: 0.1,
            dataSource: 'category_estimate',
            confidenceScore: 'low'
        };
    }
    if (combined.includes('bread') || combined.includes('cereal')) {
        return {
            iron: 1.5,
            calcium: 20,
            dataSource: 'category_estimate',
            confidenceScore: 'low'
        };
    }
    if (combined.includes('meat') || combined.includes('beef') || combined.includes('chicken')) {
        return {
            iron: 2.0,
            calcium: 8,
            dataSource: 'category_estimate',
            confidenceScore: 'low'
        };
    }
    // Default minimal estimation for any food
    return {
        dataSource: 'category_estimate',
        confidenceScore: 'low'
    };
}
//# sourceMappingURL=enhanced-micronutrient-search.js.map