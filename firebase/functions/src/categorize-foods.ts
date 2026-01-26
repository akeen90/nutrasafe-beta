/**
 * AI Food Categorization using Gemini
 * Categorizes foods to enable intelligent serving size suggestions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';
import { FOOD_CATEGORIES, getCategoryDescriptions, getCategoryById, getServingSizeForCategory, CustomCategory, isValidNewCategoryId } from './food-categories';

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
 * Progress tracking interface
 */
interface CategorizationProgress {
  collection: string;
  currentOffset: number;
  totalProcessed: number;
  totalFoods: number;
  status: 'running' | 'complete' | 'stopped';
  lastUpdated: Date;
  newCategoriesCreated: number;
}

/**
 * Get current progress for a collection
 */
async function getProgress(collection: string): Promise<CategorizationProgress | null> {
  const db = admin.firestore();
  const doc = await db.collection('categorizationProgress').doc(collection).get();

  if (!doc.exists) return null;

  const data = doc.data()!;
  return {
    collection: data.collection,
    currentOffset: data.currentOffset || 0,
    totalProcessed: data.totalProcessed || 0,
    totalFoods: data.totalFoods || 0,
    status: data.status || 'stopped',
    lastUpdated: data.lastUpdated?.toDate() || new Date(),
    newCategoriesCreated: data.newCategoriesCreated || 0
  };
}

/**
 * Save progress for a collection
 */
async function saveProgress(progress: CategorizationProgress): Promise<void> {
  const db = admin.firestore();
  await db.collection('categorizationProgress').doc(progress.collection).set({
    ...progress,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });
}

/**
 * Reset progress for a collection (allows fresh start)
 */
async function resetProgress(collection: string): Promise<void> {
  const db = admin.firestore();
  await db.collection('categorizationProgress').doc(collection).delete();
}

/**
 * Load custom categories from Firestore
 */
async function loadCustomCategories(): Promise<CustomCategory[]> {
  const db = admin.firestore();
  const snapshot = await db.collection('customFoodCategories').get();

  return snapshot.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.name,
      description: data.description,
      defaultServingSize: data.defaultServingSize,
      servingUnit: data.servingUnit,
      servingDescription: data.servingDescription,
      createdAt: data.createdAt?.toDate() || new Date(),
      createdFor: data.createdFor || ''
    };
  });
}

/**
 * Save a new custom category to Firestore
 */
async function saveCustomCategory(category: CustomCategory): Promise<void> {
  const db = admin.firestore();
  await db.collection('customFoodCategories').doc(category.id).set({
    name: category.name,
    description: category.description,
    defaultServingSize: category.defaultServingSize,
    servingUnit: category.servingUnit,
    servingDescription: category.servingDescription,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdFor: category.createdFor
  });
  console.log(`Created new custom category: ${category.id} (${category.name})`);
}

/**
 * Build the categorization prompt for Gemini
 */
