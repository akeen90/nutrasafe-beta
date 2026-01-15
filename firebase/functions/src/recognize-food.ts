/**
 * AI-Powered Food Recognition with Database Lookup
 *
 * Hybrid approach:
 * 1. Gemini 1.5 Pro identifies foods + estimates portion sizes
 * 2. Algolia searches for verified nutrition data
 * 3. Falls back to AI estimates only when no database match
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import axios from 'axios';
import { algoliasearch } from 'algoliasearch';

// Secrets
const geminiApiKey = defineSecret('GEMINI_API_KEY');
const algoliaAdminKey = defineSecret('ALGOLIA_ADMIN_API_KEY');

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
// Database indices - new cleaned databases
const SEARCH_INDICES = ['uk_foods_cleaned', 'fast_foods_database', 'generic_database'];

// Interfaces
interface GeminiIdentifiedFood {
  name: string;
  brand: string | null;
  portionGrams: number;
  searchTerms: string[];  // Alternative names for better matching
  confidence: number;
  isPackaging: boolean;  // true = photo of product packaging, false = plated/prepared food
  // Fallback estimates (used only if no database match)
  estimatedCaloriesPer100g: number;
  estimatedProteinPer100g: number;
  estimatedCarbsPer100g: number;
  estimatedFatPer100g: number;
}

interface AlgoliaFoodHit {
  objectID: string;
  name: string;
  brandName?: string;
  // Algolia stores nutrition without "Per100g" suffix
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  fiber?: number;
  sugar?: number;
  sodium?: number;
  ingredients?: string | string[];  // May be string or array depending on record
  verified?: boolean;
  isGeneric?: boolean;
}

interface FoodRecognitionItem {
  name: string;
  brand: string | null;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
  sodium: number;
  portionGrams: number;
  confidence: number;
  isFromDatabase: boolean;  // true = verified data, false = AI estimate
  databaseId: string | null;  // Algolia objectID if from database
  ingredients: string | null;
}

/**
 * Cloud Function: Recognize food items using Gemini + Algolia hybrid approach
 */
export const recognizeFood = onRequest(
  {
    cors: true,
    timeoutSeconds: 90,  // Increased for database lookups
    memory: '1GiB',
    secrets: [geminiApiKey, algoliaAdminKey],
  },
  async (req, res) => {
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

      // Step 2: Look up packaged foods in database, use AI estimates for plated food
      console.log('📚 Step 2: Processing foods (DB lookup for packaging, AI for plated)...');
      const algoliaClient = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());
      const finalFoods: FoodRecognitionItem[] = [];

      for (const identified of identifiedFoods) {
        const portionMultiplier = identified.portionGrams / 100;

        // Only search database for packaged products with branding visible
        // Plated/prepared food uses AI estimates directly (more accurate for generic items)
        if (identified.isPackaging && identified.brand) {
          const dbMatch = await searchDatabaseForFood(algoliaClient, identified);

          if (dbMatch) {
            // Database match found - use verified nutrition scaled to portion
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
              ingredients: Array.isArray(dbMatch.ingredients)
                ? dbMatch.ingredients.join(', ')
                : (dbMatch.ingredients || null),
            });
            console.log(`  ✅ [Packaging] "${identified.name}" → DB match: "${dbMatch.name}" (${dbMatch.calories || 0} kcal/100g)`);
            continue;
          }
          // If no DB match for packaging, fall through to AI estimate
          console.log(`  ⚠️ [Packaging] "${identified.name}" → No DB match, using AI estimate`);
        } else {
          console.log(`  🍽️ [Plated] "${identified.name}" → Using AI estimate (generic food)`);
        }

        // Use AI estimates for plated food or when no DB match found
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
          confidence: identified.isPackaging ? identified.confidence * 0.8 : identified.confidence,  // Lower confidence only for failed DB lookups
          isFromDatabase: false,
          databaseId: null,
          ingredients: null,
        });
      }

      const dbMatches = finalFoods.filter(f => f.isFromDatabase).length;
      const platedCount = identifiedFoods.filter(f => !f.isPackaging).length;
      console.log(`✅ Complete: ${dbMatches} from database, ${platedCount} plated (AI estimates)`);

      res.set('Access-Control-Allow-Origin', '*');
      res.status(200).json({ foods: finalFoods });
    } catch (error) {
      console.error('❌ Food recognition failed:', error);
      res.status(500).json({
        error: 'Failed to recognize food',
        details: String(error)
      });
    }
  }
);

