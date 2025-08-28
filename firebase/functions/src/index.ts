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
    food_images?: {
      food_image?: Array<{
        image_url?: string;
        image_type?: string;
      }>;
    };
    servings: {
      serving: Array<{
        calories?: string;
        carbohydrate?: string;
        fat?: string;
        fiber?: string;
        protein?: string;
        sodium?: string;
        sugar?: string;
        saturated_fat?: string;
        polyunsaturated_fat?: string;
        monounsaturated_fat?: string;
        trans_fat?: string;
        cholesterol?: string;
        potassium?: string;
        calcium?: string;
        iron?: string;
        vitamin_a?: string;
        vitamin_c?: string;
        vitamin_d?: string;
        vitamin_e?: string;
        vitamin_k?: string;
        thiamin?: string;
        riboflavin?: string;
        niacin?: string;
        vitamin_b6?: string;
        folate?: string;
        vitamin_b12?: string;
        magnesium?: string;
        phosphorus?: string;
        zinc?: string;
        serving_description: string;
        measurement_description?: string;
        metric_serving_amount?: string;
        metric_serving_unit?: string;
      }>;
    };
  };
}

let cachedToken: string | null = null;
let tokenExpiry: Date | null = null;

const FATSECRET_CLIENT_ID = functions.config().fatsecret.client_id || 'ca39fbf0342f4ad2970cbca1eccf7478';
const FATSECRET_CLIENT_SECRET = functions.config().fatsecret.client_secret || '31900952caf2458e943775f0f6fcbcab';
const FATSECRET_AUTH_URL = 'https://oauth.fatsecret.com/connect/token';
const FATSECRET_API_URL = 'https://platform.fatsecret.com/rest/server.api';
const OPENFOODFACTS_API_URL = 'https://world.openfoodfacts.net/api/v2';

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

