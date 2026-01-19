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

// Tesco food categories - extracted from official Tesco website navigation
// Using actual category names gives much better coverage than alphabetical search
const SEARCH_TERMS = [
    // ============ FRESH FOOD (4,616 items) ============
    'Fresh Fruit',
    'Fresh Vegetables',
    'Fresh Flowers',
    'Fresh Salad',
    'Coleslaw',
    'Sandwich Fillers',
    'Chilled Vegetarian',
    'Chilled Vegan',
    'Juice Smoothies',
    'Milk Butter Eggs',
    'Cheese',
    'Yogurts',
    'Dairy Free',
    'Dairy Alternatives',
    'Finest Fresh Food',
    'Fresh Meat',
    'Fresh Poultry',
    'Chilled Fish',
    'Chilled Seafood',
    'Cooked Meats',
    'Antipasti',
    'Dips',
    'Pies Pasties',
    'Quiches',
    'Party Food',
    'Deli Counter',
    'Fresh Pizza',
    'Fresh Pasta',
    'Garlic Bread',
    'Ready Meals',
    'Chilled Soup',
    'Sandwiches',
    'Salad Pots',
    'World Foods Fresh',
    'Chilled Desserts',

    // ============ BAKERY (746 items) ============
    'Bread',
    'Bread Rolls',
    'Bagels',
    'Pitta Bread',
    'Thins',
    'Wraps Flatbread',
    'International Breads',
    'Part Baked Bread',
    'Crumpets Muffins',
    'Teacakes',
    'Fruit Loaf',
    'Scones',
    'Croissants',
    'Brioche',
    'Pastries',
    'Pancakes Waffles',
    'Crepes',
    'Doughnuts',
    'Cookies',
    'Bakery Muffins',
    'Cake',
    'Birthday Cake',
    'Celebration Cake',
    'High Protein Bakery',
    'Free From Bakery',
    'From Our Bakery',
    'Finest Bakery',
    'Hot Cross Buns',

    // ============ FROZEN FOOD ============
    'Frozen Vegetarian',
    'Frozen Vegan',
    'Frozen Vegetables',
    'Chips Potatoes',
    'Frozen Sides',
    'Frozen Meat',
    'Frozen Poultry',
    'Frozen Fish',
    'Frozen Seafood',
    'Frozen Party Foods',
    'Frozen Pies',
    'Frozen Bakes',
    'Frozen Sausage Rolls',
    'Frozen Pizza',
    'Frozen Garlic Bread',
    'Frozen Ready Meals',
    'Yorkshire Puddings',
    'Stuffing',
    'Frozen Fruit',
    'Frozen Pastry',
    'Frozen Desserts',
    'Ice Cream',
    'Ice Lollies',
    'Free From Frozen',
    'Gluten Free Frozen',
    'World Foods Frozen',
    'Halal Frozen',
    'Finest Frozen Food',
    'Easy Meals Snacks',

    // ============ TREATS & SNACKS (2,452 items) ============
    'Chocolate',
    'Sweets',
    'Mints',
    'Chewing Gum',
    'Crisps',
    'Snacks',
    'Nuts',
    'Popcorn',
    'Biscuits',
    'Cereal Bars',
    'Yogurts Snacks',
    'Meat Snacking',
    'Cheese Snacking',
    'Dried Fruit',
    'Nutrient Powders',
    'Seeds',
    'Crackers',
    'Crispbreads',
    'Cake Bars',
    'Cake Slices',
    'Bakes',
    'Easter Eggs',
    'Easter Chocolates',

    // ============ FOOD CUPBOARD (7,918 items) ============
    'Cereals',
    'Breakfast Cereals',
    'Free From Foods',
    'Tins Cans',
    'Tinned Food',
    'Packets',
    'Instant Noodles',
    'Easy Meals',
    'Cooking Ingredients',
    'Cooking Sauces',
    'Meal Kits',
    'Sides',
    'Dried Pasta',
    'Rice',
    'Noodles',
    'Cous Cous',
    'Table Sauces',
    'Olives',
    'Pickles',
    'Chutney',
    'World Foods',
    'Jams',
    'Honey',
    'Spreads',
    'Desserts Cupboard',
    'Home Baking',
    'Sugar',
    'Finest Food Cupboard',

    // ============ DRINKS (Food-related only) ============
    'Juices',
    'Smoothies',
    'Wellness Drinks',
    'Fizzy Drinks',
    'Soft Drinks',
    'Water',
    'Squash',
    'Cordial',
    'Adult Soft Drinks',
    'Mixers',
    'Kids Drinks',
    'Sports Drinks',
    'Energy Drinks',
    'Milk Drinks',
    'Milkshakes',
    'On The Go Drinks',
    'Tea',
    'Coffee',
    'Hot Chocolate',
    'Malted Drinks',

    // ============ BABY & TODDLER (Food items) ============
    'Baby Food',
    'Baby Milk',
    'Toddler Food',
    'Baby Snacks',

    // ============ TESCO BRANDS ============
    'Tesco Finest',
    'Tesco Everyday Value',
    'Tesco Organic',
    'Tesco Free From',
    'Tesco Plant Chef',
    'Tesco Wicked Kitchen'
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
function isValidProduct(product: TescoProduct): { valid: boolean; reason?: string } {
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
    }, 3, 1000, `search "${query}" page ${page}`);  // Reduced from 3000ms
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
            imageUrl: productData.defaultImageUrl,
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

        // Check if already completed
        if (progress.status === 'completed') {
            console.log(`[START] Build already completed. Use reset=true to restart.`);
            return {
                success: false,
                message: 'Build already completed. Use reset to restart.',
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
            console.log(`[LOOP] Starting from term index ${progress.currentTermIndex} (${SEARCH_TERMS[progress.currentTermIndex] || 'END'})`);
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
                        // Get full details first (we need to compare even if exists)
                        const { product, error: detailsError } = await getProductDetails(searchResult.id);

                        if (detailsError) {
                            progress.errors++;
                            progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                            if (progress.errorMessages.length > 50) {
                                progress.errorMessages = progress.errorMessages.slice(-50);
                            }
                        }

                        // Check if existing and if new data is more complete
                        if (existingDoc.exists && product) {
                            const existingData = existingDoc.data();
                            if (!isMoreComplete(product, existingData)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            // New data is more complete - will update below
                            console.log(`Updating ${product.id} with more complete data (${countNutritionFields(product.nutrition)} vs ${countNutritionFields(existingData?.nutrition)} nutrition fields)`);
                        } else if (existingDoc.exists) {
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
                                await tescoCollection.doc(product.id).set(removeUndefined(product));
                                progress.productsSaved++;
                                console.log(`Saved product: ${product.id} - ${product.title?.substring(0, 40)} (${product.nutrition?.energyKcal} kcal)`);

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
                                            name: product.title, // Admin UI uses 'name'
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
                                            servingSize: product.servingSize || 'per 100g',
                                            servingSizeG: 100,
                                            category: product.category || '',
                                            imageUrl: product.imageUrl || '',
                                            source: 'Tesco',
                                            verified: true,
                                            isVerified: true,
                                            allergens: product.allergens || []
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

                        // Rate limiting - 250ms between API calls (API supports 5 req/s)
                        await sleep(250);
                    }

                    // Process additional pages (up to 5 per term with faster API)
                    const maxPages = Math.min(totalPages, 5);
                    for (let page = 1; page < maxPages; page++) {
                        await sleep(250); // 250ms delay between pages

                        const { products: pageProducts } = await searchTescoProducts(term, page);

                        for (const searchResult of pageProducts) {
                            if (seenProductIds.has(searchResult.id)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            seenProductIds.add(searchResult.id);
                            progress.productsFound++;

                            const existingDoc = await tescoCollection.doc(searchResult.id).get();
                            const { product, error: detailsError } = await getProductDetails(searchResult.id);

                            if (detailsError) {
                                progress.errors++;
                                progress.errorMessages.push(`Details fetch failed: ${detailsError}`);
                                if (progress.errorMessages.length > 50) {
                                    progress.errorMessages = progress.errorMessages.slice(-50);
                                }
                            }

                            // Check if existing and if new data is more complete
                            if (existingDoc.exists && product) {
                                const existingData = existingDoc.data();
                                if (!isMoreComplete(product, existingData)) {
                                    progress.duplicatesSkipped++;
                                    continue;
                                }
                                console.log(`Updating ${product.id} with more complete data`);
                            } else if (existingDoc.exists) {
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

                                // Save to Firestore with error handling
                                try {
                                    await tescoCollection.doc(product.id).set(removeUndefined(product));
                                    progress.productsSaved++;
                                    console.log(`Saved product: ${product.id} - ${product.title?.substring(0, 40)} (${product.nutrition?.energyKcal} kcal)`);

                                    // Track this product in recentlyFoundProducts
                                    if (!progress.recentlyFoundProducts) {
                                        progress.recentlyFoundProducts = [];
                                    }
                                    progress.recentlyFoundProducts.push({
                                        id: product.id,
                                        title: product.title || 'Unknown',
                                        brand: product.brand,
                                        hasNutrition: true,
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
                                                name: product.title, // Admin UI uses 'name'
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
                                                servingSize: product.servingSize || 'per 100g',
                                                servingSizeG: 100,
                                                category: product.category || '',
                                                imageUrl: product.imageUrl || '',
                                                source: 'Tesco',
                                                verified: true,
                                                isVerified: true,
                                                allergens: product.allergens || []
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

                            await sleep(250); // 250ms delay (API supports 5 req/s)
                        }
                    }

                } catch (searchError: any) {
                    progress.errors++;
                    progress.errorMessages.push(`Term "${term}": ${searchError.message}`);
                    if (progress.errorMessages.length > 50) {
                        progress.errorMessages = progress.errorMessages.slice(-50);
                    }
                    console.error(`Error searching "${term}":`, searchError.message);

                    // Rate limit on error - wait before continuing
                    if (searchError.response?.status === 429) {
                        console.log('Rate limited - waiting 10 seconds before next term');
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
            }

            // Mark as completed
            console.log(`[COMPLETE] All ${SEARCH_TERMS.length} search terms processed. Marking as completed.`);
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
 * Scheduled function to auto-continue Tesco build every 5 minutes
 * This keeps the build running continuously until all products are imported
 */
export const scheduledTescoBuild = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async () => {
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

        console.log(`[SCHEDULED] Status: ${progress.status}, Term: ${progress.currentTermIndex}/${progress.totalTerms}`);

        // Only run if status is 'running' (started via admin UI)
        // Don't run if paused, completed, or idle
        if (progress.status !== 'running') {
            console.log(`[SCHEDULED] Build status is '${progress.status}', not continuing.`);
            return null;
        }

        // Check if already completed
        if (progress.currentTermIndex >= SEARCH_TERMS.length) {
            console.log(`[SCHEDULED] All terms processed, marking as completed.`);
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
        if (ALGOLIA_ADMIN_KEY) {
            algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
        }

        const seenProductIds = new Set<string>();
        const batchSize = 10;
        let processedInBatch = 0;

        try {
            // Process search terms from where we left off
            console.log(`[SCHEDULED] Starting from term index ${progress.currentTermIndex}`);
            for (let termIndex = progress.currentTermIndex; termIndex < SEARCH_TERMS.length; termIndex++) {
                const term = SEARCH_TERMS[termIndex];
                progress.currentTermIndex = termIndex;
                progress.currentTerm = term;
                progress.lastUpdated = new Date().toISOString();
                await progressRef.update({...progress});

                console.log(`[SCHEDULED] Processing: "${term}" (${termIndex + 1}/${SEARCH_TERMS.length})`);

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

                        // Get full details
                        const { product, error: detailsError } = await getProductDetails(searchResult.id);

                        if (detailsError) {
                            progress.errors++;
                            progress.errorMessages.push(`Details: ${detailsError}`);
                            if (progress.errorMessages.length > 50) {
                                progress.errorMessages = progress.errorMessages.slice(-50);
                            }
                        }

                        // Check if existing and if new data is more complete
                        if (existingDoc.exists && product) {
                            const existingData = existingDoc.data();
                            if (!isMoreComplete(product, existingData)) {
                                progress.duplicatesSkipped++;
                                continue;
                            }
                            console.log(`[SCHEDULED] Updating ${product.id} with more complete data`);
                        } else if (existingDoc.exists) {
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
                                await tescoCollection.doc(product.id).set(removeUndefined(product));
                                progress.productsSaved++;
                                console.log(`[SCHEDULED] Saved: ${product.title?.substring(0, 30)} (${product.nutrition?.energyKcal} kcal)`);

                                // Sync to Algolia
                                if (algoliaClient) {
                                    await algoliaClient.saveObject({
                                        indexName: TESCO_INDEX_NAME,
                                        body: {
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
                                            fiber: product.nutrition?.fibre || 0,
                                            salt: product.nutrition?.salt || 0,
                                            sodium: product.nutrition?.salt ? product.nutrition.salt * 400 : 0,
                                            ingredients: product.ingredients || '',
                                            servingSize: product.servingSize || 'per 100g',
                                            category: product.category || '',
                                            imageUrl: product.imageUrl || '',
                                            source: 'Tesco',
                                            verified: true,
                                            allergens: product.allergens || []
                                        }
                                    }).catch(e => console.error('Algolia error:', e.message));
                                }

                                processedInBatch++;
                                if (processedInBatch >= batchSize) {
                                    progress.lastUpdated = new Date().toISOString();
                                    await progressRef.update({...progress});
                                    processedInBatch = 0;
                                }
                            } catch (e: any) {
                                progress.errors++;
                            }
                        }
                        await sleep(250);
                    }

                    // Process additional pages (up to 3 per term)
                    const maxPages = Math.min(totalPages, 3);
                    for (let page = 1; page < maxPages; page++) {
                        await sleep(250);
                        const { products: pageProducts } = await searchTescoProducts(term, page);

                        for (const searchResult of pageProducts) {
                            if (seenProductIds.has(searchResult.id)) continue;
                            seenProductIds.add(searchResult.id);
                            progress.productsFound++;

                            const existingDoc = await tescoCollection.doc(searchResult.id).get();
                            const { product } = await getProductDetails(searchResult.id);

                            // Check if existing and if new data is more complete
                            if (existingDoc.exists && product) {
                                const existingData = existingDoc.data();
                                if (!isMoreComplete(product, existingData)) continue;
                            } else if (existingDoc.exists) {
                                continue;
                            }

                            // STRICT VALIDATION for additional pages too
                            if (product) {
                                const validation = isValidProduct(product);
                                if (!validation.valid) continue;

                                progress.productsWithNutrition++;
                                try {
                                    await tescoCollection.doc(product.id).set(removeUndefined(product));
                                    progress.productsSaved++;
                                    if (algoliaClient) {
                                        await algoliaClient.saveObject({
                                            indexName: TESCO_INDEX_NAME,
                                            body: {
                                                objectID: product.id,
                                                name: product.title,
                                                foodName: product.title,
                                                brandName: product.brand,
                                                calories: product.nutrition?.energyKcal || 0,
                                                protein: product.nutrition?.protein || 0,
                                                carbs: product.nutrition?.carbohydrate || 0,
                                                fat: product.nutrition?.fat || 0,
                                                sugar: product.nutrition?.sugars || 0,
                                                fiber: product.nutrition?.fibre || 0,
                                                salt: product.nutrition?.salt || 0,
                                                ingredients: product.ingredients || '',
                                                servingSize: product.servingSize || 'per 100g',
                                                category: product.category || '',
                                                source: 'Tesco',
                                                verified: true
                                            }
                                        }).catch(() => {});
                                    }
                                } catch (e) {}
                            }
                            await sleep(250);
                        }
                    }
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
                    return null;
                }
            }

            // All done
            progress.status = 'completed';
            progress.lastUpdated = new Date().toISOString();
            await progressRef.update({...progress});
            console.log('[SCHEDULED] Build completed!');

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

/**
 * Configure Algolia index settings for Tesco products
 * Sets searchable attributes, ranking rules, etc.
 */
export const configureTescoAlgoliaIndex = functions.https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    if (!ALGOLIA_ADMIN_KEY) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }

    const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

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
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
    .https.onCall(async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    if (!ALGOLIA_ADMIN_KEY) {
        throw new functions.https.HttpsError('failed-precondition', 'Algolia admin key not configured');
    }

    const db = admin.firestore();
    const algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);

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
                    imageUrl: data.imageUrl || '',
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
    .runWith({ timeoutSeconds: 540, memory: '1GB' })
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
    if (ALGOLIA_ADMIN_KEY && !dryRun) {
        algoliaClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_ADMIN_KEY);
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
