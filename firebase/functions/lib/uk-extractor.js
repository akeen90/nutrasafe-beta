"use strict";
/**
 * UK Product Data Extraction Service - Multi-Tier Strategy
 *
 * Extracts nutrition data from official UK supermarket and manufacturer product pages.
 * Uses a multi-tier extraction strategy prioritizing official sources:
 *
 * Tier 0: TESCO8 API (PRIMARY - official UK supermarket data via RapidAPI)
 * Tier 0.5: OpenFoodFacts API (barcode lookup fallback - free, reliable)
 * Tier 1: Data Attribute JSON (data-* attributes containing product JSON)
 * Tier 2: Embedded JSON (__NEXT_DATA__, Redux state, etc.)
 * Tier 3: JSON-LD structured data
 * Tier 4: Intelligent HTML Table Parsing (validated nutrition tables)
 * Tier 4.5: Text Pattern Extraction (for div-based layouts)
 * Tier 5: Puppeteer rendering (separate function for JS-heavy sites)
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.lookupTescoProduct = exports.extractWithPuppeteer = exports.extractUKProductData = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
const cheerio = require("cheerio");
// ============================================================
// HELPER FUNCTIONS
// ============================================================
function parseNumber(value) {
    if (value === undefined || value === null || value === '')
        return undefined;
    let str = String(value);
    // Handle "less than" values
    if (str.includes('<')) {
        str = str.replace('<', '');
    }
    // Handle "trace" values
    if (str.toLowerCase().includes('trace')) {
        return 0;
    }
    // Extract just the number
    const match = str.match(/[\d.]+/);
    if (!match)
        return undefined;
    const num = parseFloat(match[0]);
    return isNaN(num) ? undefined : Math.round(num * 10) / 10;
}
// extractDomain function removed - not currently used
function identifyAllergens(text) {
    if (!text)
        return [];
    const allergens = [];
    const lowerText = text.toLowerCase();
    if (/\b(celery|celeriac)\b/.test(lowerText))
        allergens.push('Celery');
    if (/\b(wheat|barley|rye|oats|spelt|kamut|gluten)\b/.test(lowerText))
        allergens.push('Cereals containing gluten');
    if (/\b(crab|lobster|prawn|shrimp|crayfish|crustacean)\b/.test(lowerText))
        allergens.push('Crustaceans');
    if (/\b(egg|eggs)\b/.test(lowerText))
        allergens.push('Eggs');
    if (/\b(fish|cod|salmon|tuna|mackerel|anchov)\b/.test(lowerText))
        allergens.push('Fish');
    if (/\b(lupin)\b/.test(lowerText))
        allergens.push('Lupin');
    if (/\b(milk|dairy|cream|butter|cheese|lactose|whey|casein)\b/.test(lowerText))
        allergens.push('Milk');
    if (/\b(mussel|oyster|squid|snail|clam|mollusc)\b/.test(lowerText))
        allergens.push('Molluscs');
    if (/\b(mustard)\b/.test(lowerText))
        allergens.push('Mustard');
    if (/\b(almond|hazelnut|walnut|cashew|pecan|pistachio|macadamia|nut|nuts)\b/.test(lowerText))
        allergens.push('Nuts');
    if (/\b(peanut|groundnut)\b/.test(lowerText))
        allergens.push('Peanuts');
    if (/\b(sesame)\b/.test(lowerText))
        allergens.push('Sesame');
    if (/\b(soya|soy|soybean|soybeans)\b/.test(lowerText))
        allergens.push('Soybeans');
    if (/\b(sulphite|sulfite|sulphur dioxide|so2)\b/.test(lowerText))
        allergens.push('Sulphur dioxide');
    return [...new Set(allergens)];
}
function hasValidNutrition(nutrition) {
    const values = [
        nutrition.energyKcal,
        nutrition.fat,
        nutrition.carbohydrate,
        nutrition.protein
    ];
    // At least 3 of the core 4 values should be present
    return values.filter(v => v !== undefined && v !== null).length >= 3;
}
// ============================================================
// OPENFOODFACTS DATA CLEANSING
// Fixes OCR issues, bad formatting, and spelling from community data
// ============================================================
function cleanseProductName(name) {
    if (!name)
        return undefined;
    let cleaned = name;
    // Fix common OCR issues
    cleaned = cleaned
        // Fix zero/O confusion
        .replace(/0([a-zA-Z])/g, 'O$1') // 0nion -> Onion
        .replace(/([a-zA-Z])0/g, '$1o') // Chick0n -> Chicken
        // Fix 1/l/I confusion
        .replace(/([a-zA-Z])1([a-zA-Z])/g, '$1l$2') // Mi1k -> Milk
        // Fix common misspellings from OCR
        .replace(/\bChico1ate\b/gi, 'Chocolate')
        .replace(/\bVani11a\b/gi, 'Vanilla')
        .replace(/\bStrawherry\b/gi, 'Strawberry')
        .replace(/\bB1ueberry\b/gi, 'Blueberry')
        .replace(/\bRaspberrv\b/gi, 'Raspberry')
        .replace(/\bYoghurt\b/gi, 'Yoghurt') // Normalize spelling
        .replace(/\bYogurt\b/gi, 'Yoghurt')
        // Remove garbage characters
        .replace(/[^\w\s\-&'.,()%/]/g, ' ')
        // Fix multiple spaces
        .replace(/\s+/g, ' ')
        // Fix weird capitalization patterns
        .replace(/([A-Z]{2,})/g, (match) => {
        // Keep acronyms like "UK", "M&S" but fix "CHOCOLATE" -> "Chocolate"
        if (match.length <= 3)
            return match;
        return match.charAt(0) + match.slice(1).toLowerCase();
    });
    // Remove common noise from OCR
    cleaned = cleaned
        .replace(/^[\s\-_.,]+/, '') // Leading garbage
        .replace(/[\s\-_.,]+$/, '') // Trailing garbage
        .replace(/\s*\.\s*$/, '') // Trailing period
        .trim();
    // Title case if all lowercase or all uppercase
    if (cleaned === cleaned.toLowerCase() || cleaned === cleaned.toUpperCase()) {
        cleaned = cleaned.replace(/\b\w/g, (c) => c.toUpperCase());
    }
    return cleaned.length > 2 ? cleaned : undefined;
}
function cleanseBrandName(brand) {
    if (!brand)
        return undefined;
    let cleaned = brand;
    // Common brand name corrections
    const brandCorrections = {
        'tescos': 'Tesco',
        'tesc0': 'Tesco',
        "sainsbury's": "Sainsbury's",
        'sainsburys': "Sainsbury's",
        "asda's": 'Asda',
        "morrisons's": 'Morrisons',
        'morrisons': 'Morrisons',
        'waitr0se': 'Waitrose',
        'cad bury': 'Cadbury',
        'cadburys': 'Cadbury',
        'nestle': 'Nestle',
        'kel1oggs': "Kellogg's",
        'kellogg s': "Kellogg's",
        'mcvities': "McVitie's",
        'mcvitie s': "McVitie's",
        'wa1kers': 'Walkers',
        'heinz': 'Heinz',
    };
    const lowerBrand = cleaned.toLowerCase().trim();
    if (brandCorrections[lowerBrand]) {
        return brandCorrections[lowerBrand];
    }
    // Clean up
    cleaned = cleaned
        .replace(/[^\w\s\-&'.]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
    // Title case
    if (cleaned === cleaned.toLowerCase()) {
        cleaned = cleaned.replace(/\b\w/g, (c) => c.toUpperCase());
    }
    return cleaned.length > 1 ? cleaned : undefined;
}
function cleanseIngredients(ingredients) {
    if (!ingredients)
        return undefined;
    let cleaned = ingredients;
    // Fix common OCR issues in ingredients
    cleaned = cleaned
        // Fix common misreadings
        .replace(/\b0il\b/gi, 'oil')
        .replace(/\bf1our\b/gi, 'flour')
        .replace(/\bmi1k\b/gi, 'milk')
        .replace(/\bsa1t\b/gi, 'salt')
        .replace(/\bsuqar\b/gi, 'sugar')
        .replace(/\bbutt er\b/gi, 'butter')
        .replace(/\bwa ter\b/gi, 'water')
        .replace(/\bvineqar\b/gi, 'vinegar')
        // Fix spacing issues
        .replace(/,(?!\s)/g, ', ') // Add space after comma
        .replace(/\s+,/g, ',') // Remove space before comma
        .replace(/\(\s+/g, '(') // Fix spaces after (
        .replace(/\s+\)/g, ')') // Fix spaces before )
        // Fix common allergen highlighting issues
        .replace(/_([^_]+)_/g, '$1') // Remove underscores used for emphasis
        .replace(/\*([^*]+)\*/g, '$1') // Remove asterisks used for emphasis
        // Fix multiple spaces
        .replace(/\s+/g, ' ')
        // Remove non-printable characters
        .replace(/[^\x20-\x7E\n]/g, '')
        .trim();
    // Normalize ingredient list format
    if (cleaned.includes('\n')) {
        cleaned = cleaned.replace(/\n+/g, ', ');
    }
    return cleaned.length > 5 ? cleaned : undefined;
}
function cleanseNutritionValue(value, nutrientType) {
    if (value === undefined || value === null)
        return undefined;
    // Sanity checks for nutrition values per 100g
    const maxValues = {
        energyKcal: 900, // Pure fat is ~900 kcal/100g
        energyKj: 3800, // ~900 kcal in kJ
        fat: 100,
        saturates: 100,
        carbohydrate: 100,
        sugars: 100,
        fibre: 100,
        protein: 100,
        salt: 100,
    };
    const max = maxValues[nutrientType] || 100;
    // Reject obviously wrong values
    if (value < 0)
        return undefined;
    if (value > max) {
        // Might be a decimal point issue (e.g., 156 instead of 15.6)
        if (value > max * 10) {
            return Math.round(value / 100 * 10) / 10;
        }
        return Math.round(value / 10 * 10) / 10;
    }
    // Round to 1 decimal place
    return Math.round(value * 10) / 10;
}
function cleanseOpenFoodFactsData(product) {
    const cleansed = {
        ...product,
        name: cleanseProductName(product.name),
        brand: cleanseBrandName(product.brand),
        ingredients: cleanseIngredients(product.ingredients),
        nutrition: {
            energyKcal: cleanseNutritionValue(product.nutrition.energyKcal, 'energyKcal'),
            energyKj: cleanseNutritionValue(product.nutrition.energyKj, 'energyKj'),
            fat: cleanseNutritionValue(product.nutrition.fat, 'fat'),
            saturates: cleanseNutritionValue(product.nutrition.saturates, 'saturates'),
            carbohydrate: cleanseNutritionValue(product.nutrition.carbohydrate, 'carbohydrate'),
            sugars: cleanseNutritionValue(product.nutrition.sugars, 'sugars'),
            fibre: cleanseNutritionValue(product.nutrition.fibre, 'fibre'),
            protein: cleanseNutritionValue(product.nutrition.protein, 'protein'),
            salt: cleanseNutritionValue(product.nutrition.salt, 'salt'),
        },
        allergens: product.allergens?.map(a => a.replace(/^en:/, '').replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())) || [],
    };
    // Re-identify allergens from cleaned ingredients
    if (cleansed.ingredients) {
        const detectedAllergens = identifyAllergens(cleansed.ingredients);
        cleansed.allergens = [...new Set([...(cleansed.allergens || []), ...detectedAllergens])];
    }
    return cleansed;
}
// ============================================================
// TIER 1: DATA ATTRIBUTE JSON EXTRACTION (NEW)
// ============================================================
function extractDataAttributes($) {
    const dataSelectors = [
        '[data-product-info]',
        '[data-product]',
        '[data-initial-data]',
        '[data-page-data]',
        '[data-props]',
        '[data-nutrition]',
        '[data-gtm-product]',
        '[data-product-data]',
        '[data-sku-data]',
        '[data-item]',
        '[data-analytics]',
        '[data-react-props]',
        '[data-vue-props]',
    ];
    const dataAttrs = [
        'data-product-info',
        'data-product',
        'data-initial-data',
        'data-page-data',
        'data-props',
        'data-nutrition',
        'data-gtm-product',
        'data-product-data',
        'data-sku-data',
        'data-item',
        'data-analytics',
        'data-react-props',
        'data-vue-props',
    ];
    for (const selector of dataSelectors) {
        const elements = $(selector);
        let foundProduct = null;
        elements.each((_, el) => {
            if (foundProduct)
                return false; // Break if found
            for (const attr of dataAttrs) {
                const value = $(el).attr(attr);
                if (value && value.length > 10) {
                    try {
                        const json = JSON.parse(value);
                        const product = extractProductFromJson(json);
                        if (product && hasValidNutrition(product.nutrition)) {
                            console.log(`Found product via data attribute: ${attr}`);
                            foundProduct = product;
                            return false; // Break inner loop
                        }
                    }
                    catch (e) {
                        try {
                            const decoded = decodeURIComponent(value);
                            const json = JSON.parse(decoded);
                            const product = extractProductFromJson(json);
                            if (product && hasValidNutrition(product.nutrition)) {
                                console.log(`Found product via data attribute (decoded): ${attr}`);
                                foundProduct = product;
                                return false;
                            }
                        }
                        catch (e2) {
                            // Continue
                        }
                    }
                }
            }
            return; // Explicit return for TypeScript
        });
        if (foundProduct)
            return foundProduct;
    }
    return null;
}
// ============================================================
// TIER 2: EMBEDDED JSON EXTRACTION
// ============================================================
function extractEmbeddedJson(html) {
    const $ = cheerio.load(html);
    const patterns = [
        { selector: 'script#__NEXT_DATA__', method: 'nextjs' },
        { selector: 'script[data-n-head="ssr"]', method: 'nuxt' },
        { pattern: /window\.__PRELOADED_STATE__\s*=\s*(\{[\s\S]*?\});?(?:\s*<\/script>|$)/i, method: 'preloaded_state' },
        { pattern: /window\.initialReduxState\s*=\s*(\{[\s\S]*?\});/i, method: 'redux' },
        { pattern: /window\.__INITIAL_STATE__\s*=\s*(\{[\s\S]*?\});/i, method: 'initial_state' },
        { pattern: /window\.__INITIAL_PROPS__\s*=\s*(\{[\s\S]*?\});/i, method: 'initial_props' },
        { pattern: /window\.productData\s*=\s*(\{[\s\S]*?\});/i, method: 'product_data' },
        { pattern: /"product"\s*:\s*(\{[\s\S]*?"nutrition"[\s\S]*?\})/i, method: 'product_object' },
        { pattern: /window\.__data\s*=\s*(\{[\s\S]*?\});/i, method: 'tesco_data' },
        { pattern: /"productData"\s*:\s*(\{[\s\S]*?\})\s*,/i, method: 'sainsburys_graphql' },
        { pattern: /window\.APP_STATE\s*=\s*(\{[\s\S]*?\});/i, method: 'app_state' },
    ];
    for (const p of patterns) {
        if (p.selector) {
            const script = $(p.selector);
            if (script.length) {
                try {
                    const json = JSON.parse(script.html() || '');
                    const product = extractProductFromJson(json);
                    if (product && hasValidNutrition(product.nutrition)) {
                        console.log(`Found product via ${p.method}`);
                        return { product, method: p.method };
                    }
                }
                catch (e) {
                    // Continue
                }
            }
        }
    }
    const scripts = $('script').toArray();
    for (const script of scripts) {
        const content = $(script).html() || '';
        for (const p of patterns) {
            if (p.pattern) {
                const match = content.match(p.pattern);
                if (match && match[1]) {
                    try {
                        let jsonStr = match[1]
                            .replace(/undefined/g, 'null')
                            .replace(/'/g, '"');
                        const json = JSON.parse(jsonStr);
                        const product = extractProductFromJson(json);
                        if (product && hasValidNutrition(product.nutrition)) {
                            console.log(`Found product via ${p.method}`);
                            return { product, method: p.method };
                        }
                    }
                    catch (e) {
                        try {
                            const cleanedStr = match[1].replace(/(\w+):/g, '"$1":').replace(/'/g, '"');
                            const json = JSON.parse(cleanedStr);
                            const product = extractProductFromJson(json);
                            if (product && hasValidNutrition(product.nutrition)) {
                                return { product, method: p.method };
                            }
                        }
                        catch (e2) {
                            // Continue
                        }
                    }
                }
            }
        }
    }
    return { product: null, method: 'none' };
}
function extractProductFromJson(json) {
    if (!json || typeof json !== 'object')
        return null;
    const productLocations = [
        json.props?.pageProps?.product,
        json.props?.pageProps?.productDetails,
        json.props?.pageProps?.productData,
        json.props?.initialProps?.product,
        json.product,
        json.data?.product,
        json.pageProps?.product,
        json.productData,
        json.productDetails,
        json.state?.product,
        json.entities?.products,
        json.page?.product,
        json.content?.product,
    ];
    let productData = null;
    for (const loc of productLocations) {
        if (loc) {
            productData = loc;
            break;
        }
    }
    if (productData && typeof productData === 'object' && !productData.name) {
        const values = Object.values(productData);
        if (values.length > 0 && typeof values[0] === 'object') {
            productData = values[0];
        }
    }
    if (!productData) {
        productData = findProductInObject(json);
    }
    if (!productData)
        return null;
    const nutrition = findNutritionInObject(productData) || {};
    return {
        name: productData.name || productData.title || productData.productName || productData.displayName,
        brand: productData.brand?.name || productData.brand || productData.brandName,
        barcode: productData.gtin || productData.gtin13 || productData.ean || productData.barcode || productData.sku,
        description: productData.description || productData.shortDescription,
        nutrition,
        ingredients: productData.ingredients || productData.ingredientsList || productData.ingredientsText,
        allergens: productData.allergens || identifyAllergens(productData.ingredients || ''),
        imageUrl: productData.image?.url || productData.imageUrl || (Array.isArray(productData.images) ? productData.images[0]?.url : productData.images)
    };
}
function findProductInObject(obj, depth = 0) {
    if (!obj || typeof obj !== 'object' || depth > 8)
        return null;
    const keys = Object.keys(obj);
    if (keys.includes('name') && (keys.includes('nutrition') || keys.includes('nutritionInfo') || keys.includes('gtin'))) {
        return obj;
    }
    for (const key of keys) {
        const value = obj[key];
        if (value && typeof value === 'object') {
            const found = findProductInObject(value, depth + 1);
            if (found)
                return found;
        }
    }
    return null;
}
function findNutritionInObject(obj, depth = 0) {
    if (!obj || typeof obj !== 'object' || depth > 12)
        return null;
    const keys = Object.keys(obj).map(k => k.toLowerCase());
    if (keys.includes('per100g') || keys.includes('per_100g') || keys.includes('nutritionper100g')) {
        const per100g = obj.per100g || obj.per_100g || obj.nutritionPer100g || obj.NutritionPer100g;
        if (per100g) {
            const nutrition = extractNutritionValues(per100g);
            if (hasValidNutrition(nutrition))
                return nutrition;
        }
    }
    if (keys.includes('nutritiontable') || keys.includes('nutrition_table') || keys.includes('nutritiondata')) {
        const tableData = obj.nutritionTable || obj.nutrition_table || obj.nutritionData;
        const nutrition = extractNutritionValues(tableData);
        if (hasValidNutrition(nutrition))
            return nutrition;
    }
    if (keys.some(k => ['energy', 'calories', 'kcal', 'fat', 'protein', 'carbohydrate', 'carbs'].includes(k))) {
        const nutrition = extractNutritionValues(obj);
        if (hasValidNutrition(nutrition))
            return nutrition;
    }
    for (const key of Object.keys(obj)) {
        const value = obj[key];
        if (value && typeof value === 'object') {
            const found = findNutritionInObject(value, depth + 1);
            if (found && hasValidNutrition(found))
                return found;
        }
    }
    return null;
}
function extractNutritionValues(obj) {
    if (!obj || typeof obj !== 'object')
        return {};
    const nutrition = {};
    if (Array.isArray(obj)) {
        for (const item of obj) {
            if (item && typeof item === 'object') {
                const name = (item.name || item.label || item.nutrient || '').toLowerCase();
                const value = item.value || item.amount || item.per100g || item.valuePer100g;
                if (name.includes('energy') && (name.includes('kcal') || String(value).includes('kcal'))) {
                    nutrition.energyKcal = parseNumber(value);
                }
                else if (name.includes('energy') && (name.includes('kj') || String(value).includes('kJ'))) {
                    nutrition.energyKj = parseNumber(value);
                }
                else if (name === 'fat' || (name.includes('fat') && !name.includes('saturate'))) {
                    nutrition.fat = parseNumber(value);
                }
                else if (name.includes('saturate')) {
                    nutrition.saturates = parseNumber(value);
                }
                else if (name.includes('carbohydrate') || name === 'carbs') {
                    nutrition.carbohydrate = parseNumber(value);
                }
                else if (name.includes('sugar')) {
                    nutrition.sugars = parseNumber(value);
                }
                else if (name.includes('fibre') || name.includes('fiber')) {
                    nutrition.fibre = parseNumber(value);
                }
                else if (name.includes('protein')) {
                    nutrition.protein = parseNumber(value);
                }
                else if (name.includes('salt') || name.includes('sodium')) {
                    const val = parseNumber(value);
                    if (name.includes('sodium')) {
                        nutrition.salt = val ? Math.round(val * 2.5 * 10) / 10 : undefined;
                    }
                    else {
                        nutrition.salt = val;
                    }
                }
            }
        }
        return nutrition;
    }
    for (const [key, value] of Object.entries(obj)) {
        const lowerKey = key.toLowerCase();
        if (lowerKey.includes('energykcal') || lowerKey.includes('energy_kcal') || lowerKey === 'kcal' || lowerKey === 'calories') {
            nutrition.energyKcal = parseNumber(value);
        }
        else if (lowerKey.includes('energykj') || lowerKey.includes('energy_kj') || lowerKey === 'kj') {
            nutrition.energyKj = parseNumber(value);
        }
        else if (lowerKey === 'fat' || lowerKey === 'totalfat' || lowerKey === 'fat_g') {
            nutrition.fat = parseNumber(value);
        }
        else if (lowerKey.includes('saturate') || lowerKey === 'satfat') {
            nutrition.saturates = parseNumber(value);
        }
        else if (lowerKey.includes('carbohydrate') || lowerKey === 'carbs' || lowerKey === 'carb') {
            nutrition.carbohydrate = parseNumber(value);
        }
        else if (lowerKey.includes('sugar')) {
            nutrition.sugars = parseNumber(value);
        }
        else if (lowerKey.includes('fibre') || lowerKey.includes('fiber')) {
            nutrition.fibre = parseNumber(value);
        }
        else if (lowerKey.includes('protein')) {
            nutrition.protein = parseNumber(value);
        }
        else if (lowerKey.includes('salt') && !lowerKey.includes('sodium')) {
            nutrition.salt = parseNumber(value);
        }
        else if (lowerKey.includes('sodium')) {
            const val = parseNumber(value);
            nutrition.salt = val ? Math.round(val * 2.5 * 10) / 10 : undefined;
        }
    }
    return nutrition;
}
// ============================================================
// TIER 3: JSON-LD EXTRACTION
// ============================================================
function extractJsonLd(html) {
    const $ = cheerio.load(html);
    const scripts = $('script[type="application/ld+json"]');
    let productData = null;
    scripts.each((_, script) => {
        try {
            const json = JSON.parse($(script).html() || '');
            const data = Array.isArray(json) ? json.find(item => item['@type'] === 'Product') : json;
            if (data) {
                if (data['@type'] === 'Product') {
                    productData = data;
                }
                else if (data['@graph']) {
                    productData = data['@graph'].find((g) => g['@type'] === 'Product');
                }
            }
        }
        catch (e) {
            // Invalid JSON
        }
    });
    if (!productData)
        return null;
    const nutrition = {};
    if (productData.nutrition) {
        const n = productData.nutrition;
        nutrition.energyKcal = parseNumber(n.calories || n.energyKcal);
        nutrition.energyKj = parseNumber(n.energyKj);
        nutrition.fat = parseNumber(n.fatContent || n.fat);
        nutrition.saturates = parseNumber(n.saturatedFatContent || n.saturates);
        nutrition.carbohydrate = parseNumber(n.carbohydrateContent || n.carbohydrate);
        nutrition.sugars = parseNumber(n.sugarContent || n.sugars);
        nutrition.fibre = parseNumber(n.fiberContent || n.fibre);
        nutrition.protein = parseNumber(n.proteinContent || n.protein);
        nutrition.salt = parseNumber(n.sodiumContent ? parseNumber(n.sodiumContent) * 2.5 : n.salt);
    }
    return {
        name: productData.name,
        brand: productData.brand?.name || productData.brand,
        barcode: productData.gtin13 || productData.gtin || productData.sku,
        description: productData.description,
        nutrition,
        ingredients: productData.ingredients,
        imageUrl: productData.image?.url || (Array.isArray(productData.image) ? productData.image[0] : productData.image)
    };
}
function findNutritionTable($) {
    const tables = $('table').toArray();
    for (const table of tables) {
        const $table = $(table);
        const text = $table.text().toLowerCase();
        // MUST have "per 100g" - UK legal requirement
        const hasPer100g = text.includes('per 100g') || text.includes('per100g') ||
            text.includes('100g') || text.includes('typical values');
        if (!hasPer100g)
            continue;
        // Count nutrition rows
        const rows = $table.find('tr');
        let nutritionRowCount = 0;
        const nutritionKeywords = ['energy', 'fat', 'carbohydrate', 'protein', 'salt', 'sugar', 'fibre', 'fiber', 'saturate'];
        rows.each((_, row) => {
            const rowText = $(row).text().toLowerCase();
            if (nutritionKeywords.some(kw => rowText.includes(kw))) {
                nutritionRowCount++;
            }
        });
        if (nutritionRowCount >= 4) {
            const structure = detectTableStructure($table, $);
            return { table: $table, structure };
        }
    }
    return null;
}
function detectTableStructure($table, $) {
    const firstRow = $table.find('tr').first();
    const headers = firstRow.find('th, td').toArray().map(h => $(h).text().toLowerCase().trim());
    let per100gColumn = -1;
    headers.forEach((header, index) => {
        if (header.includes('per 100g') || header.includes('100g') || header.includes('typical')) {
            per100gColumn = index;
        }
    });
    if (per100gColumn === -1) {
        const secondRow = $table.find('tr').eq(1);
        const cells = secondRow.find('td, th').toArray();
        cells.forEach((cell, index) => {
            const text = $(cell).text().toLowerCase();
            if (text.includes('100g') || text.includes('per 100')) {
                per100gColumn = index;
            }
        });
    }
    if (per100gColumn === -1) {
        per100gColumn = 1;
    }
    return { labelColumn: 0, per100gColumn };
}
function extractFromIntelligentTable($) {
    const result = findNutritionTable($);
    if (!result)
        return null;
    const { table, structure } = result;
    const nutrition = {};
    const name = $('h1').first().text().trim() ||
        $('[class*="product-title"]').first().text().trim() ||
        $('[class*="product-name"]').first().text().trim();
    table.find('tr').each((_, row) => {
        const cells = $(row).find('td, th');
        if (cells.length < 2)
            return;
        const label = $(cells.eq(structure.labelColumn)).text().toLowerCase().trim();
        const valueCell = cells.eq(structure.per100gColumn);
        const value = valueCell.length ? $(valueCell).text().trim() : '';
        if (label.includes('nutrient') || label.includes('typical values'))
            return;
        if (label.includes('energy') && (label.includes('kcal') || value.includes('kcal'))) {
            nutrition.energyKcal = parseNumber(value);
        }
        else if (label.includes('energy') && (label.includes('kj') || value.includes('kJ'))) {
            nutrition.energyKj = parseNumber(value);
        }
        else if ((label === 'fat' || label.includes('fat')) && !label.includes('saturate')) {
            nutrition.fat = parseNumber(value);
        }
        else if (label.includes('saturate') || label.includes('of which saturates')) {
            nutrition.saturates = parseNumber(value);
        }
        else if (label.includes('carbohydrate')) {
            nutrition.carbohydrate = parseNumber(value);
        }
        else if (label.includes('sugar') || label.includes('of which sugars')) {
            nutrition.sugars = parseNumber(value);
        }
        else if (label.includes('fibre') || label.includes('fiber')) {
            nutrition.fibre = parseNumber(value);
        }
        else if (label.includes('protein')) {
            nutrition.protein = parseNumber(value);
        }
        else if (label.includes('salt')) {
            nutrition.salt = parseNumber(value);
        }
    });
    if (!hasValidNutrition(nutrition))
        return null;
    const ingredients = $('[class*="ingredient"]').first().text().trim() ||
        $('[data-testid*="ingredient"]').first().text().trim();
    return { name, nutrition, ingredients, allergens: identifyAllergens(ingredients) };
}
// ============================================================
// TIER 4.5: TEXT-BASED EXTRACTION (DIV/SPAN/ANY ELEMENT)
// ============================================================
function extractFromTextPatterns($) {
    // Get the entire page text
    const pageText = $('body').text();
    // Look for nutrition sections by common container classes
    const nutritionSelectors = [
        '[class*="nutrition"]',
        '[class*="nutritional"]',
        '[class*="nutrient"]',
        '[data-testid*="nutrition"]',
        '[id*="nutrition"]',
        'dl', // definition lists
        '[class*="product-info"]',
        '[class*="product-detail"]',
    ];
    let nutritionText = '';
    for (const selector of nutritionSelectors) {
        const elements = $(selector);
        if (elements.length > 0) {
            elements.each((_, el) => {
                const text = $(el).text();
                // Check if this section has nutrition keywords
                const lower = text.toLowerCase();
                if (lower.includes('energy') && (lower.includes('protein') || lower.includes('fat'))) {
                    nutritionText = text;
                    return false; // break
                }
                return; // explicit return for TypeScript
            });
            if (nutritionText)
                break;
        }
    }
    // If no nutrition section found, use page text but be more careful
    if (!nutritionText) {
        // Look for "per 100g" sections in the page
        const per100gMatch = pageText.match(/(?:per\s*100\s*g|typical\s*values)[^]*?(?:salt|sodium)[^]{0,200}/i);
        if (per100gMatch) {
            nutritionText = per100gMatch[0];
        }
    }
    if (!nutritionText)
        return null;
    const nutrition = {};
    // Extract energy (kcal)
    const kcalPatterns = [
        /energy[:\s]*(\d+(?:\.\d+)?)\s*kcal/i,
        /(\d+(?:\.\d+)?)\s*kcal/i,
        /energy[^]*?(\d+)\s*kcal/i,
    ];
    for (const pattern of kcalPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.energyKcal = parseFloat(match[1]);
            break;
        }
    }
    // Extract energy (kJ)
    const kjPatterns = [
        /energy[:\s]*(\d+(?:\.\d+)?)\s*kJ/i,
        /(\d+(?:\.\d+)?)\s*kJ/i,
    ];
    for (const pattern of kjPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.energyKj = parseFloat(match[1]);
            break;
        }
    }
    // Extract fat
    const fatPatterns = [
        /(?:^|\s)fat[:\s]*(\d+(?:\.\d+)?)\s*g/im,
        /fat\s*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of fatPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.fat = parseFloat(match[1]);
            break;
        }
    }
    // Extract saturates
    const saturatesPatterns = [
        /saturate[sd]?[:\s]*(\d+(?:\.\d+)?)\s*g/i,
        /of which saturates[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of saturatesPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.saturates = parseFloat(match[1]);
            break;
        }
    }
    // Extract carbohydrate
    const carbPatterns = [
        /carbohydrate[s]?[:\s]*(\d+(?:\.\d+)?)\s*g/i,
        /carbs[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of carbPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.carbohydrate = parseFloat(match[1]);
            break;
        }
    }
    // Extract sugars
    const sugarPatterns = [
        /sugars?[:\s]*(\d+(?:\.\d+)?)\s*g/i,
        /of which sugars[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of sugarPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.sugars = parseFloat(match[1]);
            break;
        }
    }
    // Extract fibre
    const fibrePatterns = [
        /fibre[:\s]*(\d+(?:\.\d+)?)\s*g/i,
        /fiber[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of fibrePatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.fibre = parseFloat(match[1]);
            break;
        }
    }
    // Extract protein
    const proteinPatterns = [
        /protein[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of proteinPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.protein = parseFloat(match[1]);
            break;
        }
    }
    // Extract salt
    const saltPatterns = [
        /salt[:\s]*(\d+(?:\.\d+)?)\s*g/i,
    ];
    for (const pattern of saltPatterns) {
        const match = nutritionText.match(pattern);
        if (match) {
            nutrition.salt = parseFloat(match[1]);
            break;
        }
    }
    if (!hasValidNutrition(nutrition))
        return null;
    // Extract product name
    const name = $('h1').first().text().trim() ||
        $('[class*="product-title"]').first().text().trim() ||
        $('[class*="product-name"]').first().text().trim() ||
        $('[data-testid*="product-title"]').first().text().trim();
    // Extract ingredients
    const ingredientsSelectors = [
        '[class*="ingredient"]',
        '[data-testid*="ingredient"]',
        '[id*="ingredient"]',
    ];
    let ingredients = '';
    for (const selector of ingredientsSelectors) {
        const el = $(selector).first();
        if (el.length) {
            ingredients = el.text().trim();
            if (ingredients.length > 20)
                break;
        }
    }
    return { name, nutrition, ingredients, allergens: identifyAllergens(ingredients) };
}
// ============================================================
// TESCO8 API INTEGRATION (Official UK Source)
// RapidAPI-based Tesco product search and details
// ============================================================
const TESCO8_API_KEY = functions.config().rapidapi?.key || '7e61162448msh2832ba8d19f26cep1e55c3jsn5242e6c6d761';
const TESCO8_HOST = 'tesco8.p.rapidapi.com';
async function tryTesco8Api(productName) {
    const warnings = [];
    if (!productName || productName.length < 3) {
        return { product: null, method: 'no_product_name', warnings };
    }
    try {
        console.log(`Trying Tesco8 API for: ${productName}`);
        // Step 1: Search for the product
        const searchResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-search-by-keyword`, {
            params: { query: productName },
            headers: {
                'x-rapidapi-host': TESCO8_HOST,
                'x-rapidapi-key': TESCO8_API_KEY
            },
            timeout: 10000
        });
        if (!searchResponse.data?.success || !searchResponse.data?.data?.products?.length) {
            console.log('Tesco8 API: No products found');
            return { product: null, method: 'tesco8_not_found', warnings };
        }
        // Get the first matching product
        const searchResult = searchResponse.data.data.products[0];
        console.log(`Found Tesco product: ${searchResult.title} (ID: ${searchResult.id})`);
        // Step 2: Get full product details with nutrition
        const detailsResponse = await axios_1.default.get(`https://${TESCO8_HOST}/product-details`, {
            params: { productId: searchResult.id },
            headers: {
                'x-rapidapi-host': TESCO8_HOST,
                'x-rapidapi-key': TESCO8_API_KEY
            },
            timeout: 10000
        });
        if (!detailsResponse.data?.success || !detailsResponse.data?.data?.results?.[0]?.data?.product) {
            console.log('Tesco8 API: Could not get product details');
            warnings.push('Found product but could not get details');
            return { product: null, method: 'tesco8_no_details', warnings };
        }
        const productData = detailsResponse.data.data.results[0].data.product;
        const details = productData.details || {};
        // Parse nutrition data from nutritionInfo array
        const nutrition = {};
        const nutritionItems = details.nutritionInfo || [];
        for (const item of nutritionItems) {
            const name = item.name?.toLowerCase() || '';
            const value = item.perComp || ''; // per 100g/100ml column
            // Handle energy - may be combined "209kJ / 50kcal" or separate rows
            if (name.includes('energy') || (name === '-' && value.includes('kcal'))) {
                // Extract kcal from value (either combined "209kJ / 50kcal" or just "233kcal")
                const kcalMatch = value.match(/(\d+(?:\.\d+)?)\s*kcal/i);
                if (kcalMatch)
                    nutrition.energyKcal = parseNumber(kcalMatch[1]);
                // Extract kJ if present
                const kjMatch = value.match(/(\d+(?:\.\d+)?)\s*kJ/i);
                if (kjMatch)
                    nutrition.energyKj = parseNumber(kjMatch[1]);
            }
            else if (name === 'fat' && !name.includes('saturate')) {
                nutrition.fat = parseNumber(value);
            }
            else if (name === 'saturates' || name.includes('saturate') || name === 'of which saturates') {
                nutrition.saturates = parseNumber(value);
            }
            else if ((name === 'carbohydrate' || name.includes('carbohydrate')) && !name.includes('sugar')) {
                nutrition.carbohydrate = parseNumber(value);
            }
            else if (name === 'sugars' || name.includes('sugar') || name === 'of which sugars') {
                nutrition.sugars = parseNumber(value);
            }
            else if (name === 'fibre' || name.includes('fibre') || name.includes('fiber')) {
                nutrition.fibre = parseNumber(value);
            }
            else if (name === 'protein' || name.includes('protein')) {
                nutrition.protein = parseNumber(value);
            }
            else if (name === 'salt' || name.includes('salt')) {
                nutrition.salt = parseNumber(value);
            }
        }
        // Build the product (note: Tesco images excluded - use other sources only)
        const product = {
            name: productData.title,
            brand: productData.brandName,
            barcode: productData.gtin,
            description: productData.description?.join(' '),
            nutrition,
            ingredients: details.ingredients?.join(', '),
            allergens: details.allergenInfo ? identifyAllergens(details.allergenInfo) : [],
            imageUrl: undefined, // Tesco images not used
            servingSize: details.packSize?.[0]?.value ? `${details.packSize[0].value}${details.packSize[0].units}` : undefined
        };
        if (hasValidNutrition(product.nutrition)) {
            console.log(`Tesco8 API success: ${product.name}`);
            warnings.push('Data from Tesco UK (official source)');
            return { product, method: 'tesco8_api', warnings };
        }
        console.log('Tesco8 API: Product found but nutrition incomplete');
        warnings.push('Product found but nutrition data incomplete');
        return { product: null, method: 'tesco8_incomplete', warnings };
    }
    catch (error) {
        console.log(`Tesco8 API error: ${error.message}`);
        if (error.response?.status === 429) {
            warnings.push('Tesco API rate limit reached');
        }
        return { product: null, method: 'tesco8_error', warnings };
    }
}
// ============================================================
// TIER 6: OPENFOODFACTS (LAST RESORT - WITH CLEANSING)
// ============================================================
async function tryOpenFoodFacts(barcode) {
    const warnings = [];
    if (!barcode || barcode.length < 8) {
        return { product: null, method: 'no_barcode', warnings };
    }
    try {
        console.log(`Trying OpenFoodFacts for barcode: ${barcode}`);
        const response = await axios_1.default.get(`https://world.openfoodfacts.org/api/v0/product/${barcode}.json`, { timeout: 5000 });
        if (response.data?.status === 1 && response.data.product) {
            const p = response.data.product;
            const n = p.nutriments || {};
            // Build raw product
            const rawProduct = {
                name: p.product_name || p.product_name_en,
                brand: p.brands,
                barcode: p.code,
                nutrition: {
                    energyKcal: parseNumber(n['energy-kcal_100g']),
                    energyKj: parseNumber(n['energy-kj_100g']),
                    fat: parseNumber(n['fat_100g']),
                    saturates: parseNumber(n['saturated-fat_100g']),
                    carbohydrate: parseNumber(n['carbohydrates_100g']),
                    sugars: parseNumber(n['sugars_100g']),
                    fibre: parseNumber(n['fiber_100g']),
                    protein: parseNumber(n['proteins_100g']),
                    salt: parseNumber(n['salt_100g'])
                },
                ingredients: p.ingredients_text || p.ingredients_text_en,
                allergens: p.allergens_tags || [],
                imageUrl: p.image_url || p.image_front_url
            };
            // Apply cleansing
            const cleansedProduct = cleanseOpenFoodFactsData(rawProduct);
            // Add warnings about cleansing
            if (rawProduct.name !== cleansedProduct.name) {
                warnings.push('Product name was corrected for OCR/spelling issues');
            }
            if (rawProduct.brand !== cleansedProduct.brand) {
                warnings.push('Brand name was normalized');
            }
            if (rawProduct.ingredients !== cleansedProduct.ingredients) {
                warnings.push('Ingredients text was cleaned');
            }
            // Check data quality
            const completeness = p.completeness || 0;
            if (completeness < 0.5) {
                warnings.push(`Low data completeness (${Math.round(completeness * 100)}%)`);
            }
            // Check data age
            const lastModified = p.last_modified_t;
            if (lastModified) {
                const ageInDays = (Date.now() / 1000 - lastModified) / 86400;
                if (ageInDays > 365) {
                    warnings.push(`Data may be outdated (last updated ${Math.round(ageInDays / 30)} months ago)`);
                }
            }
            // Check nutrition grade
            if (p.nutrition_grade_fr) {
                warnings.push(`Nutri-Score: ${p.nutrition_grade_fr.toUpperCase()}`);
            }
            if (hasValidNutrition(cleansedProduct.nutrition)) {
                console.log(`Found and cleansed product from OpenFoodFacts: ${cleansedProduct.name}`);
                return { product: cleansedProduct, method: 'openfoodfacts', warnings };
            }
        }
    }
    catch (error) {
        console.log(`OpenFoodFacts lookup failed: ${error.message}`);
    }
    return { product: null, method: 'openfoodfacts_not_found', warnings };
}
// ============================================================
// MAIN EXTRACTION FUNCTION
// ============================================================
exports.extractUKProductData = functions
    .runWith({ timeoutSeconds: 60, memory: '512MB' })
    .https.onCall(async (data, _context) => {
    const { url, barcode } = data;
    const timestamp = new Date().toISOString();
    const warnings = [];
    const debugInfo = { tiersAttempted: [] };
    if (!url) {
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: ['No URL provided'],
            sourceUrl: '',
            timestamp,
            error: 'URL is required'
        };
    }
    try {
        console.log(`Extracting from: ${url}`);
        console.log(`Barcode available: ${barcode || 'none'}`);
        const response = await axios_1.default.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
                'Accept-Language': 'en-GB,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'Cache-Control': 'no-cache',
            },
            timeout: 20000,
            maxRedirects: 5
        });
        const html = response.data;
        const $ = cheerio.load(html);
        debugInfo.htmlLength = html.length;
        debugInfo.scriptTagsFound = $('script').length;
        debugInfo.jsonLdFound = $('script[type="application/ld+json"]').length > 0;
        debugInfo.tablesFound = $('table').length;
        let extractedData = null;
        let extractionMethod = 'failed';
        let confidence = 0;
        // Get product name for Tesco search (from request or page title)
        const productNameForSearch = data.productName ||
            $('h1').first().text().trim() ||
            $('[class*="product-title"]').first().text().trim() ||
            $('[class*="product-name"]').first().text().trim() ||
            $('title').text().split('|')[0].trim();
        // TIER 0: TESCO8 API FIRST (official UK supermarket source)
        // This is the most reliable UK source - official Tesco data with full nutrition
        if (productNameForSearch && productNameForSearch.length >= 3) {
            debugInfo.tiersAttempted?.push('tesco8_api_primary');
            console.log(`Trying Tesco8 API first (name: ${productNameForSearch})`);
            const tescoResult = await tryTesco8Api(productNameForSearch);
            if (tescoResult.product && hasValidNutrition(tescoResult.product.nutrition)) {
                extractedData = tescoResult.product;
                extractionMethod = 'tesco8_api';
                confidence = 92; // High confidence - official Tesco data
                warnings.push(...tescoResult.warnings);
                console.log('Success via Tier 0: Tesco8 API (primary)');
                // Return immediately - official UK source found
                return {
                    success: true,
                    data: extractedData,
                    extractionMethod,
                    confidence,
                    warnings,
                    sourceUrl: url,
                    timestamp,
                    debugInfo
                };
            }
            console.log('Tesco8 API did not find this product, trying OpenFoodFacts...');
        }
        // TIER 0.5: OpenFoodFacts (when barcode is available)
        // Good fallback - free API, has UK products, no anti-bot issues
        if (barcode) {
            debugInfo.tiersAttempted?.push('openfoodfacts');
            console.log(`Trying OpenFoodFacts (barcode: ${barcode})`);
            const offResult = await tryOpenFoodFacts(barcode);
            if (offResult.product && hasValidNutrition(offResult.product.nutrition)) {
                extractedData = offResult.product;
                extractionMethod = 'openfoodfacts';
                confidence = 85; // Good confidence for barcode match
                warnings.push('Data from OpenFoodFacts (community-sourced, cleansed)');
                warnings.push(...offResult.warnings);
                console.log('Success via Tier 0.5: OpenFoodFacts');
                // Return immediately - no need to try scraping
                return {
                    success: true,
                    data: extractedData,
                    extractionMethod,
                    confidence,
                    warnings,
                    sourceUrl: url,
                    timestamp,
                    debugInfo
                };
            }
            console.log('OpenFoodFacts did not have this product, falling back to web extraction');
        }
        // TIER 1: Data Attribute JSON (fallback when APIs fail)
        debugInfo.tiersAttempted?.push('data_attributes');
        const dataAttrResult = extractDataAttributes($);
        if (dataAttrResult && hasValidNutrition(dataAttrResult.nutrition)) {
            extractedData = dataAttrResult;
            extractionMethod = 'data_attributes';
            confidence = 92;
            debugInfo.dataAttributesFound = true;
            console.log('Success via Tier 1: Data Attributes');
        }
        // TIER 2: Embedded JSON
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('embedded_json');
            const embeddedResult = extractEmbeddedJson(html);
            if (embeddedResult.product && hasValidNutrition(embeddedResult.product.nutrition)) {
                extractedData = embeddedResult.product;
                extractionMethod = 'embedded_json';
                confidence = 95;
                debugInfo.embeddedJsonFound = true;
                console.log(`Success via Tier 2: Embedded JSON (${embeddedResult.method})`);
            }
        }
        // TIER 3: JSON-LD
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('json_ld');
            const jsonLdData = extractJsonLd(html);
            if (jsonLdData && hasValidNutrition(jsonLdData.nutrition)) {
                extractedData = jsonLdData;
                extractionMethod = 'structured_data';
                confidence = 90;
                console.log('Success via Tier 3: JSON-LD');
            }
        }
        // TIER 4: Intelligent HTML Table Parsing
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('html_table');
            const tableResult = extractFromIntelligentTable($);
            if (tableResult && hasValidNutrition(tableResult.nutrition)) {
                extractedData = tableResult;
                extractionMethod = 'html_parsing';
                confidence = 80;
                debugInfo.nutritionTableFound = true;
                console.log('Success via Tier 4: Intelligent Table Parsing');
            }
        }
        // TIER 4.5: Text Pattern Extraction (for div-based layouts)
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('text_patterns');
            const textResult = extractFromTextPatterns($);
            if (textResult && hasValidNutrition(textResult.nutrition)) {
                extractedData = textResult;
                extractionMethod = 'html_parsing';
                confidence = 75;
                debugInfo.textPatternsFound = true;
                console.log('Success via Tier 4.5: Text Pattern Extraction');
            }
        }
        // Note: Tesco8 API is now tried FIRST at Tier 0
        // Puppeteer extraction available via separate extractWithPuppeteer function
        // Validate and finalize
        if (extractedData && hasValidNutrition(extractedData.nutrition)) {
            const n = extractedData.nutrition;
            if (!n.energyKcal)
                warnings.push('Missing energy (kcal)');
            if (n.fat === undefined)
                warnings.push('Missing fat');
            if (n.carbohydrate === undefined)
                warnings.push('Missing carbohydrate');
            if (n.protein === undefined)
                warnings.push('Missing protein');
            if (n.salt === undefined)
                warnings.push('Missing salt');
            if (warnings.length > 0) {
                confidence = Math.max(confidence - (warnings.length * 3), 40);
            }
            return {
                success: true,
                data: extractedData,
                extractionMethod,
                confidence,
                warnings,
                sourceUrl: url,
                timestamp,
                debugInfo
            };
        }
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: [
                'Could not extract nutrition data from page',
                `Tiers attempted: ${debugInfo.tiersAttempted?.join(', ')}`,
                `HTML length: ${debugInfo.htmlLength} bytes`,
                `Tables found: ${debugInfo.tablesFound}`,
                barcode ? 'OpenFoodFacts also did not have this product' : 'No barcode provided for fallback',
                'Try using extractWithPuppeteer for JS-rendered pages'
            ],
            sourceUrl: url,
            timestamp,
            error: 'Extraction failed - nutrition data not found',
            debugInfo
        };
    }
    catch (error) {
        console.error('Extraction error:', error);
        let errorMessage = error.message || 'Failed to fetch or parse page';
        let httpStatus = error.response?.status;
        if (httpStatus === 403) {
            errorMessage = 'Access forbidden (403)';
        }
        else if (httpStatus === 404) {
            errorMessage = 'Page not found (404)';
        }
        else if (error.code === 'ECONNABORTED') {
            errorMessage = 'Request timed out';
        }
        // FALLBACK 1: Try OpenFoodFacts when HTTP request fails and barcode is available
        if (barcode) {
            console.log(`HTTP request failed, trying OpenFoodFacts fallback with barcode: ${barcode}`);
            debugInfo.tiersAttempted?.push('openfoodfacts_fallback');
            try {
                const offResult = await tryOpenFoodFacts(barcode);
                if (offResult.product && hasValidNutrition(offResult.product.nutrition)) {
                    console.log('Success via OpenFoodFacts fallback (cleansed)');
                    warnings.push(`Original source failed: ${errorMessage}`);
                    warnings.push('Data from OpenFoodFacts (community-sourced, cleansed)');
                    warnings.push(...offResult.warnings);
                    return {
                        success: true,
                        data: offResult.product,
                        extractionMethod: 'openfoodfacts',
                        confidence: 65, // Lower confidence for fallback scenario
                        warnings,
                        sourceUrl: url,
                        timestamp,
                        debugInfo
                    };
                }
            }
            catch (offError) {
                console.error('OpenFoodFacts fallback also failed:', offError.message);
                warnings.push(`OpenFoodFacts fallback failed: ${offError.message}`);
            }
        }
        // FALLBACK 2: Try Tesco8 API when HTTP request fails and product name is available
        if (data.productName && data.productName.length >= 3) {
            console.log(`HTTP request failed, trying Tesco8 API fallback with name: ${data.productName}`);
            debugInfo.tiersAttempted?.push('tesco8_api_fallback');
            try {
                const tescoResult = await tryTesco8Api(data.productName);
                if (tescoResult.product && hasValidNutrition(tescoResult.product.nutrition)) {
                    console.log('Success via Tesco8 API fallback');
                    warnings.push(`Original source failed: ${errorMessage}`);
                    warnings.push(...tescoResult.warnings);
                    return {
                        success: true,
                        data: tescoResult.product,
                        extractionMethod: 'tesco8_api',
                        confidence: 75, // Slightly lower confidence for fallback scenario
                        warnings,
                        sourceUrl: url,
                        timestamp,
                        debugInfo
                    };
                }
            }
            catch (tescoError) {
                console.error('Tesco8 API fallback also failed:', tescoError.message);
                warnings.push(`Tesco8 API fallback failed: ${tescoError.message}`);
            }
        }
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings,
            sourceUrl: url,
            timestamp,
            error: httpStatus === 403
                ? `${errorMessage} - try extractWithPuppeteer, provide barcode for OpenFoodFacts, or productName for Tesco API`
                : errorMessage,
            debugInfo
        };
    }
});
// ============================================================
// TIER 5: PUPPETEER EXTRACTION (SEPARATE FUNCTION)
// ============================================================
exports.extractWithPuppeteer = functions
    .runWith({ timeoutSeconds: 120, memory: '2GB' })
    .https.onCall(async (data, _context) => {
    const { url, barcode } = data;
    const timestamp = new Date().toISOString();
    const warnings = [];
    const debugInfo = { tiersAttempted: ['puppeteer'] };
    if (!url) {
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: ['No URL provided'],
            sourceUrl: '',
            timestamp,
            error: 'URL is required'
        };
    }
    let browser = null;
    try {
        console.log(`Puppeteer extraction from: ${url}`);
        // Use serverless-compatible chromium for Firebase Functions
        const chromium = require('@sparticuz/chromium');
        const puppeteer = require('puppeteer-core');
        // Configure chromium for serverless environment
        chromium.setHeadlessMode = true;
        chromium.setGraphicsMode = false;
        browser = await puppeteer.launch({
            args: chromium.args,
            defaultViewport: chromium.defaultViewport,
            executablePath: await chromium.executablePath(),
            headless: chromium.headless,
        });
        const page = await browser.newPage();
        await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
        await page.waitForFunction(() => {
            const text = document.body?.innerText?.toLowerCase() || '';
            return text.includes('per 100g') || text.includes('nutrition') || text.includes('energy');
        }, { timeout: 10000 }).catch(() => {
            console.log('Timeout waiting for nutrition content');
        });
        const html = await page.content();
        debugInfo.htmlLength = html.length;
        const $ = cheerio.load(html);
        debugInfo.tablesFound = $('table').length;
        let extractedData = null;
        let extractionMethod = 'puppeteer';
        let confidence = 0;
        // Try all extraction strategies on rendered HTML
        debugInfo.tiersAttempted?.push('data_attributes');
        extractedData = extractDataAttributes($);
        if (extractedData && hasValidNutrition(extractedData.nutrition)) {
            confidence = 88;
        }
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('embedded_json');
            const embeddedResult = extractEmbeddedJson(html);
            if (embeddedResult.product && hasValidNutrition(embeddedResult.product.nutrition)) {
                extractedData = embeddedResult.product;
                confidence = 90;
            }
        }
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('json_ld');
            const jsonLdData = extractJsonLd(html);
            if (jsonLdData && hasValidNutrition(jsonLdData.nutrition)) {
                extractedData = jsonLdData;
                confidence = 85;
            }
        }
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('html_table');
            const tableResult = extractFromIntelligentTable($);
            if (tableResult && hasValidNutrition(tableResult.nutrition)) {
                extractedData = tableResult;
                confidence = 80;
                debugInfo.nutritionTableFound = true;
            }
        }
        // Text pattern extraction (for div-based layouts)
        if (!extractedData || !hasValidNutrition(extractedData.nutrition)) {
            debugInfo.tiersAttempted?.push('text_patterns');
            const textResult = extractFromTextPatterns($);
            if (textResult && hasValidNutrition(textResult.nutrition)) {
                extractedData = textResult;
                confidence = 75;
                debugInfo.textPatternsFound = true;
            }
        }
        // OpenFoodFacts fallback
        if ((!extractedData || !hasValidNutrition(extractedData.nutrition)) && barcode) {
            debugInfo.tiersAttempted?.push('openfoodfacts');
            const offResult = await tryOpenFoodFacts(barcode);
            if (offResult.product && hasValidNutrition(offResult.product.nutrition)) {
                extractedData = offResult.product;
                extractionMethod = 'openfoodfacts';
                confidence = 70;
                warnings.push('Data from OpenFoodFacts (community-sourced, cleansed)');
                warnings.push(...offResult.warnings);
            }
        }
        if (extractedData && hasValidNutrition(extractedData.nutrition)) {
            const n = extractedData.nutrition;
            if (!n.energyKcal)
                warnings.push('Missing energy (kcal)');
            if (n.fat === undefined)
                warnings.push('Missing fat');
            if (n.carbohydrate === undefined)
                warnings.push('Missing carbohydrate');
            if (n.protein === undefined)
                warnings.push('Missing protein');
            if (n.salt === undefined)
                warnings.push('Missing salt');
            if (warnings.length > 0) {
                confidence = Math.max(confidence - (warnings.length * 3), 40);
            }
            return {
                success: true,
                data: extractedData,
                extractionMethod,
                confidence,
                warnings,
                sourceUrl: url,
                timestamp,
                debugInfo
            };
        }
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: [
                'Puppeteer rendered page but could not extract nutrition',
                `Tiers attempted: ${debugInfo.tiersAttempted?.join(', ')}`,
                `Rendered HTML: ${debugInfo.htmlLength} bytes`,
                `Tables found: ${debugInfo.tablesFound}`
            ],
            sourceUrl: url,
            timestamp,
            error: 'Extraction failed even with JS rendering',
            debugInfo
        };
    }
    catch (error) {
        console.error('Puppeteer error:', error);
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: [],
            sourceUrl: url,
            timestamp,
            error: `Puppeteer error: ${error.message}`,
            debugInfo
        };
    }
    finally {
        if (browser)
            await browser.close();
    }
});
// ============================================================
// STANDALONE TESCO API LOOKUP (Direct product name search)
// Use when you only have a product name, no URL or barcode
// ============================================================
exports.lookupTescoProduct = functions
    .runWith({ timeoutSeconds: 30, memory: '256MB' })
    .https.onCall(async (data, _context) => {
    const { productName } = data;
    const timestamp = new Date().toISOString();
    const warnings = [];
    const debugInfo = { tiersAttempted: ['tesco8_api_direct'] };
    if (!productName || productName.length < 3) {
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: ['Product name must be at least 3 characters'],
            sourceUrl: '',
            timestamp,
            error: 'Product name is required (min 3 characters)'
        };
    }
    try {
        console.log(`Direct Tesco lookup for: ${productName}`);
        const result = await tryTesco8Api(productName);
        if (result.product && hasValidNutrition(result.product.nutrition)) {
            return {
                success: true,
                data: result.product,
                extractionMethod: 'tesco8_api',
                confidence: 90, // High confidence for direct API lookup
                warnings: result.warnings,
                sourceUrl: `https://www.tesco.com/groceries/en-GB/search?query=${encodeURIComponent(productName)}`,
                timestamp,
                debugInfo
            };
        }
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: result.warnings,
            sourceUrl: '',
            timestamp,
            error: 'Product not found in Tesco database',
            debugInfo
        };
    }
    catch (error) {
        console.error('Tesco lookup error:', error);
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings,
            sourceUrl: '',
            timestamp,
            error: `Tesco API error: ${error.message}`,
            debugInfo
        };
    }
});
//# sourceMappingURL=uk-extractor.js.map