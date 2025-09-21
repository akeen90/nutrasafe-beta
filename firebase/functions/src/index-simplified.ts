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
    food_description?: string;
    brand_name?: string;
    servings: {
      serving: any; // Can be array or single object
    };
  };
}

let cachedToken: string | null = null;
let tokenExpiry: Date | null = null;

const FATSECRET_CLIENT_ID = functions.config().fatsecret?.client_id || 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = functions.config().fatsecret?.client_secret || '31900952caf2458e943775f0f6fcbcab';
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

      console.log(`Searching for: ${query}`);
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
        timeout: 10000,
      });

      const searchData: FoodSearchResponse = response.data;
      console.log(`Search returned ${searchData.foods?.food?.length || 0} results`);

      if (!searchData.foods?.food) {
        res.json({foods: []});
        return;
      }

      // Get detailed nutrition information for each food
      const foods = await Promise.all(
        searchData.foods.food.slice(0, 10).map(async (food) => {
          try {
            // Get detailed nutrition data using v2 API
            const detailsResponse = await axios.get(FATSECRET_API_URL, {
              params: {
                method: 'food.get.v2',
                food_id: food.food_id,
                format: 'json',
              },
              headers: {
                'Authorization': `Bearer ${token}`,
              },
              timeout: 5000,
            });

            const foodData: FoodDetailsResponse = detailsResponse.data;
            const foodDetail = foodData.food;
            
            // Handle serving as array or single object
            const servings = foodDetail.servings?.serving;
            const serving = Array.isArray(servings) ? servings[0] : servings;
            
            // Parse all available nutrition data
            return {
              id: food.food_id,
              name: food.food_name,
              brand: food.brand_name || null,
              description: foodDetail.food_description || null,
              // Macronutrients
              calories: parseFloat(serving?.calories || '0'),
              protein: parseFloat(serving?.protein || '0'),
              carbs: parseFloat(serving?.carbohydrate || '0'),
              fat: parseFloat(serving?.fat || '0'),
              saturatedFat: parseFloat(serving?.saturated_fat || '0'),
              polyunsaturatedFat: parseFloat(serving?.polyunsaturated_fat || '0'),
              monounsaturatedFat: parseFloat(serving?.monounsaturated_fat || '0'),
              transFat: parseFloat(serving?.trans_fat || '0'),
              cholesterol: parseFloat(serving?.cholesterol || '0'),
              fiber: parseFloat(serving?.fiber || '0'),
              sugar: parseFloat(serving?.sugar || '0'),
              // Minerals
              sodium: parseFloat(serving?.sodium || '0'),
              potassium: parseFloat(serving?.potassium || '0'),
              calcium: parseFloat(serving?.calcium || '0'),
              iron: parseFloat(serving?.iron || '0'),
              // Serving info
              servingDescription: serving?.serving_description || 'per 100g',
              metricServingAmount: parseFloat(serving?.metric_serving_amount || '100'),
              metricServingUnit: serving?.metric_serving_unit || 'g',
            };
          } catch (detailError: any) {
            console.log(`Failed to get details for ${food.food_name}:`, detailError.message);
            // Return basic food info if details fail
            return {
              id: food.food_id,
              name: food.food_name,
              brand: food.brand_name || null,
              description: null,
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
              servingDescription: 'per 100g',
              metricServingAmount: 100,
              metricServingUnit: 'g',
            };
          }
        })
      );

      res.json({foods});
    } catch (error: any) {
      console.error('Error searching foods:', error.message);
      console.error('Error details:', error.response?.data || error);
      res.status(500).json({error: 'Failed to search foods', details: error.message});
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

      // Get food details using v2 API
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
      
      // Handle serving as array or single object
      const servings = food.servings?.serving;
      const serving = Array.isArray(servings) ? servings[0] : servings;

      if (!serving) {
        res.status(404).json({error: 'No serving information found'});
        return;
      }

      const result = {
        id: food.food_id,
        name: food.food_name,
        brand: food.brand_name || null,
        description: food.food_description || null,
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
        // Serving info
        servingDescription: serving.serving_description || 'per 100g',
        metricServingAmount: parseFloat(serving.metric_serving_amount || '100'),
        metricServingUnit: serving.metric_serving_unit || 'g',
      };

      res.json(result);
    } catch (error: any) {
      console.error('Error getting food details:', error.message);
      res.status(500).json({error: 'Failed to get food details', details: error.message});
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

// Keep the rest of your functions below...
