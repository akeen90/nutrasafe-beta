/**
 * Tesco Database Builder
 *
 * Systematically scans the Tesco product catalog via the Tesco8 API
 * and builds a comprehensive food database with full nutrition data.
 *
 * Features:
 * - Alphabetical search through A-Z + common food terms
 * - Category-based browsing
 * - Progress tracking with resume capability
 * - Rate limiting to respect API limits
 * - Stores to Firestore "tescoProducts" collection
 * - Syncs to Algolia "tesco_products" index
 */

import * as functions from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import axios from 'axios';
import { algoliasearch } from 'algoliasearch';

// Initialize Firebase Admin if not already
if (!admin.apps.length) {
    admin.initializeApp();
}

// API Keys - Use Firebase Secrets (set via: firebase functions:secrets:set <SECRET_NAME>)
// CRITICAL: Never hardcode API keys. Set secrets using:
//   firebase functions:secrets:set TESCO8_API_KEY
//   firebase functions:secrets:set UK_GROCERIES_API_KEY
//   firebase functions:secrets:set SPOONACULAR_API_KEY
const tesco8ApiKey = defineSecret('TESCO8_API_KEY');
const ukGroceriesApiKey = defineSecret('UK_GROCERIES_API_KEY');
const spoonacularApiKey = defineSecret('SPOONACULAR_API_KEY');
const algoliaAdminKey = defineSecret('ALGOLIA_ADMIN_API_KEY');

// API Hosts (not secrets - these are public)
const TESCO8_HOST = 'tesco8.p.rapidapi.com';
const UK_GROCERIES_HOST = 'store-groceries.p.rapidapi.com';
const SPOONACULAR_HOST = 'spoonacular-recipe-food-nutrition-v1.p.rapidapi.com';

// API Source Types
type ApiSource = 'tesco8' | 'uk_groceries' | 'spoonacular';

// Helper to remove undefined values from objects (Firestore doesn't accept undefined)
function removeUndefined<T extends Record<string, any>>(obj: T): T {
    const result: Record<string, any> = {};
    for (const [key, value] of Object.entries(obj)) {
        if (value !== undefined) {
            if (value && typeof value === 'object' && !Array.isArray(value)) {
                result[key] = removeUndefined(value);
            } else {
                result[key] = value;
            }
        }
    }
    return result as T;
}

// Algolia Configuration
const ALGOLIA_APP_ID = 'WK0TIF84M2';
const TESCO_INDEX_NAME = 'tesco_products';

// Collection and Index mapping by API source
const API_CONFIG: Record<ApiSource, { collection: string; algoliaIndex: string; displayName: string }> = {
    'tesco8': {
        collection: 'tescoProducts',
        algoliaIndex: 'tesco_products',
        displayName: 'Tesco'
    },
    'uk_groceries': {
        collection: 'ukGroceriesProducts',
        algoliaIndex: 'uk_groceries_products',
        displayName: 'UK Groceries'
    },
    'spoonacular': {
        collection: 'spoonacularRecipes',
        algoliaIndex: 'spoonacular_recipes',
        displayName: 'Spoonacular'
    }
};

// Helper to get config for an API source
function getApiConfig(apiSource: ApiSource) {
    return API_CONFIG[apiSource] || API_CONFIG['tesco8'];
}

// Tesco food categories - SIMPLIFIED broad categories only
// Strategy: ~60 broad terms with 20 pages each = maximum coverage, minimal duplicates
const SEARCH_TERMS = [
    // ============ SNACKS ============
    'Chocolate',
    'Crisps',
    'Biscuits',
    'Sweets',
    'Nuts',
    'Popcorn',
    'Crackers',

    // ============ BREAKFAST ============
    'Cereals',
    'Porridge',
    'Jam',
    'Honey',
    'Spread',

    // ============ CARBS ============
    'Pasta',
    'Rice',
    'Noodles',
    'Couscous',
    'Bread',
    'Wraps',

    // ============ SAUCES ============
    'Sauce',
    'Ketchup',
    'Mayonnaise',
    'Pesto',
    'Dressing',

    // ============ TINNED ============
    'Tinned',
    'Beans',
    'Soup',

    // ============ DRINKS ============
    'Water',
    'Juice',
    'Squash',
    'Fizzy Drinks',
    'Tea',
    'Coffee',

    // ============ DAIRY ============
    'Milk',
    'Cheese',
    'Yogurt',
    'Eggs',
    'Butter',
    'Cream',

    // ============ BAKERY ============
    'Cakes',
    'Pastries',
    'Pies',
    'Croissants',

    // ============ FRESH ============
    'Fruit',
    'Vegetables',
    'Salad',

    // ============ MEAT ============
    'Beef',
    'Pork',
    'Lamb',
    'Chicken',
    'Sausages',
    'Bacon',
    'Ham',
    'Mince',

    // ============ FISH ============
    'Fish',
    'Salmon',
    'Prawns',

    // ============ FROZEN ============
    'Frozen',
    'Ice Cream',
    'Frozen Pizza',

    // ============ READY MEALS ============
    'Ready Meals',
    'Sandwiches',
    'Pizza',

    // ============ WORLD FOOD ============
    'Chinese',
    'Indian',
    'Mexican',
    'Italian',

    // ============ DIETARY ============
    'Vegan',
    'Gluten Free',
    'Organic',

    // ============ COOKING ============
    'Oil',
    'Vinegar',
    'Spices',
    'Stock',
    'Flour',
    'Sugar',

    // ============ DELI & CHILLED ============
    'Hummus',
    'Dips',
    'Olives',
    'Coleslaw',

    // ============ CONDIMENTS ============
    'Mustard',
    'Pickles',
    'Chutney',
    'Relish',

    // ============ SNACK BARS ============
    'Cereal Bars',
    'Protein Bars',

    // ============ DRINKS EXTRA ============
    'Energy Drinks',
    'Smoothies',
    'Milkshakes',

    // ============ DESSERTS ============
    'Pudding',
    'Custard',
    'Jelly',
    'Trifle',

    // ============ SPREADS ============
    'Peanut Butter',
    'Marmite',

    // ============ BAKING ============
    'Baking',
    'Chocolate Chips',
    'Icing',

    // ============ WORLD FOOD EXTRA ============
    'Thai',
    'Japanese',
    'Korean',
    'Polish',

    // ============ PLANT-BASED ============
    'Meat Free',
    'Plant Based',
    'Quorn',

    // ============ FRESH EXTRA ============
    'Herbs',
    'Mushrooms',

    // ============ ALCOHOL ============
    'Beer',
    'Wine',
    'Spirits',

    // ============ ON-THE-GO & CONVENIENCE ============
    'Meal Deal',
    'Snack Pots',
    'Pasta Pots',
    'Sushi',
    'Salad Pots',
    'Rolls',
    'Lunch',
    'Snacking',

    // ============ ON-THE-GO DRINKS ============
    '330ml',
    '500ml',
    'Coke',
    'Pepsi',
    'Fanta',
    'Sprite',
    'Lucozade',
    'Red Bull',
    'Monster',
    'Ribena',
    'Oasis',
    'Volvic',
    'Evian',
    'Innocent',
    'Costa Coffee',
    'Starbucks',
];

// Interfaces
interface TescoProduct {
    id: string;
    tpnb: string;
    gtin: string;
    title: string;
    brand: string;
    description?: string;
    imageUrl?: string;
    price?: number;
    unitPrice?: string;
    nutrition?: {
        energyKj?: number;
        energyKcal?: number;
        fat?: number;
        saturates?: number;
        carbohydrate?: number;
        sugars?: number;
        fibre?: number;
        protein?: number;
        salt?: number;
    };
    ingredients?: string;
    allergens?: string[];
    servingSize?: string;
    category?: string;
    importedAt: string;
    source: 'tesco8_api' | 'uk_groceries_api' | 'spoonacular_api';
}

interface BuildProgress {
    apiSource: ApiSource; // Which API to use
    status: 'idle' | 'running' | 'paused' | 'completed' | 'error';
    currentTermIndex: number;
    currentTerm: string;
    totalTerms: number;
    currentPage: number;      // NEW: Which page we're on (0, 1, 2, 3, 4)
    maxPages: number;         // NEW: Max pages to fetch per term (e.g., 5)
    productsFound: number;
    productsWithNutrition: number;
    productsSaved: number;
    duplicatesSkipped: number;
    errors: number;
    startedAt: string;
    lastUpdated: string;
    lastProductSavedAt?: string; // Track when we last saved a product
    estimatedCompletion?: string;
    errorMessages: string[];
    autoRestartCount?: number; // Track how many times we've auto-restarted
    lastAutoRestart?: string; // When we last auto-restarted
    stopRequested?: boolean; // User clicked Stop - block all auto-restarts
    recentlyFoundProducts: Array<{
        id: string;
        title: string;
        brand?: string;
        hasNutrition: boolean;
        savedAt: string;
    }>;
}

// Helper: Parse numeric value from string
function parseNumber(value: string | number | undefined): number | undefined {
    if (value === undefined || value === null) return undefined;
    if (typeof value === 'number') return value;
    const cleaned = value.replace(/[^\d.]/g, '');
    const num = parseFloat(cleaned);
    return isNaN(num) ? undefined : num;
}

// Helper: Identify allergens from text
function identifyAllergens(text: string | string[]): string[] {
    const allergenList = [
        'milk', 'egg', 'peanut', 'tree nut', 'wheat', 'soy', 'fish',
        'shellfish', 'sesame', 'gluten', 'celery', 'mustard', 'lupin',
        'mollusc', 'sulphite', 'sulphur dioxide', 'crustacean'
    ];

    const textStr = Array.isArray(text) ? text.join(' ') : text;
    const lowerText = textStr.toLowerCase();

    return allergenList.filter(allergen => lowerText.includes(allergen));
}

// Helper: Check if product has valid nutrition
// STRICT: Must have calories - protein/carbs alone isn't enough
function hasValidNutrition(nutrition?: TescoProduct['nutrition']): boolean {
    if (!nutrition) return false;
    // MUST have calories (energyKcal) - this is the primary requirement
    if (!nutrition.energyKcal || nutrition.energyKcal <= 0) return false;
    // Sanity check: calories should be realistic (0-900 kcal per 100g, max is pure fat)
    if (nutrition.energyKcal > 950) return false;
    return true;
}

// Helper: Check if product is valid for saving (has required fields)
function isValidProduct(product: TescoProduct, requireIngredients: boolean = false): { valid: boolean; reason?: string } {
    // Must have a title/name
    if (!product.title || product.title.trim().length === 0) {
        return { valid: false, reason: 'Missing title' };
    }
    // Must have an ID
    if (!product.id) {
        return { valid: false, reason: 'Missing ID' };
    }
    // Must have valid calories
    if (!product.nutrition?.energyKcal || product.nutrition.energyKcal <= 0) {
        return { valid: false, reason: 'Missing or invalid calories' };
    }
    // Calories sanity check
    if (product.nutrition.energyKcal > 950) {
        return { valid: false, reason: `Calories too high: ${product.nutrition.energyKcal}` };
    }
    // Must have ingredients (if required) - minimum 10 characters to filter out garbage
    if (requireIngredients && (!product.ingredients || product.ingredients.trim().length < 10)) {
        return { valid: false, reason: 'Missing or insufficient ingredients' };
    }
    return { valid: true };
}

