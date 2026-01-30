/**
 * Algolia Service
 * Handles all Algolia index operations
 */

import algoliasearch from 'algoliasearch/lite';
import {
  ALGOLIA_INDICES,
  AlgoliaIndexName,
  INDEX_TO_COLLECTION,
  ALGOLIA_ONLY_INDICES,
  UnifiedFood,
  ReviewFlag,
} from '../types';

// Algolia configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const ALGOLIA_SEARCH_KEY = '577cc4ee3fed660318917bbb54abfb2e'; // Search-only key

// Initialize Algolia client
const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY);

/**
 * Transform raw Algolia hit to UnifiedFood format
 */
function transformToUnifiedFood(hit: Record<string, unknown>, sourceIndex: AlgoliaIndexName): UnifiedFood {
  const objectID = (hit.objectID as string) || '';

  // Handle different field naming conventions across indices
  const name = (hit.name || hit.foodName || hit.title || '') as string;
  const brandName = (hit.brandName || hit.brand || null) as string | null;
  const barcode = (hit.barcode || hit.gtin || hit.ean || null) as string | null;

  // Handle ingredients (can be string or array)
  let ingredients: string[] = [];
  let ingredientsText: string | null = null;
  if (hit.ingredients) {
    if (Array.isArray(hit.ingredients)) {
      ingredients = hit.ingredients as string[];
      ingredientsText = ingredients.join(', ');
    } else if (typeof hit.ingredients === 'string') {
      ingredientsText = hit.ingredients;
      ingredients = hit.ingredients.split(/,\s*/);
    }
  }
  if (hit.extractedIngredients) {
    ingredientsText = hit.extractedIngredients as string;
    if (!ingredients.length) {
      ingredients = ingredientsText.split(/,\s*/);
    }
  }

  // Nutrition values (per 100g)
  const calories = Number(hit.calories || hit.energyKcal || 0);
  const protein = Number(hit.protein || 0);
  const carbs = Number(hit.carbs || hit.carbohydrate || hit.carbohydrates || 0);
  const fat = Number(hit.fat || 0);
  const saturatedFat = hit.saturatedFat !== undefined ? Number(hit.saturatedFat || hit.saturates || 0) : null;
  const fiber = Number(hit.fiber || hit.fibre || 0);
  const sugar = Number(hit.sugar || hit.sugars || 0);
  const sodium = Number(hit.sodium || 0);
  const salt = hit.salt !== undefined ? Number(hit.salt) : null;

  // Serving info
  const servingDescription = (hit.servingDescription || hit.servingSize || hit.serving_description || null) as string | null;
  const servingSizeG = hit.servingSizeG !== undefined ? Number(hit.servingSizeG || hit.serving_size_g || 0) : null;
  const isPerUnit = Boolean(hit.per_unit_nutrition || hit.isPerUnit || false);

  // Extended serving info (for admin multi-serving support)
  const suggestedServingUnit = (hit.suggestedServingUnit || null) as 'g' | 'ml' | null;
  const suggestedServingSize = hit.suggestedServingSize !== undefined ? Number(hit.suggestedServingSize) : null;
  const suggestedServingDescription = (hit.suggestedServingDescription || null) as string | null;

  // Serving types array (new format for multiple serving options)
  let servingTypes: { id: string; name: string; servingSize: number; unit: 'g' | 'ml'; isDefault: boolean }[] | null = null;
  if (Array.isArray(hit.servingTypes)) {
    servingTypes = (hit.servingTypes as any[]).map((st, idx) => ({
      id: st.id || `serving_${idx}`,
      name: String(st.name || ''),
      servingSize: Number(st.servingSize || 0),
      unit: (st.unit === 'ml' ? 'ml' : 'g') as 'g' | 'ml',
      isDefault: Boolean(st.isDefault || idx === 0),
    }));
  }

  // Portions array (iOS format for backwards compatibility)
  let portions: { name: string; serving_g: number; calories: number }[] | null = null;
  if (Array.isArray(hit.portions)) {
    portions = (hit.portions as any[]).map((p) => ({
      name: String(p.name || ''),
      serving_g: Number(p.serving_g || 0),
      calories: Number(p.calories || 0),
    }));
  }

  // Verification
  const isVerified = Boolean(hit.verified || hit.isVerified || false);
  const verifiedBy = (hit.verifiedBy || null) as string | null;
  const verifiedAt = hit.verifiedAt ? new Date(hit.verifiedAt as string | number) : null;

  // Image
  const imageUrl = (hit.imageUrl || hit.image_url || null) as string | null;

  // Metadata
  const category = (hit.category || hit.department || null) as string | null;
  const source = (hit.source || null) as string | null;
  const createdAt = hit.createdAt ? new Date((hit.createdAt as { _seconds?: number })?._seconds ? (hit.createdAt as { _seconds: number })._seconds * 1000 : hit.createdAt as number * 1000) : null;
  const updatedAt = hit.updatedAt ? new Date((hit.updatedAt as { _seconds?: number })?._seconds ? (hit.updatedAt as { _seconds: number })._seconds * 1000 : hit.updatedAt as number * 1000) : null;

  // Compute review flags
  const reviewFlags = computeReviewFlags({
    name,
    calories,
    protein,
    carbs,
    fat,
    barcode,
    ingredients,
  });

  // Compute confidence score (0-100)
  const confidenceScore = computeConfidenceScore({
    name,
    brandName,
    barcode,
    ingredients,
    calories,
    isVerified,
    imageUrl,
  });

  return {
    _id: `${sourceIndex}:${objectID}`,
    objectID,
    _sourceIndex: sourceIndex,
    _firestoreCollection: INDEX_TO_COLLECTION[sourceIndex],
    _hasFirestoreBacking: !ALGOLIA_ONLY_INDICES.includes(sourceIndex),

    name,
    brandName,
    barcode,
    barcodes: barcode ? [barcode] : [],
    ingredients,
    ingredientsText,

    calories,
    protein,
    carbs,
    fat,
    saturatedFat,
    fiber,
    sugar,
    sodium,
    salt,

    servingDescription,
    servingSizeG,
    isPerUnit,
    suggestedServingUnit,
    suggestedServingSize,
    suggestedServingDescription,
    servingTypes,
    portions,

    isVerified,
    verifiedBy,
    verifiedAt,

    imageUrl,

    category,
    source,
    createdAt,
    updatedAt,

    _confidenceScore: confidenceScore,
    _reviewFlags: reviewFlags,
    _duplicateCandidates: [],
    _isDirty: false,
    _isDeleted: false,
  };
}

