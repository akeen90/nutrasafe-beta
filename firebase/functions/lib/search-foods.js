"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchFoods = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios_1 = require("axios");
const additive_analyzer_enhanced_1 = require("./additive-analyzer-enhanced");
// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}
// Helper function to parse raw serving size (no validation)
function parseRawServingSize(servingStr) {
    if (!servingStr || servingStr === '100g serving')
        return 100;
    const match = servingStr.match(/(\d+(?:\.\d+)?)\s*(g|ml|grams?|millilitre?s?)/i);
    if (match) {
        return parseFloat(match[1]);
    }
    return 100;
}
// Validate serving size - reject bad data
function validateServingSize(servingSizeG, servingDescription) {
    // If serving size is suspiciously small (under 50g) for what looks like a meal
    // these are likely RI percentages or parsing errors
    if (servingSizeG < 50 && servingSizeG > 0) {
        // Check if description suggests it's actually a small portion item
        const smallPortionKeywords = ['biscuit', 'sweet', 'chocolate', 'crisp', 'snack', 'bar', 'piece'];
        const isSmallItem = (typeof servingDescription === 'string') ? smallPortionKeywords.some(kw => servingDescription.toLowerCase().includes(kw)) : false;
        if (!isSmallItem) {
            return 100; // Reset to 100g for meals with bad data
        }
    }
    return servingSizeG;
}
// Helper function to check if ingredients are in English
function isEnglishIngredients(ingredientsText) {
    if (!ingredientsText || ingredientsText.trim().length === 0) {
        return false;
    }
    // Check for non-Latin scripts (Arabic, Chinese, Japanese, Korean, Cyrillic, Greek, Thai, etc.)
    const nonLatinPattern = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF\uAC00-\uD7AF\u0400-\u04FF\u0370-\u03FF\u0E00-\u0E7F]/;
    if (nonLatinPattern.test(ingredientsText)) {
        console.log('⚠️ Non-Latin script detected in ingredients (Arabic, Chinese, Japanese, Korean, Cyrillic, Greek, Thai, etc.)');
        return false;
    }
    // Check for common European non-English characters (French, German, Spanish, Italian accents)
    const nonEnglishPattern = /[áàâäãåąčćęèéêëėįìíîïłńòóôöõøùúûüųūÿýżźñçčšž]/i;
    if (nonEnglishPattern.test(ingredientsText)) {
        console.log('⚠️ Non-English European characters detected in ingredients');
        return false;
    }
    // Check for common non-English words
    const nonEnglishWords = [
        // French
        'ingrédients', 'eau', 'huile', 'sucre', 'sel', 'lait', 'beurre',
        // German
        'zutaten', 'wasser', 'zucker', 'salz', 'milch', 'butter',
        // Spanish
        'ingredientes', 'agua', 'azúcar', 'leche', 'mantequilla',
        // Italian
        'ingredienti', 'acqua', 'zucchero', 'latte', 'burro'
    ];
    const lowerText = ingredientsText.toLowerCase();
    const hasNonEnglishWords = nonEnglishWords.some(word => {
        // Check for word boundaries to avoid false positives
        const regex = new RegExp(`\\b${word}\\b`, 'i');
        return regex.test(lowerText);
    });
    if (hasNonEnglishWords) {
        console.log('⚠️ Non-English words detected in ingredients');
        return false;
    }
    // Check for common English food words (positive indicator)
    const englishWords = ['water', 'sugar', 'salt', 'flour', 'oil', 'butter', 'milk', 'wheat', 'ingredients'];
    const hasEnglishWords = englishWords.some(word => {
        const regex = new RegExp(`\\b${word}\\b`, 'i');
        return regex.test(lowerText);
    });
    return hasEnglishWords;
}
// Helper function to check if a product is UK/English
function isUKEnglishProduct(product) {
    // Check countries
    const countries = product.countries_tags || product.countries || [];
    const countriesString = Array.isArray(countries) ? countries.join(',').toLowerCase() : String(countries).toLowerCase();
    const isUKProduct = countriesString.includes('united-kingdom') ||
        countriesString.includes('uk') ||
        countriesString.includes('great-britain') ||
        countriesString.includes('england') ||
        countriesString.includes('scotland') ||
        countriesString.includes('wales') ||
        countriesString.includes('northern-ireland');
    // Check languages
    const languages = product.languages_tags || product.languages || [];
    const languagesString = Array.isArray(languages) ? languages.join(',').toLowerCase() : String(languages).toLowerCase();
    const hasEnglishLanguage = languagesString.includes('en') || languagesString.includes('english');
    // Check ingredients language
    const ingredientsText = product.ingredients_text_en || product.ingredients_text || '';
    const hasEnglishIngredients = isEnglishIngredients(ingredientsText);
    console.log(`🔍 Product check - UK: ${isUKProduct}, English lang: ${hasEnglishLanguage}, English ingredients: ${hasEnglishIngredients}`);
    // Accept if: (UK product OR has English language) AND has English ingredients
    // This ensures we get UK products or any product with proper English ingredient labels
    return (isUKProduct || hasEnglishLanguage) && hasEnglishIngredients;
}
// Helper function to search OpenFoodFacts by product name with UK filtering
async function searchOpenFoodFacts(query) {
    try {
        console.log(`🌍 Searching OpenFoodFacts for: "${query}"`);
        const response = await axios_1.default.get('https://world.openfoodfacts.org/cgi/search.pl', {
            params: {
                search_terms: query,
                search_simple: 1,
                action: 'process',
                json: 1,
                page_size: 10
            },
            timeout: 5000,
            headers: {
                'User-Agent': 'NutraSafe/1.0 (https://nutrasafe.co.uk)'
            }
        });
        if (response.data.products && response.data.products.length > 0) {
            // Filter for UK English products only
            const ukProducts = response.data.products.filter((product) => isUKEnglishProduct(product));
            console.log(`✅ Found ${ukProducts.length} UK English products out of ${response.data.products.length} total`);
            return ukProducts;
        }
        console.log(`⚠️ No products found on OpenFoodFacts for "${query}"`);
        return [];
    }
    catch (error) {
        console.error('❌ OpenFoodFacts API error:', error);
        return [];
    }
}
// Helper function to capitalize each word for consistent formatting
function capitalizeWords(text) {
    if (!text)
        return text;
    return text
        .split(' ')
        .map(word => {
        if (!word)
            return word;
        // Capitalize first letter, keep rest as-is (preserves acronyms like "UK")
        return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
    })
        .join(' ');
}
// Helper function to transform OpenFoodFacts data to our format
function transformOpenFoodFactsProduct(offProduct) {
    const nutriments = offProduct.nutriments || {};
    // Get ingredients text (prefer English version) - iOS app expects a string, not an array
    const ingredientsText = offProduct.ingredients_text_en || offProduct.ingredients_text || '';
    const barcode = offProduct.code || offProduct._id || '';
    // Get raw name and brand, then capitalize for consistent formatting
    const rawName = offProduct.product_name || offProduct.product_name_en || 'Unknown Product';
    const rawBrand = offProduct.brands || null;
    // Extract product image URL (OpenFoodFacts provides multiple image fields)
    const imageUrl = offProduct.image_url || offProduct.image_front_url || offProduct.image_front_small_url || null;
    return {
        id: `off-${barcode}`,
        name: capitalizeWords(rawName),
        brand: rawBrand ? capitalizeWords(rawBrand) : null,
        barcode: barcode,
        calories: { kcal: nutriments['energy-kcal_100g'] || nutriments['energy-kcal'] || 0 },
        protein: { per100g: nutriments.proteins_100g || nutriments.proteins || 0 },
        carbs: { per100g: nutriments.carbohydrates_100g || nutriments.carbohydrates || 0 },
        fat: { per100g: nutriments.fat_100g || nutriments.fat || 0 },
        fiber: { per100g: nutriments.fiber_100g || nutriments.fiber || 0 },
        sugar: { per100g: nutriments.sugars_100g || nutriments.sugars || 0 },
        sodium: nutriments.sodium_100g ? { per100g: nutriments.sodium_100g * 1000 } : (nutriments.salt_100g ? { per100g: nutriments.salt_100g * 1000 } : null),
        servingDescription: 'per 100g',
        ingredients: ingredientsText, // Return as string - iOS app will split it
        imageUrl: imageUrl, // Include product image from OpenFoodFacts
        additives: [],
        processingScore: 0,
        processingGrade: 'A',
        processingLabel: 'Not analyzed',
        micronutrientProfile: null,
        verifiedBy: null,
        verificationMethod: null,
        verifiedAt: null,
        _isOpenFoodFacts: true // Mark as external source
    };
}
// Fixed searchFoods function that properly maps ingredients field
exports.searchFoods = functions
    .runWith({
    timeoutSeconds: 30, // 30 second timeout - fast indexed search
    memory: '512MB' // Reduced memory for faster cold starts
})
    .https.onRequest(async (req, res) => {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    try {
        // Load additive database for analysis
        (0, additive_analyzer_enhanced_1.loadAdditiveDatabase)();
        // Support both GET (?q=search) and POST ({"query": "search"}) for iOS app compatibility
        const query = req.query.q || (req.body && req.body.query) || '';
        if (!query || query.trim().length < 2) {
            res.status(400).json({ error: 'Query must be at least 2 characters' });
            return;
        }
        console.log(`Searching for: "${query}"`);
        // Split query into words for multi-strategy search
        const queryWords = query.toLowerCase().split(/\s+/).filter((word) => word.length > 0);
        // FAST SEARCH: Use targeted queries instead of fetching everything
        let allDocs = new Map();
        // Helper function for fast targeted search with multiple words
        async function fastSearch(collectionName, searchTerms) {
            const searches = [];
            // Search for each word in the query
            for (const searchTerm of searchTerms) {
                // Strategy 1: Capitalize first letter (e.g., "Charlie")
                const capitalized = searchTerm.charAt(0).toUpperCase() + searchTerm.slice(1);
                // Strategy 2: All lowercase (e.g., "charlie")
                const lowercase = searchTerm.toLowerCase();
                // Strategy 3: All uppercase (e.g., "CHARLIE")
                const uppercase = searchTerm.toUpperCase();
                // Run searches in parallel for speed
                for (const term of [capitalized, lowercase, uppercase]) {
                    // Search foodName
                    searches.push(admin.firestore()
                        .collection(collectionName)
                        .where('foodName', '>=', term)
                        .where('foodName', '<=', term + '\uf8ff')
                        .limit(100)
                        .get());
                    // Search brandName
                    searches.push(admin.firestore()
                        .collection(collectionName)
                        .where('brandName', '>=', term)
                        .where('brandName', '<=', term + '\uf8ff')
                        .limit(100)
                        .get());
                }
            }
            const results = await Promise.allSettled(searches);
            let count = 0;
            results.forEach((result) => {
                if (result.status === 'fulfilled') {
                    result.value.docs.forEach((doc) => {
                        if (!allDocs.has(doc.id)) {
                            allDocs.set(doc.id, doc);
                            count++;
                        }
                    });
                }
            });
            return count;
        }
        // Helper function for Tesco search (uses 'title' and 'brand' field names)
        async function fastSearchTesco(searchTerms) {
            const searches = [];
            // Search for each word in the query
            for (const searchTerm of searchTerms) {
                const capitalized = searchTerm.charAt(0).toUpperCase() + searchTerm.slice(1);
                const lowercase = searchTerm.toLowerCase();
                const uppercase = searchTerm.toUpperCase();
                // Run searches in parallel for speed
                for (const term of [capitalized, lowercase, uppercase]) {
                    // Search title (Tesco uses 'title' instead of 'foodName')
                    searches.push(admin.firestore()
                        .collection('tescoProducts')
                        .where('title', '>=', term)
                        .where('title', '<=', term + '\uf8ff')
                        .limit(50)
                        .get());
                    // Search brand
                    searches.push(admin.firestore()
                        .collection('tescoProducts')
                        .where('brand', '>=', term)
                        .where('brand', '<=', term + '\uf8ff')
                        .limit(50)
                        .get());
                }
            }
            const results = await Promise.allSettled(searches);
            let count = 0;
            results.forEach((result) => {
                if (result.status === 'fulfilled') {
                    result.value.docs.forEach((doc) => {
                        if (!allDocs.has(doc.id)) {
                            allDocs.set(doc.id, doc);
                            count++;
                        }
                    });
                }
            });
            return count;
        }
        // Search all collections in parallel (much faster!)
        const startTime = Date.now();
        const [verifiedCount, foodsCount, ukCleanedCount, tescoCount] = await Promise.all([
            fastSearch('verifiedFoods', queryWords),
            fastSearch('foods', queryWords),
            fastSearch('uk_foods_cleaned', queryWords),
            fastSearchTesco(queryWords)
        ]);
        const searchTime = Date.now() - startTime;
        console.log(`⚡ Fast search completed in ${searchTime}ms - found ${allDocs.size} candidates (${verifiedCount} verified, ${foodsCount} foods, ${ukCleanedCount} uk_cleaned, ${tescoCount} Tesco)`);
        const verifiedSnapshot = { docs: Array.from(allDocs.values()) };
        // Convert to results and add relevance scoring
        let allResults = verifiedSnapshot.docs.map(doc => {
            const data = doc.data();
            if (!data)
                return null; // Skip if no data
            const nutrition = data.nutritionData || data.nutrition || {};
            // Handle multiple field names (Tesco uses 'title', standard uses 'foodName')
            const foodName = data.foodName || data.title || data.name || '';
            const brandName = data.brandName || data.brand || '';
            const imageUrl = data.imageUrl || null;
            // Calculate relevance score for ranking
            let relevanceScore = calculateRelevance(foodName, brandName, query, queryWords);
            // DEBUG: Log image URL status for twix products
            if (query.toLowerCase().includes('twi')) {
                console.log(`📸 ${foodName}: imageUrl=${imageUrl ? 'YES' : 'NO'}, baseScore=${relevanceScore}`);
            }
            // SMART IMAGE BOOST: Balance visual results with search relevance
            // - Generic searches (1-2 words like "twix") → BIG boost (users want to see variants)
            // - Specific searches (3+ words like "twix fingers biscuit") → SMALL boost (users want exact match)
            if (imageUrl && imageUrl.length > 0) {
                if (queryWords.length <= 2) {
                    // Generic search: prioritize images heavily to show product variants
                    relevanceScore += 20000; // Big boost for short queries
                    if (query.toLowerCase().includes('twi')) {
                        console.log(`  ✅ Applied +20000 boost → finalScore=${relevanceScore}`);
                    }
                }
                else {
                    // Specific search: still prefer images but don't override exact matches
                    relevanceScore += 500; // Small boost for specific queries
                }
            }
            // Analyze ingredients for additives and processing score
            let additiveAnalysis = null;
            let processingInfo = null;
            const ingredientsData = data.extractedIngredients || data.ingredients || null;
            const ingredientsString = Array.isArray(ingredientsData) ? ingredientsData.join(', ') : ingredientsData;
            if (ingredientsString && typeof ingredientsString === 'string') {
                try {
                    const analysisResult = (0, additive_analyzer_enhanced_1.analyzeIngredientsForAdditives)(ingredientsString);
                    const processingScore = (0, additive_analyzer_enhanced_1.calculateProcessingScore)(analysisResult.detectedAdditives, ingredientsString);
                    const grade = (0, additive_analyzer_enhanced_1.determineGrade)(processingScore.totalScore, analysisResult.hasRedFlags);
                    // Transform additives to match iOS app expectations
                    additiveAnalysis = analysisResult.detectedAdditives.map(additive => ({
                        ...additive,
                        id: additive.code, // Use code as ID for iOS Identifiable requirement
                        consumerInfo: additive.consumer_guide
                    }));
                    processingInfo = {
                        score: processingScore.totalScore,
                        grade: grade.grade,
                        label: grade.label,
                        breakdown: processingScore.breakdown
                    };
                }
                catch (error) {
                    console.log(`Additive analysis failed for ${foodName}:`, error);
                }
            }
            // Format data exactly as iOS app expects
            // Handle Tesco field names: energyKcal, carbohydrate, fibre, sugars
            const calorieValue = nutrition.calories || nutrition.energyKcal || nutrition.energy || data.calories || 0;
            const proteinValue = nutrition.protein || data.protein || 0;
            const carbsValue = nutrition.carbs || nutrition.carbohydrates || nutrition.carbohydrate || data.carbs || 0;
            const fatValue = nutrition.fat || data.fat || 0;
            const fiberValue = nutrition.fiber || nutrition.fibre || data.fiber || 0;
            const sugarValue = nutrition.sugar || nutrition.sugars || data.sugar || 0;
            const sodiumValue = nutrition.sodium || data.sodium || (nutrition.salt ? nutrition.salt * 1000 : 0);
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
                parseRawServingSize(servingDescription);
            // Validate and fix bad serving size data (e.g., RI% mistaken for grams)
            let servingSizeG = validateServingSize(rawServingSizeG, servingDescription);
            // If serving size was reset due to bad data, update description too
            if (rawServingSizeG < 50 && rawServingSizeG > 0 && servingSizeG === 100) {
                servingDescription = '100g serving';
            }
            return {
                id: doc.id,
                name: foodName,
                brand: brandName || null,
                barcode: data.barcode || data.gtin || '',
                calories: typeof calorieValue === 'object' ? calorieValue : { kcal: calorieValue },
                protein: typeof proteinValue === 'object' ? proteinValue : { per100g: proteinValue },
                carbs: typeof carbsValue === 'object' ? carbsValue : { per100g: carbsValue },
                fat: typeof fatValue === 'object' ? fatValue : { per100g: fatValue },
                fiber: typeof fiberValue === 'object' ? fiberValue : { per100g: fiberValue },
                sugar: typeof sugarValue === 'object' ? sugarValue : { per100g: sugarValue },
                sodium: sodiumValue ? (typeof sodiumValue === 'object' ? sodiumValue : { per100g: sodiumValue }) : null,
                servingDescription: servingDescription,
                servingSizeG: servingSizeG,
                suggestedServingUnit: data.suggestedServingUnit || null,
                unitOverrideLocked: data.unitOverrideLocked || false,
                // CRITICAL FIX: Map ingredients field for iOS app - keep as array
                ingredients: (() => {
                    const ingredientsData = data.extractedIngredients || data.ingredients || null;
                    if (Array.isArray(ingredientsData)) {
                        return ingredientsData; // Return array directly
                    }
                    // If it's a string, split it into array
                    if (typeof ingredientsData === 'string' && ingredientsData.trim()) {
                        return ingredientsData.split(',').map(i => i.trim()).filter(i => i.length > 0);
                    }
                    return null;
                })(),
                // CRITICAL FIX: Include verification status for dashboard filtering
                verifiedBy: data.verifiedBy || null,
                verificationMethod: data.verificationMethod || null,
                verifiedAt: data.verifiedAt || null,
                // Include micronutrient profile for vitamins/minerals display
                micronutrientProfile: data.micronutrientProfile || null,
                // Include product image URL for visual search results
                imageUrl: imageUrl,
                // Include additive analysis using comprehensive 400+ database
                additives: additiveAnalysis || [],
                processingScore: processingInfo?.score || 0,
                processingGrade: processingInfo?.grade || 'A',
                processingLabel: processingInfo?.label || 'Minimal processing',
                // Add relevance score for sorting
                _relevance: relevanceScore
            };
        })
            .filter(result => result !== null); // Remove null entries
        // Filter results that actually match the query and sort by relevance
        const filteredResults = allResults
            .filter(result => {
            const nameMatch = matchesQuery(result.name, query, queryWords);
            const brandMatch = result.brand ? matchesQuery(result.brand, query, queryWords) : false;
            return nameMatch || brandMatch;
        })
            .sort((a, b) => b._relevance - a._relevance) // Sort by relevance descending
            .slice(0, 20) // Limit to 20 results
            .map(result => {
            // Remove internal relevance score from final results
            const { _relevance, ...cleanResult } = result;
            return cleanResult;
        });
        console.log(`Found ${filteredResults.length} relevant foods from ${allResults.length} total`);
        // Also check if any results have ingredients
        const withIngredients = filteredResults.filter(r => r.ingredients && r.ingredients.length > 0);
        console.log(`${withIngredients.length} foods have ingredients data`);
        // Always search OpenFoodFacts to find products we don't have
        console.log(`Searching OpenFoodFacts for additional products: "${query}"`);
        const offProducts = await searchOpenFoodFacts(query);
        if (offProducts.length > 0) {
            console.log(`Found ${offProducts.length} products from OpenFoodFacts`);
            // Get all barcodes from internal results to avoid duplicates
            const internalBarcodes = new Set(filteredResults
                .map(r => r.barcode)
                .filter(b => b && b.length > 0));
            // Transform and analyze OpenFoodFacts products, filtering out duplicates
            const offResults = offProducts
                .filter(offProduct => {
                const barcode = offProduct.code || offProduct._id || '';
                const isDuplicate = barcode && internalBarcodes.has(barcode);
                if (isDuplicate) {
                    console.log(`Skipping duplicate barcode from OpenFoodFacts: ${barcode}`);
                }
                return !isDuplicate;
            })
                .map(offProduct => {
                const transformed = transformOpenFoodFactsProduct(offProduct);
                // Analyze ingredients for additives if available (ingredients is now a string)
                if (transformed.ingredients && transformed.ingredients.length > 0) {
                    try {
                        const ingredientsString = transformed.ingredients; // Already a string
                        const analysisResult = (0, additive_analyzer_enhanced_1.analyzeIngredientsForAdditives)(ingredientsString);
                        const processingScore = (0, additive_analyzer_enhanced_1.calculateProcessingScore)(analysisResult.detectedAdditives, ingredientsString);
                        const grade = (0, additive_analyzer_enhanced_1.determineGrade)(processingScore.totalScore, analysisResult.hasRedFlags);
                        transformed.additives = analysisResult.detectedAdditives.map(additive => ({
                            ...additive,
                            id: additive.code,
                            consumerInfo: additive.consumer_guide
                        }));
                        transformed.processingScore = processingScore.totalScore;
                        transformed.processingGrade = grade.grade;
                        transformed.processingLabel = grade.label;
                    }
                    catch (error) {
                        console.log(`Additive analysis failed for OpenFoodFacts product:`, error);
                    }
                }
                // Calculate relevance score for OpenFoodFacts results
                let relevanceScore = calculateRelevance(transformed.name, transformed.brand || '', query, queryWords);
                // Apply same image boost logic as internal results
                if (transformed.imageUrl && transformed.imageUrl.length > 0) {
                    if (queryWords.length <= 2) {
                        relevanceScore += 20000; // Generic search boost
                    }
                    else {
                        relevanceScore += 500; // Specific search boost
                    }
                }
                // Add _relevance for sorting
                return { ...transformed, _relevance: relevanceScore };
            });
            console.log(`✅ Found ${offResults.length} unique UK English products from OpenFoodFacts (${offProducts.length - offResults.length} duplicates filtered)`);
            // CRITICAL FIX: Re-add _relevance to filteredResults for proper sorting
            const filteredWithRelevance = allResults
                .filter(result => {
                const nameMatch = matchesQuery(result.name, query, queryWords);
                const brandMatch = result.brand ? matchesQuery(result.brand, query, queryWords) : false;
                return nameMatch || brandMatch;
            });
            // Merge and sort ALL results by relevance (internal + OpenFoodFacts)
            const mergedResults = [...filteredWithRelevance, ...offResults]
                .sort((a, b) => b._relevance - a._relevance) // Sort by relevance descending
                .slice(0, 20) // Limit to top 20
                .map(result => {
                // Remove internal relevance score from final results
                const { _relevance, ...cleanResult } = result;
                return cleanResult;
            });
            console.log(`📊 Returning ${mergedResults.length} total results (${filteredResults.length} internal + ${offResults.length} OpenFoodFacts)`);
            // Return merged results
            res.json({
                foods: mergedResults
            });
            return;
        }
        console.log(`No additional products found on OpenFoodFacts`);
        // Return in the exact format iOS app expects
        res.json({
            foods: filteredResults
        });
    }
    catch (error) {
        console.error('Error searching foods:', error);
        res.status(500).json({ error: 'Failed to search foods' });
    }
});
// Google-like relevance scoring
function calculateRelevance(foodName, brandName, originalQuery, queryWords) {
    const name = foodName.toLowerCase();
    const brand = brandName.toLowerCase();
    const query = originalQuery.toLowerCase();
    let score = 0;
    // Count how many query words match in brand and name
    const brandMatches = queryWords.filter(word => brand.includes(word));
    const nameMatches = queryWords.filter(word => name.includes(word));
    const brandMatchRatio = brandMatches.length / queryWords.length;
    const nameMatchRatio = nameMatches.length / queryWords.length;
    // === TIER 1: EXACT MATCHES (1000-900 points) ===
    if (name === query) {
        return 1000; // Perfect name match
    }
    if (brand === query) {
        return 950; // Perfect brand match
    }
    // === TIER 2: FULL QUERY STRING MATCHES (800-600 points) ===
    if (brand.includes(query)) {
        score = 800;
        if (brand.startsWith(query))
            score += 50; // Bonus for prefix
        return score;
    }
    if (name.includes(query)) {
        score = 700;
        if (name.startsWith(query))
            score += 50; // Bonus for prefix
        return score;
    }
    // === TIER 3: ALL QUERY WORDS PRESENT (600-400 points) ===
    if (brandMatchRatio === 1.0) {
        score = 600;
        // Bonus for words in order
        if (wordsInOrder(brand, queryWords))
            score += 100;
        // Bonus for starting with first word
        if (brand.startsWith(queryWords[0]))
            score += 75;
        return score;
    }
    if (nameMatchRatio === 1.0) {
        score = 500;
        // Bonus for words in order
        if (wordsInOrder(name, queryWords))
            score += 100;
        // Bonus for starting with first word
        if (name.startsWith(queryWords[0]))
            score += 50;
        return score;
    }
    // === TIER 4: PARTIAL MATCHES (400-200 points) ===
    // Prioritize brand matches over name matches
    if (brandMatchRatio >= 0.5) {
        score = 400 * brandMatchRatio;
        if (brand.startsWith(queryWords[0]))
            score += 50;
    }
    else if (nameMatchRatio >= 0.5) {
        score = 300 * nameMatchRatio;
        if (name.startsWith(queryWords[0]))
            score += 30;
    }
    else {
        // Very weak match - just count any word matches
        score = (brandMatches.length * 40) + (nameMatches.length * 20);
    }
    // === TIER 5: QUALITY BONUSES (up to 100 points) ===
    // Bonus for shorter, more precise matches
    const lengthBonus = Math.max(0, 50 - Math.min(name.length, 50));
    score += lengthBonus;
    // Bonus for matches at word boundaries (e.g., "charlie" matches "Charlie Bigham's" better than "charliex")
    if (hasWordBoundaryMatch(brand, queryWords[0]) || hasWordBoundaryMatch(name, queryWords[0])) {
        score += 30;
    }
    return score;
}
// Helper: Check if words appear in order in text
function wordsInOrder(text, words) {
    let lastIndex = -1;
    for (const word of words) {
        const index = text.indexOf(word, lastIndex + 1);
        if (index <= lastIndex)
            return false;
        lastIndex = index;
    }
    return true;
}
// Helper: Check if word matches at word boundary
function hasWordBoundaryMatch(text, word) {
    // Check if word appears at start or after a space/punctuation
    const regex = new RegExp(`(^|\\s|-)${word}`, 'i');
    return regex.test(text);
}
// Helper function to check if text matches query (Google-like flexible matching)
function matchesQuery(text, originalQuery, queryWords) {
    if (!text)
        return false;
    const lowerText = text.toLowerCase();
    const query = originalQuery.toLowerCase();
    // Direct match of full query string (best match)
    if (lowerText.includes(query))
        return true;
    // For single word queries, just check if word is present
    if (queryWords.length === 1) {
        return lowerText.includes(queryWords[0]);
    }
    // For multi-word queries: require at least 50% of words to match
    const matchedWords = queryWords.filter(word => lowerText.includes(word));
    return matchedWords.length >= Math.ceil(queryWords.length / 2);
}
//# sourceMappingURL=search-foods.js.map