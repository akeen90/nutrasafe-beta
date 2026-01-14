"use strict";
/**
 * AI-Powered Food Recognition with Database Lookup
 *
 * Hybrid approach:
 * 1. Gemini 1.5 Pro identifies foods + estimates portion sizes
 * 2. Algolia searches for verified nutrition data
 * 3. Falls back to AI estimates only when no database match
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.recognizeFood = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = require("axios");
const algoliasearch_1 = require("algoliasearch");
// Secrets
const geminiApiKey = (0, params_1.defineSecret)('GEMINI_API_KEY');
const algoliaAdminKey = (0, params_1.defineSecret)('ALGOLIA_ADMIN_API_KEY');
// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
// Only include indices that exist - removed new_main/new_generic to avoid 404 errors
const SEARCH_INDICES = ['verified_foods', 'foods'];
/**
 * Cloud Function: Recognize food items using Gemini + Algolia hybrid approach
 */
exports.recognizeFood = (0, https_1.onRequest)({
    cors: true,
    timeoutSeconds: 90, // Increased for database lookups
    memory: '1GiB',
    secrets: [geminiApiKey, algoliaAdminKey],
}, async (req, res) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'POST');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const { image } = req.body;
    if (!image || typeof image !== 'string') {
        res.status(400).json({ error: 'Base64 encoded image is required' });
        return;
    }
    try {
        // Step 1: Identify foods with Gemini
        console.log('🔍 Step 1: Identifying foods with Gemini...');
        const identifiedFoods = await identifyFoodsWithGemini(image, geminiApiKey.value());
        console.log(`✅ Gemini identified ${identifiedFoods.length} foods`);
        if (identifiedFoods.length === 0) {
            res.set('Access-Control-Allow-Origin', '*');
            res.status(200).json({ foods: [] });
            return;
        }
        // Step 2: Look up each food in Algolia database
        console.log('📚 Step 2: Searching database for matches...');
        const algoliaClient = (0, algoliasearch_1.algoliasearch)(ALGOLIA_APP_ID, algoliaAdminKey.value());
        const finalFoods = [];
        for (const identified of identifiedFoods) {
            const dbMatch = await searchDatabaseForFood(algoliaClient, identified);
            if (dbMatch) {
                // Database match found - use verified nutrition scaled to portion
                // Note: Algolia stores per-100g values in fields like 'calories', 'protein', etc.
                const portionMultiplier = identified.portionGrams / 100;
                finalFoods.push({
                    name: dbMatch.name,
                    brand: dbMatch.brandName || identified.brand,
                    calories: Math.round((dbMatch.calories || 0) * portionMultiplier),
                    protein: Math.round((dbMatch.protein || 0) * portionMultiplier * 10) / 10,
                    carbs: Math.round((dbMatch.carbs || 0) * portionMultiplier * 10) / 10,
                    fat: Math.round((dbMatch.fat || 0) * portionMultiplier * 10) / 10,
                    fiber: Math.round((dbMatch.fiber || 0) * portionMultiplier * 10) / 10,
                    sugar: Math.round((dbMatch.sugar || 0) * portionMultiplier * 10) / 10,
                    sodium: Math.round((dbMatch.sodium || 0) * portionMultiplier * 10) / 10,
                    portionGrams: identified.portionGrams,
                    confidence: identified.confidence,
                    isFromDatabase: true,
                    databaseId: dbMatch.objectID,
                    ingredients: dbMatch.ingredients || null,
                });
                console.log(`  ✅ "${identified.name}" → DB match: "${dbMatch.name}" (${dbMatch.calories || 0} kcal/100g)`);
            }
            else {
                // No match - use AI estimates
                const portionMultiplier = identified.portionGrams / 100;
                finalFoods.push({
                    name: identified.name,
                    brand: identified.brand,
                    calories: Math.round(identified.estimatedCaloriesPer100g * portionMultiplier),
                    protein: Math.round(identified.estimatedProteinPer100g * portionMultiplier * 10) / 10,
                    carbs: Math.round(identified.estimatedCarbsPer100g * portionMultiplier * 10) / 10,
                    fat: Math.round(identified.estimatedFatPer100g * portionMultiplier * 10) / 10,
                    fiber: 0,
                    sugar: 0,
                    sodium: 0,
                    portionGrams: identified.portionGrams,
                    confidence: identified.confidence * 0.8, // Lower confidence for AI estimates
                    isFromDatabase: false,
                    databaseId: null,
                    ingredients: null,
                });
                console.log(`  ⚠️ "${identified.name}" → No DB match, using AI estimate`);
            }
        }
        const dbMatches = finalFoods.filter(f => f.isFromDatabase).length;
        console.log(`✅ Complete: ${dbMatches}/${finalFoods.length} from database`);
        res.set('Access-Control-Allow-Origin', '*');
        res.status(200).json({ foods: finalFoods });
    }
    catch (error) {
        console.error('❌ Food recognition failed:', error);
        res.status(500).json({
            error: 'Failed to recognize food',
            details: String(error)
        });
    }
});
/**
 * Build the prompt for food identification (not nutrition estimation)
 */