/**
 * Compute review flags for data quality issues
 */
function computeReviewFlags(food: {
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  barcode: string | null;
  ingredients: string[];
}): ReviewFlag[] {
  const flags: ReviewFlag[] = [];

  // Missing name
  if (!food.name || food.name.trim() === '') {
    flags.push({
      type: 'missing_name',
      severity: 'error',
      message: 'Missing product name',
    });
  }

  // Missing nutrition
  if (food.calories === 0 && food.protein === 0 && food.carbs === 0 && food.fat === 0) {
    flags.push({
      type: 'missing_nutrition',
      severity: 'error',
      message: 'All nutrition values are zero',
    });
  }

  // Implausible calories (>900 per 100g is impossible for most foods)
  if (food.calories > 900) {
    flags.push({
      type: 'implausible_calories',
      severity: 'error',
      message: `Calories (${food.calories}) exceed 900 per 100g`,
    });
  }

  // Check macros vs calories consistency (within 30%)
  if (food.calories > 0) {
    const calculatedCalories = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9);
    const variance = Math.abs(food.calories - calculatedCalories) / food.calories;
    if (variance > 0.3 && calculatedCalories > 0) {
      flags.push({
        type: 'implausible_macros',
        severity: 'warning',
        message: `Macros (${Math.round(calculatedCalories)} cal) don't match calories (${food.calories})`,
      });
    }
  }

  // US spelling detection (non-UK)
  const usSpellings = ['color', 'flavor', 'fiber', 'center'];
  const nameAndIngredients = `${food.name} ${food.ingredients.join(' ')}`.toLowerCase();
  const hasUSSpelling = usSpellings.some(spelling => nameAndIngredients.includes(spelling));
  if (hasUSSpelling) {
    flags.push({
      type: 'non_uk',
      severity: 'warning',
      message: 'Contains US spelling (may not be UK product)',
    });
  }

  // Missing barcode
  if (!food.barcode) {
    flags.push({
      type: 'missing_barcode',
      severity: 'info',
      message: 'No barcode available',
    });
  }

  // Missing ingredients
  if (!food.ingredients.length) {
    flags.push({
      type: 'missing_ingredients',
      severity: 'info',
      message: 'No ingredients listed',
    });
  }

  return flags;
}

/**
 * Compute confidence score (0-100)
 */
function computeConfidenceScore(food: {
  name: string;
  brandName: string | null;
  barcode: string | null;
  ingredients: string[];
  calories: number;
  isVerified: boolean;
  imageUrl: string | null;
}): number {
  let score = 0;

  // Name present: +20
  if (food.name && food.name.trim()) score += 20;

  // Brand present: +10
  if (food.brandName) score += 10;

  // Barcode present: +15
  if (food.barcode) score += 15;

  // Ingredients present: +15
  if (food.ingredients.length > 0) score += 15;

  // Nutrition data present: +15
  if (food.calories > 0) score += 15;

  // Verified: +15
  if (food.isVerified) score += 15;

  // Image present: +10
  if (food.imageUrl) score += 10;

  return Math.min(100, score);
}

/**
 * Search a single index
 */
export async function searchIndex(
  indexName: AlgoliaIndexName,
  query: string = '',
  options: {
    page?: number;
    hitsPerPage?: number;
    filters?: string;
  } = {}
): Promise<{ foods: UnifiedFood[]; total: number; page: number }> {
  const { page = 0, hitsPerPage = 100, filters } = options;
  const index = algoliaClient.initIndex(indexName);

  try {
    const result = await index.search(query, {
      page,
      hitsPerPage,
      filters,
    });

    const foods = result.hits.map((hit) =>
      transformToUnifiedFood(hit as unknown as Record<string, unknown>, indexName)
    );

    return {
      foods,
      total: result.nbHits,
      page: result.page,
    };
  } catch (error) {
    console.error(`Error searching index ${indexName}:`, error);
    return { foods: [], total: 0, page: 0 };
  }
}