// English-only ingredient lookup from Open Food Facts
async function getIngredientsFromOpenFoodFacts(productName: string, brandName?: string): Promise<string | null> {
  try {
    // Search for product in Open Food Facts with English language filter
    const searchQuery = brandName ? `${brandName} ${productName}` : productName;
    const searchUrl = `${OPENFOODFACTS_API_URL}/search`;
    
    console.log(`Searching Open Food Facts for: ${searchQuery}`);
    
    const response = await axios.get(searchUrl, {
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

    const products = response.data?.products;
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
  } catch (error: any) {
    console.log(`Open Food Facts lookup failed for ${productName}:`, error.message);
    return null;
  }
}

// Check if text is primarily English (no foreign characters)
function isEnglishText(text: string): boolean {
  if (!text || text.length < 10) return false;
  
  // Check for common non-English patterns
  const foreignPatterns = [
    /[áàâäéèêëíìîïóòôöúùûüýÿñç]/gi, // Accented characters
    /[αβγδεζηθικλμνξοπρστυφχψω]/gi,   // Greek
    /[а-я]/gi,                        // Cyrillic
    /[一-龯]/g,                       // Chinese/Japanese
    /[ㄱ-ㅎ가-힣]/g                    // Korean
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

      // Get detailed nutrition information for each food
      // Handle both array and single object responses
      const foodArray = Array.isArray(searchData.foods.food) 
        ? searchData.foods.food 
        : [searchData.foods.food];
        
      const foods = await Promise.all(
        foodArray.slice(0, 10).map(async (food) => {
          try {
            // Get detailed nutrition data using v2 API
            const detailsResponse = await axios.get(FATSECRET_API_URL, {
              params: {
                method: 'food.get.v2',  // v2 is the latest available version
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
            
            // Extract image URL if available
            const imageUrl = foodDetail.food_images?.food_image?.[0]?.image_url || null;
            
            // Extract comprehensive nutrition data
            return {
              id: food.food_id,
              name: food.food_name,
              brand: food.brand_name || null,
              description: foodDetail.food_description || null,
              imageUrl: imageUrl,
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
              magnesium: parseFloat(serving?.magnesium || '0'),
              phosphorus: parseFloat(serving?.phosphorus || '0'),
              zinc: parseFloat(serving?.zinc || '0'),
              // Vitamins
              vitaminA: parseFloat(serving?.vitamin_a || '0'),
              vitaminC: parseFloat(serving?.vitamin_c || '0'),
              vitaminD: parseFloat(serving?.vitamin_d || '0'),
              vitaminE: parseFloat(serving?.vitamin_e || '0'),
              vitaminK: parseFloat(serving?.vitamin_k || '0'),
              thiamin: parseFloat(serving?.thiamin || '0'),
              riboflavin: parseFloat(serving?.riboflavin || '0'),
              niacin: parseFloat(serving?.niacin || '0'),
              vitaminB6: parseFloat(serving?.vitamin_b6 || '0'),
              folate: parseFloat(serving?.folate || '0'),
              vitaminB12: parseFloat(serving?.vitamin_b12 || '0'),
              // Serving info
              servingDescription: serving?.serving_description || 'per 100g',
              metricServingAmount: parseFloat(serving?.metric_serving_amount || '100'),
              metricServingUnit: serving?.metric_serving_unit || 'g',
              // Try to get ingredients from Open Food Facts (English only)
              ingredients: await getIngredientsFromOpenFoodFacts(food.food_name, food.brand_name),
            };
          } catch (detailError: any) {
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
        })
      );

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
      } catch (analyticsError) {
        console.log('Analytics tracking failed:', analyticsError);
        // Don't fail the main request if analytics fail
      }

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
      
      // Extract image URL if available
      const imageUrl = food.food_images?.food_image?.[0]?.image_url || null;
      
      // Try to extract ingredients from description or use our extraction function
      let ingredients: string[] = [];
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
      } catch (analyticsError) {
        console.log('Analytics tracking failed:', analyticsError);
        // Don't fail the main request if analytics fail
      }

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

// Enhanced ingredient extraction function
export const getIngredientsFromFoodName = functions
  .runWith({
    vpcConnector: 'nutrasafe-vpc-connector',
    vpcConnectorEgressSettings: 'ALL_TRAFFIC'
  })
  .https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const {foodName, searchForBranded = true} = req.body;

      if (!foodName) {
        res.status(400).json({error: 'Food name parameter is required'});
        return;
      }

      console.log(`Extracting ingredients for: ${foodName}`);

      // First, search for the specific food to get food IDs
      const token = await getFatSecretToken();
      let ingredients: string[] = [];

      try {
        // Search for branded products that might have ingredient lists
        const searchResponse = await axios.get(FATSECRET_API_URL, {
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

        const searchData: FoodSearchResponse = searchResponse.data;
        console.log(`Found ${searchData.foods?.food?.length || 0} food items for "${foodName}"`);

        if (searchData.foods?.food) {
          // Try to find branded products first (more likely to have ingredients)
          // Handle both array and single object responses
          const foodArray = Array.isArray(searchData.foods.food) 
            ? searchData.foods.food 
            : [searchData.foods.food];
            
          const brandedFoods = foodArray.filter(food => 
            food.brand_name && food.brand_name.trim() !== ''
          );
            
          const foodsToCheck = searchForBranded && brandedFoods.length > 0 
            ? brandedFoods.slice(0, 5)  // Check top 5 branded foods
            : foodArray.slice(0, 3); // Check top 3 foods

          console.log(`Checking ${foodsToCheck.length} foods for ingredient information`);

          // Try to get detailed information for each food item
          for (const food of foodsToCheck) {
            try {
              // Use food.get.v3 which sometimes includes more detailed information
              await axios.get(FATSECRET_API_URL, {
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
              
            } catch (detailError: any) {
              console.log(`Failed to get details for food ${food.food_id}:`, detailError.message);
            }
          }
        }

        // Since FatSecret doesn't provide ingredient lists in their API,
        // we'll use intelligent parsing of the food name and known food database
        ingredients = extractIngredientsFromFoodName(foodName);

      } catch (apiError: any) {
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
      } catch (analyticsError) {
        console.log('Analytics tracking failed:', analyticsError);
      }

      res.json({
        foodName,
        ingredients,
        extractionMethod: ingredients.length > 0 ? 'name_parsing' : 'not_found',
        note: 'Ingredient extraction is based on food name analysis. For accurate ingredient lists, check product packaging.'
      });

    } catch (error: any) {
      console.error('Error extracting ingredients:', error);
      res.status(500).json({error: 'Failed to extract ingredients'});
    }
  });
});

// Helper function to extract ingredients from food names
function extractIngredientsFromFoodName(foodName: string): string[] {
  const lowerName = foodName.toLowerCase();
  let ingredients: string[] = [];

  // Common ingredient mappings based on food names
  const ingredientMappings: {[key: string]: string[]} = {
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
export const trackEvent = functions.https.onCall(async (data, context) => {
  try {
    const { eventType, userId, metadata } = data;
    
    if (!eventType) {
      throw new functions.https.HttpsError('invalid-argument', 'Event type is required');
    }

    const eventData = {
      eventType,
      userId: userId || context.auth?.uid || 'anonymous',
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
  } catch (error: any) {
    console.error('Error tracking event:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const getAnalytics = functions.https.onCall(async (data, context) => {
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

      const dailyData: any[] = [];
      dailyStatsSnapshot.forEach(doc => {
        dailyData.push({ id: doc.id, ...doc.data() });
      });

      return dailyData;
    }

    return {};
  } catch (error: any) {
    console.error('Error getting analytics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const getUserStats = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    // Get all Firebase Authentication users
    const listUsersResult = await admin.auth().listUsers(100);
    const users: any[] = [];

    for (const userRecord of listUsersResult.users) {
      // Get additional user data from Firestore if it exists
      let firestoreData: any = {};
      try {
        const firestoreDoc = await admin.firestore().collection('users').doc(userRecord.uid).get();
        if (firestoreDoc.exists) {
          firestoreData = firestoreDoc.data() || {};
        }
      } catch (error) {
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
      } catch (error) {
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
  } catch (error: any) {
    console.error('Error getting user stats:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});


// User Management Functions
export const createUser = functions.https.onCall(async (data, context) => {
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
  } catch (error: any) {
    console.error('Error creating user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const updateUser = functions.https.onCall(async (data, context) => {
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
    } catch (error) {
      throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
    }

    // Update Firebase Auth user if name is being updated
    if (updates.name) {
      await admin.auth().updateUser(userId, {
        displayName: updates.name,
      });
    }

    // Update Firestore user data
    await admin.firestore().collection('users').doc(userId).set({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true };
  } catch (error: any) {
    console.error('Error updating user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

export const deleteUser = functions.https.onCall(async (data, context) => {
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
    } catch (error) {
      throw new functions.https.HttpsError('not-found', 'User not found in Firebase Authentication');
    }

    // Delete user from Firebase Authentication
    await admin.auth().deleteUser(userId);

    // Delete user data from Firestore
    try {
      await admin.firestore().collection('users').doc(userId).delete();
    } catch (error) {
      console.log('No Firestore data to delete for user:', userId);
    }

    return { success: true };
  } catch (error: any) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to manually add current admin as user
export const addAdminAsUser = functions.https.onCall(async (data, context) => {
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
  } catch (error: any) {
    console.error('Error adding admin as user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});