function buildIdentificationPrompt() {
    return `You are an expert food identification AI. Analyse this meal photo and identify ALL visible food items.

For EACH food item you can clearly see, provide:
1. name: Specific food name (e.g., "grilled chicken breast" not "chicken", "basmati rice" not "rice")
2. brand: Brand name if visible on packaging, otherwise null
3. portionGrams: Estimated weight in grams of the visible portion (use plate/utensils for scale)
4. searchTerms: Array of 2-3 alternative names for database searching (e.g., ["chicken breast", "grilled chicken", "chicken fillet"])
5. confidence: Your confidence in the identification (0.0-1.0)
6. estimatedCaloriesPer100g: Estimated calories per 100g (UK values)
7. estimatedProteinPer100g: Estimated protein per 100g
8. estimatedCarbsPer100g: Estimated carbs per 100g
9. estimatedFatPer100g: Estimated fat per 100g

PORTION SIZE GUIDELINES:
- Small chicken breast: ~120g
- Medium chicken breast: ~165g
- Cup of rice (cooked): ~160g
- Medium potato: ~170g
- Slice of bread: ~30-40g
- Handful of vegetables: ~80g
- Restaurant portion pasta: ~250g

IMPORTANT:
- Be SPECIFIC with names - we'll search a food database
- Include searchTerms that might match database entries
- Estimate portion sizes conservatively
- Use UK standard nutritional values for estimates
- List composite items as whole (e.g., "chicken sandwich" not separate ingredients)

Respond with ONLY valid JSON (no markdown):
{
  "foods": [
    {
      "name": "specific food name",
      "brand": "brand or null",
      "portionGrams": number,
      "searchTerms": ["term1", "term2"],
      "confidence": 0.0-1.0,
      "estimatedCaloriesPer100g": number,
      "estimatedProteinPer100g": number,
      "estimatedCarbsPer100g": number,
      "estimatedFatPer100g": number
    }
  ]
}

If no food is visible, return: {"foods": []}`;
}
/**
 * Identify foods using Gemini 2.0 Flash (best balance of speed and accuracy)
 */
