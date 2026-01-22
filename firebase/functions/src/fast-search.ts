import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FOOD_CATEGORIES, FoodCategory } from './food-categories';

// In-memory cache for search results (will reset on function cold start)
const searchCache = new Map<string, { results: any[], timestamp: number }>();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Precomputed frequent search results (warm cache)
let commonFoodsCache: any[] = [];
let lastCacheUpdate = 0;

// Cache for custom categories
let customCategoriesCache: FoodCategory[] = [];
let customCategoriesCacheTime = 0;
const CUSTOM_CATEGORIES_CACHE_DURATION = 10 * 60 * 1000; // 10 minutes

// Load custom categories from Firestore (exported for future use)
export async function loadCustomCategories(): Promise<FoodCategory[]> {
  const now = Date.now();
  if (customCategoriesCache.length > 0 && (now - customCategoriesCacheTime) < CUSTOM_CATEGORIES_CACHE_DURATION) {
    return customCategoriesCache;
  }

  try {
    const snapshot = await admin.firestore().collection('customFoodCategories').get();
    customCategoriesCache = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: data.id || doc.id,
        name: data.name,
        description: data.description || '',
        defaultServingSize: data.defaultServingSize,
        servingUnit: data.servingUnit || 'g',
        servingDescription: data.servingDescription,
        keywords: data.keywords || []
      };
    });
    customCategoriesCacheTime = now;
    return customCategoriesCache;
  } catch (error) {
    console.error('Failed to load custom categories:', error);
    return customCategoriesCache; // Return stale cache on error
  }
}

// Get category by ID (checks both built-in and custom)
function getCategoryById(categoryId: string, customCategories: FoodCategory[]): FoodCategory | null {
  const builtIn = FOOD_CATEGORIES.find(c => c.id === categoryId);
  if (builtIn) return builtIn;
  return customCategories.find(c => c.id === categoryId) || null;
}

// Generate smart serving options based on category and actual data (exported for future use)
export function generateServingOptions(
  categoryId: string | null,
  actualServingSizeG: number,
  actualServingDescription: string,
  customCategories: FoodCategory[]
): Array<{ size: number; unit: string; description: string; isDefault: boolean }> {
  const options: Array<{ size: number; unit: string; description: string; isDefault: boolean }> = [];

  // Get category-based serving if we have a category
  let categoryServing: { size: number; unit: string; description: string } | null = null;
  if (categoryId) {
    const category = getCategoryById(categoryId, customCategories);
    if (category) {
      categoryServing = {
        size: category.defaultServingSize,
        unit: category.servingUnit,
        description: category.servingDescription
      };
    }
  }

  const isActual100g = actualServingSizeG === 100 || actualServingDescription === '100g serving' || actualServingDescription === 'per 100g';

  if (isActual100g) {
    // Actual serving is 100g - use category suggestion as primary
    if (categoryServing && categoryServing.size !== 100) {
      options.push({
        size: categoryServing.size,
        unit: categoryServing.unit,
        description: categoryServing.description,
        isDefault: true
      });

      // Add half portion option
      const halfSize = Math.round(categoryServing.size / 2);
      if (halfSize >= 10) {
        options.push({
          size: halfSize,
          unit: categoryServing.unit,
          description: `Small portion (${halfSize}${categoryServing.unit})`,
          isDefault: false
        });
      }

      // Add double portion option
      const doubleSize = categoryServing.size * 2;
      if (doubleSize <= 500) {
        options.push({
          size: doubleSize,
          unit: categoryServing.unit,
          description: `Large portion (${doubleSize}${categoryServing.unit})`,
          isDefault: false
        });
      }
    } else {
      // No category or category also says 100g - just use 100g with some options
      options.push({
        size: 100,
        unit: 'g',
        description: 'per 100g',
        isDefault: true
      });
      options.push({
        size: 50,
        unit: 'g',
        description: 'Half portion (50g)',
        isDefault: false
      });
      options.push({
        size: 150,
        unit: 'g',
        description: 'Large portion (150g)',
        isDefault: false
      });
    }
  } else {
    // Actual serving is NOT 100g - use category as primary, actual at bottom
    if (categoryServing && categoryServing.size !== actualServingSizeG) {
      // Category suggestion first
      options.push({
        size: categoryServing.size,
        unit: categoryServing.unit,
        description: categoryServing.description,
        isDefault: true
      });
    }

    // Add a middle option if there's room
    if (categoryServing && actualServingSizeG > 0) {
      const midSize = Math.round((categoryServing.size + actualServingSizeG) / 2);
      if (midSize !== categoryServing.size && midSize !== actualServingSizeG && midSize > 10) {
        options.push({
          size: midSize,
          unit: 'g',
          description: `${midSize}g portion`,
          isDefault: options.length === 0
        });
      }
    }

    // Actual serving at the bottom
    if (actualServingSizeG > 0 && actualServingSizeG !== 100) {
      const unit = actualServingDescription.includes('ml') ? 'ml' : 'g';
      options.push({
        size: actualServingSizeG,
        unit: unit,
        description: actualServingDescription,
        isDefault: options.length === 0
      });
    }
  }

  // Ensure we have at least one option
  if (options.length === 0) {
    options.push({
      size: 100,
      unit: 'g',
      description: 'per 100g',
      isDefault: true
    });
  }

  // Ensure exactly one default
  const hasDefault = options.some(o => o.isDefault);
  if (!hasDefault && options.length > 0) {
    options[0].isDefault = true;
  }

  return options;
}