// Helper: Count non-zero nutrition fields
function countNutritionFields(nutrition?: TescoProduct['nutrition']): number {
    if (!nutrition) return 0;
    let count = 0;
    if (nutrition.energyKcal) count++;
    if (nutrition.energyKj) count++;
    if (nutrition.fat) count++;
    if (nutrition.saturates) count++;
    if (nutrition.carbohydrate) count++;
    if (nutrition.sugars) count++;
    if (nutrition.fibre) count++;
    if (nutrition.protein) count++;
    if (nutrition.salt) count++;
    return count;
}

// Helper: Check if new product has more complete data than existing
function isMoreComplete(newProduct: TescoProduct, existingData: any): boolean {
    const newNutritionCount = countNutritionFields(newProduct.nutrition);
    const existingNutritionCount = countNutritionFields(existingData.nutrition);

    // New has more nutrition fields
    if (newNutritionCount > existingNutritionCount) return true;

    // New has ingredients but existing doesn't
    if (newProduct.ingredients && !existingData.ingredients) return true;

    // New has allergens but existing doesn't
    if (newProduct.allergens?.length && !existingData.allergens?.length) return true;

    return false;
}

// Helper: Strip HTML tags and clean ingredients text
function cleanIngredients(text: string | string[] | undefined): string {
    if (!text) return '';
    let str = Array.isArray(text) ? text.join(', ') : text;

    // Remove HTML tags like <p>, <strong>, </strong>, etc.
    str = str.replace(/<[^>]*>/g, '');

    // Remove "INGREDIENTS:" prefix if present
    str = str.replace(/^INGREDIENTS:\s*/i, '');

    // Clean up whitespace
    str = str.replace(/\s+/g, ' ').trim();

    return str;
}

// Helper: Sleep function
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Token Bucket Rate Limiter - allows burst while maintaining average rate
 * Much more efficient than fixed delays - only waits when actually needed
 */
class RateLimiter {
    private tokens: number;
    private lastRefill: number;
    private readonly maxTokens: number;
    private readonly refillRate: number; // tokens per millisecond

    constructor(requestsPerSecond: number, burstCapacity: number = requestsPerSecond) {
        this.maxTokens = burstCapacity;
        this.tokens = burstCapacity;
        this.refillRate = requestsPerSecond / 1000;
        this.lastRefill = Date.now();
    }

    private refillTokens(): void {
        const now = Date.now();
        const elapsed = now - this.lastRefill;
        this.tokens = Math.min(this.maxTokens, this.tokens + elapsed * this.refillRate);
        this.lastRefill = now;
    }

    async acquire(): Promise<void> {
        this.refillTokens();
        if (this.tokens >= 1) {
            this.tokens -= 1;
            return;
        }
        // Calculate wait time needed to get 1 token
        const waitTime = Math.ceil((1 - this.tokens) / this.refillRate);
        await sleep(waitTime);
        return this.acquire();
    }

    async execute<T>(fn: () => Promise<T>): Promise<T> {
        await this.acquire();
        return fn();
    }
}

// 3 req/s with burst of 3 (conservative to preserve API quota)
const apiRateLimiter = new RateLimiter(3, 3);

// Parallel batch processing constants
const PARALLEL_BATCH_SIZE = 3; // Process 3 products concurrently (matches rate limit)

interface BatchResult {
    productId: string;
    product: TescoProduct | null;
    error?: string;
}

/**
 * Process product IDs in parallel batches with rate limiting
 * Returns results for all products (success or error)
 */
async function processProductBatch(productIds: string[]): Promise<BatchResult[]> {
    const results: BatchResult[] = [];

    for (let i = 0; i < productIds.length; i += PARALLEL_BATCH_SIZE) {
        const batch = productIds.slice(i, i + PARALLEL_BATCH_SIZE);

        const batchPromises = batch.map(async (productId): Promise<BatchResult> => {
            try {
                const { product, error } = await apiRateLimiter.execute(
                    () => getProductDetails(productId)
                );
                return { productId, product, error };
            } catch (err: any) {
                return { productId, product: null, error: err.message };
            }
        });

        const batchResults = await Promise.allSettled(batchPromises);

        for (const result of batchResults) {
            if (result.status === 'fulfilled') {
                results.push(result.value);
            } else {
                // Promise rejected - shouldn't happen but handle it
                results.push({ productId: 'unknown', product: null, error: result.reason?.message || 'Unknown error' });
            }
        }
    }

    return results;
}

// OPTIMIZED: Batch check which product IDs already exist in Firestore
async function batchCheckExisting(
    tescoCollection: admin.firestore.CollectionReference,
    productIds: string[]
): Promise<Map<string, any>> {
    const existingMap = new Map<string, any>();

    // Firestore getAll can handle up to 100 documents at once
    const chunks: string[][] = [];
    for (let i = 0; i < productIds.length; i += 100) {
        chunks.push(productIds.slice(i, i + 100));
    }

    for (const chunk of chunks) {
        const refs = chunk.map(id => tescoCollection.doc(id));
        const docs = await admin.firestore().getAll(...refs);
        docs.forEach((doc, index) => {
            if (doc.exists) {
                existingMap.set(chunk[index], doc.data());
            }
        });
    }

    return existingMap;
}

// Parse serving size string to extract numeric value in grams/ml
function parseServingSizeToGrams(servingSize: string | undefined): number {
    if (!servingSize) return 100;

    // Match patterns like "330ml", "100g", "1 serving (50g)", "per 100g"
    const match = servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml|grams?|millilitre?s?)/i);
    if (match) {
        return parseFloat(match[1]);
    }

    // Default to 100g if we can't parse
    return 100;
}

// OPTIMIZED: Prepare Algolia object from product
function prepareAlgoliaObject(product: TescoProduct): any {
    const servingSizeStr = product.servingSize || 'per 100g';
    const servingSizeG = parseServingSizeToGrams(product.servingSize);

    return {
        objectID: product.id,
        name: product.title,
        foodName: product.title,
        brandName: product.brand,
        brand: product.brand,
        barcode: product.gtin,
        gtin: product.gtin,
        calories: product.nutrition?.energyKcal || 0,
        protein: product.nutrition?.protein || 0,
        carbs: product.nutrition?.carbohydrate || 0,
        fat: product.nutrition?.fat || 0,
        saturates: product.nutrition?.saturates || 0,
        sugar: product.nutrition?.sugars || 0,
        sugars: product.nutrition?.sugars || 0,
        fiber: product.nutrition?.fibre || 0,
        fibre: product.nutrition?.fibre || 0,
        salt: product.nutrition?.salt || 0,
        sodium: product.nutrition?.salt ? product.nutrition.salt * 400 : 0,
        ingredients: product.ingredients || '',
        servingSize: servingSizeStr,
        servingDescription: servingSizeStr, // iOS app expects this key
        servingSizeG: servingSizeG, // Parse actual serving size
        category: product.category || '',
        imageUrl: '', // Tesco images not used
        source: 'Tesco',
        verified: true,
        isVerified: true,
        allergens: product.allergens || []
    };
}

// Helper: Retry with exponential backoff
async function retryWithBackoff<T>(
    fn: () => Promise<T>,
    maxRetries: number = 3,
    baseDelay: number = 500,  // Reduced from 2000ms - API supports 5 req/s
    operationName: string = 'operation'
): Promise<T> {
    let lastError: any;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return await fn();
        } catch (error: any) {
            lastError = error;
            const statusCode = error.response?.status;

            // If rate limited (429), wait longer and retry
            if (statusCode === 429 && attempt < maxRetries) {
                const delay = baseDelay * Math.pow(2, attempt); // Exponential backoff: 2s, 4s, 8s
                console.log(`Rate limited on ${operationName}, waiting ${delay}ms before retry ${attempt + 1}/${maxRetries}...`);
                await sleep(delay);
                continue;
            }

            // For other errors, only retry once
            if (attempt < 1) {
                console.log(`Error in ${operationName}: ${error.message}, retrying once...`);
                await sleep(1000);
                continue;
            }

            throw error;
        }
    }

    throw lastError;
}

/**
 * Search Tesco products by keyword
 * @param apiKey - The API key (from secret) to use for the request
 */
async function searchTescoProducts(query: string, page: number = 0, apiKey?: string): Promise<{ products: any[]; totalPages: number }> {
    const key = apiKey || tesco8ApiKey.value();
    if (!key) {
        console.error('TESCO8_API_KEY secret not configured');
        return { products: [], totalPages: 0 };
    }

    return retryWithBackoff(async () => {
        const response = await axios.get(
            `https://${TESCO8_HOST}/product-search-by-keyword`,
            {
                params: {
                    query,
                    page: page.toString()
                },
                headers: {
                    'x-rapidapi-host': TESCO8_HOST,
                    'x-rapidapi-key': key
                },
                timeout: 15000
            }
        );

        if (!response.data?.success) {
            return { products: [], totalPages: 0 };
        }

        const products = response.data?.data?.products || [];
        const pagination = response.data?.data?.pagination || {};
        const totalPages = pagination.totalPages || 1;

        return { products, totalPages };
    }, 3, 1000, `search "${query}" page ${page}`);  // Reduced from 3000ms
}

/**
 * Search UK Groceries API - General UK grocery products
 * This API returns products with full details in one call (no separate details fetch needed)
 * @param apiKey - The API key (from secret) to use for the request
 */
async function searchUKGroceriesProducts(query: string, page: number = 0, apiKey?: string): Promise<{ products: TescoProduct[]; totalPages: number }> {
    const key = apiKey || ukGroceriesApiKey.value();
    if (!key) {
        console.error('UK_GROCERIES_API_KEY secret not configured');
        return { products: [], totalPages: 0 };
    }

    return retryWithBackoff(async () => {
        const response = await axios.get(
            `https://${UK_GROCERIES_HOST}/groceries/search/${encodeURIComponent(query)}`,
            {
                headers: {
                    'x-rapidapi-host': UK_GROCERIES_HOST,
                    'x-rapidapi-key': key
                },
                timeout: 30000
            }
        );

        console.log(`[UK_GROCERIES] Search "${query}" response keys: ${JSON.stringify(Object.keys(response.data || {}))}`);

        // The API might return data in different formats - handle both array and object
        let rawProducts: any[] = [];

        if (Array.isArray(response.data)) {
            rawProducts = response.data;
        } else if (response.data?.products) {
            rawProducts = response.data.products;
        } else if (response.data?.items) {
            rawProducts = response.data.items;
        } else if (response.data?.data) {
            rawProducts = Array.isArray(response.data.data) ? response.data.data : [response.data.data];
        }

        console.log(`[UK_GROCERIES] Found ${rawProducts.length} raw products for "${query}"`);

        // Parse and filter products with nutrition data
        const products: TescoProduct[] = [];

        for (const item of rawProducts) {
            try {
                const parsed = parseUKGroceriesProduct(item);
                if (parsed && hasValidNutrition(parsed.nutrition)) {
                    products.push(parsed);
                }
            } catch (e: any) {
                console.warn(`[UK_GROCERIES] Failed to parse product: ${e.message}`);
            }
        }

        console.log(`[UK_GROCERIES] ${products.length} products with valid nutrition for "${query}"`);

        // This API doesn't paginate the same way - assume single page for now
        return { products, totalPages: 1 };
    }, 3, 2000, `UK groceries search "${query}"`);
}

/**
 * Parse UK Groceries API product into our standard format
 */