function buildCategorizationPrompt(foods: FoodToCategorize[], customCategories: CustomCategory[]): string {
  const categoryDescriptions = getCategoryDescriptions(customCategories);

  const foodList = foods.map((food, index) => {
    const parts = [`${index + 1}. "${food.foodName}"`];
    if (food.brandName) parts.push(`Brand: ${food.brandName}`);
    if (food.ingredients) {
      const ingredientsStr = Array.isArray(food.ingredients) ? food.ingredients.join(', ') : String(food.ingredients);
      parts.push(`Ingredients: ${ingredientsStr.substring(0, 100)}...`);
    }
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
- Consider the physical form: cans, bottles, packets, fresh items, etc.

IMPORTANT - CREATING NEW CATEGORIES:
- If a food does NOT fit any existing category well, you MAY create a NEW category
- Only create a new category if really necessary (existing categories don't fit)
- Do NOT use "unknown" - instead create an appropriate new category
- When creating a new category, include these extra fields: isNew, newCategoryName, newCategoryDescription, newServingSize, newServingUnit (g or ml), newServingDescription

CRITICAL - REALISTIC UK SERVING SIZES:
Serving sizes must reflect how much a SINGLE PERSON would eat in ONE sitting, NOT per 100g reference amounts.

SERVING SIZE GUIDELINES:
- Chocolate bars/sweets: 25-45g (one bar/small bag)
- Chocolate-covered snacks (raisins, nuts): 30-40g (small handful)
- Crisps/snacks: 25-35g (single bag)
- Biscuits/crackers: 25-35g (2-4 biscuits)
- Nuts/dried fruit (plain): 25-30g (small handful)
- Cereal: 30-45g (one bowl)
- Bread: 40-80g (1-2 slices)
- Yogurt: 125-150g (one pot)
- Canned goods: 150-200g (half a standard tin)
- Ready meals: 300-400g (one container)
- Fresh meat/fish: 100-150g (one portion)
- Cheese: 30-40g (matchbox-sized piece)
- Drinks: 250-330ml (one glass/can)
- Soup: 250-300g (one bowl)
- Ice cream: 60-100g (one scoop or small tub)
- Dips/spreads: 30-40g (with crackers/bread)
- Condiments: 15-30g (tablespoon)

NEVER use 100g as a default serving size unless it genuinely reflects a single portion!

RESPOND IN THIS EXACT JSON FORMAT (no markdown, just raw JSON):
[
  {"index": 1, "categoryId": "existing_category_id", "confidence": "high"},
  {"index": 2, "categoryId": "chocolate_covered_raisins", "confidence": "medium", "isNew": true, "newCategoryName": "Chocolate Covered Raisins", "newCategoryDescription": "Chocolate-coated dried raisins snack", "newServingSize": 35, "newServingUnit": "g", "newServingDescription": "small handful (35g)"}
]

Confidence levels:
- "high": Very clear match or new category is obviously correct
- "medium": Good match but could be ambiguous
- "low": Best guess`;
}

/**
 * Extract JSON from various response formats
 */
function extractJsonFromResponse(responseText: string): any[] {
  let jsonStr = responseText.trim();

  // Remove markdown code blocks
  if (jsonStr.includes('```')) {
    const match = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (match) {
      jsonStr = match[1].trim();
    } else {
      jsonStr = jsonStr.replace(/```json?\n?/g, '').replace(/```\n?/g, '').trim();
    }
  }

  // Try to find JSON array in the response
  const arrayMatch = jsonStr.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    jsonStr = arrayMatch[0];
  }

  // Clean up common issues
  jsonStr = jsonStr
    .replace(/,\s*]/g, ']')  // Remove trailing commas
    .replace(/,\s*}/g, '}')  // Remove trailing commas in objects
    .replace(/[\x00-\x1F\x7F]/g, ' '); // Remove control characters

  return JSON.parse(jsonStr);
}

/**
 * Call Gemini API to categorize foods with retry logic
 */
async function callGeminiForCategorization(foods: FoodToCategorize[], apiKey: string, customCategories: CustomCategory[]): Promise<any[]> {
  const prompt = buildCategorizationPrompt(foods, customCategories);
  const maxRetries = 3;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      // Using gemini-2.0-flash-lite - cheapest available model
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.1, // Low temperature for consistent categorization
            maxOutputTokens: 4096 // Increased for larger batches
          }
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 60000 // Increased timeout
        }
      );

      const responseText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

      if (!responseText) {
        console.error(`Attempt ${attempt}: Empty response from Gemini`);
        if (attempt === maxRetries) {
          // Return fallback results for all foods
          return foods.map((_, index) => ({
            index: index + 1,
            categoryId: 'uncategorized',
            confidence: 'low'
          }));
        }
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
        continue;
      }

      try {
        const parsed = extractJsonFromResponse(responseText);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed;
        }
        throw new Error('Parsed result is not a valid array');
      } catch (parseError) {
        console.error(`Attempt ${attempt}: Failed to parse Gemini response:`, responseText.substring(0, 500));
        if (attempt === maxRetries) {
          // Return fallback results
          console.log('Returning fallback results after all retries failed');
          return foods.map((_, index) => ({
            index: index + 1,
            categoryId: 'uncategorized',
            confidence: 'low'
          }));
        }
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    } catch (apiError: any) {
      console.error(`Attempt ${attempt}: Gemini API error:`, apiError.message);
      if (attempt === maxRetries) {
        // Return fallback results on API failure
        return foods.map((_, index) => ({
          index: index + 1,
          categoryId: 'uncategorized',
          confidence: 'low'
        }));
      }
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
    }
  }

  // Should never reach here, but just in case
  return foods.map((_, index) => ({
    index: index + 1,
    categoryId: 'uncategorized',
    confidence: 'low'
  }));
}