export const fastSearchFoods = functions.https.onRequest(async (req, res) => {
  const startTime = Date.now();
  
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }

  try {
    const query = (req.query.q as string) || (req.body && req.body.query) || '';
    
    if (!query || query.trim().length < 2) {
      res.status(400).json({ error: 'Query must be at least 2 characters' });
      return;
    }

    const normalizedQuery = query.toLowerCase().trim();
    const cacheKey = normalizedQuery;
    
    // Check cache first
    const cached = searchCache.get(cacheKey);
    if (cached && (Date.now() - cached.timestamp) < CACHE_DURATION) {
      console.log(`Cache hit for "${query}" - ${Date.now() - startTime}ms`);
      res.json({ 
        foods: cached.results,
        cached: true,
        searchTime: Date.now() - startTime
      });
      return;
    }

    // For very common searches, use precomputed cache
    if (normalizedQuery.length <= 3 && ['a', 'e', 'i', 'o', 'u', 'the', 'and'].includes(normalizedQuery)) {
      await updateCommonFoodsCache();
      const filteredResults = commonFoodsCache
        .filter(food => food.name.toLowerCase().includes(normalizedQuery))
        .slice(0, 20);
      
      console.log(`Common search "${query}" - ${Date.now() - startTime}ms`);
      res.json({ 
        foods: filteredResults,
        cached: true,
        searchTime: Date.now() - startTime
      });
      return;
    }

    // Load custom categories for serving size lookups
    const customCategories = await loadCustomCategories();

    // Optimized single query strategy
    let searchResults: any[] = [];

    // Strategy 1: Direct prefix match (fastest)
    const firstWord = normalizedQuery.split(' ')[0];
    const capitalizedWord = firstWord.charAt(0).toUpperCase() + firstWord.slice(1);

    try {
      const snapshot = await admin.firestore()
        .collection('verifiedFoods')
        .where('foodName', '>=', capitalizedWord)
        .where('foodName', '<=', capitalizedWord + '\uf8ff')
        .limit(50) // Reduced from 500
        .get();

      searchResults = snapshot.docs.map(doc => {
        const data = doc.data();
        return formatFoodResult(doc.id, data, customCategories);
      });

    } catch (error) {
      console.error('Direct search failed:', error);
    }

    // Strategy 2: If few results, try lowercase
    if (searchResults.length < 10) {
      try {
        const snapshot = await admin.firestore()
          .collection('verifiedFoods')
          .where('foodName', '>=', firstWord)
          .where('foodName', '<=', firstWord + '\uf8ff')
          .limit(30)
          .get();

        const additionalResults = snapshot.docs.map(doc => {
          const data = doc.data();
          return formatFoodResult(doc.id, data, customCategories);
        });

        // Merge results, avoiding duplicates
        const existingIds = new Set(searchResults.map(r => r.id));
        additionalResults.forEach(result => {
          if (!existingIds.has(result.id)) {
            searchResults.push(result);
          }
        });

      } catch (error) {
        console.error('Lowercase search failed:', error);
      }
    }

    // Strategy 3: Search Tesco products (uses 'title' field instead of 'foodName')
    if (searchResults.length < 15) {
      try {
        const tescoSnapshot = await admin.firestore()
          .collection('tescoProducts')
          .where('title', '>=', capitalizedWord)
          .where('title', '<=', capitalizedWord + '\uf8ff')
          .limit(20)
          .get();

        const tescoResults = tescoSnapshot.docs.map(doc => {
          const data = doc.data();
          return formatFoodResult(doc.id, data, customCategories);
        });

        // Merge results, avoiding duplicates
        const existingIds = new Set(searchResults.map(r => r.id));
        const existingBarcodes = new Set(searchResults.map(r => r.barcode).filter(b => b));
        tescoResults.forEach(result => {
          // Check both ID and barcode for duplicates
          if (!existingIds.has(result.id) && (!result.barcode || !existingBarcodes.has(result.barcode))) {
            searchResults.push(result);
          }
        });

        console.log(`Added ${tescoResults.length} Tesco products to search results`);
      } catch (error) {
        console.error('Tesco search failed:', error);
      }
    }

    // Fast client-side filtering and ranking
    const queryWords = normalizedQuery.split(/\s+/);
    let filteredResults = searchResults.filter(food => {
      const foodName = food.name.toLowerCase();
      const brandName = (food.brand || '').toLowerCase();
      
      // Quick contains check
      return queryWords.some((word: string) => 
        foodName.includes(word) || brandName.includes(word)
      );
    });

    // Simple ranking (much faster than complex scoring)
    filteredResults = filteredResults
      .map(food => ({
        ...food,
        _score: calculateFastScore(food, normalizedQuery, queryWords)
      }))
      .sort((a, b) => b._score - a._score)
      .slice(0, 20)
      .map(({ _score, ...food }) => food); // Remove score from final result

    // Cache the results
    searchCache.set(cacheKey, {
      results: filteredResults,
      timestamp: Date.now()
    });

    const searchTime = Date.now() - startTime;
    console.log(`Fast search "${query}" - ${searchTime}ms - ${filteredResults.length} results`);

    res.json({
      foods: filteredResults,
      searchTime: searchTime,
      cached: false
    });

  } catch (error) {
    console.error('Fast search error:', error);
    res.status(500).json({ error: 'Search failed' });
  }
});