function parseUKGroceriesProduct(item: any): TescoProduct | null {
    if (!item) return null;

    // Extract ID - try multiple fields
    const id = item.id || item.productId || item.sku || item.gtin || `ukg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Extract title/name
    const title = item.name || item.title || item.productName || item.description;
    if (!title) return null;

    // Extract brand
    const brand = item.brand || item.brandName || item.manufacturer || '';

    // Extract price
    const price = parseNumber(item.price || item.unitPrice || item.currentPrice);

    // Extract image
    const imageUrl = item.image || item.imageUrl || item.img || item.thumbnail ||
                     item.images?.[0] || item.productImage;

    // Extract nutrition - try multiple possible structures
    let nutrition: TescoProduct['nutrition'] = {};

    const nutritionData = item.nutrition || item.nutritionalInfo || item.nutritionInfo ||
                          item.nutritionFacts || item.nutrients || item.nutritionalValues || item;

    if (nutritionData) {
        // Try to extract each nutrient with multiple possible field names
        nutrition.energyKcal = parseNumber(
            nutritionData.energyKcal || nutritionData.kcal || nutritionData.calories ||
            nutritionData.energy_kcal || nutritionData.caloriesKcal || nutritionData.cal ||
            nutritionData.Energy?.kcal
        );

        nutrition.energyKj = parseNumber(
            nutritionData.energyKj || nutritionData.kj || nutritionData.energy_kj ||
            nutritionData.kilojoules || nutritionData.Energy?.kj
        );

        nutrition.fat = parseNumber(
            nutritionData.fat || nutritionData.totalFat || nutritionData.Fat ||
            nutritionData.fats || nutritionData.lipids
        );

        nutrition.saturates = parseNumber(
            nutritionData.saturates || nutritionData.saturatedFat || nutritionData.saturated ||
            nutritionData.saturated_fat || nutritionData.Saturates
        );

        nutrition.carbohydrate = parseNumber(
            nutritionData.carbohydrate || nutritionData.carbohydrates || nutritionData.carbs ||
            nutritionData.totalCarbohydrate || nutritionData.Carbohydrate
        );

        nutrition.sugars = parseNumber(
            nutritionData.sugars || nutritionData.sugar || nutritionData.totalSugars ||
            nutritionData.Sugars
        );

        nutrition.fibre = parseNumber(
            nutritionData.fibre || nutritionData.fiber || nutritionData.dietaryFibre ||
            nutritionData.dietary_fiber || nutritionData.Fibre
        );

        nutrition.protein = parseNumber(
            nutritionData.protein || nutritionData.proteins || nutritionData.Protein
        );

        // Handle salt - check for salt field first, then convert from sodium if needed
        // UK uses salt in grams, US uses sodium in mg
        const saltDirect = parseNumber(nutritionData.salt || nutritionData.Salt);
        if (saltDirect !== undefined && saltDirect > 0) {
            nutrition.salt = saltDirect;
        } else {
            // Try to convert from sodium (sodium is typically in mg)
            const sodiumVal = parseNumber(nutritionData.sodium);
            if (sodiumVal !== undefined && sodiumVal > 0) {
                // Sodium in mg to salt in g: salt = sodium(mg) * 2.5 / 1000
                nutrition.salt = (sodiumVal * 2.5) / 1000;
            }
        }
    }

    // Extract ingredients
    let ingredients = item.ingredients || item.ingredientsList || item.ingredientsText ||
                      item.ingredient_list || '';
    if (Array.isArray(ingredients)) {
        ingredients = ingredients.join(', ');
    }

    // Extract allergens
    let allergens: string[] = [];
    if (item.allergens) {
        allergens = Array.isArray(item.allergens) ? item.allergens : [item.allergens];
    } else if (item.allergenInfo) {
        allergens = identifyAllergens(item.allergenInfo);
    } else if (ingredients) {
        allergens = identifyAllergens(ingredients);
    }

    // Extract category
    const category = item.category || item.department || item.aisle || item.superDepartment || '';

    // Extract serving size
    const servingSize = item.servingSize || item.serving_size || item.portionSize || '';

    // Extract barcode/GTIN
    const gtin = item.gtin || item.barcode || item.ean || item.upc || '';

    return {
        id: `ukg_${id}`,
        tpnb: '',
        gtin,
        title,
        brand,
        description: item.description || item.productDescription || '',
        imageUrl,
        price,
        unitPrice: item.unitPrice || item.pricePerUnit || '',
        nutrition,
        ingredients,
        allergens,
        servingSize,
        category,
        importedAt: new Date().toISOString(),
        source: 'uk_groceries_api'
    };
}

/**
 * Search Spoonacular API - Grocery products with nutrition
 * Uses product search to find actual food items (not recipes)
 * @param apiKey - The API key (from secret) to use for the request
 */
async function searchSpoonacularProducts(query: string, page: number = 0, apiKey?: string): Promise<{ products: TescoProduct[]; totalPages: number }> {
    const key = apiKey || spoonacularApiKey.value();
    if (!key) {
        console.error('SPOONACULAR_API_KEY secret not configured');
        return { products: [], totalPages: 0 };
    }

    return retryWithBackoff(async () => {
        const offset = page * 10; // 10 results per page

        // Use grocery product search (not recipes)
        const response = await axios.get(
            `https://${SPOONACULAR_HOST}/food/products/search`,
            {
                params: {
                    query: query,
                    number: 10,
                    offset: offset
                },
                headers: {
                    'x-rapidapi-host': SPOONACULAR_HOST,
                    'x-rapidapi-key': key
                },
                timeout: 30000
            }
        );

        console.log(`[SPOONACULAR] Product search "${query}" offset ${offset} - status: ${response.status}`);

        const results = response.data?.products || [];
        const totalResults = response.data?.totalProducts || 0;
        const totalPages = Math.ceil(totalResults / 10);

        console.log(`[SPOONACULAR] Found ${results.length} products for "${query}" (${totalResults} total)`);

        // Parse products - need to fetch full details for nutrition
        const products: TescoProduct[] = [];

        for (const product of results) {
            try {
                // Get full product details with nutrition
                const detailResponse = await axios.get(
                    `https://${SPOONACULAR_HOST}/food/products/${product.id}`,
                    {
                        headers: {
                            'x-rapidapi-host': SPOONACULAR_HOST,
                            'x-rapidapi-key': key
                        },
                        timeout: 15000
                    }
                );

                const parsed = parseSpoonacularProduct(detailResponse.data);
                if (parsed && hasValidNutrition(parsed.nutrition)) {
                    products.push(parsed);
                }

                // Small delay to avoid rate limiting
                await new Promise(resolve => setTimeout(resolve, 200));
            } catch (e: any) {
                console.warn(`[SPOONACULAR] Failed to get product ${product.id}: ${e.message}`);
            }
        }

        console.log(`[SPOONACULAR] ${products.length} products with valid nutrition for "${query}"`);

        return { products, totalPages };
    }, 3, 2000, `Spoonacular search "${query}" page ${page}`);
}

/**
 * Parse Spoonacular grocery product into our standard product format
 */