/**
 * Process categorization results (handles new categories)
 */
async function processResults(
  foods: FoodToCategorize[],
  geminiResults: any[],
  customCategories: CustomCategory[]
): Promise<{ results: CategorizationResult[], newCategories: CustomCategory[] }> {
  const newCategories: CustomCategory[] = [];

  const results = foods.map((food, index) => {
    const result = geminiResults.find(r => r.index === index + 1);
    let categoryId = result?.categoryId || 'unknown';
    const confidence = result?.confidence || 'low';

    // Check if this is a new category
    if (result?.isNew && isValidNewCategoryId(categoryId, customCategories)) {
      const newCategory: CustomCategory = {
        id: categoryId,
        name: result.newCategoryName || categoryId.replace(/_/g, ' ').replace(/\b\w/g, (c: string) => c.toUpperCase()),
        description: result.newCategoryDescription || `Category for ${food.foodName}`,
        defaultServingSize: result.newServingSize || 100,
        servingUnit: result.newServingUnit || 'g',
        servingDescription: result.newServingDescription || 'per 100g',
        createdAt: new Date(),
        createdFor: food.foodName
      };

      // Only add if not already in newCategories list (avoid duplicates in same batch)
      if (!newCategories.some(c => c.id === categoryId)) {
        newCategories.push(newCategory);
        // Also add to customCategories so subsequent items in same batch can use it
        customCategories.push(newCategory);
      }

      return {
        id: food.id,
        foodName: food.foodName,
        categoryId: categoryId,
        categoryName: newCategory.name,
        suggestedServingSize: newCategory.defaultServingSize,
        servingUnit: newCategory.servingUnit,
        servingDescription: newCategory.servingDescription,
        confidence: confidence as 'high' | 'medium' | 'low',
        isNewCategory: true
      };
    }

    // Existing category
    const category = getCategoryById(categoryId, customCategories);
    const servingInfo = getServingSizeForCategory(categoryId, customCategories);

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

  return { results, newCategories };
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

      // Load existing custom categories
      const customCategories = await loadCustomCategories();
      console.log(`Loaded ${customCategories.length} custom categories`);

      const apiKey = getGeminiApiKey();
      console.log(`Categorizing ${foods.length} foods...`);

      const geminiResults = await callGeminiForCategorization(foods, apiKey, customCategories);
      const { results, newCategories } = await processResults(foods, geminiResults, customCategories);

      // Save any new categories created
      for (const newCat of newCategories) {
        await saveCustomCategory(newCat);
      }

      console.log(`Successfully categorized ${results.length} foods, created ${newCategories.length} new categories`);
      res.json({
        success: true,
        results,
        newCategoriesCreated: newCategories.map(c => ({ id: c.id, name: c.name }))
      });

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
          collection = 'verifiedFoods',
          saveResults = true,
          resume = true  // If true, resume from saved progress; if false, start fresh
        } = req.body;

        const db = admin.firestore();
        const apiKey = getGeminiApiKey();

        // Get total count for this collection
        const totalSnapshot = await db.collection(collection).count().get();
        const totalFoods = totalSnapshot.data().count;

        // Check for existing progress
        let existingProgress = await getProgress(collection);
        let offset = 0;
        let totalProcessedSoFar = 0;
        let newCatsCreatedSoFar = 0;

        if (resume && existingProgress && existingProgress.status !== 'complete') {
          // Resume from where we left off
          offset = existingProgress.currentOffset;
          totalProcessedSoFar = existingProgress.totalProcessed;
          newCatsCreatedSoFar = existingProgress.newCategoriesCreated;
          console.log(`Resuming from offset ${offset} (${totalProcessedSoFar} already processed)`);
        } else if (!resume) {
          // Starting fresh - reset progress
          await resetProgress(collection);
          console.log(`Starting fresh categorization for ${collection}`);
        }

        // Load existing custom categories (once at start, we'll update it as new ones are created)
        let customCategories = await loadCustomCategories();
        console.log(`Loaded ${customCategories.length} custom categories`);

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
            foodName: data.foodName || data.name || data.title || data.productName || '',
            brandName: data.brandName || data.brand || '',
            ingredients: data.ingredients || data.extractedIngredients || data.ingredientsList || '',
            servingDescription: data.servingDescription || data.servingSize || data.servingInfo || ''
          };
        });

        console.log(`Fetched ${foods.length} foods from ${collection}`);

        // Process in batches of 20 for Gemini
        const batchSize = 20;
        const allResults: CategorizationResult[] = [];
        const allNewCategories: CustomCategory[] = [];

        for (let i = 0; i < foods.length; i += batchSize) {
          const batch = foods.slice(i, i + batchSize);
          console.log(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(foods.length / batchSize)}`);

          const geminiResults = await callGeminiForCategorization(batch, apiKey, customCategories);
          const { results, newCategories } = await processResults(batch, geminiResults, customCategories);
          allResults.push(...results);

          // Save any new categories immediately so they're available for future batches
          for (const newCat of newCategories) {
            if (!allNewCategories.some(c => c.id === newCat.id)) {
              await saveCustomCategory(newCat);
              allNewCategories.push(newCat);
              console.log(`Created new category: ${newCat.id} (${newCat.name})`);
            }
          }

          // Small delay between batches to avoid rate limiting
          if (i + batchSize < foods.length) {
            await new Promise(resolve => setTimeout(resolve, 50)); // 50ms delay between Gemini calls
          }
        }

        // Save results to database if requested
        if (saveResults) {
          const firestoreBatch = db.batch();
          let updateCount = 0;

          for (const result of allResults) {
            const docRef = db.collection(collection).doc(result.id);
            firestoreBatch.update(docRef, {
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
              await firestoreBatch.commit();
            }
          }

          // Commit remaining updates
          if (updateCount % 500 !== 0) {
            await firestoreBatch.commit();
          }

          console.log(`Updated ${updateCount} foods in database`);
        }

        // Calculate new totals
        const newTotalProcessed = totalProcessedSoFar + allResults.length;
        const newOffset = offset + allResults.length;
        const newCatsTotal = newCatsCreatedSoFar + allNewCategories.length;
        const hasMore = newOffset < totalFoods;

        // Save progress
        await saveProgress({
          collection,
          currentOffset: newOffset,
          totalProcessed: newTotalProcessed,
          totalFoods: totalFoods,
          status: hasMore ? 'running' : 'complete',
          lastUpdated: new Date(),
          newCategoriesCreated: newCatsTotal
        });

        console.log(`Progress saved: ${newTotalProcessed}/${totalFoods} (${hasMore ? 'more to process' : 'complete'})`);

        res.json({
          success: true,
          processed: allResults.length,
          totalProcessed: newTotalProcessed,
          totalFoods: totalFoods,
          currentOffset: newOffset,
          hasMore: hasMore,
          percentComplete: Math.round((newTotalProcessed / totalFoods) * 100),
          newCategoriesCreated: allNewCategories.map(c => ({ id: c.id, name: c.name })),
          totalNewCategories: newCatsTotal,
          results: allResults,
          message: hasMore
            ? `Processed ${newTotalProcessed}/${totalFoods} foods. More remaining.`
            : `Complete! All ${totalFoods} foods categorized.`
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

      // Load custom categories
      const customCategories = await loadCustomCategories();

      const allCategories = [
        ...FOOD_CATEGORIES.map(c => ({ id: c.id, name: c.name, isCustom: false })),
        ...customCategories.map(c => ({ id: c.id, name: c.name, isCustom: true }))
      ];

      res.json({
        success: true,
        stats: {
          collection,
          total,
          categorized,
          uncategorized: total - categorized,
          percentCategorized: total > 0 ? Math.round((categorized / total) * 100) : 0,
          categorySample: categoryCounts,
          availableCategories: allCategories,
          customCategoryCount: customCategories.length
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

      // Load custom categories to check for valid category
      const customCategories = await loadCustomCategories();

      const category = getCategoryById(categoryId, customCategories);
      if (!category) {
        res.status(400).json({ error: 'Invalid categoryId' });
        return;
      }

      const servingInfo = getServingSizeForCategory(categoryId, customCategories);
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
 * HTTP Function: Get all available categories (built-in + custom)
 */
export const getCategories = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      // Load custom categories
      const customCategories = await loadCustomCategories();

      const builtInCategories = FOOD_CATEGORIES.map(cat => ({
        id: cat.id,
        name: cat.name,
        description: cat.description,
        defaultServingSize: cat.defaultServingSize,
        servingUnit: cat.servingUnit,
        servingDescription: cat.servingDescription,
        isCustom: false
      }));

      const customCategoryList = customCategories.map(cat => ({
        id: cat.id,
        name: cat.name,
        description: cat.description,
        defaultServingSize: cat.defaultServingSize,
        servingUnit: cat.servingUnit,
        servingDescription: cat.servingDescription,
        isCustom: true,
        createdFor: cat.createdFor
      }));

      res.json({
        success: true,
        categories: [...builtInCategories, ...customCategoryList],
        builtInCount: builtInCategories.length,
        customCount: customCategoryList.length
      });
    } catch (error: any) {
      console.error('Get categories error:', error);
      res.status(500).json({ error: error.message || 'Failed to get categories' });
    }
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
          foodName: data.foodName || data.name || data.title || data.productName || 'Unknown',
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

/**
 * HTTP Function: Get categorization progress for a collection
 * GET ?collection=foods
 */
export const getCategorizationProgress = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const { collection = 'foods' } = req.query;
      const progress = await getProgress(collection as string);

      if (!progress) {
        res.json({
          success: true,
          hasProgress: false,
          message: 'No progress found for this collection'
        });
        return;
      }

      res.json({
        success: true,
        hasProgress: true,
        progress
      });

    } catch (error: any) {
      console.error('Get progress error:', error);
      res.status(500).json({ error: error.message || 'Failed to get progress' });
    }
  });
});

/**
 * HTTP Function: Reset categorization progress for a collection
 * POST body: { collection: string }
 */
export const resetCategorizationProgress = functions.https.onRequest((req, res) => {
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
      const { collection = 'foods' } = req.body;
      await resetProgress(collection);

      res.json({
        success: true,
        message: `Progress reset for ${collection}. Next scan will start from beginning.`
      });

    } catch (error: any) {
      console.error('Reset progress error:', error);
      res.status(500).json({ error: error.message || 'Failed to reset progress' });
    }
  });
});

// Realistic serving size corrections for common custom category types
const SERVING_SIZE_CORRECTIONS: Record<string, { size: number; description: string }> = {
  // Chocolate-covered items - small handful portions
  'chocolate_covered_raisins': { size: 35, description: 'small handful (35g)' },
  'chocolate_covered_nuts': { size: 35, description: 'small handful (35g)' },
  'chocolate_raisins': { size: 35, description: 'small handful (35g)' },
  'chocolate_nuts': { size: 35, description: 'small handful (35g)' },
  'chocolate_peanuts': { size: 35, description: 'small handful (35g)' },
  'chocolate_almonds': { size: 35, description: 'small handful (35g)' },
  // Crackers and rice cakes
  'crackers': { size: 30, description: '3-4 crackers (30g)' },
  'rice_cakes': { size: 20, description: '2 rice cakes (20g)' },
  'corn_thins': { size: 20, description: '2-3 corn thins (20g)' },
  'rice_crackers': { size: 30, description: '6-8 crackers (30g)' },
  // Canned goods
  'canned_meat': { size: 80, description: 'half tin serving (80g)' },
  'canned_fish': { size: 80, description: 'half tin serving (80g)' },
  'canned_vegetables': { size: 80, description: 'side serving (80g)' },
  // Snack items
  'trail_mix': { size: 35, description: 'small handful (35g)' },
  'mixed_nuts': { size: 30, description: 'small handful (30g)' },
  'dried_fruit': { size: 30, description: 'small handful (30g)' },
  'popcorn': { size: 25, description: 'small bag (25g)' },
  'pretzels': { size: 30, description: 'small handful (30g)' },
  // Confectionery
  'fudge': { size: 30, description: '2 pieces (30g)' },
  'toffee': { size: 25, description: '3-4 pieces (25g)' },
  'hard_candy': { size: 20, description: '4-5 pieces (20g)' },
  'marshmallows': { size: 30, description: '4-5 marshmallows (30g)' },
  // Baked goods
  'cookies': { size: 30, description: '2 cookies (30g)' },
  'biscuits': { size: 30, description: '2-3 biscuits (30g)' },
  'shortbread': { size: 25, description: '2 fingers (25g)' },
  // Spreads
  'nut_butter': { size: 20, description: '1 tablespoon (20g)' },
  'chocolate_spread': { size: 20, description: '1 tablespoon (20g)' },
  'jam': { size: 15, description: '1 tablespoon (15g)' },
  'honey': { size: 15, description: '1 tablespoon (15g)' },
};

/**
 * HTTP Function: Fix custom categories with unrealistic serving sizes
 * POST body: { dryRun?: boolean }
 */
export const fixCustomCategoryServingSizes = functions.https.onRequest((req, res) => {
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
      const { dryRun = false } = req.body;
      const db = admin.firestore();

      // Load all custom categories
      const customCategoriesSnapshot = await db.collection('customFoodCategories').get();

      const updates: Array<{ id: string; oldSize: number; newSize: number; newDescription: string }> = [];
      const alreadyGood: string[] = [];

      for (const doc of customCategoriesSnapshot.docs) {
        const data = doc.data();
        const categoryId = data.id || doc.id;
        const currentSize = data.defaultServingSize;

        // Check if this category has a known correction
        const correction = SERVING_SIZE_CORRECTIONS[categoryId];

        if (correction) {
          if (currentSize !== correction.size) {
            updates.push({
              id: categoryId,
              oldSize: currentSize,
              newSize: correction.size,
              newDescription: correction.description
            });

            if (!dryRun) {
              await doc.ref.update({
                defaultServingSize: correction.size,
                servingDescription: correction.description
              });
            }
          } else {
            alreadyGood.push(categoryId);
          }
        } else if (currentSize >= 100) {
          // Flag categories with 100g+ serving sizes that might need manual review
          // Try to guess a better size based on category name
          let suggestedSize = currentSize;
          let suggestedDescription = data.servingDescription;
          const name = (data.name || categoryId).toLowerCase();

          if (name.includes('chocolate') && (name.includes('raisin') || name.includes('nut') || name.includes('covered'))) {
            suggestedSize = 35;
            suggestedDescription = 'small handful (35g)';
          } else if (name.includes('cracker') || name.includes('crisp')) {
            suggestedSize = 30;
            suggestedDescription = '3-4 crackers (30g)';
          } else if (name.includes('biscuit') || name.includes('cookie')) {
            suggestedSize = 30;
            suggestedDescription = '2-3 biscuits (30g)';
          } else if (name.includes('nut') || name.includes('seed')) {
            suggestedSize = 30;
            suggestedDescription = 'small handful (30g)';
          } else if (name.includes('candy') || name.includes('sweet') || name.includes('fudge') || name.includes('toffee')) {
            suggestedSize = 25;
            suggestedDescription = '2-3 pieces (25g)';
          } else if (name.includes('spread') || name.includes('butter')) {
            suggestedSize = 20;
            suggestedDescription = '1 tablespoon (20g)';
          } else if (name.includes('dried') || name.includes('fruit')) {
            suggestedSize = 30;
            suggestedDescription = 'small handful (30g)';
          }

          if (suggestedSize !== currentSize) {
            updates.push({
              id: categoryId,
              oldSize: currentSize,
              newSize: suggestedSize,
              newDescription: suggestedDescription
            });

            if (!dryRun) {
              await doc.ref.update({
                defaultServingSize: suggestedSize,
                servingDescription: suggestedDescription
              });
            }
          }
        }
      }

      res.json({
        success: true,
        dryRun,
        message: dryRun ? 'Dry run - no changes made' : `Fixed ${updates.length} custom category serving sizes`,
        totalCustomCategories: customCategoriesSnapshot.size,
        updated: updates,
        alreadyCorrect: alreadyGood,
        updateCount: updates.length
      });

    } catch (error: any) {
      console.error('Fix serving sizes error:', error);
      res.status(500).json({ error: error.message || 'Failed to fix serving sizes' });
    }
  });
});

/**
 * HTTP Function: Fix foods that have wrong serving sizes based on their categories
 * POST body: { collection?: string, dryRun?: boolean, batchSize?: number }
 */
export const fixFoodServingSizes = functions
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
        collection = 'verifiedFoods',
        dryRun = false,
        batchSize = 500
      } = req.body;

      const db = admin.firestore();

      // Load all custom categories with their correct serving sizes
      const customCategories = await loadCustomCategories();

      // Build a map of category ID -> correct serving info
      const categoryServingSizes: Record<string, { size: number; unit: string; description: string }> = {};

      // Add built-in categories
      for (const cat of FOOD_CATEGORIES) {
        categoryServingSizes[cat.id] = {
          size: cat.defaultServingSize,
          unit: cat.servingUnit,
          description: cat.servingDescription
        };
      }

      // Add custom categories (these now have the corrected sizes)
      for (const cat of customCategories) {
        categoryServingSizes[cat.id] = {
          size: cat.defaultServingSize,
          unit: cat.servingUnit,
          description: cat.servingDescription
        };
      }

      // Query all foods that have a category assigned
      const snapshot = await db.collection(collection)
        .where('foodCategory', '!=', null)
        .limit(batchSize)
        .get();

      if (snapshot.empty) {
        res.json({
          success: true,
          message: 'No categorized foods found',
          updated: 0
        });
        return;
      }

      const updates: Array<{ id: string; name: string; category: string; oldSize: number; newSize: number }> = [];
      const batch = db.batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const categoryId = data.foodCategory;
        const currentSize = data.suggestedServingSize;

        // Get the correct serving size for this category
        const correctServing = categoryServingSizes[categoryId];

        if (correctServing && currentSize !== correctServing.size) {
          updates.push({
            id: doc.id,
            name: data.foodName || data.name || 'Unknown',
            category: categoryId,
            oldSize: currentSize,
            newSize: correctServing.size
          });

          if (!dryRun) {
            batch.update(doc.ref, {
              suggestedServingSize: correctServing.size,
              suggestedServingUnit: correctServing.unit,
              suggestedServingDescription: correctServing.description
            });
            batchCount++;
          }
        }
      }

      if (!dryRun && batchCount > 0) {
        await batch.commit();
      }

      // Check if there are more foods to process
      const totalSnapshot = await db.collection(collection)
        .where('foodCategory', '!=', null)
        .count()
        .get();
      const totalCategorized = totalSnapshot.data().count;
      const hasMore = snapshot.size === batchSize;

      res.json({
        success: true,
        dryRun,
        message: dryRun
          ? `Dry run - found ${updates.length} foods needing updates`
          : `Updated ${updates.length} food serving sizes`,
        collection,
        processed: snapshot.size,
        totalCategorized,
        updated: updates.length,
        hasMore,
        samples: updates.slice(0, 20) // Show first 20 as samples
      });

    } catch (error: any) {
      console.error('Fix food serving sizes error:', error);
      res.status(500).json({ error: error.message || 'Failed to fix food serving sizes' });
    }
  });
});

/**
 * HTTP Function: Batch save approved food categorizations
 * Updates both Firestore (where applicable) and Algolia directly
 * POST body: { foods: Array<{ objectID, sourceIndex, categoryId, servingSizeG, servingValidated }> }
 */
import { algoliasearch } from 'algoliasearch';

const ALGOLIA_APP_ID = 'WK0TIF84M2';
const getAlgoliaAdminKey = () => functions.config().algolia?.admin_key || process.env.ALGOLIA_ADMIN_API_KEY || '';

// Mapping from Algolia index to Firestore collection
const INDEX_TO_COLLECTION: Record<string, string | null> = {
  'verified_foods': 'verifiedFoods',
  'foods': 'foods',
  'manual_foods': 'manualFoods',
  'user_added': 'userAdded',
  'ai_enhanced': 'aiEnhanced',
  'ai_manually_added': 'aiManuallyAdded',
  'tesco_products': 'tescoProducts',
  'uk_foods_cleaned': null,        // Algolia-only
  'fast_foods_database': null,     // Algolia-only
  'generic_database': null,        // Algolia-only
  'consumer_foods': 'consumer_foods',
};

export const batchSaveFoodCategories = functions
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
      const { foods } = req.body;

      if (!foods || !Array.isArray(foods) || foods.length === 0) {
        res.status(400).json({ error: 'foods array is required' });
        return;
      }

      const adminKey = getAlgoliaAdminKey();
      if (!adminKey) {
        res.status(500).json({ error: 'Algolia admin key not configured' });
        return;
      }

      const client = algoliasearch(ALGOLIA_APP_ID, adminKey);
      const db = admin.firestore();
      const customCategories = await loadCustomCategories();

      const results = {
        total: foods.length,
        firestoreUpdated: 0,
        algoliaUpdated: 0,
        errors: [] as string[],
      };

      // Group foods by source index for batch processing
      const foodsByIndex: Record<string, typeof foods> = {};
      for (const food of foods) {
        const index = food.sourceIndex || 'unknown';
        if (!foodsByIndex[index]) foodsByIndex[index] = [];
        foodsByIndex[index].push(food);
      }

      // Process each index
      for (const [indexName, indexFoods] of Object.entries(foodsByIndex)) {
        const firestoreCollection = INDEX_TO_COLLECTION[indexName];

        // Get category info for each food
        const updateData = indexFoods.map(food => {
          const category = getCategoryById(food.categoryId, customCategories);
          const servingInfo = getServingSizeForCategory(food.categoryId, customCategories);

          // Priority: 1) passed servingSizeG from categorizer, 2) category default, 3) fallback 100g
          // The categorizer already applies its tiered logic (validated > pack_size > category_default)
          // so we should trust what it sends
          const finalServingSize = food.servingSizeG && food.servingSizeG > 0
            ? food.servingSizeG
            : (servingInfo?.size || 100);

          return {
            objectID: food.objectID,
            categoryId: food.categoryId,
            categoryName: category?.name || 'Unknown',
            servingSizeG: finalServingSize,
            servingUnit: servingInfo?.unit || 'g',
            servingDescription: servingInfo?.description || 'per serving',
            servingValidated: food.servingValidated || false,
          };
        });

        // Update Firestore if this index has a backing collection
        if (firestoreCollection) {
          let batch = db.batch();
          let batchCount = 0;

          for (const data of updateData) {
            const docRef = db.collection(firestoreCollection).doc(data.objectID);
            batch.update(docRef, {
              foodCategory: data.categoryId,
              foodCategoryName: data.categoryName,
              // Update BOTH fields - servingSizeG is what the app uses for display/calculation
              servingSizeG: data.servingSizeG,
              serving_size_g: data.servingSizeG, // Also update snake_case version
              suggestedServingSize: data.servingSizeG,
              suggestedServingUnit: data.servingUnit,
              suggestedServingDescription: data.servingDescription,
              servingValidated: data.servingValidated,
              categoryConfidence: 'ai_reviewed',
              categorizedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            batchCount++;

            // Firestore batches have a 500 operation limit
            if (batchCount >= 500) {
              await batch.commit();
              results.firestoreUpdated += batchCount;
              batch = db.batch(); // Create a NEW batch after committing
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            await batch.commit();
            results.firestoreUpdated += batchCount;
          }

          // Note: Algolia will be updated automatically via Firestore triggers
          // for collections that have sync triggers
        } else {
          // Algolia-only index - update directly
          const algoliaUpdates = updateData.map(data => ({
            objectID: data.objectID,
            foodCategory: data.categoryId,
            foodCategoryName: data.categoryName,
            // Update BOTH fields - servingSizeG is what the app uses for display/calculation
            servingSizeG: data.servingSizeG,
            serving_size_g: data.servingSizeG, // Also update snake_case version
            suggestedServingSize: data.servingSizeG,
            suggestedServingUnit: data.servingUnit,
            suggestedServingDescription: data.servingDescription,
            servingValidated: data.servingValidated,
            categoryConfidence: 'ai_reviewed',
            categorizedAt: new Date().toISOString(),
          }));

          // Batch update in chunks of 1000
          const BATCH_SIZE = 1000;
          for (let i = 0; i < algoliaUpdates.length; i += BATCH_SIZE) {
            const batch = algoliaUpdates.slice(i, i + BATCH_SIZE);
            await client.partialUpdateObjects({
              indexName,
              objects: batch,
              createIfNotExists: false,
            });
            results.algoliaUpdated += batch.length;
          }
        }
      }

      res.json({
        success: true,
        message: `Saved ${results.total} food categorizations`,
        ...results,
      });

    } catch (error: any) {
      console.error('Batch save categories error:', error);
      res.status(500).json({ error: error.message || 'Failed to save categories' });
    }
  });
});