/**
 * Search all indices in parallel with verified_foods prioritized
 */
export async function searchAllIndices(
  query: string = '',
  indicesToSearch: AlgoliaIndexName[] = [...ALGOLIA_INDICES],
  options: {
    hitsPerPage?: number;
  } = {}
): Promise<{ foods: UnifiedFood[]; totalByIndex: Record<AlgoliaIndexName, number> }> {
  const { hitsPerPage = 1000 } = options;

  const results = await Promise.all(
    indicesToSearch.map(async (indexName) => {
      const result = await searchIndex(indexName, query, { hitsPerPage });
      return { indexName, ...result };
    })
  );

  const foods: UnifiedFood[] = [];
  const totalByIndex: Record<AlgoliaIndexName, number> = {} as Record<AlgoliaIndexName, number>;

  // Prioritize verified_foods by adding them first
  const priorityOrder: AlgoliaIndexName[] = ['verified_foods', 'uk_foods_cleaned', 'tesco_products', 'manual_foods', 'ai_enhanced', 'user_added', 'foods', 'ai_manually_added', 'fast_foods_database', 'generic_database'];

  // Sort results by priority order
  const sortedResults = results.sort((a, b) => {
    const aIndex = priorityOrder.indexOf(a.indexName);
    const bIndex = priorityOrder.indexOf(b.indexName);
    const aPriority = aIndex === -1 ? 999 : aIndex;
    const bPriority = bIndex === -1 ? 999 : bIndex;
    return aPriority - bPriority;
  });

  sortedResults.forEach((result) => {
    foods.push(...result.foods);
    totalByIndex[result.indexName] = result.total;
  });

  return { foods, totalByIndex };
}

/**
 * Search by barcode across all indices
 */
export async function searchByBarcode(
  barcode: string,
  indicesToSearch: AlgoliaIndexName[] = [...ALGOLIA_INDICES]
): Promise<{ foods: UnifiedFood[]; totalByIndex: Record<AlgoliaIndexName, number> }> {
  const results = await Promise.all(
    indicesToSearch.map(async (indexName) => {
      const result = await searchIndex(indexName, '', {
        hitsPerPage: 100,
        filters: `barcode:"${barcode}"`
      });
      return { indexName, ...result };
    })
  );

  const foods: UnifiedFood[] = [];
  const totalByIndex: Record<AlgoliaIndexName, number> = {} as Record<AlgoliaIndexName, number>;

  // Prioritize verified_foods first
  const priorityOrder: AlgoliaIndexName[] = ['verified_foods', 'uk_foods_cleaned', 'tesco_products', 'manual_foods', 'ai_enhanced', 'user_added', 'foods', 'ai_manually_added', 'fast_foods_database', 'generic_database'];

  const sortedResults = results.sort((a, b) => {
    const aIndex = priorityOrder.indexOf(a.indexName);
    const bIndex = priorityOrder.indexOf(b.indexName);
    const aPriority = aIndex === -1 ? 999 : aIndex;
    const bPriority = bIndex === -1 ? 999 : bIndex;
    return aPriority - bPriority;
  });

  sortedResults.forEach((result) => {
    foods.push(...result.foods);
    totalByIndex[result.indexName] = result.total;
  });

  return { foods, totalByIndex };
}

/**
 * Get index statistics
 */
export async function getIndexStats(): Promise<Record<AlgoliaIndexName, { entries: number }>> {
  const stats: Record<AlgoliaIndexName, { entries: number }> = {} as Record<AlgoliaIndexName, { entries: number }>;

  await Promise.all(
    ALGOLIA_INDICES.map(async (indexName) => {
      try {
        const index = algoliaClient.initIndex(indexName);
        const result = await index.search('', {
          hitsPerPage: 0,
          analytics: false,
        });
        stats[indexName] = { entries: result.nbHits };
      } catch (error) {
        console.error(`Error getting stats for ${indexName}:`, error);
        stats[indexName] = { entries: 0 };
      }
    })
  );

  return stats;
}

/**
 * Get a single food by ID from Algolia
 * Searches all indices to find the food
 */
export async function getFoodById(foodId: string): Promise<UnifiedFood | null> {
  // Try each index until we find the food
  for (const indexName of ALGOLIA_INDICES) {
    try {
      const index = algoliaClient.initIndex(indexName);
      // Use search with objectID filter instead of getObject
      const result = await index.search('', {
        filters: `objectID:${foodId}`,
        hitsPerPage: 1,
      });

      if (result.hits.length > 0) {
        return transformToUnifiedFood(result.hits[0] as Record<string, unknown>, indexName);
      }
    } catch (error) {
      // Object not found in this index, continue to next
      continue;
    }
  }

  return null;
}

export { algoliaClient };
