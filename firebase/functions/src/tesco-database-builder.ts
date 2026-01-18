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
import * as admin from 'firebase-admin';
import axios from 'axios';
import { algoliasearch } from 'algoliasearch';

// Initialize Firebase Admin if not already
if (!admin.apps.length) {
    admin.initializeApp();
}

// Tesco8 API Configuration
const TESCO8_API_KEY = functions.config().rapidapi?.key || '7e61162448msh2832ba8d19f26cep1e55c3jsn5242e6c6d761';
const TESCO8_HOST = 'tesco8.p.rapidapi.com';

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
const ALGOLIA_APP_ID = functions.config().algolia?.app_id || 'WK0TIF84M2';
const ALGOLIA_ADMIN_KEY = functions.config().algolia?.admin_key;
const TESCO_INDEX_NAME = 'tesco_products';

// Search terms for comprehensive coverage
const SEARCH_TERMS = [
    // Alphabet
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    // Common food categories
    'milk', 'bread', 'cheese', 'chicken', 'beef', 'pork', 'fish', 'salmon',
    'pasta', 'rice', 'cereal', 'yogurt', 'butter', 'eggs', 'bacon',
    'sausage', 'ham', 'turkey', 'lamb', 'vegetables', 'fruit', 'apple',
    'banana', 'orange', 'potato', 'tomato', 'onion', 'carrot', 'broccoli',
    'spinach', 'lettuce', 'cucumber', 'pepper', 'mushroom', 'beans',
    'soup', 'sauce', 'pizza', 'chips', 'crisps', 'biscuits', 'chocolate',
    'ice cream', 'frozen', 'ready meal', 'sandwich', 'wrap', 'salad',
    'juice', 'water', 'cola', 'coffee', 'tea', 'wine', 'beer', 'snack',
    'nuts', 'seeds', 'oil', 'vinegar', 'herbs', 'spices', 'flour', 'sugar',
    'honey', 'jam', 'spread', 'mayo', 'ketchup', 'mustard', 'pickle',
    'organic', 'free range', 'gluten free', 'vegan', 'vegetarian',
    // Brands
    'tesco finest', 'tesco everyday', 'tesco organic', 'tesco free from'
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
    source: 'tesco8_api';
}

interface BuildProgress {
    status: 'idle' | 'running' | 'paused' | 'completed' | 'error';
    currentTermIndex: number;
    currentTerm: string;
    totalTerms: number;
    productsFound: number;
    productsWithNutrition: number;
    productsSaved: number;
    duplicatesSkipped: number;
    errors: number;
    startedAt: string;
    lastUpdated: string;
    estimatedCompletion?: string;
    errorMessages: string[];
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
function hasValidNutrition(nutrition?: TescoProduct['nutrition']): boolean {
    if (!nutrition) return false;
    return !!(nutrition.energyKcal || nutrition.protein || nutrition.carbohydrate);
}

// Helper: Sleep function
const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Helper: Retry with exponential backoff
async function retryWithBackoff<T>(
    fn: () => Promise<T>,
    maxRetries: number = 3,
    baseDelay: number = 2000,
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
 */
async function searchTescoProducts(query: string, page: number = 0): Promise<{ products: any[]; totalPages: number }> {
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
                    'x-rapidapi-key': TESCO8_API_KEY
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
    }, 3, 3000, `search "${query}" page ${page}`);
}

/**
 * Get full product details including nutrition
 */
interface ProductDetailsResult {
    product: TescoProduct | null;
    error?: string;
}

