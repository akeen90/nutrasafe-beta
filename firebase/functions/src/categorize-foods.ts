/**
 * AI Food Categorization using Gemini
 * Categorizes foods to enable intelligent serving size suggestions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import { FOOD_CATEGORIES, getCategoryDescriptions, getCategoryById, getServingSizeForCategory } from './food-categories';

const cors = require('cors')({ origin: true });

interface FoodToCategorize {
  id: string;
  foodName: string;
  brandName?: string;
  ingredients?: string;
  servingDescription?: string;
}

interface CategorizationResult {
  id: string;
  foodName: string;
  categoryId: string;
  categoryName: string;
  suggestedServingSize: number;
  servingUnit: string;
  servingDescription: string;
  confidence: 'high' | 'medium' | 'low';
}

/**
 * Get Gemini API key from Firebase config or environment
 */
function getGeminiApiKey(): string {
  const configKey = functions.config().gemini?.api_key;
  const envKey = process.env.GEMINI_API_KEY;

  if (configKey) return configKey;
  if (envKey) return envKey;

  throw new functions.https.HttpsError('failed-precondition', 'Gemini API key not configured');
}

/**
 * Build the categorization prompt for Gemini
 */
function buildCategorizationPrompt(foods: FoodToCategorize[]): string {
  const categoryDescriptions = getCategoryDescriptions();

  const foodList = foods.map((food, index) => {
    const parts = [`${index + 1}. "${food.foodName}"`];
    if (food.brandName) parts.push(`Brand: ${food.brandName}`);
    if (food.ingredients) parts.push(`Ingredients: ${food.ingredients.substring(0, 100)}...`);
    if (food.servingDescription) parts.push(`Serving: ${food.servingDescription}`);
    return parts.join(' | ');
  }).join('\n');

  return `You are a UK food categorization expert. Analyze each food item and assign the most appropriate category ID from the list below.

AVAILABLE CATEGORIES:
${categoryDescriptions}

FOOD ITEMS TO CATEGORIZE:
${foodList}

INSTRUCTIONS:
- Assign exactly ONE category ID to each food
- Consider the food name, brand, and ingredients
- For branded products, recognize UK brands (Heinz, Walkers, Cadbury, Greggs, etc.)
- If unsure, use "unknown"
- Consider the physical form: cans, bottles, packets, fresh items, etc.

RESPOND IN THIS EXACT JSON FORMAT (no markdown, just raw JSON):
[
  {"index": 1, "categoryId": "category_id_here", "confidence": "high"},
  {"index": 2, "categoryId": "category_id_here", "confidence": "medium"}
]

Confidence levels:
- "high": Very clear match (branded products, obvious categories)
- "medium": Good match but could be ambiguous
- "low": Best guess, item is unusual or unclear`;
}

/**
 * Call Gemini API to categorize foods
 */
async function callGeminiForCategorization(foods: FoodToCategorize[], apiKey: string): Promise<any[]> {
  const prompt = buildCategorizationPrompt(foods);

  // Using gemini-1.5-flash-8b - cheapest model ($0.0375/1M input tokens)
  const response = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-8b:generateContent?key=${apiKey}`,
    {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.1, // Low temperature for consistent categorization
        maxOutputTokens: 2048
      }
    },
    {
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000
    }
  );

  const responseText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

  if (!responseText) {
    throw new Error('Empty response from Gemini');
  }

  // Parse JSON response (handle potential markdown wrapping)
  let jsonStr = responseText;
  if (jsonStr.startsWith('```')) {
    jsonStr = jsonStr.replace(/```json?\n?/g, '').replace(/```\n?/g, '');
  }

  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    console.error('Failed to parse Gemini response:', responseText);
    throw new Error('Invalid JSON response from Gemini');
  }
}

/**
 * Process categorization results
 */
function processResults(foods: FoodToCategorize[], geminiResults: any[]): CategorizationResult[] {
  return foods.map((food, index) => {
    const result = geminiResults.find(r => r.index === index + 1);
    const categoryId = result?.categoryId || 'unknown';
    const confidence = result?.confidence || 'low';

    const category = getCategoryById(categoryId);
    const servingInfo = getServingSizeForCategory(categoryId);

    return {
      id: food.id,
      foodName: food.foodName,
      categoryId: categoryId,
      categoryName: category?.name || 'Unknown',
      suggestedServingSize: servingInfo?.size || 100,
      servingUnit: servingInfo?.unit || 'g',
      servingDescription: servingInfo?.description || 'per 100g',
      confidence: confidence as 'high' | 'medium' | 'low'
    };
  });
}