/**
 * Build the prompt for food identification (not nutrition estimation)
 */
function buildIdentificationPrompt(): string {
  return `You are an expert food identification AI. Analyse this photo and identify ALL visible food items.

For EACH food item you can clearly see, provide:
1. name: Specific food name (e.g., "grilled chicken breast" not "chicken", "basmati rice" not "rice")
2. brand: Brand name if visible on packaging, otherwise null
3. portionGrams: Estimated weight in grams of the visible portion (use plate/utensils for scale)
4. searchTerms: Array of 2-3 alternative names for database searching (e.g., ["chicken breast", "grilled chicken", "chicken fillet"])
5. confidence: Your confidence in the identification (0.0-1.0)
6. isPackaging: true if this is a photo of PRODUCT PACKAGING (box, wrapper, label visible), false if it's PLATED/PREPARED FOOD on a plate or being eaten
7. estimatedCaloriesPer100g: Estimated calories per 100g (UK values)
8. estimatedProteinPer100g: Estimated protein per 100g
9. estimatedCarbsPer100g: Estimated carbs per 100g
10. estimatedFatPer100g: Estimated fat per 100g

PACKAGING vs PLATED FOOD:
- isPackaging = true: Photo shows product in original packaging with labels/branding visible (ready meal box, snack wrapper, etc.)
- isPackaging = false: Photo shows food on a plate, in a bowl, being prepared, or already cooked/served

CRITICAL - BREAK DOWN PLATED MEALS INTO COMPONENTS:
For plated/prepared food (isPackaging = false), you MUST list each component SEPARATELY:
- "Sausage and mash with gravy" should be listed as THREE separate items: "pork sausages", "mashed potato", "gravy"
- "Full English breakfast" should be listed as separate items: "bacon rashers", "fried eggs", "baked beans", "toast", "mushrooms", etc.
- "Roast dinner" should be: "roast chicken", "roast potatoes", "carrots", "gravy", etc.
- DO NOT combine multiple foods into one item - always separate them

PORTION SIZE GUIDELINES (per component) - BE REALISTIC:
- Single steak (sirloin/ribeye): ~150-200g (NOT 400g+)
- Large portion chips/fries: ~150-180g (NOT 300g+)
- Medium portion chips/fries: ~100-130g
- 2 pork sausages: ~120g
- Mashed potato serving: ~150-200g
- Gravy portion: ~50-80g
- Small chicken breast: ~120g
- Medium chicken breast: ~165g
- Cup of rice (cooked): ~160g
- Medium potato: ~170g
- Slice of bread: ~30-40g
- Handful of vegetables: ~80g
- Restaurant portion pasta: ~250g
- Bacon rasher: ~25g
- Fried egg: ~50g
- Burger patty: ~100-150g
- Side salad: ~100g

NUTRITIONAL ESTIMATES (per 100g UK values) - USE THESE EXACT VALUES:
- Sirloin/ribeye steak (cooked): ~160 kcal, 25g protein, 0g carbs, 7g fat
- Fillet steak (cooked): ~180 kcal, 27g protein, 0g carbs, 8g fat
- Chips/fries (oven baked): ~200 kcal, 3g protein, 30g carbs, 8g fat
- Chips/fries (deep fried): ~280 kcal, 3g protein, 35g carbs, 14g fat
- Pork sausages: ~250 kcal, 12g protein, 3g carbs, 20g fat
- Mashed potato (with butter): ~100 kcal, 2g protein, 15g carbs, 4g fat
- Gravy: ~35 kcal, 1g protein, 4g carbs, 2g fat
- Roast chicken: ~190 kcal, 25g protein, 0g carbs, 10g fat
- Roast potatoes: ~150 kcal, 2g protein, 22g carbs, 6g fat
- Grilled salmon: ~200 kcal, 22g protein, 0g carbs, 12g fat
- Burger patty (beef): ~240 kcal, 20g protein, 1g carbs, 18g fat
- Pizza slice (cheese): ~240 kcal, 10g protein, 28g carbs, 10g fat

REALISTIC CALORIE TOTALS for reference:
- Steak (180g) + chips (150g): ~290 + ~420 = ~710 kcal total
- Burger with bun + chips: ~500 + ~350 = ~850 kcal total
- Chicken breast + rice: ~320 + ~210 = ~530 kcal total
DO NOT estimate meals over 800-1000 kcal unless they are clearly very large portions

IMPORTANT:
- Be SPECIFIC with names - we'll search a food database for packaged items
- Include searchTerms that might match database entries
- Estimate portion sizes conservatively
- Use UK standard nutritional values for estimates
- For packaged items only: list as whole (e.g., "chicken sandwich")
- For plated food: ALWAYS break down into individual components

Respond with ONLY valid JSON (no markdown):
{
  "foods": [
    {
      "name": "specific food name",
      "brand": "brand or null",
      "portionGrams": number,
      "searchTerms": ["term1", "term2"],
      "confidence": 0.0-1.0,
      "isPackaging": true/false,
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
async function identifyFoodsWithGemini(base64Image: string, apiKey: string): Promise<GeminiIdentifiedFood[]> {
  // Using gemini-2.0-flash for best multimodal performance
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

  const response = await axios.post(url, {
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
      temperature: 0.1,  // Very low for consistent, accurate identification
      topP: 0.8,
      topK: 20,
      maxOutputTokens: 4096,
    }
  });

  const text = response.data.candidates?.[0]?.content?.parts?.[0]?.text || '{"foods": []}';
  return parseGeminiResponse(text);
}

/**
 * Parse Gemini's identification response
 */
function parseGeminiResponse(responseText: string): GeminiIdentifiedFood[] {
  try {
    let cleanedText = responseText.trim();
    cleanedText = cleanedText.replace(/^```json\s*/i, '');
    cleanedText = cleanedText.replace(/^```\s*/i, '');
    cleanedText = cleanedText.replace(/\s*```$/i, '');
    cleanedText = cleanedText.trim();

    const parsed = JSON.parse(cleanedText);
    const foods: GeminiIdentifiedFood[] = [];

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
              ? item.searchTerms.filter((t: unknown) => typeof t === 'string')
              : [item.name],
            confidence: typeof item.confidence === 'number'
              ? Math.min(1, Math.max(0, item.confidence))
              : 0.5,
            isPackaging: item.isPackaging === true,  // Default to false (plated food) if not specified
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
  } catch (error) {
    console.error('Failed to parse Gemini response:', responseText, error);
    return [];
  }
}

/**
 * Search Algolia database for a food match
 */
async function searchDatabaseForFood(
  client: ReturnType<typeof algoliasearch>,
  food: GeminiIdentifiedFood
): Promise<AlgoliaFoodHit | null> {
  // Build search queries from the identified food
  const searchQueries = [
    food.name,  // Primary name
    ...(food.searchTerms || []),  // Alternative terms
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
          const hit = result.hits[0] as unknown as AlgoliaFoodHit;

          // Check if it's a reasonable match (basic validation)
          const queryWords = query.toLowerCase().split(' ');
          const hitName = hit.name.toLowerCase();
          const matchScore = queryWords.filter(word => hitName.includes(word)).length / queryWords.length;

          // Accept if at least 50% of query words match
          if (matchScore >= 0.5) {
            return hit;
          }
        }
      } catch (error) {
        // Continue to next index if this one fails
        console.warn(`Search failed for "${query}" in ${indexName}:`, error);
      }
    }
  }

  return null;
}
