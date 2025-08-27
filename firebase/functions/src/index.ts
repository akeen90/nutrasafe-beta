import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import * as cors from 'cors';

admin.initializeApp();

const corsHandler = cors({origin: true});

interface FatSecretTokenResponse {
  access_token: string;
  expires_in: number;
  token_type: string;
}

interface FoodSearchResponse {
  foods?: {
    food?: Array<{
      food_id: string;
      food_name: string;
      brand_name?: string;
      food_type: string;
      food_url?: string;
    }>;
    max_results?: string;
    page_number?: string;
    total_results?: string;
  };
}

interface FoodDetailsResponse {
  food: {
    food_id: string;
    food_name: string;
    brand_name?: string;
    servings: {
      serving: Array<{
        calories?: string;
        carbohydrate?: string;
        fat?: string;
        fiber?: string;
        protein?: string;
        sodium?: string;
        sugar?: string;
        serving_description: string;
      }>;
    };
  };
}

let cachedToken: string | null = null;
let tokenExpiry: Date | null = null;

const FATSECRET_CLIENT_ID = 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = '9b2fa211700749fa98ac5dd243602189';
const FATSECRET_AUTH_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';

async function getFatSecretToken(): Promise<string> {
  if (cachedToken && tokenExpiry && tokenExpiry > new Date()) {
    return cachedToken;
  }

  const credentials = Buffer.from(`${FATSECRET_CLIENT_ID}:${FATSECRET_CLIENT_SECRET}`).toString('base64');
  
  try {
    console.log('Requesting FatSecret token...');
    const response = await axios.post(
      FATSECRET_AUTH_URL,
      'grant_type=client_credentials',
      {
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        timeout: 10000
      }
    );

    const tokenData: FatSecretTokenResponse = response.data;
    cachedToken = tokenData.access_token;
    tokenExpiry = new Date(Date.now() + (tokenData.expires_in - 60) * 1000); // 60 second buffer

    console.log('FatSecret token obtained successfully');
    return cachedToken;
  } catch (error: any) {
    console.error('Error getting FatSecret token:', error.response?.data || error.message);
    throw new functions.https.HttpsError('internal', `Failed to authenticate with FatSecret API: ${error.message}`);
  }
}

export const searchFoods = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const {query, maxResults = '50'} = req.body;

      if (!query) {
        res.status(400).json({error: 'Query parameter is required'});
        return;
      }

      const token = await getFatSecretToken();

      const response = await axios.get(FATSECRET_API_URL, {
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

      const searchData: FoodSearchResponse = response.data;

      if (!searchData.foods?.food) {
        res.json({foods: []});
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

      res.json({foods});
    } catch (error) {
      console.error('Error searching foods:', error);
      res.status(500).json({error: 'Failed to search foods'});
    }
  });
});

export const getFoodDetails = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const {foodId} = req.body;

      if (!foodId) {
        res.status(400).json({error: 'Food ID parameter is required'});
        return;
      }

      const token = await getFatSecretToken();

      const response = await axios.get(FATSECRET_API_URL, {
        params: {
          method: 'food.get.v2',
          food_id: foodId,
          format: 'json',
        },
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const foodData: FoodDetailsResponse = response.data;
      const food = foodData.food;
      const serving = food.servings.serving[0];

      if (!serving) {
        res.status(404).json({error: 'No serving information found'});
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
    } catch (error) {
      console.error('Error getting food details:', error);
      res.status(500).json({error: 'Failed to get food details'});
    }
  });
});

// Health check endpoint
export const healthCheck = functions.https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'nutrasafe-functions'
    });
  });
});

// IP check endpoint - shows what IP Firebase Functions uses for outbound requests
export const checkIP = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    try {
      // Make a request to an IP detection service
      const ipResponse = await axios.get('https://api.ipify.org?format=json', {
        timeout: 5000
      });
      
      res.json({
        outboundIP: ipResponse.data.ip,
        timestamp: new Date().toISOString(),
        service: 'nutrasafe-functions',
        region: 'us-central1'
      });
    } catch (error: any) {
      console.error('Error checking IP:', error.message);
      res.status(500).json({
        error: 'Failed to check IP',
        message: error.message
      });
    }
  });
});