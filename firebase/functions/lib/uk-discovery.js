"use strict";
/**
 * UK Product Page Discovery Service
 *
 * Uses Google Custom Search API to find official UK supermarket and manufacturer
 * product pages for food items. Only returns results from whitelisted UK domains.
 *
 * This is a DISCOVERY tool - it finds where the data is, not the data itself.
 * The actual extraction happens in uk-extractor.ts
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateManualSearchLinks = exports.discoverUKProductPage = void 0;
const functions = require("firebase-functions");
const axios_1 = require("axios");
const UK_APPROVED_SOURCES = [
    // Tier 1: Major UK Supermarkets
    { domain: 'tesco.com', name: 'Tesco', type: 'supermarket', productPattern: /\/groceries\/.*\/products\//, priority: 1 },
    { domain: 'sainsburys.co.uk', name: "Sainsbury's", type: 'supermarket', productPattern: /\/gol-ui\/product\//, priority: 1 },
    { domain: 'asda.com', name: 'Asda', type: 'supermarket', productPattern: /\/product\//, priority: 1 },
    { domain: 'groceries.asda.com', name: 'Asda Groceries', type: 'supermarket', productPattern: /\/product\//, priority: 1 },
    { domain: 'morrisons.com', name: 'Morrisons', type: 'supermarket', productPattern: /\/products\//, priority: 1 },
    { domain: 'groceries.morrisons.com', name: 'Morrisons Groceries', type: 'supermarket', productPattern: /\/products\//, priority: 1 },
    { domain: 'waitrose.com', name: 'Waitrose', type: 'supermarket', productPattern: /\/ecom\/products\//, priority: 1 },
    { domain: 'ocado.com', name: 'Ocado', type: 'supermarket', productPattern: /\/product\//, priority: 1 },
    // Tier 2: Other UK Supermarkets
    { domain: 'aldi.co.uk', name: 'Aldi UK', type: 'supermarket', priority: 2 },
    { domain: 'lidl.co.uk', name: 'Lidl UK', type: 'supermarket', priority: 2 },
    { domain: 'iceland.co.uk', name: 'Iceland', type: 'supermarket', priority: 2 },
    { domain: 'coop.co.uk', name: 'Co-op', type: 'supermarket', priority: 2 },
    { domain: 'marksandspencer.com', name: 'M&S', type: 'supermarket', priority: 2 },
    // Tier 3: UK Food Retailers
    { domain: 'boots.com', name: 'Boots', type: 'retailer', priority: 3 },
    { domain: 'hollandandbarrett.com', name: 'Holland & Barrett', type: 'retailer', priority: 3 },
];
// ============================================================
// BARCODE COUNTRY DETECTION
// ============================================================
// GS1 barcode prefixes by country/region
const BARCODE_PREFIXES = [
    { prefix: '500', country: 'UK', isUK: true },
    { prefix: '501', country: 'UK', isUK: true },
    { prefix: '509', country: 'UK', isUK: true },
    { prefix: '539', country: 'Ireland', isUK: false }, // Close enough, often sold in UK
    { prefix: '00', country: 'USA/Canada', isUK: false },
    { prefix: '01', country: 'USA/Canada', isUK: false },
    { prefix: '02', country: 'Store Internal', isUK: false },
    { prefix: '030', country: 'USA/Canada', isUK: false },
    { prefix: '040', country: 'Germany', isUK: false },
    { prefix: '300', country: 'France', isUK: false },
    { prefix: '400', country: 'Germany', isUK: false },
    { prefix: '450', country: 'Japan', isUK: false },
    { prefix: '460', country: 'Russia', isUK: false },
    { prefix: '471', country: 'Taiwan', isUK: false },
    { prefix: '489', country: 'Hong Kong', isUK: false },
    { prefix: '520', country: 'Greece', isUK: false },
    { prefix: '529', country: 'Cyprus', isUK: false },
    { prefix: '531', country: 'North Macedonia', isUK: false },
    { prefix: '535', country: 'Malta', isUK: false },
    { prefix: '540', country: 'Belgium/Luxembourg', isUK: false },
    { prefix: '560', country: 'Portugal', isUK: false },
    { prefix: '569', country: 'Iceland', isUK: false },
    { prefix: '570', country: 'Denmark', isUK: false },
    { prefix: '590', country: 'Poland', isUK: false },
    { prefix: '599', country: 'Hungary', isUK: false },
    { prefix: '600', country: 'South Africa', isUK: false },
    { prefix: '609', country: 'Mauritius', isUK: false },
    { prefix: '611', country: 'Morocco', isUK: false },
    { prefix: '619', country: 'Tunisia', isUK: false },
    { prefix: '621', country: 'Syria', isUK: false },
    { prefix: '628', country: 'Saudi Arabia', isUK: false },
    { prefix: '629', country: 'UAE', isUK: false },
    { prefix: '640', country: 'Finland', isUK: false },
    { prefix: '690', country: 'China', isUK: false },
    { prefix: '729', country: 'Israel', isUK: false },
    { prefix: '730', country: 'Sweden', isUK: false },
    { prefix: '740', country: 'Guatemala', isUK: false },
    { prefix: '750', country: 'Mexico', isUK: false },
    { prefix: '759', country: 'Venezuela', isUK: false },
    { prefix: '760', country: 'Switzerland', isUK: false },
    { prefix: '770', country: 'Colombia', isUK: false },
    { prefix: '773', country: 'Uruguay', isUK: false },
    { prefix: '775', country: 'Peru', isUK: false },
    { prefix: '777', country: 'Bolivia', isUK: false },
    { prefix: '779', country: 'Argentina', isUK: false },
    { prefix: '780', country: 'Chile', isUK: false },
    { prefix: '784', country: 'Paraguay', isUK: false },
    { prefix: '786', country: 'Ecuador', isUK: false },
    { prefix: '789', country: 'Brazil', isUK: false },
    { prefix: '800', country: 'Italy', isUK: false },
    { prefix: '840', country: 'Spain', isUK: false },
    { prefix: '850', country: 'Cuba', isUK: false },
    { prefix: '858', country: 'Slovakia', isUK: false },
    { prefix: '859', country: 'Czech Republic', isUK: false },
    { prefix: '860', country: 'Serbia', isUK: false },
    { prefix: '869', country: 'Turkey', isUK: false },
    { prefix: '870', country: 'Netherlands', isUK: false },
    { prefix: '880', country: 'South Korea', isUK: false },
    { prefix: '885', country: 'Thailand', isUK: false },
    { prefix: '888', country: 'Singapore', isUK: false },
    { prefix: '890', country: 'India', isUK: false },
    { prefix: '893', country: 'Vietnam', isUK: false },
    { prefix: '899', country: 'Indonesia', isUK: false },
    { prefix: '900', country: 'Austria', isUK: false },
    { prefix: '930', country: 'Australia', isUK: false },
    { prefix: '940', country: 'New Zealand', isUK: false },
    { prefix: '955', country: 'Malaysia', isUK: false },
    { prefix: '958', country: 'Macau', isUK: false },
];
function getBarcodeCountry(barcode) {
    if (!barcode || barcode.length < 3)
        return null;
    // Try 3-digit prefix first, then 2-digit
    for (const len of [3, 2]) {
        const prefix = barcode.substring(0, len);
        const match = BARCODE_PREFIXES.find(p => p.prefix === prefix);
        if (match)
            return { country: match.country, isUK: match.isUK };
    }
    return null;
}
// ============================================================
// HELPER FUNCTIONS
// ============================================================
function extractDomain(url) {
    try {
        const hostname = new URL(url).hostname.toLowerCase();
        // Remove 'www.' prefix if present
        return hostname.replace(/^www\./, '');
    }
    catch {
        return '';
    }
}
function findApprovedSource(url) {
    const domain = extractDomain(url);
    return UK_APPROVED_SOURCES.find(source => domain === source.domain || domain.endsWith('.' + source.domain)) || null;
}
function calculateConfidence(url, source, hasBarcode, searchQuery) {
    let confidence = 50; // Base confidence for being on approved domain
    // Higher confidence for Tier 1 supermarkets
    if (source.priority === 1)
        confidence += 20;
    else if (source.priority === 2)
        confidence += 10;
    // Higher confidence if URL matches product page pattern
    if (source.productPattern && source.productPattern.test(url)) {
        confidence += 15;
    }
    // Higher confidence if searching by barcode (more precise)
    if (hasBarcode) {
        confidence += 10;
    }
    // Cap at 95 (never 100% - human verification always recommended)
    return Math.min(confidence, 95);
}
function isProductPage(url, source) {
    if (source.productPattern) {
        return source.productPattern.test(url);
    }
    // Fallback: check for common product URL patterns
    const productPatterns = [
        /\/product\//i,
        /\/products\//i,
        /\/p\//i,
        /\/item\//i,
        /\/groceries\/.*\/\d+/i,
    ];
    return productPatterns.some(pattern => pattern.test(url));
}
// ============================================================
// GOOGLE CUSTOM SEARCH
// ============================================================
// Primary method: Direct API call via axios
async function searchGoogleDirect(query, apiKey, searchEngineId) {
    const url = 'https://www.googleapis.com/customsearch/v1';
    const response = await axios_1.default.get(url, {
        params: {
            key: apiKey,
            cx: searchEngineId,
            q: query,
            num: 10,
            gl: 'uk',
            lr: 'lang_en',
        }
    });
    return {
        items: response.data.items || []
    };
}
// ============================================================
// MAIN DISCOVERY FUNCTION
// ============================================================
exports.discoverUKProductPage = functions.https.onCall(async (data, context) => {
    const timestamp = new Date().toISOString();
    // Get API keys from environment/config
    const apiKey = functions.config().google?.custom_search_api_key || functions.config().google?.search_api_key;
    const searchEngineId = functions.config().google?.search_engine_id;
    if (!apiKey || !searchEngineId) {
        console.error('Google Custom Search API not configured.');
        return {
            success: false,
            searchQuery: '',
            sources: [],
            totalFound: 0,
            timestamp,
            error: 'Google Custom Search API not configured.'
        };
    }
    const { foodName, barcode, brand } = data;
    const hasBarcode = !!barcode && barcode.length >= 8;
    // Check barcode country - detect foreign products
    let barcodeCountry = null;
    if (hasBarcode) {
        barcodeCountry = getBarcodeCountry(barcode);
        console.log(`Barcode ${barcode} -> Country: ${barcodeCountry?.country || 'Unknown'}, isUK: ${barcodeCountry?.isUK}`);
    }
    // Build search strategies (try in order until results found)
    const searchStrategies = [];
    // Top UK supermarket domains for site restriction (simplified)
    const topSites = 'site:tesco.com OR site:sainsburys.co.uk OR site:asda.com OR site:morrisons.com OR site:waitrose.com OR site:ocado.com';
    // Strategy 1: UK barcode search (only if barcode is UK origin)
    if (hasBarcode && barcodeCountry?.isUK) {
        searchStrategies.push({
            name: 'UK Barcode',
            query: `${barcode} (${topSites})`
        });
    }
    // Strategy 2: Brand + Product name (most likely to succeed)
    if (brand && foodName) {
        // Check if brand contains UK supermarket name
        const ukBrands = ['tesco', 'sainsbury', 'asda', 'morrisons', 'waitrose', 'aldi', 'lidl', 'co-op', 'm&s', 'marks'];
        const brandLower = brand.toLowerCase();
        const isUKBrand = ukBrands.some(b => brandLower.includes(b));
        if (isUKBrand) {
            // UK own-brand product - search that supermarket directly
            searchStrategies.push({
                name: 'UK Brand Direct',
                query: `"${brand}" "${foodName}" nutrition`
            });
        }
        searchStrategies.push({
            name: 'Brand + Name',
            query: `"${brand}" "${foodName}" (${topSites})`
        });
    }
    // Strategy 3: Just product name with sites
    if (foodName) {
        searchStrategies.push({
            name: 'Name Only',
            query: `"${foodName}" nutrition (${topSites})`
        });
    }
    // Strategy 4: Barcode (any origin) - last resort
    if (hasBarcode && !barcodeCountry?.isUK) {
        searchStrategies.push({
            name: 'Non-UK Barcode',
            query: `${barcode} (${topSites})`
        });
    }
    // Try each strategy until we find results
    let sources = [];
    let usedQuery = '';
    for (const strategy of searchStrategies) {
        try {
            console.log(`Trying strategy: ${strategy.name} - Query: ${strategy.query}`);
            const searchResult = await searchGoogleDirect(strategy.query, apiKey, searchEngineId);
            // Process results
            const foundSources = [];
            for (const item of searchResult.items) {
                const url = item.link;
                const approvedSource = findApprovedSource(url);
                if (!approvedSource)
                    continue;
                const isProduct = isProductPage(url, approvedSource);
                const confidence = calculateConfidence(url, approvedSource, hasBarcode, strategy.query);
                foundSources.push({
                    url,
                    domain: extractDomain(url),
                    sourceName: approvedSource.name,
                    sourceType: approvedSource.type,
                    title: item.title || '',
                    snippet: item.snippet || '',
                    confidence,
                    isProductPage: isProduct,
                    priority: approvedSource.priority
                });
            }
            if (foundSources.length > 0) {
                sources = foundSources;
                usedQuery = strategy.query;
                console.log(`Strategy "${strategy.name}" found ${foundSources.length} results`);
                break; // Found results, stop trying
            }
        }
        catch (error) {
            console.error(`Strategy "${strategy.name}" failed:`, error.message);
        }
    }
    // Sort by priority then confidence
    sources.sort((a, b) => {
        if (a.priority !== b.priority)
            return a.priority - b.priority;
        return b.confidence - a.confidence;
    });
    // Build informative error message if no results
    let error;
    if (sources.length === 0) {
        if (barcodeCountry && !barcodeCountry.isUK) {
            error = `Non-UK product (${barcodeCountry.country} barcode) - not found on UK supermarket sites`;
        }
        else {
            error = 'No matching product found on UK supermarket sites';
        }
    }
    return {
        success: sources.length > 0,
        searchQuery: usedQuery || searchStrategies[0]?.query || '',
        sources,
        totalFound: sources.length,
        timestamp,
        error
    };
});
// ============================================================
// MANUAL DISCOVERY (NO API KEY REQUIRED)
// Generates search URLs for manual verification
// ============================================================
exports.generateManualSearchLinks = functions.https.onCall(async (data, context) => {
    const { foodName, barcode, brand } = data;
    const searchTerm = barcode || `${brand || ''} ${foodName || ''}`.trim();
    const encodedSearch = encodeURIComponent(searchTerm);
    // Build site-restricted Google query
    const siteRestrictions = UK_APPROVED_SOURCES
        .filter(s => s.priority <= 2)
        .map(s => `site:${s.domain}`)
        .join(' OR ');
    const googleQuery = `${searchTerm} (${siteRestrictions})`;
    // Generate direct search links for each supermarket
    const supermarketLinks = [
        {
            name: 'Tesco',
            url: `https://www.tesco.com/groceries/en-GB/search?query=${encodedSearch}`,
            domain: 'tesco.com'
        },
        {
            name: "Sainsbury's",
            url: `https://www.sainsburys.co.uk/gol-ui/SearchResults/${encodedSearch}`,
            domain: 'sainsburys.co.uk'
        },
        {
            name: 'Asda',
            url: `https://groceries.asda.com/search/${encodedSearch}`,
            domain: 'asda.com'
        },
        {
            name: 'Morrisons',
            url: `https://groceries.morrisons.com/search?entry=${encodedSearch}`,
            domain: 'morrisons.com'
        },
        {
            name: 'Waitrose',
            url: `https://www.waitrose.com/ecom/shop/search?searchTerm=${encodedSearch}`,
            domain: 'waitrose.com'
        },
        {
            name: 'Ocado',
            url: `https://www.ocado.com/search?entry=${encodedSearch}`,
            domain: 'ocado.com'
        },
        {
            name: 'Aldi UK',
            url: `https://www.aldi.co.uk/search?q=${encodedSearch}`,
            domain: 'aldi.co.uk'
        },
        {
            name: 'Lidl UK',
            url: `https://www.lidl.co.uk/q/query/${encodedSearch}`,
            domain: 'lidl.co.uk'
        }
    ];
    return {
        success: true,
        googleQuery,
        supermarketLinks
    };
});
//# sourceMappingURL=uk-discovery.js.map