function parseSpoonacularProduct(product: any): TescoProduct | null {
    if (!product) return null;

    const id = product.id ? `spoon_${product.id}` : `spoon_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const title = product.title;
    if (!title) return null;

    // Extract nutrition from the product nutrition structure
    let nutrition: TescoProduct['nutrition'] = {};
    const nutrients = product.nutrition?.nutrients || [];

    for (const nutrient of nutrients) {
        const name = nutrient.name?.toLowerCase() || '';
        const amount = nutrient.amount;
        // Note: unit is available as nutrient.unit if needed for debugging

        // Get serving size for normalization
        // Spoonacular returns nutrition per serving, we need per 100g
        const servingGrams = parseFloat(product.servings?.size) || parseFloat(product.servingSize) || 100;

        // Normalize to per 100g
        const normalizeToP100g = (val: number) => {
            if (servingGrams && servingGrams !== 100) {
                return (val / servingGrams) * 100;
            }
            return val;
        };

        // Map Spoonacular nutrients to our format
        if (name === 'calories') {
            nutrition.energyKcal = normalizeToP100g(amount);
        } else if (name === 'fat') {
            nutrition.fat = normalizeToP100g(amount);
        } else if (name === 'saturated fat') {
            nutrition.saturates = normalizeToP100g(amount);
        } else if (name === 'carbohydrates') {
            nutrition.carbohydrate = normalizeToP100g(amount);
        } else if (name === 'sugar') {
            nutrition.sugars = normalizeToP100g(amount);
        } else if (name === 'fiber') {
            nutrition.fibre = normalizeToP100g(amount);
        } else if (name === 'protein') {
            nutrition.protein = normalizeToP100g(amount);
        } else if (name === 'sodium') {
            // Sodium is in mg, normalize to per 100g then convert to salt in g
            // salt = sodium(mg) * 2.5 / 1000
            const sodiumPer100g = normalizeToP100g(amount);
            nutrition.salt = (sodiumPer100g * 2.5) / 1000;
        }
    }

    // Extract ingredients
    const ingredients = product.ingredientList || product.ingredients || '';

    // Extract allergens from ingredients
    const allergens = identifyAllergens(ingredients);

    // Get image URL
    const imageUrl = product.image || product.images?.[0] || '';

    // Get serving size
    const servingSize = product.servingSize || '';

    // Get category/aisle
    const category = product.aisle || product.breadcrumbs?.join(' > ') || 'Grocery';

    // Get barcode/UPC if available
    const gtin = product.upc || product.ean || '';

    return {
        id,
        tpnb: '',
        gtin,
        title,
        brand: product.brand || 'Unknown',
        description: product.description || '',
        imageUrl,
        price: product.price,
        unitPrice: '',
        nutrition,
        ingredients,
        allergens,
        servingSize,
        category,
        importedAt: new Date().toISOString(),
        source: 'spoonacular_api'
    };
}

/**
 * Get full product details including nutrition
 * @param apiKey - The API key (from secret) to use for the request
 */
interface ProductDetailsResult {
    product: TescoProduct | null;
    error?: string;
}

async function getProductDetails(productId: string, apiKey?: string): Promise<ProductDetailsResult> {
    const key = apiKey || tesco8ApiKey.value();
    if (!key) {
        console.error('TESCO8_API_KEY secret not configured');
        return { product: null, error: 'API key not configured' };
    }

    try {
        console.log(`Fetching product details for: ${productId}`);
        const response = await retryWithBackoff(async () => {
            return axios.get(
                `https://${TESCO8_HOST}/product-details`,
                {
                    params: { productId },
                    headers: {
                        'x-rapidapi-host': TESCO8_HOST,
                        'x-rapidapi-key': key
                    },
                    timeout: 15000
                }
            );
        }, 3, 1000, `product details ${productId}`);  // Reduced from 3000ms

        // Debug logging
        console.log(`Product ${productId} response status: ${response.status}`);
        console.log(`Product ${productId} response success: ${response.data?.success}`);
        console.log(`Product ${productId} response keys: ${JSON.stringify(Object.keys(response.data || {}))}`);

        if (!response.data?.success) {
            const errorMsg = `API returned success=false for ${productId}. Response: ${JSON.stringify(response.data).substring(0, 200)}`;
            console.error(errorMsg);
            return { product: null, error: errorMsg };
        }

        if (!response.data?.data?.results?.[0]?.data?.product) {
            const errorMsg = `No product data in response for ${productId}. Structure: data.data=${!!response.data?.data}, results=${JSON.stringify(response.data?.data?.results?.length || 0)}`;
            console.error(errorMsg);
            return { product: null, error: errorMsg };
        }

        const productData = response.data.data.results[0].data.product;
        const details = productData.details || {};

        // Check if this is a food item (filter out non-food products)
        const category = (productData.superDepartment || productData.department || '').toLowerCase();
        const title = (productData.title || '').toLowerCase();
        const brand = (productData.brand || '').toLowerCase();

        // Non-food categories
        const NON_FOOD_CATEGORIES = [
            'household', 'cleaning', 'laundry', 'pet', 'health', 'beauty',
            'toiletries', 'baby', 'nappies', 'home', 'garden', 'diy',
            'electrical', 'stationery', 'clothing', 'toys', 'seasonal',
            'battery', 'batteries'
        ];

        // Non-food brands (products from these brands are never food)
        const NON_FOOD_BRANDS = [
            'duracell', 'energizer', 'panasonic', 'varta', // Batteries
            'oral-b', 'oral b', 'colgate', 'sensodyne', 'aquafresh', 'listerine', // Oral care
            'dove', 'lynx', 'sure', 'nivea', 'garnier', 'loreal', "l'oreal", // Personal care
            'andrex', 'cushelle', 'kleenex', 'plenty', // Toilet/tissue
            'fairy', 'persil', 'ariel', 'bold', 'daz', 'surf', 'comfort', // Cleaning/laundry
            'dettol', 'domestos', 'flash', 'cillit bang', 'mr muscle', // Disinfectant/cleaning
            'nurofen', 'paracetamol', 'ibuprofen', 'calpol', 'lemsip', // Medicine
            'pampers', 'huggies', // Baby care
            'whiskas', 'felix', 'pedigree', 'iams', 'purina' // Pet food
        ];

        // Non-food keywords in title
        const NON_FOOD_KEYWORDS = [
            'battery', 'batteries', 'charger',
            'toothpaste', 'toothbrush', 'mouthwash', 'dental', 'floss',
            'shampoo', 'conditioner', 'soap', 'shower gel', 'body wash',
            'deodorant', 'antiperspirant', 'moisturiser', 'moisturizer',
            'toilet roll', 'toilet tissue', 'kitchen roll', 'tissues',
            'washing liquid', 'laundry', 'dishwasher', 'washing up',
            'bleach', 'disinfectant', 'cleaner', 'polish',
            'painkiller', 'tablet', 'capsule', 'medicine',
            'nappies', 'nappy', 'diaper', 'baby wipe',
            'cat food', 'dog food', 'pet food', 'pet treats',
            'light bulb', 'lightbulb', 'extension lead', 'plug'
        ];

        // Check category
        if (NON_FOOD_CATEGORIES.some(nf => category.includes(nf))) {
            console.log(`Skipping non-food product: ${productData.title} (category: ${category})`);
            return { product: null, error: `Non-food item: ${category}` };
        }

        // Check brand
        if (NON_FOOD_BRANDS.some(nfb => brand.includes(nfb))) {
            console.log(`Skipping non-food brand: ${productData.title} (brand: ${productData.brand})`);
            return { product: null, error: `Non-food brand: ${productData.brand}` };
        }

        // Check title keywords
        if (NON_FOOD_KEYWORDS.some(nfk => title.includes(nfk))) {
            console.log(`Skipping non-food product: ${productData.title} (title keyword match)`);
            return { product: null, error: `Non-food keyword in title` };
        }

        // Parse nutrition
        const nutrition: TescoProduct['nutrition'] = {};
        const nutritionItems = details.nutritionInfo || [];
        let servingSize: string | undefined;

        // Log the full details object structure to understand available fields
        console.log(`Product ${productId} details keys: ${JSON.stringify(Object.keys(details))}`);
        if (nutritionItems.length > 0) {
            console.log(`Product ${productId} nutrition item sample: ${JSON.stringify(nutritionItems[0])}`);
        }

        for (const item of nutritionItems) {
            const name = item.name?.toLowerCase() || '';
            const value = item.perComp || ''; // per 100g column

            // Energy - handles multiple formats:
            // 1. "Energy Content (KCAL)" with value "360"
            // 2. "Energy" with value "360kcal"
            // 3. "Energy" with value "1506kJ/360kcal" (slash-separated, kJ first then kcal)
            // 4. "Energy" with value "360kcal/1506kJ" (slash-separated, kcal first then kJ)
            if (name.includes('energy') || (name === '-' && value.includes('kcal'))) {
                // Check if name contains (KCAL) or (KJ) - indicates the value is just a number
                if (name.includes('(kcal)') || name.includes('kcal)')) {
                    // Value is just the number, e.g., "360"
                    nutrition.energyKcal = parseNumber(value);
                } else if (name.includes('(kj)') || name.includes('kj)')) {
                    // Value is just the number for kJ
                    nutrition.energyKj = parseNumber(value);
                } else {
                    // Value contains units - MUST extract with regex to avoid concatenation issues
                    // e.g., "1506kJ/360kcal" should give kcal=360, NOT kcal=1506360

                    // Extract kcal value - look for number immediately before 'kcal'
                    const kcalMatch = value.match(/(\d+(?:\.\d+)?)\s*kcal/i);
                    if (kcalMatch) {
                        nutrition.energyKcal = parseFloat(kcalMatch[1]);
                    }

                    // Extract kJ value - look for number immediately before 'kJ'
                    const kjMatch = value.match(/(\d+(?:\.\d+)?)\s*kJ/i);
                    if (kjMatch) {
                        nutrition.energyKj = parseFloat(kjMatch[1]);
                    }

                    // ONLY fall back to plain number parsing if NO unit found AND value doesn't contain a slash
                    // This prevents "1506kJ/360kcal" from being parsed as 1506360
                    if (!kcalMatch && !kjMatch && !value.includes('/') && !name.includes('kj')) {
                        const plainNum = parseNumber(value) || 0;
                        // Sanity check: calories per 100g should be under 1000 (pure fat is ~900)
                        if (plainNum > 0 && plainNum < 1000) {
                            nutrition.energyKcal = plainNum;
                        }
                    }
                }
            // Fat - handles "Fat", "Total Fat", "Total Fat (g)" etc. but NOT saturated fat
            } else if ((name === 'fat' || name.includes('total fat') || (name.startsWith('fat') && !name.includes('saturate'))) && !name.includes('saturate')) {
                nutrition.fat = parseNumber(value);
            } else if (name.includes('saturate')) {
                nutrition.saturates = parseNumber(value);
            } else if ((name.includes('carbohydrate') || name.includes('carbs') || name.includes('total carbohydrate')) && !name.includes('sugar')) {
                nutrition.carbohydrate = parseNumber(value);
            } else if (name.includes('sugar')) {
                nutrition.sugars = parseNumber(value);
            } else if (name.includes('fibre') || name.includes('fiber') || name.includes('dietary fiber')) {
                nutrition.fibre = parseNumber(value);
            } else if (name.includes('protein')) {
                nutrition.protein = parseNumber(value);
            } else if (name.includes('salt') || name.includes('sodium')) {
                // Handle sodium conversion if needed (sodium to salt = sodium * 2.5)
                if (name.includes('sodium') && !name.includes('salt')) {
                    const sodiumMg = parseNumber(value) || 0;
                    // If value is in mg (typically >100), convert to g then to salt
                    if (sodiumMg > 10) {
                        nutrition.salt = (sodiumMg / 1000) * 2.5;
                    } else if (sodiumMg > 0) {
                        // Already in grams
                        nutrition.salt = sodiumMg * 2.5;
                    }
                } else {
                    nutrition.salt = parseNumber(value);
                }
            }

            // Extract serving size from perServing column value or header
            // Try multiple patterns - Tesco uses various formats
            if (!servingSize) {
                // Check perServing column value for patterns like "30g", "Per 30g serving", etc.
                const perServingValue = item.perServing || '';
                if (perServingValue) {
                    // Try direct number match first (e.g., "30g" or "50ml")
                    let servingMatch = perServingValue.match(/^(\d+(?:\.\d+)?)\s*(g|ml)$/i);
                    if (!servingMatch) {
                        // Try "Per Xg" or "Per X g" format
                        servingMatch = perServingValue.match(/per\s+(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    }
                    if (!servingMatch) {
                        // Try "Xg serving" format
                        servingMatch = perServingValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)\s*serving/i);
                    }
                    if (!servingMatch) {
                        // Try any number with g/ml
                        servingMatch = perServingValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    }
                    if (servingMatch) {
                        servingSize = `${servingMatch[1]}${servingMatch[2].toLowerCase()}`;
                        console.log(`Found serving size from perServing: ${servingSize} (original: ${perServingValue})`);
                    }
                }
            }
        }

        // Try to get serving size from nutrition table header or servingSize field
        if (!servingSize && details.servingSize) {
            const match = details.servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.servingSize: ${servingSize}`);
            }
        }

        // Look for serving size in typical serving info
        if (!servingSize && details.typicalServingSize) {
            const match = details.typicalServingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.typicalServingSize: ${servingSize}`);
            }
        }

        // Check for servingHeader field (some products have this)
        if (!servingSize && details.servingHeader) {
            const match = details.servingHeader.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.servingHeader: ${servingSize}`);
            }
        }

        // Check unitOfMeasure or portionSize fields
        if (!servingSize && details.portionSize) {
            const match = details.portionSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from details.portionSize: ${servingSize}`);
            }
        }

        // Check product-level serving info
        if (!servingSize && productData.servingSize) {
            const match = productData.servingSize.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
            if (match) {
                servingSize = `${match[1]}${match[2].toLowerCase()}`;
                console.log(`Found serving size from productData.servingSize: ${servingSize}`);
            }
        }

        // Last resort: try to infer from the nutrition table structure itself
        // Sometimes the column header contains "Per serving (Xg)"
        if (!servingSize && details.nutritionInfo?.length > 0) {
            // Check for perServingHeader or columnHeaders
            const firstItem = details.nutritionInfo[0];
            for (const key of Object.keys(firstItem || {})) {
                if (key.toLowerCase().includes('serving') && !key.toLowerCase().includes('percomp')) {
                    const headerValue = String(firstItem[key] || '');
                    const match = headerValue.match(/(\d+(?:\.\d+)?)\s*(g|ml)/i);
                    if (match) {
                        servingSize = `${match[1]}${match[2].toLowerCase()}`;
                        console.log(`Found serving size from nutrition header field '${key}': ${servingSize}`);
                        break;
                    }
                }
            }
        }

        // Default to 100g if no serving size found (it's per 100g anyway)
        if (!servingSize) {
            servingSize = '100g';
            console.log(`No serving size found for ${productId}, defaulting to 100g`);
        }

        // CRITICAL: Skip products without ingredients AND without nutrition
        // Real food products ALWAYS have either ingredients or nutritional info
        // Non-food items (batteries, toiletries) have neither
        const hasIngredients = details.ingredients &&
            (Array.isArray(details.ingredients) ? details.ingredients.length > 0 : details.ingredients.trim().length > 0);
        const hasNutritionData = hasValidNutrition(nutrition);

        if (!hasIngredients && !hasNutritionData) {
            console.log(`Skipping non-food product: ${productData.title} (no ingredients and no nutrition data)`);
            return { product: null, error: 'Non-food item: no ingredients or nutrition' };
        }

        // Build product object
        const product: TescoProduct = {
            id: productData.id || productId,
            tpnb: productData.tpnb || '',
            gtin: productData.gtin || '',
            title: productData.title || '',
            brand: productData.brandName || 'Tesco',
            description: Array.isArray(productData.description)
                ? productData.description.join(' ')
                : productData.description,
            imageUrl: '', // Tesco images not used
            price: productData.price?.actual,
            unitPrice: productData.price?.unitPrice,
            nutrition,
            ingredients: cleanIngredients(details.ingredients),
            allergens: details.allergenInfo ? identifyAllergens(details.allergenInfo) : [],
            servingSize,
            category: productData.superDepartment || productData.department,
            importedAt: new Date().toISOString(),
            source: 'tesco8_api'
        };

        return { product };
    } catch (error: any) {
        console.error(`Details error for product ${productId}:`, error.message);
        return { product: null, error: `Exception: ${error.message}` };
    }
}

