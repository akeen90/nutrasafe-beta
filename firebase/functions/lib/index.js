"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkIP = exports.healthCheck = exports.getFoodDetails = exports.searchFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const cors = require("cors");
admin.initializeApp();
const corsHandler = cors({ origin: true });
let cachedToken = null;
let tokenExpiry = null;
const FATSECRET_CLIENT_ID = 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = '9b2fa211700749fa98ac5dd243602189';
const FATSECRET_AUTH_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';
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
            const foods = searchData.foods.food.map(food => ({
                id: food.food_id,
                name: food.food_name,
                brand: food.brand_name || null,
                calories: 0, // Will be populated by getFoodDetails
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0,
                sugar: 0,
                sodium: 0,
            }));
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
        try {
            const { foodId } = req.body;
            if (!foodId) {
                res.status(400).json({ error: 'Food ID parameter is required' });
                return;
            }
            const token = await getFatSecretToken();
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
            const serving = food.servings.serving[0];
            if (!serving) {
                res.status(404).json({ error: 'No serving information found' });
                return;
            }
            const result = {
                id: food.food_id,
                name: food.food_name,
                brand: food.brand_name || null,
                calories: parseFloat(serving.calories || '0'),
                protein: parseFloat(serving.protein || '0'),
                carbs: parseFloat(serving.carbohydrate || '0'),
                fat: parseFloat(serving.fat || '0'),
                fiber: parseFloat(serving.fiber || '0'),
                sugar: parseFloat(serving.sugar || '0'),
                sodium: parseFloat(serving.sodium || '0'),
            };
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
//# sourceMappingURL=index.js.map