"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoodByBarcode = exports.addAdminAsUser = exports.deleteUser = exports.updateUser = exports.createUser = exports.getUserStats = exports.getAnalytics = exports.trackEvent = exports.getIngredientsFromFoodName = exports.checkIP = exports.healthCheck = exports.getFoodDetails = exports.searchFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const cors = require("cors");
admin.initializeApp();
const corsHandler = cors({ origin: true });
let cachedToken = null;
let tokenExpiry = null;
const FATSECRET_CLIENT_ID = functions.config().fatsecret.client_id || 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = functions.config().fatsecret.client_secret || '31900952caf2458e943775f0f6fcbcab';
const FATSECRET_AUTH_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';
const OPENFOODFACTS_API_URL = 'https://world.openfoodfacts.net/api/v2';
async function getFatSecretToken() {
    var _a;
    if (cachedToken && tokenExpiry && tokenExpiry > new Date()) {
        return cachedToken;
    }
    const credentials = Buffer.from(`${FATSECRET_CLIENT_ID}:${FATSECRET_CLIENT_SECRET}`).toString('base64');
    try {
        console.log('Requesting FatSecret token...');
        const response = await axios_1.default.post(FATSECRET_AUTH_URL, 'grant_type=client_credentials', {
            headers: {
                'Authorization': `Basic ${credentials}`,
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            timeout: 10000
        });
        const tokenData = response.data;
        cachedToken = tokenData.access_token;
        tokenExpiry = new Date(Date.now() + (tokenData.expires_in - 60) * 1000); // 60 second buffer
        console.log('FatSecret token obtained successfully');
        return cachedToken;
    }
    catch (error) {
        console.error('Error getting FatSecret token:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
        throw new functions.https.HttpsError('internal', `Failed to authenticate with FatSecret API: ${error.message}`);
    }
}
// English-only ingredient lookup from Open Food Facts
async function getIngredientsFromOpenFoodFacts(productName, brandName) {
    var _a;
    try {
        // Search for product in Open Food Facts with English language filter
        const searchQuery = brandName ? `${brandName} ${productName}` : productName;
        const searchUrl = `${OPENFOODFACTS_API_URL}/search`;
        console.log(`Searching Open Food Facts for: ${searchQuery}`);
        const response = await axios_1.default.get(searchUrl, {
            params: {
                search_terms: searchQuery,
                search_simple: 1,
                action: 'process',
                json: 1,
                page_size: 5,
                // Filter for English-only products
                countries: 'united-kingdom,united-states,australia,canada,new-zealand',
                language: 'en'
            },
            timeout: 3000,
            headers: {
                'User-Agent': 'NutraSafe-App/1.0'
            }
        });
        const products = (_a = response.data) === null || _a === void 0 ? void 0 : _a.products;
        if (!products || products.length === 0) {
            console.log(`No Open Food Facts products found for: ${searchQuery}`);
            return null;
        }
        // Look for the best match (English ingredients)
        for (const product of products) {
            // Check if ingredients are in English (no accents, foreign characters)
            const ingredients = product.ingredients_text;
            if (ingredients && isEnglishText(ingredients)) {
                console.log(`Found English ingredients for ${searchQuery}: ${ingredients.substring(0, 100)}...`);
                return ingredients;
            }
        }
        console.log(`No English ingredients found for: ${searchQuery}`);
        return null;
    }
    catch (error) {
        console.log(`Open Food Facts lookup failed for ${productName}:`, error.message);
        return null;
    }
}
// Check if text is primarily English (no foreign characters)
function isEnglishText(text) {
    if (!text || text.length < 10)
        return false;
    // Check for common non-English patterns
    const foreignPatterns = [
        /[áàâäéèêëíìîïóòôöúùûüýÿñç]/gi, // Accented characters
        /[αβγδεζηθικλμνξοπρστυφχψω]/gi, // Greek
        /[а-я]/gi, // Cyrillic
        /[一-龯]/g, // Chinese/Japanese
        /[ㄱ-ㅎ가-힣]/g // Korean
    ];
    // If more than 10% foreign characters, reject
    let foreignCount = 0;
    for (const pattern of foreignPatterns) {
        const matches = text.match(pattern);
        if (matches) {
            foreignCount += matches.length;
        }
    }
    return foreignCount < (text.length * 0.1);
}
exports.searchFoods = functions
    .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
})
    .https.onRequest(async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a;
        try {
            const { query, maxResults = '50' } = req.body;
            if (!query) {
                res.status(400).json({ error: 'Query parameter is required' });
                return;
            }
            const token = await getFatSecretToken();
            const response = await axios_1.default.get(FATSECRET_API_URL, {
                params: {
                    method: 'foods.search',
                    search_expression: query,
                    format: 'json',
                    max_results: maxResults,
                },
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            const searchData = response.data;
            if (!((_a = searchData.foods) === null || _a === void 0 ? void 0 : _a.food)) {
                res.json({ foods: [] });
                return;
            }
            // Get detailed nutrition information for each food
            // Handle both array and single object responses
            const foodArray = Array.isArray(searchData.foods.food)
                ? searchData.foods.food
                : [searchData.foods.food];
            const foods = await Promise.all(foodArray.slice(0, 10).map(async (food) => {
                var _a, _b, _c, _d;
                try {
                    // Get detailed nutrition data using v2 API
                    const detailsResponse = await axios_1.default.get(FATSECRET_API_URL, {
                        params: {
                            method: 'food.get.v2', // v2 is the latest available version
                            food_id: food.food_id,
                            format: 'json',
                        },
                        headers: {
                            'Authorization': `Bearer ${token}`,
                        },
                        timeout: 5000,
                    });
                    const foodData = detailsResponse.data;
                    const foodDetail = foodData.food;
                    // Handle serving as array or single object
                    const servings = (_a = foodDetail.servings) === null || _a === void 0 ? void 0 : _a.serving;
                    const serving = Array.isArray(servings) ? servings[0] : servings;
                    // Extract image URL if available
                    const imageUrl = ((_d = (_c = (_b = foodDetail.food_images) === null || _b === void 0 ? void 0 : _b.food_image) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.image_url) || null;
                    // Extract comprehensive nutrition data
                    return {
                        id: food.food_id,
                        name: food.food_name,
                        brand: food.brand_name || null,
                        description: foodDetail.food_description || null,
                        imageUrl: imageUrl,
                        // Macronutrients
                        calories: parseFloat((serving === null || serving === void 0 ? void 0 : serving.calories) || '0'),
                        protein: parseFloat((serving === null || serving === void 0 ? void 0 : serving.protein) || '0'),
                        carbs: parseFloat((serving === null || serving === void 0 ? void 0 : serving.carbohydrate) || '0'),
                        fat: parseFloat((serving === null || serving === void 0 ? void 0 : serving.fat) || '0'),
                        saturatedFat: parseFloat((serving === null || serving === void 0 ? void 0 : serving.saturated_fat) || '0'),
                        polyunsaturatedFat: parseFloat((serving === null || serving === void 0 ? void 0 : serving.polyunsaturated_fat) || '0'),
                        monounsaturatedFat: parseFloat((serving === null || serving === void 0 ? void 0 : serving.monounsaturated_fat) || '0'),
                        transFat: parseFloat((serving === null || serving === void 0 ? void 0 : serving.trans_fat) || '0'),
                        cholesterol: parseFloat((serving === null || serving === void 0 ? void 0 : serving.cholesterol) || '0'),
                        fiber: parseFloat((serving === null || serving === void 0 ? void 0 : serving.fiber) || '0'),
                        sugar: parseFloat((serving === null || serving === void 0 ? void 0 : serving.sugar) || '0'),
                        // Minerals
                        sodium: parseFloat((serving === null || serving === void 0 ? void 0 : serving.sodium) || '0'),
                        potassium: parseFloat((serving === null || serving === void 0 ? void 0 : serving.potassium) || '0'),
                        calcium: parseFloat((serving === null || serving === void 0 ? void 0 : serving.calcium) || '0'),
                        iron: parseFloat((serving === null || serving === void 0 ? void 0 : serving.iron) || '0'),
                        magnesium: parseFloat((serving === null || serving === void 0 ? void 0 : serving.magnesium) || '0'),
                        phosphorus: parseFloat((serving === null || serving === void 0 ? void 0 : serving.phosphorus) || '0'),
                        zinc: parseFloat((serving === null || serving === void 0 ? void 0 : serving.zinc) || '0'),
                        // Vitamins
                        vitaminA: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_a) || '0'),
                        vitaminC: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_c) || '0'),
                        vitaminD: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_d) || '0'),
                        vitaminE: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_e) || '0'),
                        vitaminK: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_k) || '0'),
                        thiamin: parseFloat((serving === null || serving === void 0 ? void 0 : serving.thiamin) || '0'),
                        riboflavin: parseFloat((serving === null || serving === void 0 ? void 0 : serving.riboflavin) || '0'),
                        niacin: parseFloat((serving === null || serving === void 0 ? void 0 : serving.niacin) || '0'),
                        vitaminB6: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_b6) || '0'),
                        folate: parseFloat((serving === null || serving === void 0 ? void 0 : serving.folate) || '0'),
                        vitaminB12: parseFloat((serving === null || serving === void 0 ? void 0 : serving.vitamin_b12) || '0'),
                        // Serving info
                        servingDescription: (serving === null || serving === void 0 ? void 0 : serving.serving_description) || 'per 100g',
                        metricServingAmount: parseFloat((serving === null || serving === void 0 ? void 0 : serving.metric_serving_amount) || '100'),
                        metricServingUnit: (serving === null || serving === void 0 ? void 0 : serving.metric_serving_unit) || 'g',
                        // Try to get ingredients from Open Food Facts (English only)
                        ingredients: await getIngredientsFromOpenFoodFacts(food.food_name, food.brand_name),
                    };
                }
                catch (detailError) {
                    console.log(`Failed to get details for ${food.food_name}:`, detailError.message);
                    // Return basic food info with available data from search
                    return {
                        id: food.food_id,
                        name: food.food_name,
                        brand: food.brand_name || null,
                        description: null,
                        imageUrl: null,
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                        saturatedFat: 0,
                        polyunsaturatedFat: 0,
                        monounsaturatedFat: 0,
                        transFat: 0,
                        cholesterol: 0,
                        fiber: 0,
                        sugar: 0,
                        sodium: 0,
                        potassium: 0,
                        calcium: 0,
                        iron: 0,
                        magnesium: 0,
                        phosphorus: 0,
                        zinc: 0,
                        vitaminA: 0,
                        vitaminC: 0,
                        vitaminD: 0,
                        vitaminE: 0,
                        vitaminK: 0,
                        thiamin: 0,
                        riboflavin: 0,
                        niacin: 0,
                        vitaminB6: 0,
                        folate: 0,
                        vitaminB12: 0,
                        servingDescription: 'per 100g',
                        metricServingAmount: 100,
                        metricServingUnit: 'g',
                        ingredients: null, // No ingredients available when details fail
                    };
                }
            }));
            // Track the search event for analytics
            try {
                await admin.firestore().collection('analytics_events').add({
                    eventType: 'food_search',
                    userId: 'anonymous',
                    metadata: {
                        query,
                        resultsCount: foods.length,
                        timestamp: admin.firestore.FieldValue.serverTimestamp()
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    date: new Date().toISOString().split('T')[0],
                });
                // Update daily stats
                const today = new Date().toISOString().split('T')[0];
                const dailyStatsRef = admin.firestore().collection('daily_stats').doc(today);
                await dailyStatsRef.set({
                    date: today,
                    food_search_count: admin.firestore.FieldValue.increment(1),
                    total_events: admin.firestore.FieldValue.increment(1),
                    last_updated: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            }
            catch (analyticsError) {
                console.log('Analytics tracking failed:', analyticsError);
                // Don't fail the main request if analytics fail
            }
            res.json({ foods });
        }
        catch (error) {
            console.error('Error searching foods:', error);
            res.status(500).json({ error: 'Failed to search foods' });
        }
    });
});
exports.getFoodDetails = functions
    .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
})
    .https.onRequest(async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a, _b, _c, _d;
        try {
            const { foodId } = req.body;
            if (!foodId) {
                res.status(400).json({ error: 'Food ID parameter is required' });
                return;
            }
            const token = await getFatSecretToken();
            // Get food details using v2 API
            const response = await axios_1.default.get(FATSECRET_API_URL, {
                params: {
                    method: 'food.get.v2',
                    food_id: foodId,
                    format: 'json',
                },
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            const foodData = response.data;
            const food = foodData.food;
            // Handle serving as array or single object
            const servings = (_a = food.servings) === null || _a === void 0 ? void 0 : _a.serving;
            const serving = Array.isArray(servings) ? servings[0] : servings;
            if (!serving) {
                res.status(404).json({ error: 'No serving information found' });
                return;
            }
            // Extract image URL if available
            const imageUrl = ((_d = (_c = (_b = food.food_images) === null || _b === void 0 ? void 0 : _b.food_image) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.image_url) || null;
            // Try to extract ingredients from description or use our extraction function
            let ingredients = [];
            if (food.food_description) {
                // Simple extraction from description - look for "Ingredients:" section
                const ingredientsMatch = food.food_description.match(/ingredients[:\s]+([^.]+)/i);
                if (ingredientsMatch) {
                    ingredients = ingredientsMatch[1].split(',').map(i => i.trim());
                }
            }
            // If no ingredients found in description, use name-based extraction
            if (ingredients.length === 0) {
                ingredients = extractIngredientsFromFoodName(food.food_name);
            }
            const result = {
                id: food.food_id,
                name: food.food_name,
                brand: food.brand_name || null,
                description: food.food_description || null,
                imageUrl: imageUrl,
                ingredients: ingredients,
                // Macronutrients
                calories: parseFloat(serving.calories || '0'),
                protein: parseFloat(serving.protein || '0'),
                carbs: parseFloat(serving.carbohydrate || '0'),
                fat: parseFloat(serving.fat || '0'),
                saturatedFat: parseFloat(serving.saturated_fat || '0'),
                polyunsaturatedFat: parseFloat(serving.polyunsaturated_fat || '0'),
                monounsaturatedFat: parseFloat(serving.monounsaturated_fat || '0'),
                transFat: parseFloat(serving.trans_fat || '0'),
                cholesterol: parseFloat(serving.cholesterol || '0'),
                fiber: parseFloat(serving.fiber || '0'),
                sugar: parseFloat(serving.sugar || '0'),
                // Minerals
                sodium: parseFloat(serving.sodium || '0'),
                potassium: parseFloat(serving.potassium || '0'),
                calcium: parseFloat(serving.calcium || '0'),
                iron: parseFloat(serving.iron || '0'),
                magnesium: parseFloat(serving.magnesium || '0'),
                phosphorus: parseFloat(serving.phosphorus || '0'),
                zinc: parseFloat(serving.zinc || '0'),
                // Vitamins (if available in v2)
                vitaminA: parseFloat(serving.vitamin_a || '0'),
                vitaminC: parseFloat(serving.vitamin_c || '0'),
                vitaminD: parseFloat(serving.vitamin_d || '0'),
                vitaminE: parseFloat(serving.vitamin_e || '0'),
                vitaminK: parseFloat(serving.vitamin_k || '0'),
                thiamin: parseFloat(serving.thiamin || '0'),
                riboflavin: parseFloat(serving.riboflavin || '0'),
                niacin: parseFloat(serving.niacin || '0'),
                vitaminB6: parseFloat(serving.vitamin_b6 || '0'),
                folate: parseFloat(serving.folate || '0'),
                vitaminB12: parseFloat(serving.vitamin_b12 || '0'),
                // Serving info
                servingDescription: serving.serving_description || 'per 100g',
                metricServingAmount: parseFloat(serving.metric_serving_amount || '100'),
                metricServingUnit: serving.metric_serving_unit || 'g',
            };
            // Track the food details event for analytics
            try {
                await admin.firestore().collection('analytics_events').add({
                    eventType: 'food_details',
                    userId: 'anonymous',
                    metadata: {
                        foodId,
                        foodName: result.name,
                        timestamp: admin.firestore.FieldValue.serverTimestamp()
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    date: new Date().toISOString().split('T')[0],
                });
                // Update daily stats
                const today = new Date().toISOString().split('T')[0];
                const dailyStatsRef = admin.firestore().collection('daily_stats').doc(today);
                await dailyStatsRef.set({
                    date: today,
                    food_details_count: admin.firestore.FieldValue.increment(1),
                    total_events: admin.firestore.FieldValue.increment(1),
                    last_updated: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
            }
            catch (analyticsError) {
                console.log('Analytics tracking failed:', analyticsError);
                // Don't fail the main request if analytics fail
            }
            res.json(result);
        }
        catch (error) {
            console.error('Error getting food details:', error);
            res.status(500).json({ error: 'Failed to get food details' });
        }
    });
});
// Health check endpoint
exports.healthCheck = functions.https.onRequest((req, res) => {
    return corsHandler(req, res, async () => {
        res.json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            service: 'nutrasafe-functions'
        });
    });
});
// IP check endpoint - shows what IP Firebase Functions uses for outbound requests
exports.checkIP = functions
    .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
})
    .https.onRequest((req, res) => {
    return corsHandler(req, res, async () => {
        try {
            // Make a request to an IP detection service
            const ipResponse = await axios_1.default.get('https://api.ipify.org?format=json', {
                timeout: 5000
            });
            res.json({
                outboundIP: ipResponse.data.ip,
                timestamp: new Date().toISOString(),
                service: 'nutrasafe-functions',
                region: 'us-central1'
            });
        }
        catch (error) {
            console.error('Error checking IP:', error.message);
            res.status(500).json({
                error: 'Failed to check IP',
                message: error.message
            });
        }
    });
});
// Enhanced ingredient extraction function
exports.getIngredientsFromFoodName = functions
    .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
})
    .https.onRequest(async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a, _b, _c;
        try {
            const { foodName, searchForBranded = true } = req.body;
            if (!foodName) {
                res.status(400).json({ error: 'Food name parameter is required' });
                return;
            }
            console.log(`Extracting ingredients for: ${foodName}`);
            // First, search for the specific food to get food IDs
            const token = await getFatSecretToken();
            let ingredients = [];
            try {
                // Search for branded products that might have ingredient lists
                const searchResponse = await axios_1.default.get(FATSECRET_API_URL, {
                    params: {
                        method: 'foods.search',
                        search_expression: foodName,
                        format: 'json',
                        max_results: '20',
                    },
                    headers: {
                        'Authorization': `Bearer ${token}`,
                    },
                    timeout: 15000
                });
                const searchData = searchResponse.data;
                console.log(`Found ${((_b = (_a = searchData.foods) === null || _a === void 0 ? void 0 : _a.food) === null || _b === void 0 ? void 0 : _b.length) || 0} food items for "${foodName}"`);
                if ((_c = searchData.foods) === null || _c === void 0 ? void 0 : _c.food) {
                    // Try to find branded products first (more likely to have ingredients)
                    // Handle both array and single object responses
                    const foodArray = Array.isArray(searchData.foods.food)
                        ? searchData.foods.food
                        : [searchData.foods.food];
                    const brandedFoods = foodArray.filter(food => food.brand_name && food.brand_name.trim() !== '');
                    const foodsToCheck = searchForBranded && brandedFoods.length > 0
                        ? brandedFoods.slice(0, 5) // Check top 5 branded foods
                        : foodArray.slice(0, 3); // Check top 3 foods
                    console.log(`Checking ${foodsToCheck.length} foods for ingredient information`);
                    // Try to get detailed information for each food item
                    for (const food of foodsToCheck) {
                        try {
                            // Use food.get.v3 which sometimes includes more detailed information
                            await axios_1.default.get(FATSECRET_API_URL, {
                                params: {
                                    method: 'food.get.v2',
                                    food_id: food.food_id,
                                    format: 'json',
                                },
                                headers: {
                                    'Authorization': `Bearer ${token}`,
                                },
                                timeout: 10000
                            });
                            console.log(`Got details for food ID ${food.food_id}: ${food.food_name}`);
                            // FatSecret API doesn't typically include ingredients in the standard response
                            // but we can extract some info from the food name and description
                        }
                        catch (detailError) {
                            console.log(`Failed to get details for food ${food.food_id}:`, detailError.message);
                        }
                    }
                }
                // Since FatSecret doesn't provide ingredient lists in their API,
                // we'll use intelligent parsing of the food name and known food database
                ingredients = extractIngredientsFromFoodName(foodName);
            }
            catch (apiError) {
                console.error('FatSecret API error:', apiError.message);
                // Fallback to name-based ingredient extraction
                ingredients = extractIngredientsFromFoodName(foodName);
            }
            // Track the ingredient extraction event
            try {
                await admin.firestore().collection('analytics_events').add({
                    eventType: 'ingredient_extraction',
                    userId: 'anonymous',
                    metadata: {
                        foodName,
                        ingredientsFound: ingredients.length,
                        timestamp: admin.firestore.FieldValue.serverTimestamp()
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    date: new Date().toISOString().split('T')[0],
                });
            }
            catch (analyticsError) {
                console.log('Analytics tracking failed:', analyticsError);
            }
            res.json({
                foodName,
                ingredients,
                extractionMethod: ingredients.length > 0 ? 'name_parsing' : 'not_found',
                note: 'Ingredient extraction is based on food name analysis. For accurate ingredient lists, check product packaging.'
            });
        }
        catch (error) {
            console.error('Error extracting ingredients:', error);
            res.status(500).json({ error: 'Failed to extract ingredients' });
        }
    });
});
// Helper function to extract ingredients from food names
function extractIngredientsFromFoodName(foodName) {
    const lowerName = foodName.toLowerCase();
    let ingredients = [];
    // Common ingredient mappings based on food names
    const ingredientMappings = {
        'pizza': ['wheat flour', 'tomatoes', 'cheese', 'yeast', 'olive oil', 'salt'],
        'bread': ['wheat flour', 'yeast', 'salt', 'water'],
        'pasta': ['durum wheat', 'water', 'eggs'],
        'yogurt': ['milk', 'live cultures', 'sugar'],
        'yoghurt': ['milk', 'live cultures', 'sugar'],
        'cheese': ['milk', 'salt', 'enzymes', 'bacterial cultures'],
        'butter': ['cream', 'salt'],
        'milk': ['milk'],
        'chicken': ['chicken'],
        'beef': ['beef'],
        'pork': ['pork'],
        'fish': ['fish'],
        'salmon': ['salmon'],
        'tuna': ['tuna'],
        'rice': ['rice'],
        'oats': ['oats'],
        'quinoa': ['quinoa'],
        'apple': ['apple'],
        'banana': ['banana'],
        'orange': ['orange'],
        'spinach': ['spinach'],
        'broccoli': ['broccoli'],
        'carrot': ['carrot'],
        'potato': ['potato'],
        'tomato': ['tomato'],
        'onion': ['onion'],
        'garlic': ['garlic'],
        'egg': ['egg'],
        'chocolate': ['cocoa', 'sugar', 'milk', 'cocoa butter'],
        'ice cream': ['milk', 'cream', 'sugar', 'eggs', 'vanilla'],
        'cookie': ['wheat flour', 'sugar', 'butter', 'eggs', 'baking powder'],
        'cake': ['wheat flour', 'sugar', 'eggs', 'butter', 'baking powder'],
        'cereal': ['grains', 'sugar', 'vitamins', 'minerals'],
        'soup': ['water', 'vegetables', 'salt', 'spices'],
        'juice': ['fruit', 'water'],
        'soda': ['water', 'sugar', 'carbon dioxide', 'artificial flavors'],
        'tea': ['tea leaves'],
        'coffee': ['coffee beans'],
    };
    // Check for direct matches first
    for (const [foodType, ingredientList] of Object.entries(ingredientMappings)) {
        if (lowerName.includes(foodType)) {
            ingredients = [...ingredients, ...ingredientList];
            break; // Take the first match to avoid duplicates
        }
    }
    // If no direct match, try to extract ingredients from compound food names
    if (ingredients.length === 0) {
        // Look for ingredient keywords in the food name
        const possibleIngredients = [
            'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'shrimp',
            'milk', 'cheese', 'butter', 'cream', 'yogurt', 'eggs',
            'wheat', 'rice', 'oats', 'corn', 'barley', 'quinoa',
            'tomato', 'onion', 'garlic', 'pepper', 'mushroom', 'spinach',
            'apple', 'banana', 'orange', 'berry', 'grape',
            'sugar', 'salt', 'oil', 'vinegar', 'herbs', 'spices'
        ];
        for (const ingredient of possibleIngredients) {
            if (lowerName.includes(ingredient)) {
                ingredients.push(ingredient);
            }
        }
    }
    // Remove duplicates and return
    return [...new Set(ingredients)];
}
// Analytics Functions
exports.trackEvent = functions.https.onCall(async (data, context) => {
    var _a;
    try {
        const { eventType, userId, metadata } = data;
        if (!eventType) {
            throw new functions.https.HttpsError('invalid-argument', 'Event type is required');
        }
        const eventData = {
            eventType,
            userId: userId || ((_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid) || 'anonymous',
            metadata: metadata || {},
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            date: new Date().toISOString().split('T')[0], // YYYY-MM-DD for easy querying
        };
        await admin.firestore().collection('analytics_events').add(eventData);
        // Update daily stats
        const dailyStatsRef = admin.firestore()
            .collection('daily_stats')
            .doc(eventData.date);
        await dailyStatsRef.set({
            date: eventData.date,
            [`${eventType}_count`]: admin.firestore.FieldValue.increment(1),
            total_events: admin.firestore.FieldValue.increment(1),
            last_updated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return { success: true, eventId: eventData };
    }
    catch (error) {
        console.error('Error tracking event:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.getAnalytics = functions.https.onCall(async (data, context) => {
    try {
        // Check if user is admin (you might want to implement proper admin checking)
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        const { period = '30', type = 'overview' } = data;
        const daysAgo = parseInt(period);
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - daysAgo);
        if (type === 'overview') {
            // Get total users from Firebase Authentication
            const listUsersResult = await admin.auth().listUsers();
            const totalUsers = listUsersResult.users.length;
            // Get active users (users with events in last 30 days)
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            const activeUsersSnapshot = await admin.firestore()
                .collection('analytics_events')
                .where('timestamp', '>=', thirtyDaysAgo)
                .get();
            const activeUserIds = new Set();
            activeUsersSnapshot.forEach(doc => {
                const data = doc.data();
                if (data.userId && data.userId !== 'anonymous') {
                    activeUserIds.add(data.userId);
                }
            });
            // Get API calls today
            const today = new Date().toISOString().split('T')[0];
            const todayStatsDoc = await admin.firestore()
                .collection('daily_stats')
                .doc(today)
                .get();
            const todayStats = todayStatsDoc.data() || {};
            const apiCallsToday = (todayStats.food_search_count || 0) + (todayStats.food_details_count || 0);
            return {
                totalUsers,
                activeUsers: activeUserIds.size,
                apiCallsToday,
                systemUptime: '99.9%'
            };
        }
        if (type === 'daily') {
            const dailyStatsSnapshot = await admin.firestore()
                .collection('daily_stats')
                .where('date', '>=', startDate.toISOString().split('T')[0])
                .orderBy('date', 'asc')
                .get();
            const dailyData = [];
            dailyStatsSnapshot.forEach(doc => {
                dailyData.push(Object.assign({ id: doc.id }, doc.data()));
            });
            return dailyData;
        }
        return {};
    }
    catch (error) {
        console.error('Error getting analytics:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.getUserStats = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        // Get all Firebase Authentication users
        const listUsersResult = await admin.auth().listUsers(100);
        const users = [];
        for (const userRecord of listUsersResult.users) {
            // Get additional user data from Firestore if it exists
            let firestoreData = {};
            try {
                const firestoreDoc = await admin.firestore().collection('users').doc(userRecord.uid).get();
                if (firestoreDoc.exists) {
                    firestoreData = firestoreDoc.data() || {};
                }
            }
            catch (error) {
                // Firestore data doesn't exist, that's ok
            }
            // Get last activity from analytics
            let lastActive = 'Never';
            try {
                const lastActivitySnapshot = await admin.firestore()
                    .collection('analytics_events')
                    .where('userId', '==', userRecord.uid)
                    .orderBy('timestamp', 'desc')
                    .limit(1)
                    .get();
                if (!lastActivitySnapshot.empty) {
                    const lastActivity = lastActivitySnapshot.docs[0].data();
                    const timestamp = lastActivity.timestamp.toDate();
                    lastActive = timestamp.toLocaleDateString();
                }
            }
            catch (error) {
                // No analytics data yet
            }
            users.push({
                id: userRecord.uid,
                email: userRecord.email || 'Unknown',
                name: userRecord.displayName || firestoreData.name || 'Unknown User',
                status: userRecord.disabled ? 'inactive' : 'active',
                plan: firestoreData.plan || 'Basic',
                lastActive,
                createdAt: userRecord.metadata.creationTime,
                emailVerified: userRecord.emailVerified
            });
        }
        return users;
    }
    catch (error) {
        console.error('Error getting user stats:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// User Management Functions
exports.createUser = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        const { email, name, plan = 'Basic', password = 'tempPassword123!' } = data;
        if (!email || !name) {
            throw new functions.https.HttpsError('invalid-argument', 'Email and name are required');
        }
        // Create the Firebase Authentication user
        const userRecord = await admin.auth().createUser({
            email,
            displayName: name,
            password,
            emailVerified: false,
        });
        // Create additional user data in Firestore
        await admin.firestore().collection('users').doc(userRecord.uid).set({
            email,
            name,
            plan,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, userId: userRecord.uid, message: 'User created successfully. Password: tempPassword123!' };
    }
    catch (error) {
        console.error('Error creating user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.updateUser = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        const { userId, updates } = data;
        if (!userId) {
            throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
        }
        // Check if user exists in Firebase Auth
        try {
            await admin.auth().getUser(userId);
        }
        catch (error) {
            throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
        }
        // Update Firebase Auth user if name is being updated
        if (updates.name) {
            await admin.auth().updateUser(userId, {
                displayName: updates.name,
            });
        }
        // Update Firestore user data
        await admin.firestore().collection('users').doc(userId).set(Object.assign(Object.assign({}, updates), { updatedAt: admin.firestore.FieldValue.serverTimestamp() }), { merge: true });
        return { success: true };
    }
    catch (error) {
        console.error('Error updating user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
exports.deleteUser = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        const { userId } = data;
        if (!userId) {
            throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
        }
        // Check if user exists in Firebase Auth
        try {
            await admin.auth().getUser(userId);
        }
        catch (error) {
            throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
        }
        // Delete user from Firebase Authentication
        await admin.auth().deleteUser(userId);
        // Delete user data from Firestore
        try {
            await admin.firestore().collection('users').doc(userId).delete();
        }
        catch (error) {
            console.log('No Firestore data to delete for user:', userId);
        }
        return { success: true };
    }
    catch (error) {
        console.error('Error deleting user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// Function to manually add current admin as user
exports.addAdminAsUser = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        const adminEmail = context.auth.token.email || 'admin@nutrasafe.com';
        const adminName = context.auth.token.name || 'Admin User';
        // Check if admin user already exists
        const existingUsers = await admin.firestore()
            .collection('users')
            .where('email', '==', adminEmail)
            .get();
        if (!existingUsers.empty) {
            return { success: true, message: 'Admin user already exists' };
        }
        // Create admin user
        const userRef = admin.firestore().collection('users').doc(context.auth.uid);
        await userRef.set({
            email: adminEmail,
            name: adminName,
            plan: 'Admin',
            status: 'active',
            role: 'admin',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, message: 'Admin user created successfully' };
    }
    catch (error) {
        console.error('Error adding admin as user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// Barcode search function
exports.searchFoodByBarcode = functions
    .runWith({
    memory: '512MB',
    timeoutSeconds: 60,
})
    .https.onRequest(async (req, res) => {
    return corsHandler(req, res, async () => {
        var _a, _b;
        try {
            const { barcode } = req.body;
            if (!barcode) {
                res.status(400).json({ error: 'Barcode parameter is required' });
                return;
            }
            console.log('Searching for barcode:', barcode);
            const token = await getFatSecretToken();
            // Search for food by barcode using FatSecret API
            const searchResponse = await axios_1.default.get(FATSECRET_API_URL, {
                params: {
                    method: 'food.search',
                    search_expression: barcode,
                    format: 'json',
                    max_results: '10',
                },
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            console.log('FatSecret search response:', JSON.stringify(searchResponse.data, null, 2));
            const searchData = searchResponse.data;
            if (!((_a = searchData.foods) === null || _a === void 0 ? void 0 : _a.food) || searchData.foods.food.length === 0) {
                res.status(404).json({
                    success: false,
                    error: 'No product found for this barcode'
                });
                return;
            }
            // Get the first food item and fetch its details
            const firstFood = searchData.foods.food[0];
            // Get detailed food information
            const detailsResponse = await axios_1.default.get(FATSECRET_API_URL, {
                params: {
                    method: 'food.get.v2',
                    food_id: firstFood.food_id,
                    format: 'json',
                },
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });
            const foodData = detailsResponse.data;
            const food = foodData.food;
            // Handle serving as array or single object
            const servings = (_b = food.servings) === null || _b === void 0 ? void 0 : _b.serving;
            const serving = Array.isArray(servings) ? servings[0] : servings;
            if (!serving) {
                res.status(404).json({
                    success: false,
                    error: 'No nutritional information available for this product'
                });
                return;
            }
            // Try to get ingredients from Open Food Facts (English only)
            const ingredients = await getIngredientsFromOpenFoodFacts(food.food_name, food.brand_name);
            // Extract serving sizes from the food data
            const servingSizes = [];
            if (Array.isArray(servings)) {
                for (const srv of servings) {
                    if (srv.serving_description && srv.metric_serving_amount) {
                        servingSizes.push({
                            description: srv.serving_description,
                            metric_serving_amount: parseFloat(srv.metric_serving_amount || '100'),
                            metric_serving_unit: srv.metric_serving_unit || 'g'
                        });
                    }
                }
            }
            else if (serving.serving_description) {
                servingSizes.push({
                    description: serving.serving_description,
                    metric_serving_amount: parseFloat(serving.metric_serving_amount || '100'),
                    metric_serving_unit: serving.metric_serving_unit || 'g'
                });
            }
            // Default serving size if none found
            if (servingSizes.length === 0) {
                servingSizes.push({
                    description: '100g',
                    metric_serving_amount: 100,
                    metric_serving_unit: 'g'
                });
            }
            const result = {
                success: true,
                food: {
                    food_id: food.food_id,
                    food_name: food.food_name,
                    brand_name: food.brand_name || null,
                    food_description: food.food_description || null,
                    ingredients: ingredients,
                    // Macronutrients
                    calories: parseFloat(serving.calories || '0'),
                    protein: parseFloat(serving.protein || '0'),
                    carbohydrates: parseFloat(serving.carbohydrate || '0'),
                    fat: parseFloat(serving.fat || '0'),
                    saturated_fat: parseFloat(serving.saturated_fat || '0'),
                    fiber: parseFloat(serving.fiber || '0'),
                    sugar: parseFloat(serving.sugar || '0'),
                    // Minerals
                    sodium: parseFloat(serving.sodium || '0'),
                    potassium: parseFloat(serving.potassium || '0'),
                    calcium: parseFloat(serving.calcium || '0'),
                    iron: parseFloat(serving.iron || '0'),
                    // Vitamins
                    vitamin_a: parseFloat(serving.vitamin_a || '0'),
                    vitamin_c: parseFloat(serving.vitamin_c || '0'),
                    vitamin_d: parseFloat(serving.vitamin_d || '0'),
                    // Serving info
                    servingSizes: servingSizes,
                    serving_description: serving.serving_description || 'per 100g',
                    metric_serving_amount: parseFloat(serving.metric_serving_amount || '100'),
                    metric_serving_unit: serving.metric_serving_unit || 'g',
                }
            };
            console.log('Returning barcode result:', JSON.stringify(result, null, 2));
            res.json(result);
        }
        catch (error) {
            console.error('Error searching for barcode:', error);
            if (error.response) {
                console.error('API Error Response:', error.response.data);
            }
            res.status(500).json({
                success: false,
                error: 'Failed to search for product by barcode'
            });
        }
    });
});
//# sourceMappingURL=index.js.map