/**
 * Get current build progress
 */
export const getTescoBuildProgress = functions.https.onCall(async (_data, context) => {
    // Verify admin
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const db = admin.firestore();
    const progressDoc = await db.collection('system').doc('tescoBuildProgress').get();

    if (!progressDoc.exists) {
        return {
            apiSource: 'tesco8',
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            currentPage: 0,
            maxPages: 5,
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: '',
            lastUpdated: '',
            errorMessages: [],
            recentlyFoundProducts: []
        } as BuildProgress;
    }

    return progressDoc.data() as BuildProgress;
});

/**
 * Start or resume the Tesco database build
 */
export const startTescoBuild = functions
    .runWith({
        timeoutSeconds: 540,
        memory: '1GB',
        secrets: [tesco8ApiKey, ukGroceriesApiKey, spoonacularApiKey, algoliaAdminKey]
    })
    .https.onCall(async (data, context) => {
        // Verify admin
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }

        const db = admin.firestore();
        const progressRef = db.collection('system').doc('tescoBuildProgress');

        // Get API source from request (default to tesco8)
        const requestedApiSource: ApiSource = data?.apiSource || 'tesco8';

        // Get current progress
        const progressDoc = await progressRef.get();
        let progress: BuildProgress = progressDoc.exists
            ? progressDoc.data() as BuildProgress
            : {
                apiSource: requestedApiSource,
                status: 'idle',
                currentTermIndex: 0,
                currentTerm: '',
                totalTerms: SEARCH_TERMS.length,
                currentPage: 0,       // Start fresh with new simplified terms
                maxPages: 20,         // 20 pages per term for deep coverage
                productsFound: 0,
                productsWithNutrition: 0,
                productsSaved: 0,
                duplicatesSkipped: 0,
                errors: 0,
                startedAt: new Date().toISOString(),
                lastUpdated: new Date().toISOString(),
                errorMessages: [],
                recentlyFoundProducts: []
            };

        // Ensure currentPage and maxPages exist for older progress docs
        if (progress.currentPage === undefined) progress.currentPage = 0;
        if (progress.maxPages === undefined) progress.maxPages = 20;
        if (!progress.apiSource) progress.apiSource = 'tesco8';

        // If switching API source, FORCE RESET to start fresh with new API
        if (data?.apiSource && data.apiSource !== progress.apiSource) {
            console.log(`[START] Switching API source from ${progress.apiSource} to ${data.apiSource} - FORCING RESET`);
            progress = {
                apiSource: data.apiSource,
                status: 'running',
                currentTermIndex: 0,
                currentTerm: SEARCH_TERMS[0],
                totalTerms: SEARCH_TERMS.length,
                currentPage: 0,
                maxPages: 20,
                productsFound: 0,
                productsWithNutrition: 0,
                productsSaved: 0,
                duplicatesSkipped: 0,
                errors: 0,
                startedAt: new Date().toISOString(),
                lastUpdated: new Date().toISOString(),
                errorMessages: [`Switched to ${data.apiSource} API`],
                recentlyFoundProducts: []
            };
            // Skip other checks - we're starting fresh with new API
            await progressRef.set(progress);
            console.log(`[START] API switch complete - starting fresh build with ${data.apiSource}`);
            return {
                success: true,
                message: `Switched to ${data.apiSource} API and started fresh build`,
                progress
            };
        }

        // Log current status for debugging
        console.log(`[START] Current status: ${progress.status}, currentTermIndex: ${progress.currentTermIndex}/${SEARCH_TERMS.length}, lastUpdated: ${progress.lastUpdated}`);

        // Check if already running - but handle stale 'running' status
        // Cloud Functions timeout after 540 seconds (9 mins) without updating status
        // If lastUpdated is more than 10 minutes old, the function has timed out
        if (progress.status === 'running') {
            const lastUpdated = new Date(progress.lastUpdated).getTime();
            const now = Date.now();
            const staleCutoff = 10 * 60 * 1000; // 10 minutes

            if (now - lastUpdated < staleCutoff) {
                // Recently updated - actually still running
                console.log(`[START] Build already running (last updated ${Math.round((now - lastUpdated) / 1000)}s ago). Returning.`);
                return {
                    success: false,
                    message: 'Build already in progress',
                    progress
                };
            } else {
                // Stale 'running' status - function timed out without updating
                console.log(`[START] Detected stale 'running' status (last updated ${Math.round((now - lastUpdated) / 60000)} mins ago). Resuming build...`);
                // Fall through to allow restart
            }
        }

        // Option to reset - check this FIRST before the completed check
        if (data?.reset) {
            console.log(`[START] Reset requested - restarting build from beginning with API: ${requestedApiSource}`);
            progress = {
                apiSource: requestedApiSource,
                status: 'running',
                currentTermIndex: 0,
                currentTerm: SEARCH_TERMS[0],
                totalTerms: SEARCH_TERMS.length,
                currentPage: 0,       // Start fresh with new simplified terms
                maxPages: 20,         // 20 pages per term for deep coverage
                productsFound: 0,
                productsWithNutrition: 0,
                productsSaved: 0,
                duplicatesSkipped: 0,
                errors: 0,
                startedAt: new Date().toISOString(),
                lastUpdated: new Date().toISOString(),
                errorMessages: [],
                recentlyFoundProducts: []
            };
        } else if (progress.status === 'completed') {
            // Check if we have NEW terms to process (totalTerms increased)
            if (progress.currentTermIndex < SEARCH_TERMS.length) {
                console.log(`[START] Build was completed but NEW terms detected! Continuing from term ${progress.currentTermIndex} (${SEARCH_TERMS[progress.currentTermIndex]})`);
                progress.status = 'running';
                progress.totalTerms = SEARCH_TERMS.length;
                progress.currentTerm = SEARCH_TERMS[progress.currentTermIndex];
                progress.currentPage = 0; // Start fresh for the new term
                progress.lastUpdated = new Date().toISOString();
            } else {
                // Truly completed - all terms done
                console.log(`[START] Build already completed. Use reset=true to restart.`);
                return {
                    success: false,
                    message: 'Build already completed. Use reset to restart.',
                    progress
                };
            }
        } else {
            progress.status = 'running';
            progress.lastUpdated = new Date().toISOString();
        }

        // Clear stop flag when starting - user initiated a new start
        progress.stopRequested = false;
        console.log(`[START] Starting build with API: ${progress.apiSource}, stopRequested cleared`);

        await progressRef.set(progress);

        // Get the correct collection and index for this API source
        const apiConfig = getApiConfig(progress.apiSource);
        const productCollection = db.collection(apiConfig.collection);
        const algoliaIndexName = apiConfig.algoliaIndex;
        console.log(`[START] Using collection: ${apiConfig.collection}, Algolia index: ${algoliaIndexName}`);

        // Initialize Algolia
        let algoliaClient: ReturnType<typeof algoliasearch> | null = null;
        const algoliaKey = algoliaAdminKey.value();
        if (algoliaKey) {
            algoliaClient = algoliasearch(ALGOLIA_APP_ID, algoliaKey);
        }

        const seenProductIds = new Set<string>();
        const ALGOLIA_BATCH_SIZE = 100; // Batch Algolia writes for efficiency
        let algoliaBatch: any[] = [];

        // Helper to flush Algolia batch
        const flushAlgoliaBatch = async () => {
            if (algoliaBatch.length > 0 && algoliaClient) {
                try {
                    await algoliaClient.saveObjects({
                        indexName: algoliaIndexName,
                        objects: algoliaBatch
                    });
                    console.log(`[ALGOLIA] Flushed ${algoliaBatch.length} objects to ${algoliaIndexName}`);
                } catch (e: any) {
                    console.error(`[ALGOLIA] Batch error: ${e.message}`);
                }
                algoliaBatch = [];
            }
        };

        try {
            // Process search terms from where we left off - 5 PAGES PER TERM
            // This approach: Pages 0-4 of term 0, then pages 0-4 of term 1, etc.
            console.log(`[LOOP] Starting from term index ${progress.currentTermIndex} page ${progress.currentPage} (${SEARCH_TERMS[progress.currentTermIndex] || 'END'})`);
            for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
                const term = SEARCH_TERMS[termIndex];
                progress.currentTermIndex = termIndex;
                progress.currentTerm = term;

                // Process multiple pages for this term (from currentPage to maxPages-1)
                const startPage = (termIndex === progress.currentTermIndex) ? progress.currentPage : 0;
                for (let page = startPage; page < progress.maxPages; page++) {
                    progress.currentPage = page;
                    progress.lastUpdated = new Date().toISOString();
                    await progressRef.update({...progress});

                    console.log(`[SEARCH] "${term}" page ${page + 1}/${progress.maxPages} (term ${termIndex + 1}/${SEARCH_TERMS.length}) [API: ${progress.apiSource}]`);

                    let shouldBreakAfterProcessing = false;

                    try {
                        let batchResults: Array<{ productId: string; product: TescoProduct | null; error?: string }> = [];
                        let existingMap: Map<string, any> = new Map();

                        // Handle different API sources
                        if (progress.apiSource === 'uk_groceries') {
                            // UK Groceries API returns full products directly
                            const { products: fullProducts } = await searchUKGroceriesProducts(term, page);

                            // Skip if no products
                            if (fullProducts.length === 0) {
                                console.log(`[SEARCH] UK Groceries: No products found for "${term}"`);
                                break; // Move to next term - UK Groceries doesn't paginate
                            }

                            // Filter out already seen products
                            const newProducts = fullProducts.filter(p => !seenProductIds.has(p.id));
                            newProducts.forEach(p => seenProductIds.add(p.id));
                            progress.productsFound += newProducts.length;

                            // Batch check existing documents
                            const productIds = newProducts.map(p => p.id);
                            existingMap = await batchCheckExisting(productCollection, productIds);

                            // Convert to batch result format
                            batchResults = newProducts.map(product => ({
                                productId: product.id,
                                product,
                                error: undefined
                            }));

                            console.log(`[SEARCH] UK Groceries: ${newProducts.length} new products for "${term}"`);

                            // UK Groceries doesn't paginate - move to next term after processing
                            shouldBreakAfterProcessing = true;
                        } else if (progress.apiSource === 'spoonacular') {
                            // Spoonacular API returns full recipes with nutrition
                            const { products: fullProducts, totalPages } = await searchSpoonacularProducts(term, page);

                            // Skip if no products
                            if (fullProducts.length === 0) {
                                console.log(`[SEARCH] Spoonacular: No recipes found for "${term}"`);
                                break; // Move to next term
                            }

                            // Skip if this page doesn't exist
                            if (page >= totalPages) {
                                console.log(`[SEARCH] Spoonacular: Term "${term}" only has ${totalPages} pages, done`);
                                break;
                            }

                            // Filter out already seen products
                            const newProducts = fullProducts.filter(p => !seenProductIds.has(p.id));
                            newProducts.forEach(p => seenProductIds.add(p.id));
                            progress.productsFound += newProducts.length;

                            // Batch check existing documents
                            const productIds = newProducts.map(p => p.id);
                            existingMap = await batchCheckExisting(productCollection, productIds);

                            // Convert to batch result format
                            batchResults = newProducts.map(product => ({
                                productId: product.id,
                                product,
                                error: undefined
                            }));

                            console.log(`[SEARCH] Spoonacular: ${newProducts.length} new recipes for "${term}"`);
                        } else {
                            // Tesco8 API - search returns IDs, then fetch details
                            const { products, totalPages } = await searchTescoProducts(term, page);

                            // Skip if this page doesn't exist for this term
                            if (page >= totalPages) {
                                console.log(`[SEARCH] Term "${term}" only has ${totalPages} pages, done with this term`);
                                break; // Move to next term
                            }

                            // OPTIMIZED: Batch check which products already exist
                            const newProductIds = products.filter(p => !seenProductIds.has(p.id)).map(p => p.id);
                            newProductIds.forEach(id => seenProductIds.add(id));
                            progress.productsFound += newProductIds.length;

                            // Batch read existing documents
                            existingMap = await batchCheckExisting(productCollection, newProductIds);

                            // OPTIMIZED: Fetch product details in parallel batches with rate limiting
                            const idsToFetch = newProductIds.filter(id => {
                                const existing = existingMap.get(id);
                                return !existing || true;
                            });

                            console.log(`[BATCH] Fetching ${idsToFetch.length} products in parallel batches`);
                            batchResults = await processProductBatch(idsToFetch);
                        }

                    // Process batch results
                    for (const { productId, product, error: detailsError } of batchResults) {
                        if (detailsError) {
                            progress.errors++;
                            progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                            if (progress.errorMessages.length > 50) {
                                progress.errorMessages = progress.errorMessages.slice(-50);
                            }
                            continue;
                        }

                        const existingData = existingMap.get(productId);

                        // Check if existing and if new data is more complete
                        if (existingData && product) {
                            if (!isMoreComplete(product, existingData)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            // New data is more complete - will update below
                            console.log(`Updating ${product.id} with more complete data`);
                        } else if (existingData) {
                            progress.duplicatesSkipped++;
                            continue;
                        }

                        if (product) {
                            // STRICT VALIDATION: Must have title, ID, and valid calories
                            const validation = isValidProduct(product);
                            if (!validation.valid) {
                                console.log(`Skipping invalid product: ${product.title?.substring(0, 40)} - ${validation.reason}`);
                                progress.errors++;
                                progress.errorMessages.push(`Invalid product: ${validation.reason} - ${product.title?.substring(0, 30)}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue;
                            }

                            progress.productsWithNutrition++;

                            // Save to Firestore with error handling (set will create or update)
                            try {
                                await productCollection.doc(product.id).set(removeUndefined(product));
                                progress.productsSaved++;
                                progress.lastProductSavedAt = new Date().toISOString(); // Track for stall detection
                                console.log(`Saved product to ${apiConfig.collection}: ${product.id} - ${product.title?.substring(0, 40)} (${product.nutrition?.energyKcal} kcal)`);

                                // Track this product in recentlyFoundProducts
                                if (!progress.recentlyFoundProducts) {
                                    progress.recentlyFoundProducts = [];
                                }
                                progress.recentlyFoundProducts.push({
                                    id: product.id,
                                    title: product.title || 'Unknown',
                                    brand: product.brand,
                                    hasNutrition: hasValidNutrition(product.nutrition),
                                    savedAt: new Date().toISOString()
                                });
                                // Keep only last 30 products
                                if (progress.recentlyFoundProducts.length > 30) {
                                    progress.recentlyFoundProducts = progress.recentlyFoundProducts.slice(-30);
                                }
                            } catch (firestoreError: any) {
                                console.error(`Firestore save error for ${product.id}:`, firestoreError.message);
                                progress.errors++;
                                progress.errorMessages.push(`Firestore save failed: ${firestoreError.message}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue; // Skip Algolia sync if Firestore failed
                            }

                            // OPTIMIZED: Add to Algolia batch instead of individual writes
                            algoliaBatch.push(prepareAlgoliaObject(product));
                            if (algoliaBatch.length >= ALGOLIA_BATCH_SIZE) {
                                await flushAlgoliaBatch();
                            }
                        }
                    }
                        // No sleep() needed - rate limiter handles timing

                        // Flush Algolia batch after each page
                        await flushAlgoliaBatch();

                        // Update progress after each page
                        progress.lastUpdated = new Date().toISOString();
                        await progressRef.update({...progress});

                    } catch (searchError: any) {
                        progress.errors++;
                        progress.errorMessages.push(`Term "${term}" page ${page}: ${searchError.message}`);
                        if (progress.errorMessages.length > 50) {
                            progress.errorMessages = progress.errorMessages.slice(-50);
                        }
                        console.error(`Error searching "${term}" page ${page}:`, searchError.message);

                        // Rate limit on error - wait before continuing
                        if (searchError.response?.status === 429) {
                            console.log('Rate limited - waiting 10 seconds before next page');
                            await sleep(10000);
                        } else {
                            // Short delay for other errors
                            await sleep(500);
                        }
                    }

                    // Check for pause request
                    const currentProgress = await progressRef.get();
                    if (currentProgress.data()?.status === 'paused') {
                        console.log('Build paused by user');
                        return {
                            success: true,
                            message: 'Build paused',
                            progress: currentProgress.data()
                        };
                    }

                    // For UK Groceries API, break after first page (no pagination)
                    if (shouldBreakAfterProcessing) {
                        console.log(`[SEARCH] UK Groceries: Moving to next term after processing`);
                        break;
                    }
                } // End page loop

                // Reset page to 0 for next term
                progress.currentPage = 0;
            } // End term loop

            // Final flush of any remaining Algolia objects
            await flushAlgoliaBatch();

            // Mark as completed
            console.log(`[COMPLETE] All ${SEARCH_TERMS.length} search terms processed.`);
            progress.status = 'completed';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});

            return {
                success: true,
                message: 'Build completed',
                progress
            };

        } catch (error: any) {
            console.error(`[ERROR] Fatal error: ${error.message}`, error.stack);
            progress.status = 'error';
            progress.errorMessages.push(`Fatal: ${error.message}`);
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});

            throw new functions.https.HttpsError('internal', `Build failed: ${error.message}`);
        }
    });