// Filter out Tesco image URLs (blocked domain)
function filterImageUrl(imageUrl: string | null | undefined): string | null {
  if (!imageUrl) return null;
  const lowerUrl = imageUrl.toLowerCase();
  // Block Tesco image URLs
  if (lowerUrl.includes('tesco.com') || lowerUrl.includes('tescolabs.') || lowerUrl.includes('.tesco.')) {
    return null;
  }
  return imageUrl;
}

// Simplified food result formatting
function formatFoodResult(id: string, data: any, customCategories: FoodCategory[] = []) {
  const nutrition = data.nutritionData || data.nutrition || {};

  // Extract serving size from multiple possible field names
  let servingDescription = data.servingDescription ||
                           data.serving_description ||
                           data.servingSize ||
                           data.serving_size ||
                           '100g serving';

  // Extract raw numeric serving size in grams (before validation)
  const rawServingSizeG = data.servingSizeG ||
                          data.serving_size_g ||
                          data.servingWeightG ||
                          extractRawServingSize(servingDescription);

  // Validate and fix bad serving size data (e.g., RI% mistaken for grams)
  const servingSizeG = validateServingSize(rawServingSizeG, servingDescription);

  // If serving size was reset due to bad data, update description too
  if (rawServingSizeG < 50 && rawServingSizeG > 0 && servingSizeG === 100) {
    servingDescription = '100g serving';
  }

  // Get food category
  const foodCategory = data.foodCategory || null;

  // Generate smart serving options based on category
  const servingOptions = generateServingOptions(
    foodCategory,
    servingSizeG,
    servingDescription,
    customCategories
  );

  // Get the default serving from options
  const defaultServing = servingOptions.find(o => o.isDefault) || servingOptions[0];

  return {
    id: id,
    name: data.foodName || data.title || data.name || '',
    brand: data.brandName || data.brand || null,
    barcode: data.barcode || data.gtin || '',
    calories: extractNutritionValue(nutrition.calories || nutrition.energyKcal || data.calories),
    protein: extractNutritionValue(nutrition.protein || data.protein),
    carbs: extractNutritionValue(nutrition.carbs || nutrition.carbohydrates || nutrition.carbohydrate || data.carbs),
    fat: extractNutritionValue(nutrition.fat || data.fat),
    fiber: extractNutritionValue(nutrition.fiber || nutrition.fibre || data.fiber),
    sugar: extractNutritionValue(nutrition.sugar || nutrition.sugars || data.sugar),
    sodium: extractNutritionValue(nutrition.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0)),
    servingDescription: defaultServing.description,
    servingSizeG: defaultServing.size,
    servingOptions: servingOptions,
    foodCategory: foodCategory,
    ingredients: data.extractedIngredients || data.ingredients || null,
    additives: data.additives || null,
    verifiedBy: data.verifiedBy || null,
    verificationMethod: data.verificationMethod || null,
    verifiedAt: data.verifiedAt || null,
    imageUrl: filterImageUrl(data.imageUrl)
  };
}

