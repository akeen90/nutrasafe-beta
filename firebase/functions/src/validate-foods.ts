/**
 * AI Food Data Validation using Gemini
 * Validates and cleans food data using AI knowledge:
 * - Fixes product name formatting/spelling
 * - Fixes brand formatting/spelling
 * - Cleans ingredients (UK spelling, proper formatting)
 * - Identifies non-UK/discontinued products
 * - Validates and fixes calories
 * - Validates serving sizes
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const cors = require('cors')({ origin: true });

interface FoodToValidate {
  id: string;
  foodName: string;
  brandName?: string;
  ingredients?: string | string[];
  calories?: number;
  servingSize?: number;
  servingUnit?: string;
  protein?: number;
  carbs?: number;
  fat?: number;
}

interface ValidationResult {
  id: string;
  originalFood: {
    foodName: string;
    brandName?: string;
    ingredients?: string;
    calories?: number;
    servingSize?: number;
  };
  validatedFood: {
    foodName: string;
    brandName?: string;
    ingredients?: string;
    calories?: number;
    servingSize?: number;
    servingUnit?: string;
  };
  changes: string[];
  issues: string[];
  action: 'update' | 'delete' | 'review' | 'none';
  deleteReason?: string;
  confidence: 'high' | 'medium' | 'low';
}

interface ValidationProgress {
  collection: string;
  currentOffset: number;
  totalProcessed: number;
  totalFoods: number;
  updatedCount: number;
  markedForDeletionCount: number;
  status: 'running' | 'complete' | 'stopped';
  lastUpdated: Date;
}

/**
 * Get Gemini API key
 */
function getGeminiApiKey(): string {
  const configKey = functions.config().gemini?.api_key;
  const envKey = process.env.GEMINI_API_KEY;

  if (configKey) return configKey;
  if (envKey) return envKey;

  throw new functions.https.HttpsError('failed-precondition', 'Gemini API key not configured');
}

/**
 * Get validation progress
 */
async function getProgress(collection: string): Promise<ValidationProgress | null> {
  const db = admin.firestore();
  const doc = await db.collection('validationProgress').doc(collection).get();

  if (!doc.exists) return null;

  const data = doc.data()!;
  return {
    collection: data.collection,
    currentOffset: data.currentOffset || 0,
    totalProcessed: data.totalProcessed || 0,
    totalFoods: data.totalFoods || 0,
    updatedCount: data.updatedCount || 0,
    markedForDeletionCount: data.markedForDeletionCount || 0,
    status: data.status || 'stopped',
    lastUpdated: data.lastUpdated?.toDate() || new Date()
  };
}

/**
 * Save validation progress
 */
async function saveProgress(progress: ValidationProgress): Promise<void> {
  const db = admin.firestore();
  await db.collection('validationProgress').doc(progress.collection).set({
    ...progress,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  });
}

/**
 * Build the validation prompt for Gemini
 */