async function identifyFoodsWithGemini(base64Image, apiKey) {
    var _a, _b, _c, _d, _e;
    // Using gemini-2.0-flash for best multimodal performance
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;
    const response = await axios_1.default.post(url, {
        contents: [{
                parts: [
                    { text: buildIdentificationPrompt() },
                    {
                        inline_data: {
                            mime_type: 'image/jpeg',
                            data: base64Image
                        }
                    }
                ]
            }],
        generationConfig: {
            temperature: 0.1, // Very low for consistent, accurate identification
            topP: 0.8,
            topK: 20,
            maxOutputTokens: 4096,
        }
    });
    const text = ((_e = (_d = (_c = (_b = (_a = response.data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) || '{"foods": []}';
    return parseGeminiResponse(text);
}
/**
 * Parse Gemini's identification response
 */
function parseGeminiResponse(responseText) {
    try {
        let cleanedText = responseText.trim();
        cleanedText = cleanedText.replace(/^```json\s*/i, '');
        cleanedText = cleanedText.replace(/^```\s*/i, '');
        cleanedText = cleanedText.replace(/\s*```$/i, '');
        cleanedText = cleanedText.trim();
        const parsed = JSON.parse(cleanedText);
        const foods = [];
        if (Array.isArray(parsed.foods)) {
            for (const item of parsed.foods) {
                if (typeof item.name === 'string' && item.name.length > 0) {
                    foods.push({
                        name: item.name,
                        brand: typeof item.brand === 'string' ? item.brand : null,
                        portionGrams: typeof item.portionGrams === 'number' && item.portionGrams > 0
                            ? Math.round(item.portionGrams)
                            : 100,
                        searchTerms: Array.isArray(item.searchTerms)
                            ? item.searchTerms.filter((t) => typeof t === 'string')
                            : [item.name],
                        confidence: typeof item.confidence === 'number'
                            ? Math.min(1, Math.max(0, item.confidence))
                            : 0.5,
                        estimatedCaloriesPer100g: typeof item.estimatedCaloriesPer100g === 'number'
                            ? Math.max(0, item.estimatedCaloriesPer100g)
                            : 100,
                        estimatedProteinPer100g: typeof item.estimatedProteinPer100g === 'number'
                            ? Math.max(0, item.estimatedProteinPer100g)
                            : 5,
                        estimatedCarbsPer100g: typeof item.estimatedCarbsPer100g === 'number'
                            ? Math.max(0, item.estimatedCarbsPer100g)
                            : 10,
                        estimatedFatPer100g: typeof item.estimatedFatPer100g === 'number'
                            ? Math.max(0, item.estimatedFatPer100g)
                            : 5,
                    });
                }
            }
        }
        return foods;
    }
    catch (error) {
        console.error('Failed to parse Gemini response:', responseText, error);
        return [];
    }
}
/**
 * Search Algolia database for a food match
 */
async function searchDatabaseForFood(client, food) {
    // Build search queries from the identified food
    const searchQueries = [
        food.name, // Primary name
        ...(food.searchTerms || []), // Alternative terms
    ];
    // If brand is specified, try brand + name first
    if (food.brand) {
        searchQueries.unshift(`${food.brand} ${food.name}`);
    }
    // Try each search query across indices
    for (const query of searchQueries) {
        for (const indexName of SEARCH_INDICES) {
            try {
                const result = await client.searchSingleIndex({
                    indexName,
                    searchParams: {
                        query,
                        hitsPerPage: 3,
                        attributesToRetrieve: [
                            'objectID', 'name', 'brandName',
                            'calories', 'protein', 'carbs', 'fat',
                            'fiber', 'sugar', 'sodium',
                            'ingredients', 'verified', 'isGeneric'
                        ],
                    },
                });
                if (result.hits && result.hits.length > 0) {
                    const hit = result.hits[0];
                    // Check if it's a reasonable match (basic validation)
                    const queryWords = query.toLowerCase().split(' ');
                    const hitName = hit.name.toLowerCase();
                    const matchScore = queryWords.filter(word => hitName.includes(word)).length / queryWords.length;
                    // Accept if at least 50% of query words match
                    if (matchScore >= 0.5) {
                        return hit;
                    }
                }
            }
            catch (error) {
                // Continue to next index if this one fails
                console.warn(`Search failed for "${query}" in ${indexName}:`, error);
            }
        }
    }
    return null;
}
//# sourceMappingURL=recognize-food.js.map