/**
 * Pause the Tesco database build
 */
export const pauseTescoBuild = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');

    await progressRef.update({
        status: 'paused',
        lastUpdated: new Date().toISOString()
    });

    return { success: true, message: 'Build paused' };
});

/**
 * STOP the Tesco database build completely (not just pause)
 * This sets status to 'idle' so scheduled function won't restart it
 */
export const stopTescoBuild = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const db = admin.firestore();
    const progressRef = db.collection('system').doc('tescoBuildProgress');

    await progressRef.update({
        status: 'idle',
        stopRequested: true, // Block scheduled function from auto-restarting
        lastUpdated: new Date().toISOString()
    });

    console.log('[STOP] Build stopped completely - stopRequested flag set');
    return { success: true, message: 'Build stopped completely' };
});

/**
 * Scheduled function to auto-continue Tesco build every 5 minutes
 * This keeps the build running continuously until all products are imported
 */
export const scheduledTescoBuild = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .pubsub
    .schedule('every 5 minutes')
    .onRun(async () => {
        const db = admin.firestore();
        const progressRef = db.collection('system').doc('tescoBuildProgress');

        // Get current progress
        const progressDoc = await progressRef.get();
        let progress: BuildProgress = progressDoc.exists
            ? progressDoc.data() as BuildProgress
            : {
                apiSource: 'tesco8',
                status: 'idle',
                currentTermIndex: 0,
                currentTerm: '',
                totalTerms: SEARCH_TERMS.length,
                currentPage: 0,
                maxPages: 5,
                productsFound: 0,
                productsWithNutrition: 0,
                productsSaved: 0,
                duplicatesSkipped: 0,
                errors: 0,
                startedAt: new Date().toISOString(),
                lastUpdated: new Date().toISOString(),
                errorMessages: [],
                recentlyFoundProducts: []
            };

        // Ensure currentPage and maxPages exist for older progress docs
        if (progress.currentPage === undefined) progress.currentPage = 0;
        if (progress.maxPages === undefined) progress.maxPages = 20;
        if (!progress.apiSource) progress.apiSource = 'tesco8';

        // Get the correct collection and index for this API source
        const apiConfig = getApiConfig(progress.apiSource);
        const productCollection = db.collection(apiConfig.collection);
        const algoliaIndexName = apiConfig.algoliaIndex;

        console.log(`[SCHEDULED] Status: ${progress.status}, Page: ${progress.currentPage}/${progress.maxPages}, Term: ${progress.currentTermIndex}/${progress.totalTerms}, API: ${progress.apiSource}`);

        // Only run if status is 'running' (started via admin UI)
        // Don't run if paused, completed, or idle
        if (progress.status !== 'running') {
            console.log(`[SCHEDULED] Build status is '${progress.status}', not continuing.`);
            return null;
        }

        // Check if user requested stop - respect the stop request
        if (progress.stopRequested) {
            console.log(`[SCHEDULED] Stop was requested by user - aborting scheduled run`);
            return null;
        }

        // ============ STALL DETECTION & AUTO-RESTART ============
        // Check if we've stalled (no product saved in last 2 minutes)
        const STALL_THRESHOLD_MS = 2 * 60 * 1000; // 2 minutes
        const AUTO_RESTART_DELAY_MS = 30 * 1000; // 30 seconds
        const now = Date.now();

        const lastProductTime = progress.lastProductSavedAt
            ? new Date(progress.lastProductSavedAt).getTime()
            : new Date(progress.lastUpdated).getTime();
        const timeSinceLastProduct = now - lastProductTime;

        if (timeSinceLastProduct > STALL_THRESHOLD_MS) {
            console.log(`[SCHEDULED] ⚠️ STALL DETECTED! No product saved for ${Math.round(timeSinceLastProduct / 1000)}s`);
            console.log(`[SCHEDULED] 🔄 Auto-restarting: pausing, waiting 30s, then resuming...`);

            // Update progress to show we're auto-restarting
            progress.autoRestartCount = (progress.autoRestartCount || 0) + 1;
            progress.lastAutoRestart = new Date().toISOString();
            progress.errorMessages.push(`Auto-restart #${progress.autoRestartCount} at ${progress.lastAutoRestart} - stalled for ${Math.round(timeSinceLastProduct / 1000)}s`);
            if (progress.errorMessages.length > 50) {
                progress.errorMessages = progress.errorMessages.slice(-50);
            }

            // Step 1: Pause
            progress.status = 'paused';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});
            console.log(`[SCHEDULED] ⏸️ Paused. Waiting ${AUTO_RESTART_DELAY_MS / 1000}s before restart...`);

            // Step 2: Wait 30 seconds
            await new Promise(resolve => setTimeout(resolve, AUTO_RESTART_DELAY_MS));

            // Step 3: Check if stop was requested during the wait
            const freshProgress = await progressRef.get();
            if (freshProgress.exists && freshProgress.data()?.stopRequested) {
                console.log(`[SCHEDULED] Stop was requested during wait period - not resuming`);
                return null;
            }

            // Step 4: Resume
            progress.status = 'running';
            progress.lastUpdated = new Date().toISOString();
            progress.lastProductSavedAt = new Date().toISOString(); // Reset the timer
            await progressRef.update({...progress});
            console.log(`[SCHEDULED] ▶️ Resumed after auto-restart #${progress.autoRestartCount}`);
        }
        // ============ END STALL DETECTION ============

        // Check if already completed (all terms done)
        if (progress.currentTermIndex >= SEARCH_TERMS.length) {
            console.log(`[SCHEDULED] All ${SEARCH_TERMS.length} terms completed, marking as completed.`);
            progress.status = 'completed';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});
            return null;
        }

        // Update lastUpdated to show we're still active
        progress.lastUpdated = new Date().toISOString();
        await progressRef.update({...progress});

        // Initialize Algolia
        let algoliaClient: ReturnType<typeof algoliasearch> | null = null;
        const algoliaKey = algoliaAdminKey.value();
        if (algoliaKey) {
            algoliaClient = algoliasearch(ALGOLIA_APP_ID, algoliaKey);
        }

        const seenProductIds = new Set<string>();
        const ALGOLIA_BATCH_SIZE = 100;
        let algoliaBatch: any[] = [];

        // Helper to flush Algolia batch
        const flushAlgoliaBatch = async () => {
            if (algoliaBatch.length > 0 && algoliaClient) {
                try {
                    await algoliaClient.saveObjects({
                        indexName: algoliaIndexName,
                        objects: algoliaBatch
                    });
                    console.log(`[SCHEDULED] Flushed ${algoliaBatch.length} items to ${algoliaIndexName}`);
                } catch (e: any) {
                    console.error(`[SCHEDULED] Algolia batch error: ${e.message}`);
                }
                algoliaBatch = [];
            }
        };

        try {
            // Process search terms from where we left off - 5 PAGES PER TERM
            // This approach: Pages 0-4 of term 0, then pages 0-4 of term 1, etc.
            console.log(`[SCHEDULED] Starting from term index ${progress.currentTermIndex} page ${progress.currentPage}`);
            for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
                const term = SEARCH_TERMS[termIndex];
                progress.currentTermIndex = termIndex;
                progress.currentTerm = term;

                // Process multiple pages for this term (from currentPage to maxPages-1)
                const startPage = (termIndex === progress.currentTermIndex) ? progress.currentPage : 0;
                for (let page = startPage; page < progress.maxPages; page++) {
                    progress.currentPage = page;
                    progress.lastUpdated = new Date().toISOString();
                    await progressRef.update({...progress});

                    console.log(`[SCHEDULED] "${term}" page ${page + 1}/${progress.maxPages} (term ${termIndex + 1}/${SEARCH_TERMS.length}) [API: ${progress.apiSource || 'tesco8'}]`);

                    let shouldBreakAfterProcessing = false;

                    try {
                        let batchResults: Array<{ productId: string; product: TescoProduct | null; error?: string }> = [];
                        let existingMap: Map<string, any> = new Map();

                        // Handle different API sources
                        if (progress.apiSource === 'uk_groceries') {
                            // UK Groceries API returns full products directly
                            const { products: fullProducts } = await searchUKGroceriesProducts(term, page);

                            // Skip if no products
                            if (fullProducts.length === 0) {
                                console.log(`[SCHEDULED] UK Groceries: No products found for "${term}"`);
                                break; // Move to next term
                            }

                            // Filter out already seen products
                            const newProducts = fullProducts.filter(p => !seenProductIds.has(p.id));
                            newProducts.forEach(p => seenProductIds.add(p.id));
                            progress.productsFound += newProducts.length;

                            // Batch check existing documents
                            const productIds = newProducts.map(p => p.id);
                            existingMap = await batchCheckExisting(productCollection, productIds);

                            // Convert to batch result format
                            batchResults = newProducts.map(product => ({
                                productId: product.id,
                                product,
                                error: undefined
                            }));

                            console.log(`[SCHEDULED] UK Groceries: ${newProducts.length} new products for "${term}"`);
                            shouldBreakAfterProcessing = true;
                        } else if (progress.apiSource === 'spoonacular') {
                            // Spoonacular API returns full recipes with nutrition
                            const { products: fullProducts, totalPages } = await searchSpoonacularProducts(term, page);

                            // Skip if no products
                            if (fullProducts.length === 0) {
                                console.log(`[SCHEDULED] Spoonacular: No recipes found for "${term}"`);
                                break; // Move to next term
                            }

                            // Skip if this page doesn't exist
                            if (page >= totalPages) {
                                console.log(`[SCHEDULED] Spoonacular: Term "${term}" only has ${totalPages} pages, done`);
                                break;
                            }

                            // Filter out already seen products
                            const newProducts = fullProducts.filter(p => !seenProductIds.has(p.id));
                            newProducts.forEach(p => seenProductIds.add(p.id));
                            progress.productsFound += newProducts.length;

                            // Batch check existing documents
                            const productIds = newProducts.map(p => p.id);
                            existingMap = await batchCheckExisting(productCollection, productIds);

                            // Convert to batch result format
                            batchResults = newProducts.map(product => ({
                                productId: product.id,
                                product,
                                error: undefined
                            }));

                            console.log(`[SCHEDULED] Spoonacular: ${newProducts.length} new recipes for "${term}"`);
                        } else {
                            // Tesco8 API - search returns IDs, then fetch details
                            const { products, totalPages } = await searchTescoProducts(term, page);

                            // Skip if this page doesn't exist for this term
                            if (page >= totalPages) {
                                console.log(`[SCHEDULED] Term "${term}" only has ${totalPages} pages, done with this term`);
                                break; // Move to next term
                            }

                            // OPTIMIZED: Filter out already seen products first
                            const newProducts = products.filter(p => {
                                if (seenProductIds.has(p.id)) {
                                    progress.duplicatesSkipped++;
                                    return false;
                                }
                                seenProductIds.add(p.id);
                                progress.productsFound++;
                                return true;
                            });

                            // OPTIMIZED: Batch check which products already exist in Firestore
                            const newProductIds = newProducts.map(p => p.id);
                            existingMap = await batchCheckExisting(productCollection, newProductIds);

                            // OPTIMIZED: Fetch product details in parallel batches with rate limiting
                            if (newProductIds.length > 0) {
                                console.log(`[SCHEDULED] Fetching ${newProductIds.length} products in parallel batches`);
                                batchResults = await processProductBatch(newProductIds);
                            }
                        }

                    // Process batch results
                    if (batchResults.length > 0) {

                        for (const { productId, product, error: detailsError } of batchResults) {
                            if (detailsError) {
                                progress.errors++;
                                progress.errorMessages.push(`Details: ${detailsError}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue;
                            }

                            // Check if existing and if new data is more complete
                            const existingData = existingMap.get(productId);
                            if (existingData && product) {
                                if (!isMoreComplete(product, existingData)) {
                                    progress.duplicatesSkipped++;
                                    continue;
                                }
                                console.log(`[SCHEDULED] Updating ${product.id} with more complete data`);
                            } else if (existingData) {
                                progress.duplicatesSkipped++;
                                continue;
                            }

                            if (product) {
                                // STRICT VALIDATION: Must have title, ID, and valid calories
                                const validation = isValidProduct(product);
                                if (!validation.valid) {
                                    console.log(`[SCHEDULED] Skipping invalid: ${product.title?.substring(0, 30)} - ${validation.reason}`);
                                    continue;
                                }

                                progress.productsWithNutrition++;

                                try {
                                    await productCollection.doc(product.id).set(removeUndefined(product));
                                    progress.productsSaved++;
                                    progress.lastProductSavedAt = new Date().toISOString(); // Track for stall detection
                                    console.log(`[SCHEDULED] Saved to ${apiConfig.collection}: ${product.title?.substring(0, 30)} (${product.nutrition?.energyKcal} kcal)`);

                                    // OPTIMIZED: Add to Algolia batch instead of individual writes
                                    algoliaBatch.push(prepareAlgoliaObject(product));
                                    if (algoliaBatch.length >= ALGOLIA_BATCH_SIZE) {
                                        await flushAlgoliaBatch();
                                    }
                                } catch (e: any) {
                                    progress.errors++;
                                }
                            }
                        }
                    } // End if (batchResults.length > 0)

                        // Update progress after processing this page
                        progress.lastUpdated = new Date().toISOString();
                        await progressRef.update({...progress});

                        // Flush any remaining Algolia items after processing page
                        await flushAlgoliaBatch();

                    } catch (searchError: any) {
                        progress.errors++;
                        if (searchError.response?.status === 429) {
                            await sleep(10000);
                        }
                    }

                    // Check for pause
                    const currentProgress = await progressRef.get();
                    if (currentProgress.data()?.status === 'paused') {
                        console.log('[SCHEDULED] Build paused');
                        // Flush remaining Algolia items before pausing
                        await flushAlgoliaBatch();
                        return null;
                    }

                    // For UK Groceries API, break after first page (no pagination)
                    if (shouldBreakAfterProcessing) {
                        console.log(`[SCHEDULED] UK Groceries: Moving to next term after processing`);
                        break;
                    }
                } // End page loop

                // Reset page to 0 for next term
                progress.currentPage = 0;
            } // End term loop

            // Flush any remaining Algolia items
            await flushAlgoliaBatch();

            // All terms are done - mark as completed
            progress.status = 'completed';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});
            console.log(`[SCHEDULED] All ${SEARCH_TERMS.length} terms completed!`);

        } catch (error: any) {
            console.error(`[SCHEDULED] Error: ${error.message}`);
            progress.errorMessages.push(`Scheduled: ${error.message}`);
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});
        }

        return null;
    });

/**
 * Reset the Tesco database (delete all and start fresh)
 */
export const resetTescoDatabase = functions
    .runWith({ timeoutSeconds: 300, memory: '512MB', secrets: [algoliaAdminKey] })
    .https.onCall(async (_data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }

        const db = admin.firestore();
        const tescoCollection = db.collection('tescoProducts');

        // Delete all documents in batches
        const batchSize = 500;
        let deleted = 0;

        while (true) {
            const snapshot = await tescoCollection.limit(batchSize).get();
            if (snapshot.empty) break;

            const batch = db.batch();
            snapshot.docs.forEach(doc => batch.delete(doc.ref));
            await batch.commit();
            deleted += snapshot.size;
            console.log(`Deleted ${deleted} Tesco products`);
        }

        // Reset progress
        await db.collection('system').doc('tescoBuildProgress').set({
            apiSource: 'tesco8',
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            currentPage: 0,
            maxPages: 20,
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: '',
            lastUpdated: new Date().toISOString(),
            errorMessages: [],
            recentlyFoundProducts: []
        });

        // Clear Algolia index
        const clearAlgoliaKey = algoliaAdminKey.value();
        if (clearAlgoliaKey) {
            try {
                const algoliaClient = algoliasearch(ALGOLIA_APP_ID, clearAlgoliaKey);
                await algoliaClient.clearObjects({ indexName: TESCO_INDEX_NAME });
                console.log('Cleared Algolia index');
            } catch (error: any) {
                console.error('Algolia clear error:', error.message);
            }
        }

        return {
            success: true,
            message: `Reset complete. Deleted ${deleted} products.`,
            deletedCount: deleted
        };
    });

/**
 * Get stats about the Tesco database
 */
export const getTescoDatabaseStats = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const db = admin.firestore();
    const tescoCollection = db.collection('tescoProducts');

    // Get count using aggregation
    const snapshot = await tescoCollection.count().get();
    const totalProducts = snapshot.data().count;

    // Get sample products with nutrition
    const withNutritionSnapshot = await tescoCollection
        .where('nutrition.energyKcal', '>', 0)
        .limit(1)
        .get();

    // Get recent imports
    const recentSnapshot = await tescoCollection
        .orderBy('importedAt', 'desc')
        .limit(5)
        .get();

    const recentProducts = recentSnapshot.docs.map(doc => ({
        id: doc.id,
        title: doc.data().title,
        brand: doc.data().brand,
        hasNutrition: hasValidNutrition(doc.data().nutrition),
        importedAt: doc.data().importedAt
    }));

    return {
        totalProducts,
        hasNutritionEstimate: !withNutritionSnapshot.empty,
        recentProducts,
        collectionName: 'tescoProducts',
        algoliaIndex: TESCO_INDEX_NAME
    };
});

/**
 * Configure Algolia index settings for Tesco products
 * Sets searchable attributes, ranking rules, etc.
 */
export const configureTescoAlgoliaIndex = functions
    .runWith({ secrets: [algoliaAdminKey] })
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const configAlgoliaKey = algoliaAdminKey.value();
    if (!configAlgoliaKey) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }

    const algoliaClient = algoliasearch(ALGOLIA_APP_ID, configAlgoliaKey);

    try {
        await algoliaClient.setSettings({
            indexName: TESCO_INDEX_NAME,
            indexSettings: {
                // Searchable attributes - configured for Tesco product fields
                searchableAttributes: [
                    'unordered(foodName)', // Product name (title)
                    'unordered(brandName)', // Brand name
                    'barcode', // Barcode (GTIN)
                    'unordered(ingredients)', // Ingredients text
                    'unordered(category)' // Product category
                ],

                // Custom ranking
                customRanking: [
                    'desc(calories)', // Products with nutrition data rank higher
                    'asc(foodName)' // Alphabetical for ties
                ],

                // Ranking criteria
                ranking: [
                    'typo',
                    'words',
                    'filters',
                    'proximity',
                    'attribute',
                    'exact',
                    'custom'
                ],

                // Typo tolerance
                minWordSizefor1Typo: 3,
                minWordSizefor2Typos: 6,
                typoTolerance: true,

                // Query settings
                exactOnSingleWordQuery: 'word',
                removeWordsIfNoResults: 'allOptional',
                queryType: 'prefixLast',

                // Language handling
                ignorePlurals: ['en'],
                removeStopWords: ['en'],

                // Highlighting
                attributesToHighlight: ['foodName', 'brandName'],
                highlightPreTag: '<em>',
                highlightPostTag: '</em>',

                // Attributes to retrieve
                attributesToRetrieve: [
                    'objectID',
                    'foodName',
                    'brandName',
                    'barcode',
                    'calories',
                    'protein',
                    'carbs',
                    'fat',
                    'sugar',
                    'fiber',
                    'salt',
                    'ingredients',
                    'servingSize',
                    'category',
                    'imageUrl',
                    'source'
                ]
            }
        });

        console.log('✅ Configured Tesco Algolia index settings');
        return { success: true, message: 'Tesco Algolia index configured' };
    } catch (error: any) {
        console.error('❌ Error configuring Tesco Algolia index:', error.message);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Sync all Tesco products from Firestore to Algolia
 * Use this to re-sync if products weren't indexed during build
 */
export const syncTescoToAlgolia = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB', secrets: [algoliaAdminKey] })
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const syncAlgoliaKey = algoliaAdminKey.value();
    if (!syncAlgoliaKey) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }

    const db = admin.firestore();
    const algoliaClient = algoliasearch(ALGOLIA_APP_ID, syncAlgoliaKey);

    try {
        // First configure the index settings
        await algoliaClient.setSettings({
            indexName: TESCO_INDEX_NAME,
            indexSettings: {
                searchableAttributes: [
                    'unordered(name)', // Admin UI uses 'name'
                    'unordered(foodName)',
                    'unordered(brandName)',
                    'barcode',
                    'gtin',
                    'unordered(ingredients)',
                    'unordered(category)'
                ],
                customRanking: ['desc(calories)', 'asc(name)'],
                typoTolerance: true,
                minWordSizefor1Typo: 3,
                minWordSizefor2Typos: 6
            }
        });
        console.log('✅ Index settings configured');

        // Get all Tesco products from Firestore
        const tescoCollection = db.collection('tescoProducts');
        let synced = 0;
        let errors = 0;
        const batchSize = 100;
        let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

        while (true) {
            let query = tescoCollection.orderBy('importedAt', 'desc').limit(batchSize);
            if (lastDoc) {
                query = query.startAfter(lastDoc);
            }

            const snapshot = await query.get();
            if (snapshot.empty) {
                break;
            }

            // Prepare batch for Algolia with full field mapping
            const objects = snapshot.docs.map(doc => {
                const data = doc.data();
                const nutrition = data.nutrition || {};
                return {
                    objectID: doc.id,
                    name: data.title || '', // Admin UI uses 'name'
                    foodName: data.title || '',
                    brandName: data.brand || 'Tesco',
                    brand: data.brand || 'Tesco',
                    barcode: data.gtin || '',
                    gtin: data.gtin || '',
                    calories: nutrition.energyKcal || 0,
                    protein: nutrition.protein || 0,
                    carbs: nutrition.carbohydrate || 0,
                    fat: nutrition.fat || 0,
                    saturates: nutrition.saturates || 0,
                    sugar: nutrition.sugars || 0,
                    sugars: nutrition.sugars || 0,
                    fiber: nutrition.fibre || 0,
                    fibre: nutrition.fibre || 0,
                    salt: nutrition.salt || 0,
                    sodium: nutrition.salt ? nutrition.salt * 400 : 0,
                    ingredients: data.ingredients || '',
                    servingSize: data.servingSize || 'per 100g',
                    servingSizeG: 100,
                    category: data.category || '',
                    imageUrl: '', // Tesco images not used
                    source: 'Tesco',
                    verified: true,
                    isVerified: true,
                    allergens: data.allergens || []
                };
            });

            // Save batch to Algolia
            try {
                await algoliaClient.saveObjects({
                    indexName: TESCO_INDEX_NAME,
                    objects: objects
                });
                synced += objects.length;
                console.log(`Synced ${synced} products to Algolia...`);
            } catch (algoliaError: any) {
                console.error('Algolia batch save error:', algoliaError.message);
                errors += objects.length;
            }

            lastDoc = snapshot.docs[snapshot.docs.length - 1];

            // Small delay to avoid overwhelming Algolia
            await sleep(100);
        }

        return {
            success: true,
            message: `Synced ${synced} Tesco products to Algolia`,
            synced,
            errors
        };
    } catch (error: any) {
        console.error('❌ Error syncing Tesco to Algolia:', error.message);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

/**
 * Clean up existing Tesco database - removes HTML tags from ingredients,
 * validates nutrition data, and removes invalid products
 */
export const cleanupTescoDatabase = functions
    .runWith({ timeoutSeconds: 540, memory: '1GB', secrets: [algoliaAdminKey] })
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const db = admin.firestore();
    const tescoCollection = db.collection('tescoProducts');
    const dryRun = data?.dryRun === true; // Pass dryRun: true to preview without changes

    let processed = 0;
    let cleaned = 0;
    let deleted = 0;
    let invalidCalories = 0;
    let htmlCleaned = 0;
    const errors: string[] = [];
    const batchSize = 100;
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

    // Initialize Algolia for sync
    let algoliaClient: ReturnType<typeof algoliasearch> | null = null;
    const cleanupAlgoliaKey = algoliaAdminKey.value();
    if (cleanupAlgoliaKey && !dryRun) {
        algoliaClient = algoliasearch(ALGOLIA_APP_ID, cleanupAlgoliaKey);
    }

    console.log(`Starting Tesco database cleanup... (dryRun: ${dryRun})`);

    while (true) {
        let query = tescoCollection.orderBy('importedAt').limit(batchSize);
        if (lastDoc) {
            query = query.startAfter(lastDoc);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
            break;
        }

        for (const doc of snapshot.docs) {
            processed++;
            const data = doc.data();
            const updates: Record<string, any> = {};
            let needsDelete = false;
            let needsUpdate = false;

            // 1. Check for valid title
            if (!data.title || data.title.trim().length === 0) {
                needsDelete = true;
                errors.push(`${doc.id}: Missing title`);
            }

            // 2. Check for valid calories
            const calories = data.nutrition?.energyKcal;
            if (!calories || calories <= 0 || calories > 950) {
                needsDelete = true;
                invalidCalories++;
                if (calories > 950) {
                    errors.push(`${doc.id}: Invalid calories (${calories})`);
                } else {
                    errors.push(`${doc.id}: Missing calories`);
                }
            }

            // 3. Clean HTML from ingredients
            if (data.ingredients && typeof data.ingredients === 'string') {
                const hasHtml = /<[^>]+>/.test(data.ingredients);
                if (hasHtml) {
                    const cleanedIngredients = cleanIngredients(data.ingredients);
                    updates['ingredients'] = cleanedIngredients;
                    needsUpdate = true;
                    htmlCleaned++;
                    console.log(`Cleaning HTML from ${doc.id}: "${data.ingredients.substring(0, 50)}..." → "${cleanedIngredients.substring(0, 50)}..."`);
                }
            }

            // Apply changes
            if (needsDelete) {
                deleted++;
                if (!dryRun) {
                    await doc.ref.delete();
                    // Also delete from Algolia
                    if (algoliaClient) {
                        try {
                            await algoliaClient.deleteObject({ indexName: TESCO_INDEX_NAME, objectID: doc.id });
                        } catch (e) {
                            // Ignore Algolia delete errors
                        }
                    }
                }
            } else if (needsUpdate) {
                cleaned++;
                if (!dryRun) {
                    await doc.ref.update(updates);
                    // Also update in Algolia
                    if (algoliaClient) {
                        try {
                            await algoliaClient.partialUpdateObject({
                                indexName: TESCO_INDEX_NAME,
                                objectID: doc.id,
                                attributesToUpdate: { ingredients: updates['ingredients'] }
                            });
                        } catch (e) {
                            // Ignore Algolia update errors
                        }
                    }
                }
            }
        }

        lastDoc = snapshot.docs[snapshot.docs.length - 1];

        if (processed % 500 === 0) {
            console.log(`Processed ${processed} products... (cleaned: ${cleaned}, deleted: ${deleted})`);
        }

        // Small delay to avoid overwhelming Firestore
        await sleep(50);
    }

    const result = {
        success: true,
        dryRun,
        processed,
        cleaned,
        deleted,
        invalidCalories,
        htmlCleaned,
        errors: errors.slice(0, 100), // Only return first 100 errors
        message: dryRun
            ? `DRY RUN: Would clean ${cleaned} products and delete ${deleted} invalid products`
            : `Cleaned ${cleaned} products and deleted ${deleted} invalid products`
    };

    console.log(`Cleanup complete: ${JSON.stringify({ ...result, errors: `${errors.length} total` })}`);
    return result;
});
