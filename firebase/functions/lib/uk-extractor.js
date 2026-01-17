"use strict";
/**
 * UK Product Data Extraction Service
 *
 * Extracts nutrition data from official UK supermarket and manufacturer product pages.
 * Uses multiple extraction strategies:
 * 1. Structured data (JSON-LD, microdata)
 * 2. Supermarket-specific HTML parsers
 * 3. AI extraction as fallback
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.extractUKProductData = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
const cheerio = require("cheerio");
// ============================================================
// HELPER FUNCTIONS
// ============================================================
function parseNumber(value) {
    if (value === undefined || value === null || value === '')
        return undefined;
    const num = parseFloat(String(value).replace(/[^0-9.-]/g, ''));
    return isNaN(num) ? undefined : Math.round(num * 10) / 10;
}
function extractDomain(url) {
    try {
        const hostname = new URL(url).hostname.toLowerCase();
        return hostname.replace(/^www\./, '');
    }
    catch {
        return '';
    }
}
function identifyAllergens(text) {
    if (!text)
        return [];
    const allergens = [];
    const lowerText = text.toLowerCase();
    // Check for UK 14 allergens
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
    return [...new Set(allergens)]; // Remove duplicates
}
// ============================================================
// STRUCTURED DATA EXTRACTION (JSON-LD)
// ============================================================
function extractStructuredData(html) {
    const $ = cheerio.load(html);
    // Look for JSON-LD
    const scripts = $('script[type="application/ld+json"]');
    let productData = null;
    scripts.each((_, script) => {
        try {
            const json = JSON.parse($(script).html() || '');
            // Handle both single object and array
            const data = Array.isArray(json) ? json.find(item => item['@type'] === 'Product') : json;
            if (data && (data['@type'] === 'Product' || data['@graph']?.find((g) => g['@type'] === 'Product'))) {
                productData = data['@type'] === 'Product' ? data : data['@graph'].find((g) => g['@type'] === 'Product');
            }
        }
        catch (e) {
            // Invalid JSON, continue
        }
    });
    if (!productData)
        return null;
    // Extract nutrition from JSON-LD
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
// ============================================================
// TESCO PARSER
// ============================================================
async function extractFromTesco(html) {
    const $ = cheerio.load(html);
    try {
        // Tesco uses __PRELOADED_STATE__ or data attributes
        const scripts = $('script').filter((_, el) => {
            const text = $(el).html() || '';
            return text.includes('__PRELOADED_STATE__') || text.includes('productData');
        });
        // Try to extract from preloaded state
        for (let i = 0; i < scripts.length; i++) {
            const scriptContent = $(scripts[i]).html() || '';
            // Try to find JSON data
            const match = scriptContent.match(/window\.__PRELOADED_STATE__\s*=\s*({.*?});/s) ||
                scriptContent.match(/window\.productData\s*=\s*({.*?});/s);
            if (match) {
                try {
                    const data = JSON.parse(match[1]);
                    const product = data.product || data;
                    const nutritionInfo = product.nutritionInfo?.per100g || product.nutrition?.per100g || {};
                    return {
                        name: product.title || product.name,
                        brand: product.brand,
                        barcode: product.gtin || product.barcode,
                        nutrition: {
                            energyKcal: parseNumber(nutritionInfo.energyKcal || nutritionInfo.calories),
                            energyKj: parseNumber(nutritionInfo.energyKj),
                            fat: parseNumber(nutritionInfo.fat),
                            saturates: parseNumber(nutritionInfo.saturates || nutritionInfo.saturatedFat),
                            carbohydrate: parseNumber(nutritionInfo.carbohydrate || nutritionInfo.carbs),
                            sugars: parseNumber(nutritionInfo.sugars),
                            fibre: parseNumber(nutritionInfo.fibre || nutritionInfo.fiber),
                            protein: parseNumber(nutritionInfo.protein),
                            salt: parseNumber(nutritionInfo.salt)
                        },
                        ingredients: product.ingredients,
                        allergens: product.allergens || identifyAllergens(product.ingredients || '')
                    };
                }
                catch (e) {
                    // Continue trying
                }
            }
        }
        // Fallback: Parse HTML directly
        const name = $('h1[data-auto="pdp-product-title"]').text().trim() ||
            $('h1.product-title').text().trim();
        const brand = $('.product-brand').text().trim();
        // Parse nutrition table
        const nutrition = {};
        $('table.nutrition-table tr, .nutrition-row').each((_, row) => {
            const cells = $(row).find('td, .nutrition-cell');
            if (cells.length >= 2) {
                const label = $(cells[0]).text().toLowerCase().trim();
                const value = $(cells[1]).text().trim();
                if (label.includes('energy') && label.includes('kcal'))
                    nutrition.energyKcal = parseNumber(value);
                else if (label.includes('energy') && label.includes('kj'))
                    nutrition.energyKj = parseNumber(value);
                else if (label.includes('fat') && !label.includes('saturate'))
                    nutrition.fat = parseNumber(value);
                else if (label.includes('saturate'))
                    nutrition.saturates = parseNumber(value);
                else if (label.includes('carbohydrate'))
                    nutrition.carbohydrate = parseNumber(value);
                else if (label.includes('sugar'))
                    nutrition.sugars = parseNumber(value);
                else if (label.includes('fibre') || label.includes('fiber'))
                    nutrition.fibre = parseNumber(value);
                else if (label.includes('protein'))
                    nutrition.protein = parseNumber(value);
                else if (label.includes('salt'))
                    nutrition.salt = parseNumber(value);
            }
        });
        if (!name)
            return null;
        return {
            name,
            brand,
            nutrition,
            ingredients: $('.ingredients-content, .product-ingredients').text().trim()
        };
    }
    catch (error) {
        console.error('Tesco extraction error:', error);
        return null;
    }
}
// ============================================================
// SAINSBURY'S PARSER
// ============================================================
async function extractFromSainsburys(html) {
    const $ = cheerio.load(html);
    try {
        const name = $('h1.pd__header').text().trim() ||
            $('[data-test-id="product-title"]').text().trim();
        const brand = $('.pd__brand').text().trim();
        const nutrition = {};
        // Sainsbury's nutrition table
        $('.pd__nutrition-table tr, .nutrition-table-row').each((_, row) => {
            const cells = $(row).find('td, th');
            if (cells.length >= 2) {
                const label = $(cells[0]).text().toLowerCase().trim();
                // Get the "per 100g" column value (usually second column)
                const value = $(cells[1]).text().trim();
                if (label.includes('energy') && (label.includes('kcal') || value.includes('kcal'))) {
                    nutrition.energyKcal = parseNumber(value.replace('kcal', ''));
                }
                else if (label.includes('energy') && (label.includes('kj') || value.includes('kj'))) {
                    nutrition.energyKj = parseNumber(value.replace('kJ', ''));
                }
                else if (label === 'fat' || (label.includes('fat') && !label.includes('saturate'))) {
                    nutrition.fat = parseNumber(value);
                }
                else if (label.includes('saturate')) {
                    nutrition.saturates = parseNumber(value);
                }
                else if (label.includes('carbohydrate')) {
                    nutrition.carbohydrate = parseNumber(value);
                }
                else if (label.includes('sugar')) {
                    nutrition.sugars = parseNumber(value);
                }
                else if (label.includes('fibre')) {
                    nutrition.fibre = parseNumber(value);
                }
                else if (label.includes('protein')) {
                    nutrition.protein = parseNumber(value);
                }
                else if (label.includes('salt')) {
                    nutrition.salt = parseNumber(value);
                }
            }
        });
        const ingredients = $('.pd__ingredients, .ingredients-list').text().trim();
        if (!name)
            return null;
        return {
            name,
            brand,
            nutrition,
            ingredients,
            allergens: identifyAllergens(ingredients)
        };
    }
    catch (error) {
        console.error('Sainsbury\'s extraction error:', error);
        return null;
    }
}
// ============================================================
// ASDA PARSER
// ============================================================
async function extractFromAsda(html) {
    const $ = cheerio.load(html);
    try {
        const name = $('h1.pdp-main-details__title').text().trim() ||
            $('[data-auto-id="product-title"]').text().trim();
        const nutrition = {};
        // Parse nutrition table
        $('.nutrition-table tr, .pdp-nutrition__row').each((_, row) => {
            const cells = $(row).find('td');
            if (cells.length >= 2) {
                const label = $(cells[0]).text().toLowerCase().trim();
                const value = $(cells[1]).text().trim();
                if (label.includes('energy') && label.includes('kcal'))
                    nutrition.energyKcal = parseNumber(value);
                else if (label.includes('energy') && label.includes('kj'))
                    nutrition.energyKj = parseNumber(value);
                else if (label === 'fat')
                    nutrition.fat = parseNumber(value);
                else if (label.includes('saturate'))
                    nutrition.saturates = parseNumber(value);
                else if (label.includes('carbohydrate'))
                    nutrition.carbohydrate = parseNumber(value);
                else if (label.includes('sugar'))
                    nutrition.sugars = parseNumber(value);
                else if (label.includes('fibre'))
                    nutrition.fibre = parseNumber(value);
                else if (label.includes('protein'))
                    nutrition.protein = parseNumber(value);
                else if (label.includes('salt'))
                    nutrition.salt = parseNumber(value);
            }
        });
        const ingredients = $('.pdp-description-reviews__ingredients-content').text().trim();
        if (!name)
            return null;
        return {
            name,
            nutrition,
            ingredients,
            allergens: identifyAllergens(ingredients)
        };
    }
    catch (error) {
        console.error('Asda extraction error:', error);
        return null;
    }
}
// ============================================================
// GENERIC HTML PARSER
// ============================================================
async function extractGeneric(html) {
    const $ = cheerio.load(html);
    try {
        // Try to find product name
        const name = $('h1').first().text().trim() ||
            $('[class*="product-title"]').first().text().trim() ||
            $('[class*="product-name"]').first().text().trim();
        const nutrition = {};
        // Look for any nutrition table
        $('table').each((_, table) => {
            const tableText = $(table).text().toLowerCase();
            if (tableText.includes('energy') || tableText.includes('protein') || tableText.includes('carbohydrate')) {
                $(table).find('tr').each((_, row) => {
                    const cells = $(row).find('td, th');
                    if (cells.length >= 2) {
                        const label = $(cells[0]).text().toLowerCase().trim();
                        const value = $(cells[1]).text().trim();
                        if (label.includes('energy') && label.includes('kcal'))
                            nutrition.energyKcal = parseNumber(value);
                        else if (label.includes('energy') && label.includes('kj'))
                            nutrition.energyKj = parseNumber(value);
                        else if (label === 'fat')
                            nutrition.fat = parseNumber(value);
                        else if (label.includes('saturate'))
                            nutrition.saturates = parseNumber(value);
                        else if (label.includes('carbohydrate'))
                            nutrition.carbohydrate = parseNumber(value);
                        else if (label.includes('sugar'))
                            nutrition.sugars = parseNumber(value);
                        else if (label.includes('fibre') || label.includes('fiber'))
                            nutrition.fibre = parseNumber(value);
                        else if (label.includes('protein'))
                            nutrition.protein = parseNumber(value);
                        else if (label.includes('salt'))
                            nutrition.salt = parseNumber(value);
                    }
                });
            }
        });
        // Look for ingredients
        const ingredients = $('[class*="ingredient"]').first().text().trim();
        if (!name)
            return null;
        return {
            name,
            nutrition,
            ingredients,
            allergens: identifyAllergens(ingredients)
        };
    }
    catch (error) {
        console.error('Generic extraction error:', error);
        return null;
    }
}
// ============================================================
// MAIN EXTRACTION FUNCTION
// ============================================================
exports.extractUKProductData = functions.https.onCall(async (data, _context) => {
    const { url } = data; // sourceType is optional, we detect from URL
    const timestamp = new Date().toISOString();
    const warnings = [];
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
        // Fetch the page
        const response = await axios_1.default.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-GB,en;q=0.9',
            },
            timeout: 15000,
            maxRedirects: 5
        });
        const html = response.data;
        let extractedData = null;
        let extractionMethod = 'failed';
        let confidence = 0;
        // Strategy 1: Try structured data (JSON-LD)
        extractedData = extractStructuredData(html);
        if (extractedData && extractedData.nutrition && Object.keys(extractedData.nutrition).length >= 3) {
            extractionMethod = 'structured_data';
            confidence = 90;
        }
        // Strategy 2: Try supermarket-specific parser
        if (!extractedData || confidence < 70) {
            const domain = extractDomain(url);
            let supermarketData = null;
            if (domain.includes('tesco')) {
                supermarketData = await extractFromTesco(html);
            }
            else if (domain.includes('sainsbury')) {
                supermarketData = await extractFromSainsburys(html);
            }
            else if (domain.includes('asda')) {
                supermarketData = await extractFromAsda(html);
            }
            else {
                supermarketData = await extractGeneric(html);
            }
            if (supermarketData && supermarketData.nutrition && Object.keys(supermarketData.nutrition).length >= 3) {
                extractedData = supermarketData;
                extractionMethod = 'html_parsing';
                confidence = 80;
            }
        }
        // Validate extracted data
        if (extractedData) {
            // Check for complete UK nutrition data
            const n = extractedData.nutrition;
            if (!n.energyKcal)
                warnings.push('Missing energy (kcal)');
            if (!n.fat && n.fat !== 0)
                warnings.push('Missing fat');
            if (!n.carbohydrate && n.carbohydrate !== 0)
                warnings.push('Missing carbohydrate');
            if (!n.protein && n.protein !== 0)
                warnings.push('Missing protein');
            if (!n.salt && n.salt !== 0)
                warnings.push('Missing salt (UK requirement)');
            // Reduce confidence if data incomplete
            if (warnings.length > 0) {
                confidence = Math.max(confidence - (warnings.length * 10), 30);
            }
            return {
                success: true,
                data: extractedData,
                extractionMethod,
                confidence,
                warnings,
                sourceUrl: url,
                timestamp
            };
        }
        // All strategies failed
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: ['Could not extract nutrition data from page'],
            sourceUrl: url,
            timestamp,
            error: 'Extraction failed - page structure not recognized'
        };
    }
    catch (error) {
        console.error('Extraction error:', error);
        return {
            success: false,
            extractionMethod: 'failed',
            confidence: 0,
            warnings: [],
            sourceUrl: url,
            timestamp,
            error: error.message || 'Failed to fetch or parse page'
        };
    }
});
//# sourceMappingURL=uk-extractor.js.map