function buildValidationPrompt(foods: FoodToValidate[]): string {
  const foodList = foods.map((food, index) => {
    const parts = [`${index + 1}. Name: "${food.foodName}"`];
    if (food.brandName) parts.push(`Brand: "${food.brandName}"`);
    if (food.ingredients) {
      const ingredientsStr = Array.isArray(food.ingredients)
        ? food.ingredients.join(', ')
        : String(food.ingredients);
      parts.push(`Ingredients: "${ingredientsStr.substring(0, 300)}"`);
    }
    if (food.calories !== undefined) parts.push(`Calories: ${food.calories} kcal/100g`);
    if (food.servingSize !== undefined) parts.push(`Serving: ${food.servingSize}${food.servingUnit || 'g'}`);
    if (food.protein !== undefined) parts.push(`Protein: ${food.protein}g`);
    if (food.carbs !== undefined) parts.push(`Carbs: ${food.carbs}g`);
    if (food.fat !== undefined) parts.push(`Fat: ${food.fat}g`);
    return parts.join(' | ');
  }).join('\n');

  return `You are a UK food data validation expert. Review each food item and clean/validate the data using your knowledge.

FOOD ITEMS TO VALIDATE:
${foodList}

VALIDATION TASKS:

1. **PRODUCT NAME CLEANING**:
   - Fix spelling errors and typos
   - Use proper UK English spelling (e.g., "Flavoured" not "Flavored")
   - Fix capitalisation (proper case for product names)
   - Remove unnecessary characters, extra spaces, or dirty data
   - Standardise format (Brand Name - Product Description)

2. **BRAND NAME CLEANING**:
   - Fix spelling of brand names
   - Use official brand capitalisation (e.g., "Cadbury", "Heinz", "Tesco")
   - Remove "Ltd", "PLC", etc. unless part of product name

3. **INGREDIENTS CLEANING**:
   - Use UK spelling throughout (colour, flavour, fibre, aluminium, etc.)
   - Fix ingredient spelling errors
   - Clean up formatting (proper commas, remove duplicates)
   - Remove dirty data (random characters, encoding issues)
   - Standardise format: "Ingredient1, Ingredient2, Ingredient3"
   - Use parentheses for sub-ingredients: "Chocolate (Cocoa Mass, Sugar, Cocoa Butter)"

4. **IDENTIFY PRODUCTS TO DELETE** (mark action: "delete"):
   - Non-UK products that shouldn't be in UK database (e.g., "Coke Light" - US product, UK uses "Diet Coke")
   - Products with foreign language names that aren't sold in UK
   - Discontinued products you know are no longer available
   - Duplicate/corrupted entries with garbled names
   - Products with nonsensical or incomplete data

5. **CALORIE VALIDATION**:
   - Check if calories are plausible for the food type
   - Common ranges: Most foods 50-500 kcal/100g, oils/nuts 500-900, pure sugar ~400
   - If wildly wrong (e.g., bread at 1000 kcal or chocolate at 50 kcal), suggest correct value or mark for deletion
   - Cross-check: Calories should roughly equal (protein*4 + carbs*4 + fat*9)

6. **SERVING SIZE VALIDATION**:
   - If you KNOW the correct serving size for a branded product, suggest it
   - Common UK servings: Chocolate bar 30-50g, Crisps 25-35g, Yoghurt 125-150g, Cereal 30-45g
   - Only suggest if confident, otherwise leave as-is

RESPOND IN THIS EXACT JSON FORMAT (no markdown, just raw JSON):
[
  {
    "index": 1,
    "action": "update",
    "confidence": "high",
    "changes": ["Fixed spelling: 'Choclate' to 'Chocolate'", "UK spelling for ingredients"],
    "issues": [],
    "validatedFood": {
      "foodName": "Cadbury Dairy Milk Chocolate Bar",
      "brandName": "Cadbury",
      "ingredients": "Milk, Sugar, Cocoa Butter, Cocoa Mass, Vegetable Fats, Emulsifiers (E442, E476), Flavourings",
      "servingSize": 45
    }
  },
  {
    "index": 2,
    "action": "delete",
    "confidence": "high",
    "deleteReason": "Coke Light is US product - UK equivalent is Diet Coke",
    "changes": [],
    "issues": ["Non-UK product"]
  },
  {
    "index": 3,
    "action": "none",
    "confidence": "high",
    "changes": [],
    "issues": [],
    "validatedFood": {}
  }
]

ACTION VALUES:
- "update": Data needs corrections - apply validatedFood changes
- "delete": Product should be removed from UK database
- "review": Needs human review (uncertain data)
- "none": Data is already correct, no changes needed

Only include fields in validatedFood that need to be changed. Empty validatedFood = no changes.
For calories, only include if you're confident in the correction.`;
}

/**
 * Extract JSON from Gemini response
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

  // Find JSON array
  const arrayMatch = jsonStr.match(/\[[\s\S]*\]/);
  if (arrayMatch) {
    jsonStr = arrayMatch[0];
  }

  // Clean up
  jsonStr = jsonStr
    .replace(/,\s*]/g, ']')
    .replace(/,\s*}/g, '}')
    .replace(/[\x00-\x1F\x7F]/g, ' ');

  return JSON.parse(jsonStr);
}

/**
 * Call Gemini for validation
 */
