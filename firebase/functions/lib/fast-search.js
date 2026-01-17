"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.fastSearchFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// In-memory cache for search results (will reset on function cold start)
const searchCache = new Map();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
// Precomputed frequent search results (warm cache)
let commonFoodsCache = [];
let lastCacheUpdate = 0;
exports.fastSearchFoods = functions.https.onRequest(async (req, res) => {
    const startTime = Date.now();
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
        const normalizedQuery = query.toLowerCase().trim();
        const cacheKey = normalizedQuery;
        // Check cache first
        const cached = searchCache.get(cacheKey);
        if (cached && (Date.now() - cached.timestamp) < CACHE_DURATION) {
            console.log(`Cache hit for "${query}" - ${Date.now() - startTime}ms`);
            res.json({
                foods: cached.results,
                cached: true,
                searchTime: Date.now() - startTime
            });
            return;
        }
        // For very common searches, use precomputed cache
        if (normalizedQuery.length <= 3 && ['a', 'e', 'i', 'o', 'u', 'the', 'and'].includes(normalizedQuery)) {
            await updateCommonFoodsCache();
            const filteredResults = commonFoodsCache
                .filter(food => food.name.toLowerCase().includes(normalizedQuery))
                .slice(0, 20);
            console.log(`Common search "${query}" - ${Date.now() - startTime}ms`);
            res.json({
                foods: filteredResults,
                cached: true,
                searchTime: Date.now() - startTime
            });
            return;
        }
        // Optimized single query strategy
        let searchResults = [];
        // Strategy 1: Direct prefix match (fastest)
        const firstWord = normalizedQuery.split(' ')[0];
        const capitalizedWord = firstWord.charAt(0).toUpperCase() + firstWord.slice(1);
        try {
            const snapshot = await admin.firestore()
                .collection('verifiedFoods')
                .where('foodName', '>=', capitalizedWord)
                .where('foodName', '<=', capitalizedWord + '\uf8ff')
                .limit(50) // Reduced from 500
                .get();
            searchResults = snapshot.docs.map(doc => {
                const data = doc.data();
                return formatFoodResult(doc.id, data);
            });
        }
        catch (error) {
            console.error('Direct search failed:', error);
        }
        // Strategy 2: If few results, try lowercase
        if (searchResults.length < 10) {
            try {
                const snapshot = await admin.firestore()
                    .collection('verifiedFoods')
                    .where('foodName', '>=', firstWord)
                    .where('foodName', '<=', firstWord + '\uf8ff')
                    .limit(30)
                    .get();
                const additionalResults = snapshot.docs.map(doc => {
                    const data = doc.data();
                    return formatFoodResult(doc.id, data);
                });
                // Merge results, avoiding duplicates
                const existingIds = new Set(searchResults.map(r => r.id));
                additionalResults.forEach(result => {
                    if (!existingIds.has(result.id)) {
                        searchResults.push(result);
                    }
                });
            }
            catch (error) {
                console.error('Lowercase search failed:', error);
            }
        }
        // Fast client-side filtering and ranking
        const queryWords = normalizedQuery.split(/\s+/);
        let filteredResults = searchResults.filter(food => {
            const foodName = food.name.toLowerCase();
            const brandName = (food.brand || '').toLowerCase();
            // Quick contains check
            return queryWords.some((word) => foodName.includes(word) || brandName.includes(word));
        });
        // Simple ranking (much faster than complex scoring)
        filteredResults = filteredResults
            .map(food => ({
            ...food,
            _score: calculateFastScore(food, normalizedQuery, queryWords)
        }))
            .sort((a, b) => b._score - a._score)
            .slice(0, 20)
            .map(({ _score, ...food }) => food); // Remove score from final result
        // Cache the results
        searchCache.set(cacheKey, {
            results: filteredResults,
            timestamp: Date.now()
        });
        const searchTime = Date.now() - startTime;
        console.log(`Fast search "${query}" - ${searchTime}ms - ${filteredResults.length} results`);
        res.json({
            foods: filteredResults,
            searchTime: searchTime,
            cached: false
        });
    }
    catch (error) {
        console.error('Fast search error:', error);
        res.status(500).json({ error: 'Search failed' });
    }
});
// Simplified food result formatting
function formatFoodResult(id, data) {
    const nutrition = data.nutritionData || data.nutrition || {};
    return {
        id: id,
        name: data.foodName || '',
        brand: data.brandName || null,
        barcode: data.barcode || '',
        calories: extractNutritionValue(nutrition.calories || data.calories),
        protein: extractNutritionValue(nutrition.protein || data.protein),
        carbs: extractNutritionValue(nutrition.carbs || nutrition.carbohydrates || data.carbs),
        fat: extractNutritionValue(nutrition.fat || data.fat),
        fiber: extractNutritionValue(nutrition.fiber || nutrition.fibre || data.fiber),
        sugar: extractNutritionValue(nutrition.sugar || nutrition.sugars || data.sugar),
        sodium: extractNutritionValue(nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0)),
        servingDescription: data.servingSize || '100g serving',
        ingredients: data.extractedIngredients || data.ingredients || null,
        additives: data.additives || null,
        verifiedBy: data.verifiedBy || null,
        verificationMethod: data.verificationMethod || null,
        verifiedAt: data.verifiedAt || null
    };
}
// Fast nutrition value extraction
function extractNutritionValue(field) {
    if (typeof field === 'number')
        return field;
    if (field && typeof field === 'object') {
        if (field.per100g !== undefined)
            return field.per100g;
        if (field.kcal !== undefined)
            return field.kcal;
        if (field.value !== undefined)
            return field.value;
    }
    return 0;
}
// Simplified scoring for speed
function calculateFastScore(food, query, queryWords) {
    const name = food.name.toLowerCase();
    const brand = (food.brand || '').toLowerCase();
    let score = 0;
    // Exact name match
    if (name === query)
        return 1000;
    // Name starts with query
    if (name.startsWith(query))
        score += 500;
    // All words found in name
    const foundWords = queryWords.filter((word) => name.includes(word));
    score += foundWords.length * 100;
    // Brand bonus
    if (brand.includes(query))
        score += 50;
    // Shorter names get slight bonus
    score += Math.max(0, 50 - name.length);
    return score;
}
// Update cache of common foods for frequent searches
async function updateCommonFoodsCache() {
    const now = Date.now();
    if (now - lastCacheUpdate < 10 * 60 * 1000)
        return; // Update every 10 minutes
    try {
        const snapshot = await admin.firestore()
            .collection('verifiedFoods')
            .where('verifiedBy', '==', 'company') // Prioritize verified foods
            .limit(200)
            .get();
        commonFoodsCache = snapshot.docs.map(doc => formatFoodResult(doc.id, doc.data()));
        lastCacheUpdate = now;
        console.log(`Updated common foods cache: ${commonFoodsCache.length} foods`);
    }
    catch (error) {
        console.error('Failed to update common foods cache:', error);
    }
}
//# sourceMappingURL=fast-search.js.map