/**
 * HTTP Function: Categorize a batch of foods
 * POST body: { foods: [{ id, foodName, brandName?, ingredients? }] }
 */
export const categorizeFoods = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      const { foods } = req.body;

      if (!foods || !Array.isArray(foods) || foods.length === 0) {
        res.status(400).json({ error: 'foods array is required' });
        return;
      }

      if (foods.length > 50) {
        res.status(400).json({ error: 'Maximum 50 foods per request' });
        return;
      }

      const apiKey = getGeminiApiKey();
      console.log(`Categorizing ${foods.length} foods...`);

      const geminiResults = await callGeminiForCategorization(foods, apiKey);
      const results = processResults(foods, geminiResults);

      console.log(`Successfully categorized ${results.length} foods`);
      res.json({ success: true, results });

    } catch (error: any) {
      console.error('Categorization error:', error);
      res.status(500).json({
        error: error.message || 'Categorization failed',
        details: error.response?.data || null
      });
    }
  });
});

/**
 * HTTP Function: Categorize foods from database and save results
 * POST body: { limit?: number, offset?: number, collection?: string, saveResults?: boolean }
 */
export const categorizeFoodsFromDatabase = functions
  .runWith({ timeoutSeconds: 540, memory: '1GB' })
  .https.onRequest((req, res) => {
    cors(req, res, async () => {
      if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
      }

      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
      }

      try {
        const {
          limit = 50,
          offset = 0,
          collection = 'verifiedFoods',
          saveResults = true,
          onlyUncategorized = true
        } = req.body;

        const db = admin.firestore();
        const apiKey = getGeminiApiKey();

        // Query foods from database - get all foods (we'll overwrite categories)
        const snapshot = await db.collection(collection).limit(limit).offset(offset).get();

        if (snapshot.empty) {
          res.json({
            success: true,
            message: 'No foods to categorize',
            processed: 0,
            total: 0
          });
          return;
        }

        // Prepare ALL foods for categorization (overwrite existing categories)
        const foods: FoodToCategorize[] = snapshot.docs.map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            foodName: data.foodName || data.name || '',
            brandName: data.brandName || data.brand || '',
            ingredients: data.ingredients || data.extractedIngredients || '',
            servingDescription: data.servingDescription || data.servingSize || ''
          };
        });

        console.log(`Fetched ${foods.length} foods from ${collection}`);

        // Process in batches of 20 for Gemini
        const batchSize = 20;
        const allResults: CategorizationResult[] = [];

        for (let i = 0; i < foods.length; i += batchSize) {
          const batch = foods.slice(i, i + batchSize);
          console.log(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(foods.length / batchSize)}`);

          const geminiResults = await callGeminiForCategorization(batch, apiKey);
          const results = processResults(batch, geminiResults);
          allResults.push(...results);

          // Small delay between batches to avoid rate limiting
          if (i + batchSize < foods.length) {
            await new Promise(resolve => setTimeout(resolve, 50)); // 50ms delay between Gemini calls
          }
        }

        // Save results to database if requested
        if (saveResults) {
          const batch = db.batch();
          let updateCount = 0;

          for (const result of allResults) {
            const docRef = db.collection(collection).doc(result.id);
            batch.update(docRef, {
              foodCategory: result.categoryId,
              foodCategoryName: result.categoryName,
              suggestedServingSize: result.suggestedServingSize,
              suggestedServingUnit: result.servingUnit,
              suggestedServingDescription: result.servingDescription,
              categoryConfidence: result.confidence,
              categorizedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            updateCount++;

            // Commit in batches of 500 (Firestore limit)
            if (updateCount % 500 === 0) {
              await batch.commit();
            }
          }

          // Commit remaining updates
          if (updateCount % 500 !== 0) {
            await batch.commit();
          }

          console.log(`Updated ${updateCount} foods in database`);
        }

        // Count total uncategorized
        const totalQuery = onlyUncategorized
          ? db.collection(collection).where('foodCategory', '==', null)
          : db.collection(collection);
        const totalSnapshot = await totalQuery.count().get();
        const totalRemaining = totalSnapshot.data().count;

        res.json({
          success: true,
          processed: allResults.length,
          totalRemaining: onlyUncategorized ? totalRemaining : 'N/A',
          results: allResults,
          message: saveResults ? 'Categories saved to database' : 'Preview only - not saved'
        });

      } catch (error: any) {
        console.error('Database categorization error:', error);
        res.status(500).json({
          error: error.message || 'Categorization failed',
          details: error.response?.data || null
        });
      }
    });
  });

/**
 * HTTP Function: Get categorization statistics
 */
export const getCategorizeStats = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const { collection = 'verifiedFoods' } = req.query;
      const db = admin.firestore();

      // Get total count
      const totalSnapshot = await db.collection(collection as string).count().get();
      const total = totalSnapshot.data().count;

      // Get categorized count
      const categorizedSnapshot = await db.collection(collection as string)
        .where('foodCategory', '!=', null)
        .count()
        .get();
      const categorized = categorizedSnapshot.data().count;

      // Get counts per category (sample first 1000)
      const sampleSnapshot = await db.collection(collection as string)
        .where('foodCategory', '!=', null)
        .limit(1000)
        .get();

      const categoryCounts: Record<string, number> = {};
      sampleSnapshot.docs.forEach(doc => {
        const category = doc.data().foodCategory;
        if (category) {
          categoryCounts[category] = (categoryCounts[category] || 0) + 1;
        }
      });

      res.json({
        success: true,
        stats: {
          collection,
          total,
          categorized,
          uncategorized: total - categorized,
          percentCategorized: total > 0 ? Math.round((categorized / total) * 100) : 0,
          categorySample: categoryCounts,
          availableCategories: FOOD_CATEGORIES.map(c => ({ id: c.id, name: c.name }))
        }
      });

    } catch (error: any) {
      console.error('Stats error:', error);
      res.status(500).json({ error: error.message || 'Failed to get stats' });
    }
  });
});

/**
 * HTTP Function: Update a single food's category manually
 */
export const updateFoodCategory = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
      const { foodId, categoryId, collection = 'verifiedFoods' } = req.body;

      if (!foodId || !categoryId) {
        res.status(400).json({ error: 'foodId and categoryId are required' });
        return;
      }

      const category = getCategoryById(categoryId);
      if (!category) {
        res.status(400).json({ error: 'Invalid categoryId' });
        return;
      }

      const servingInfo = getServingSizeForCategory(categoryId);
      const db = admin.firestore();

      await db.collection(collection).doc(foodId).update({
        foodCategory: categoryId,
        foodCategoryName: category.name,
        suggestedServingSize: servingInfo?.size || 100,
        suggestedServingUnit: servingInfo?.unit || 'g',
        suggestedServingDescription: servingInfo?.description || 'per 100g',
        categoryConfidence: 'manual',
        categorizedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      res.json({
        success: true,
        message: `Food categorized as ${category.name}`,
        category: {
          id: categoryId,
          name: category.name,
          servingSize: servingInfo?.size,
          servingUnit: servingInfo?.unit,
          servingDescription: servingInfo?.description
        }
      });

    } catch (error: any) {
      console.error('Update category error:', error);
      res.status(500).json({ error: error.message || 'Failed to update category' });
    }
  });
});

/**
 * HTTP Function: Get all available categories
 */
export const getCategories = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    res.json({
      success: true,
      categories: FOOD_CATEGORIES.map(cat => ({
        id: cat.id,
        name: cat.name,
        description: cat.description,
        defaultServingSize: cat.defaultServingSize,
        servingUnit: cat.servingUnit,
        servingDescription: cat.servingDescription
      }))
    });
  });
});

/**
 * HTTP Function: Get foods for preview before categorization
 * GET ?collection=foods&limit=50&offset=0
 */
export const getFoodsForCategorization = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const {
        collection = 'foods',
        limit = '50',
        offset = '0'
      } = req.query;

      const db = admin.firestore();
      const limitNum = parseInt(limit as string) || 50;
      const offsetNum = parseInt(offset as string) || 0;

      // Get total count
      const totalSnapshot = await db.collection(collection as string).count().get();
      const total = totalSnapshot.data().count;

      // Get foods
      const snapshot = await db.collection(collection as string)
        .limit(limitNum)
        .offset(offsetNum)
        .get();

      const foods = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          foodName: data.foodName || data.name || 'Unknown',
          brandName: data.brandName || data.brand || '',
          currentCategory: data.foodCategory || null,
          currentCategoryName: data.foodCategoryName || null
        };
      });

      res.json({
        success: true,
        total,
        offset: offsetNum,
        limit: limitNum,
        foods
      });

    } catch (error: any) {
      console.error('Get foods error:', error);
      res.status(500).json({ error: error.message || 'Failed to get foods' });
    }
  });
});