async function callGeminiForValidation(foods: FoodToValidate[], apiKey: string): Promise<any[]> {
  const prompt = buildValidationPrompt(foods);
  const maxRetries = 3;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${apiKey}`,
        {
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 8192
          }
        },
        {
          headers: { 'Content-Type': 'application/json' },
          timeout: 90000
        }
      );

      const responseText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

      if (!responseText) {
        console.error(`Attempt ${attempt}: Empty response from Gemini`);
        if (attempt === maxRetries) {
          return foods.map((_, index) => ({
            index: index + 1,
            action: 'none',
            confidence: 'low',
            changes: [],
            issues: ['AI validation failed'],
            validatedFood: {}
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
        throw new Error('Invalid response format');
      } catch (parseError) {
        console.error(`Attempt ${attempt}: Failed to parse response:`, responseText.substring(0, 500));
        if (attempt === maxRetries) {
          return foods.map((_, index) => ({
            index: index + 1,
            action: 'none',
            confidence: 'low',
            changes: [],
            issues: ['Failed to parse AI response'],
            validatedFood: {}
          }));
        }
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    } catch (apiError: any) {
      console.error(`Attempt ${attempt}: API error:`, apiError.message);
      if (attempt === maxRetries) {
        return foods.map((_, index) => ({
          index: index + 1,
          action: 'none',
          confidence: 'low',
          changes: [],
          issues: ['API error'],
          validatedFood: {}
        }));
      }
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
    }
  }

  return [];
}

/**
 * Process validation results
 */
function processResults(foods: FoodToValidate[], geminiResults: any[]): ValidationResult[] {
  return foods.map((food, index) => {
    const result = geminiResults.find(r => r.index === index + 1) || {
      action: 'none',
      confidence: 'low',
      changes: [],
      issues: [],
      validatedFood: {}
    };

    const ingredientsStr = food.ingredients
      ? (Array.isArray(food.ingredients) ? food.ingredients.join(', ') : String(food.ingredients))
      : undefined;

    return {
      id: food.id,
      originalFood: {
        foodName: food.foodName,
        brandName: food.brandName,
        ingredients: ingredientsStr,
        calories: food.calories,
        servingSize: food.servingSize
      },
      validatedFood: result.validatedFood || {},
      changes: result.changes || [],
      issues: result.issues || [],
      action: result.action || 'none',
      deleteReason: result.deleteReason,
      confidence: result.confidence || 'low'
    };
  });
}

/**
 * HTTP Function: Validate foods from database
 */
export const validateFoodsFromDatabase = functions
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
          collection = 'uk_foods_cleaned',
          saveResults = true,
          resume = true
        } = req.body;

        const db = admin.firestore();
        const apiKey = getGeminiApiKey();

        // Get total count
        const totalSnapshot = await db.collection(collection).count().get();
        const totalFoods = totalSnapshot.data().count;

        // Check for existing progress
        let existingProgress = await getProgress(collection);
        let offset = 0;
        let totalProcessedSoFar = 0;
        let updatedCountSoFar = 0;
        let markedForDeletionSoFar = 0;

        if (resume && existingProgress && existingProgress.status !== 'complete') {
          offset = existingProgress.currentOffset;
          totalProcessedSoFar = existingProgress.totalProcessed;
          updatedCountSoFar = existingProgress.updatedCount;
          markedForDeletionSoFar = existingProgress.markedForDeletionCount;
          console.log(`Resuming from offset ${offset} (${totalProcessedSoFar} already processed)`);
        } else if (!resume) {
          await db.collection('validationProgress').doc(collection).delete().catch(() => {});
          await db.collection('markedForDeletion').doc(collection).delete().catch(() => {});
        }

        // Fetch foods
        const foodsSnapshot = await db.collection(collection)
          .offset(offset)
          .limit(limit)
          .get();

        if (foodsSnapshot.empty) {
          // Mark as complete
          await saveProgress({
            collection,
            currentOffset: totalFoods,
            totalProcessed: totalFoods,
            totalFoods,
            updatedCount: updatedCountSoFar,
            markedForDeletionCount: markedForDeletionSoFar,
            status: 'complete',
            lastUpdated: new Date()
          });

          res.json({
            success: true,
            processed: 0,
            totalProcessed: totalFoods,
            totalFoods,
            hasMore: false,
            percentComplete: 100,
            message: 'Validation complete'
          });
          return;
        }

        // Convert to validation format
        const foods: FoodToValidate[] = foodsSnapshot.docs.map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            foodName: data.foodName || data.name || '',
            brandName: data.brandName || data.brand,
            ingredients: data.ingredients,
            calories: data.calories || data.kcal || data.energy,
            servingSize: data.servingSize || data.serving_size,
            servingUnit: data.servingUnit || data.serving_unit || 'g',
            protein: data.protein,
            carbs: data.carbs || data.carbohydrates,
            fat: data.fat || data.fats
          };
        });

        console.log(`Validating ${foods.length} foods from ${collection}...`);

        // Process in batches of 15 for Gemini
        const batchSize = 15;
        const allResults: ValidationResult[] = [];
        let updatedCount = 0;
        let markedForDeletion: any[] = [];

        for (let i = 0; i < foods.length; i += batchSize) {
          const batch = foods.slice(i, i + batchSize);
          const geminiResults = await callGeminiForValidation(batch, apiKey);
          const results = processResults(batch, geminiResults);
          allResults.push(...results);

          // Save results if requested
          if (saveResults) {
            const writeBatch = db.batch();

            for (const result of results) {
              if (result.action === 'update' && Object.keys(result.validatedFood).length > 0) {
                const docRef = db.collection(collection).doc(result.id);
                const updateData: any = {
                  ...result.validatedFood,
                  lastValidated: admin.firestore.FieldValue.serverTimestamp(),
                  validationChanges: result.changes
                };
                writeBatch.update(docRef, updateData);
                updatedCount++;
              } else if (result.action === 'delete') {
                markedForDeletion.push({
                  id: result.id,
                  foodName: result.originalFood.foodName,
                  brandName: result.originalFood.brandName,
                  reason: result.deleteReason || 'Marked for deletion by AI',
                  confidence: result.confidence,
                  markedAt: new Date().toISOString()
                });
              }
            }

            await writeBatch.commit();
          }

          // Small delay between batches
          if (i + batchSize < foods.length) {
            await new Promise(resolve => setTimeout(resolve, 100));
          }
        }

        // Save marked for deletion items
        if (saveResults && markedForDeletion.length > 0) {
          const deletionDoc = db.collection('markedForDeletion').doc(collection);
          const existingDeletions = await deletionDoc.get();
          const existingItems = existingDeletions.exists ? (existingDeletions.data()?.items || []) : [];

          await deletionDoc.set({
            items: [...existingItems, ...markedForDeletion],
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
          });
        }

        // Update progress
        const newOffset = offset + foods.length;
        const newTotalProcessed = totalProcessedSoFar + foods.length;
        const newUpdatedCount = updatedCountSoFar + updatedCount;
        const newMarkedForDeletion = markedForDeletionSoFar + markedForDeletion.length;
        const hasMore = newOffset < totalFoods;

        await saveProgress({
          collection,
          currentOffset: newOffset,
          totalProcessed: newTotalProcessed,
          totalFoods,
          updatedCount: newUpdatedCount,
          markedForDeletionCount: newMarkedForDeletion,
          status: hasMore ? 'running' : 'complete',
          lastUpdated: new Date()
        });

        const percentComplete = Math.round((newTotalProcessed / totalFoods) * 100);

        res.json({
          success: true,
          processed: foods.length,
          totalProcessed: newTotalProcessed,
          totalFoods,
          hasMore,
          percentComplete,
          updatedCount: newUpdatedCount,
          markedForDeletionCount: newMarkedForDeletion,
          results: allResults.slice(0, 100) // Return last 100 for display
        });

      } catch (error: any) {
        console.error('Validation error:', error);
        res.status(500).json({
          error: error.message || 'Validation failed',
          details: error.response?.data || null
        });
      }
    });
  });

/**
 * Get validation statistics
 */
export const getValidationStats = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const collection = req.query.collection as string || 'uk_foods_cleaned';
      const db = admin.firestore();

      // Get total count
      const totalSnapshot = await db.collection(collection).count().get();
      const total = totalSnapshot.data().count;

      // Get validated count (foods with lastValidated field)
      const validatedSnapshot = await db.collection(collection)
        .where('lastValidated', '!=', null)
        .count()
        .get();
      const validated = validatedSnapshot.data().count;

      // Get marked for deletion count
      const deletionDoc = await db.collection('markedForDeletion').doc(collection).get();
      const markedForDeletion = deletionDoc.exists ? (deletionDoc.data()?.items?.length || 0) : 0;

      res.json({
        success: true,
        stats: {
          total,
          validated,
          unvalidated: total - validated,
          percentValidated: total > 0 ? Math.round((validated / total) * 100) : 0,
          markedForDeletion
        }
      });

    } catch (error: any) {
      console.error('Error getting validation stats:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Get validation progress
 */
export const getValidationProgress = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const collection = req.query.collection as string || 'uk_foods_cleaned';
      const progress = await getProgress(collection);

      if (progress) {
        res.json({
          success: true,
          hasProgress: true,
          progress
        });
      } else {
        res.json({
          success: true,
          hasProgress: false
        });
      }

    } catch (error: any) {
      console.error('Error getting progress:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Reset validation progress
 */
export const resetValidationProgress = functions.https.onRequest((req, res) => {
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
      const { collection = 'uk_foods_cleaned' } = req.body;
      const db = admin.firestore();

      await db.collection('validationProgress').doc(collection).delete();

      res.json({
        success: true,
        message: `Validation progress reset for ${collection}`
      });

    } catch (error: any) {
      console.error('Error resetting progress:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Get foods for validation preview
 */
export const getFoodsForValidation = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const collection = req.query.collection as string || 'uk_foods_cleaned';
      const limit = parseInt(req.query.limit as string) || 50;
      const db = admin.firestore();

      // Get total count
      const totalSnapshot = await db.collection(collection).count().get();
      const total = totalSnapshot.data().count;

      // Get sample foods
      const foodsSnapshot = await db.collection(collection)
        .limit(limit)
        .get();

      const foods = foodsSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          foodName: data.foodName || data.name || 'Unknown',
          brandName: data.brandName || data.brand,
          calories: data.calories || data.kcal,
          hasIngredients: !!(data.ingredients &&
            (Array.isArray(data.ingredients) ? data.ingredients.length > 0 : data.ingredients.length > 0)),
          lastValidated: data.lastValidated ? 'Validated' : 'Not validated'
        };
      });

      res.json({
        success: true,
        total,
        foods
      });

    } catch (error: any) {
      console.error('Error getting foods:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Get items marked for deletion
 */
export const getMarkedForDeletion = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      const collection = req.query.collection as string || 'uk_foods_cleaned';
      const db = admin.firestore();

      const deletionDoc = await db.collection('markedForDeletion').doc(collection).get();

      if (!deletionDoc.exists) {
        res.json({
          success: true,
          items: [],
          count: 0
        });
        return;
      }

      const items = deletionDoc.data()?.items || [];

      res.json({
        success: true,
        items,
        count: items.length
      });

    } catch (error: any) {
      console.error('Error getting marked items:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Delete items marked for deletion
 */
export const deleteMarkedItems = functions.https.onRequest((req, res) => {
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
      const { collection = 'uk_foods_cleaned', itemIds } = req.body;
      const db = admin.firestore();

      if (!itemIds || !Array.isArray(itemIds) || itemIds.length === 0) {
        res.status(400).json({ error: 'itemIds array is required' });
        return;
      }

      // Delete from main collection
      const batch = db.batch();
      let deletedCount = 0;

      for (const id of itemIds) {
        const docRef = db.collection(collection).doc(id);
        batch.delete(docRef);
        deletedCount++;

        // Firestore batch limit
        if (deletedCount >= 500) break;
      }

      await batch.commit();

      // Update marked for deletion list
      const deletionDoc = db.collection('markedForDeletion').doc(collection);
      const existingDeletions = await deletionDoc.get();

      if (existingDeletions.exists) {
        const existingItems = existingDeletions.data()?.items || [];
        const remainingItems = existingItems.filter((item: any) => !itemIds.includes(item.id));

        await deletionDoc.set({
          items: remainingItems,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      res.json({
        success: true,
        deleted: deletedCount,
        message: `Deleted ${deletedCount} items from ${collection}`
      });

    } catch (error: any) {
      console.error('Error deleting items:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Remove item from marked for deletion (keep in database)
 */
export const unmarkForDeletion = functions.https.onRequest((req, res) => {
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
      const { collection = 'uk_foods_cleaned', itemIds } = req.body;
      const db = admin.firestore();

      if (!itemIds || !Array.isArray(itemIds) || itemIds.length === 0) {
        res.status(400).json({ error: 'itemIds array is required' });
        return;
      }

      const deletionDoc = db.collection('markedForDeletion').doc(collection);
      const existingDeletions = await deletionDoc.get();

      if (!existingDeletions.exists) {
        res.json({ success: true, removed: 0 });
        return;
      }

      const existingItems = existingDeletions.data()?.items || [];
      const remainingItems = existingItems.filter((item: any) => !itemIds.includes(item.id));

      await deletionDoc.set({
        items: remainingItems,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      res.json({
        success: true,
        removed: existingItems.length - remainingItems.length,
        message: `Removed ${existingItems.length - remainingItems.length} items from deletion list`
      });

    } catch (error: any) {
      console.error('Error unmarking items:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Clear all marked for deletion items
 */
export const clearMarkedForDeletion = functions.https.onRequest((req, res) => {
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
      const { collection = 'uk_foods_cleaned' } = req.body;
      const db = admin.firestore();

      await db.collection('markedForDeletion').doc(collection).delete();

      res.json({
        success: true,
        message: `Cleared marked for deletion list for ${collection}`
      });

    } catch (error: any) {
      console.error('Error clearing list:', error);
      res.status(500).json({ error: error.message });
    }
  });
});