// Extract raw serving size (no validation)
function extractRawServingSize(servingStr: string): number {
  if (!servingStr || servingStr === '100g serving') return 100;
  const match = servingStr.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
  return match ? parseFloat(match[1]) : 100;
}

// Validate serving size - reject bad data (RI%, parsing errors)
function validateServingSize(servingSizeG: number, servingDescription: string): number {
  if (servingSizeG < 50 && servingSizeG > 0) {
    // Only allow small servings for actual small items (snacks, biscuits, etc.)
    const smallPortionKeywords = ['biscuit', 'sweet', 'chocolate', 'crisp', 'snack', 'bar', 'piece'];
    const isSmallItem = smallPortionKeywords.some(kw => servingDescription.toLowerCase().includes(kw));
    if (!isSmallItem) {
      return 100;
    }
  }
  return servingSizeG;
}

// Fast nutrition value extraction
function extractNutritionValue(field: any): number {
  if (typeof field === 'number') return field;
  if (field && typeof field === 'object') {
    if (field.per100g !== undefined) return field.per100g;
    if (field.kcal !== undefined) return field.kcal;
    if (field.value !== undefined) return field.value;
  }
  return 0;
}

// Simplified scoring for speed
function calculateFastScore(food: any, query: string, queryWords: string[]): number {
  const name = food.name.toLowerCase();
  const brand = (food.brand || '').toLowerCase();
  
  let score = 0;
  
  // Exact name match
  if (name === query) return 1000;
  
  // Name starts with query
  if (name.startsWith(query)) score += 500;
  
  // All words found in name
  const foundWords = queryWords.filter((word: string) => name.includes(word));
  score += foundWords.length * 100;
  
  // Brand bonus
  if (brand.includes(query)) score += 50;
  
  // Shorter names get slight bonus
  score += Math.max(0, 50 - name.length);
  
  return score;
}

// Update cache of common foods for frequent searches
async function updateCommonFoodsCache() {
  const now = Date.now();
  if (now - lastCacheUpdate < 10 * 60 * 1000) return; // Update every 10 minutes

  try {
    // Load custom categories for serving size lookups
    const customCategories = await loadCustomCategories();

    const snapshot = await admin.firestore()
      .collection('verifiedFoods')
      .where('verifiedBy', '==', 'company') // Prioritize verified foods
      .limit(200)
      .get();

    commonFoodsCache = snapshot.docs.map(doc =>
      formatFoodResult(doc.id, doc.data(), customCategories)
    );

    lastCacheUpdate = now;
    console.log(`Updated common foods cache: ${commonFoodsCache.length} foods`);

  } catch (error) {
    console.error('Failed to update common foods cache:', error);
  }
}