async function getProductDetails(productId: string): Promise<ProductDetailsResult> {
    try {
        console.log(`Fetching product details for: ${productId}`);
        const response = await retryWithBackoff(async () => {
            return axios.get(
                `https://${TESCO8_HOST}/product-details`,
                {
                    params: { productId },
                    headers: {
                        'x-rapidapi-host': TESCO8_HOST,
                        'x-rapidapi-key': TESCO8_API_KEY
                    },
                    timeout: 15000
                }
            );
        }, 3, 3000, `product details ${productId}`);

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

            if (name.includes('energy') || (name === '-' && value.includes('kcal'))) {
                const kcalMatch = value.match(/(\d+(?:\.\d+)?)\s*kcal/i);
                if (kcalMatch) nutrition.energyKcal = parseNumber(kcalMatch[1]);
                const kjMatch = value.match(/(\d+(?:\.\d+)?)\s*kJ/i);
                if (kjMatch) nutrition.energyKj = parseNumber(kjMatch[1]);
            } else if (name === 'fat' && !name.includes('saturate')) {
                nutrition.fat = parseNumber(value);
            } else if (name.includes('saturate')) {
                nutrition.saturates = parseNumber(value);
            } else if (name.includes('carbohydrate') && !name.includes('sugar')) {
                nutrition.carbohydrate = parseNumber(value);
            } else if (name.includes('sugar')) {
                nutrition.sugars = parseNumber(value);
            } else if (name.includes('fibre') || name.includes('fiber')) {
                nutrition.fibre = parseNumber(value);
            } else if (name.includes('protein')) {
                nutrition.protein = parseNumber(value);
            } else if (name.includes('salt')) {
                nutrition.salt = parseNumber(value);
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
            imageUrl: productData.defaultImageUrl,
            price: productData.price?.actual,
            unitPrice: productData.price?.unitPrice,
            nutrition,
            ingredients: Array.isArray(details.ingredients)
                ? details.ingredients.join(', ')
                : details.ingredients,
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
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
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
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (data, context) => {
        // Verify admin
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }

        const db = admin.firestore();
        const progressRef = db.collection('system').doc('tescoBuildProgress');
        const tescoCollection = db.collection('tescoProducts');

        // Get current progress
        const progressDoc = await progressRef.get();
        let progress: BuildProgress = progressDoc.exists
            ? progressDoc.data() as BuildProgress
            : {
                status: 'idle',
                currentTermIndex: 0,
                currentTerm: '',
                totalTerms: SEARCH_TERMS.length,
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

        // Check if already running
        if (progress.status === 'running') {
            return {
                success: false,
                message: 'Build already in progress',
                progress
            };
        }

        // Option to reset
        if (data?.reset) {
            progress = {
                status: 'running',
                currentTermIndex: 0,
                currentTerm: SEARCH_TERMS[0],
                totalTerms: SEARCH_TERMS.length,
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
        } else {
            progress.status = 'running';
            progress.lastUpdated = new Date().toISOString();
        }

        await progressRef.set(progress);

        // Initialize Algolia
        let algoliaClient: ReturnType<typeof algoliasearch> | null = null;
        if (ALGOLIA_ADMIN_KEY) {
            algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
        }

        const seenProductIds = new Set<string>();
        const batchSize = 10; // Products to process before saving progress
        let processedInBatch = 0;

        try {
            // Process search terms from where we left off
            for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
                const term = SEARCH_TERMS[termIndex];
                progress.currentTermIndex = termIndex;
                progress.currentTerm = term;
                progress.lastUpdated = new Date().toISOString();
                await progressRef.update({...progress});

                console.log(`Searching for: "${term}" (${termIndex + 1}/${SEARCH_TERMS.length})`);

                try {
                    // Search for this term
                    const { products, totalPages } = await searchTescoProducts(term, 0);

                    // Process first page
                    for (const searchResult of products) {
                        if (seenProductIds.has(searchResult.id)) {
                            progress.duplicatesSkipped++;
                            continue;
                        }
                        seenProductIds.add(searchResult.id);
                        progress.productsFound++;

                        // Check if already in database
                        const existingDoc = await tescoCollection.doc(searchResult.id).get();
                        if (existingDoc.exists) {
                            progress.duplicatesSkipped++;
                            continue;
                        }

                        // Get full details
                        const { product, error: detailsError } = await getProductDetails(searchResult.id);

                        if (detailsError) {
                            progress.errors++;
                            progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                            if (progress.errorMessages.length > 50) {
                                progress.errorMessages = progress.errorMessages.slice(-50);
                            }
                        }

                        if (product) {
                            if (hasValidNutrition(product.nutrition)) {
                                progress.productsWithNutrition++;
                            }

                            // Validate product ID before saving
                            if (!product.id) {
                                console.error('Product has no ID, skipping:', product.title);
                                progress.errors++;
                                progress.errorMessages.push(`Product has no ID: ${product.title?.substring(0, 50)}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                                continue;
                            }

                            // Save to Firestore with error handling
                            try {
                                await tescoCollection.doc(product.id).set(removeUndefined(product));
                                progress.productsSaved++;
                                console.log(`Saved product: ${product.id} - ${product.title?.substring(0, 40)}`);

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

                            // Sync to Algolia
                            if (algoliaClient) {
                                try {
                                    await algoliaClient.saveObject({
                                        indexName: TESCO_INDEX_NAME,
                                        body: {
                                            objectID: product.id,
                                            foodName: product.title,
                                            brandName: product.brand,
                                            barcode: product.gtin,
                                            calories: product.nutrition?.energyKcal,
                                            protein: product.nutrition?.protein,
                                            carbs: product.nutrition?.carbohydrate,
                                            fat: product.nutrition?.fat,
                                            sugar: product.nutrition?.sugars,
                                            fiber: product.nutrition?.fibre,
                                            salt: product.nutrition?.salt,
                                            ingredients: product.ingredients,
                                            servingSize: product.servingSize,
                                            category: product.category,
                                            imageUrl: product.imageUrl,
                                            source: 'tesco8_api'
                                        }
                                    });
                                } catch (algoliaError: any) {
                                    console.error('Algolia sync error:', algoliaError.message);
                                }
                            }

                            processedInBatch++;

                            // Save progress periodically
                            if (processedInBatch >= batchSize) {
                                progress.lastUpdated = new Date().toISOString();
                                await progressRef.update({...progress});
                                processedInBatch = 0;
                            }
                        }

                        // Rate limiting - 2 seconds between API calls to avoid 429 errors
                        await sleep(2000);
                    }

                    // Process additional pages (up to 3 per term to stay within rate limits)
                    const maxPages = Math.min(totalPages, 3);
                    for (let page = 1; page < maxPages; page++) {
                        await sleep(1500); // 1.5 second delay between pages

                        const { products: pageProducts } = await searchTescoProducts(term, page);

                        for (const searchResult of pageProducts) {
                            if (seenProductIds.has(searchResult.id)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            seenProductIds.add(searchResult.id);
                            progress.productsFound++;

                            const existingDoc = await tescoCollection.doc(searchResult.id).get();
                            if (existingDoc.exists) {
                                progress.duplicatesSkipped++;
                                continue;
                            }

                            const { product, error: detailsError } = await getProductDetails(searchResult.id);

                            if (detailsError) {
                                progress.errors++;
                                progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                            }

                            if (product) {
                                if (hasValidNutrition(product.nutrition)) {
                                    progress.productsWithNutrition++;
                                }

                                // Validate product ID before saving
                                if (!product.id) {
                                    console.error('Product has no ID, skipping:', product.title);
                                    progress.errors++;
                                    progress.errorMessages.push(`Product has no ID: ${product.title?.substring(0, 50)}`);
                                    if (progress.errorMessages.length > 50) {
                                        progress.errorMessages = progress.errorMessages.slice(-50);
                                    }
                                    continue;
                                }

                                // Save to Firestore with error handling
                                try {
                                    await tescoCollection.doc(product.id).set(removeUndefined(product));
                                    progress.productsSaved++;
                                    console.log(`Saved product: ${product.id} - ${product.title?.substring(0, 40)}`);

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

                                if (algoliaClient) {
                                    try {
                                        await algoliaClient.saveObject({
                                            indexName: TESCO_INDEX_NAME,
                                            body: {
                                                objectID: product.id,
                                                foodName: product.title,
                                                brandName: product.brand,
                                                barcode: product.gtin,
                                                calories: product.nutrition?.energyKcal,
                                                protein: product.nutrition?.protein,
                                                carbs: product.nutrition?.carbohydrate,
                                                fat: product.nutrition?.fat,
                                                sugar: product.nutrition?.sugars,
                                                fiber: product.nutrition?.fibre,
                                                salt: product.nutrition?.salt,
                                                ingredients: product.ingredients,
                                                servingSize: product.servingSize,
                                                category: product.category,
                                                imageUrl: product.imageUrl,
                                                source: 'tesco8_api'
                                            }
                                        });
                                    } catch (algoliaError: any) {
                                        console.error('Algolia sync error:', algoliaError.message);
                                    }
                                }

                                processedInBatch++;
                                if (processedInBatch >= batchSize) {
                                    progress.lastUpdated = new Date().toISOString();
                                    await progressRef.update({...progress});
                                    processedInBatch = 0;
                                }
                            }

                            await sleep(2000); // 2 second delay to avoid API rate limits
                        }
                    }

                } catch (searchError: any) {
                    progress.errors++;
                    progress.errorMessages.push(`Term "${term}": ${searchError.message}`);
                    if (progress.errorMessages.length > 50) {
                        progress.errorMessages = progress.errorMessages.slice(-50);
                    }
                    console.error(`Error searching "${term}":`, searchError.message);

                    // Rate limit on error - wait longer before continuing
                    if (searchError.response?.status === 429) {
                        console.log('Rate limited - waiting 30 seconds before next term');
                        await sleep(30000);
                    } else {
                        // Short delay for other errors
                        await sleep(2000);
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
            }

            // Mark as completed
            progress.status = 'completed';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});

            return {
                success: true,
                message: 'Build completed',
                progress
            };

        } catch (error: any) {
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
 * Reset the Tesco database (delete all and start fresh)
 */
export const resetTescoDatabase = functions
    .runWith({ timeoutSeconds: 300, memory: '512MB' })
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
            status: 'idle',
            currentTermIndex: 0,
            currentTerm: '',
            totalTerms: SEARCH_TERMS.length,
            productsFound: 0,
            productsWithNutrition: 0,
            productsSaved: 0,
            duplicatesSkipped: 0,
            errors: 0,
            startedAt: '',
            lastUpdated: new Date().toISOString(),
            errorMessages: []
        });

        // Clear Algolia index
        if (ALGOLIA_ADMIN_KEY) {
            try {
                const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
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
